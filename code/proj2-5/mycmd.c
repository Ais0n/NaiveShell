/*
程序名：mycmd.c
作者：黄彦玮
学号：3180102067
说明：myshell命令执行模块
完成时间：2020-08-18
*/
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <time.h>
#include <fcntl.h>
#include <signal.h>
#include <sys/wait.h>
#include <sys/signal.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <errno.h>
#include <dirent.h>
#include <pwd.h>
#include "mycmd.h"
#include "main.h"
#include "proc_list.h"
extern char **environ;                       //环境变量
extern char dirname[BUF];                    //当前目录名称
extern int proc_num;                         //进程表大小
extern char arg[MAX_ARG][BUF];               //分割后的命令
extern struct proc_item proc_list[MAX_PROC]; //进程表
extern int stdin_copy;                       //stdin文件描述符的备份

//cd指令
int execd(int l, int r)
{
    //检查参数个数，下同
    if (r - l > 2)
        return ARG_TOO_MANY; //参数过多
    if (r - l == 2)          //2个参数时，修改目录到参数对应目录
    {
        int res = chdir(arg[l + 1]);
        if (res)
            return ARG_WRONG; //参数错误（路径打不开）
    }
    else //1个参数时，切换到主目录
    {
        int res = chdir(getenv("HOME"));
        if (res)
            return HOME_CANNOT_GET; //无法获取主目录路径
    }
    return EXIT_OK; //正常退出
}

//clr指令
int execlr(int l, int r)
{
    if (r - l > 1)
        return ARG_TOO_MANY;
    //清屏
    printf("\033[1H\033[2J");
    return EXIT_OK;
}

//pwd指令
int exepwd(int l, int r)
{
    if (r - l > 1)
        return ARG_TOO_MANY;
    //获取当前目录名称
    if (getworkdir(dirname) == -1)
        return CURPATH_FAILED; //无法获取当前路径
    //输出当前目录名称
    printf("%s\n", dirname);
    return EXIT_OK;
}

//time指令
int exetime(int l, int r)
{
    if (r - l > 1)
        return ARG_TOO_MANY;
    time_t *timep = malloc(sizeof(*timep));
    //获取时间戳并转化成字符形式
    time(timep);
    char *s = ctime(timep);
    printf("%s", s);
    return EXIT_OK;
}

//dir指令
int exedir(int l, int r)
{
    if (r - l > 2)
        return ARG_TOO_MANY;
    else if (r - l < 2)
        return ARG_TOO_FEW; //参数过少
    DIR *dp;
    struct dirent *entry;
    struct stat statbuf;
    //调用系统调用，新建目录流
    if ((dp = opendir(arg[l + 1])) == NULL)
        return ARG_WRONG;
    //切换到对应文件夹
    chdir(arg[l + 1]);
    //依次从目录流中读取目录下文件信息
    while ((entry = readdir(dp)) != NULL)
    {
        //获取文件属性，d_name是文件名，statbuf是文件属性，其中statbuf.st_mode是文件类型
        lstat(entry->d_name, &statbuf);
        //根据不同的文件类型采取不同的输出方式
        if (S_ISDIR(statbuf.st_mode)) //目录，蓝色
        {
            if (strcmp(entry->d_name, ".") == 0 || strcmp(entry->d_name, "..") == 0)
                continue;
            printf("\033[34m%s$ \033[0m\n", entry->d_name);
        }
        else if (S_ISLNK(statbuf.st_mode)) //符号链接，绿色
        {
            printf("\033[32m%s$ \033[0m\n", entry->d_name);
        }
        else if (S_ISREG(statbuf.st_mode)) //普通文件，白色
        {
            printf("%s\n", entry->d_name);
        }
        else //其他文件，红色
        {
            printf("\033[31m%s$ \033[0m\n", entry->d_name);
        }
    }
    //关闭目录流
    closedir(dp);
    return EXIT_OK;
}

//environ指令
int exeenviron(int l, int r)
{
    if (r - l > 1)
        return ARG_TOO_MANY;
    //从指向环境变量的外部变量environ中不断读取环境变量信息
    char **env = environ;
    while (*env)
    {
        printf("%s\n", *env);
        env++;
    }
    return EXIT_OK;
}

//echo指令
int exeecho(int l, int r)
{
    if (r - l == 1) //无参数直接输出回车
        printf("\n");
    else //有参数按顺序输出参数，多个空格合并
    {
        int i;
        for (i = l + 1; i < r; i++)
        {
            printf("%s", arg[i]);
            if (i != r - 1)
                printf(" ");
            else
                printf("\n");
        }
    }
    return EXIT_OK;
}

//exit指令或quit指令
int exeexit(int l, int r)
{
    return QUIT; //退出Shell
}

//jobs指令
int exejobs(int l, int r)
{
    if (r - l > 1)
        return ARG_TOO_MANY;
    int i;
    //遍历进程表，打印进程信息
    for (i = 0; i < proc_num; i++)
    {
        printf("[%d]%4d  %s  %s\n", i + 1, proc_list[i].pid, (proc_list[i].status == RUNNING) ? "Running" : "Stopped", proc_list[i].proc_name);
    }
    return EXIT_OK;
}

//bg指令
int exebg(int l, int r)
{
    if (r - l > 2)
        return ARG_TOO_MANY;
    if (r - l < 2)
        return ARG_TOO_FEW;
    //将用户输入的作业号转换成int类型
    int id = atoi(arg[l + 1]);
    if (id > 0 && id <= proc_num)
    {
        //由于输出时作业号从1开始编号，而进程表中储存时从0开始编号，所以这里编号要-1
        id--;
        //对于停止的进程，先更新进程表，然后向其发送SITCONT信号令其继续运行
        if (proc_list[id].pid && proc_list[id].status == STOPPED)
        {
            proc_list[id].status = RUNNING;
            proc_list[id].isbg = 1; //后台运行
            kill(proc_list[id].pid, SIGCONT);
            //输出进程信息
            printf("[%d]  %s\n", proc_list[id].pid, proc_list[id].proc_name);
        }
        return EXIT_OK;
    }
    else
        return ARG_WRONG;
}

//fg指令
int exefg(int l, int r)
{
    if (r - l > 2)
        return ARG_TOO_MANY;
    if (r - l < 2)
        return ARG_TOO_FEW;
    //将用户输入的作业号转换成int类型
    int id = atoi(arg[l + 1]);
    if (id > 0 && id <= proc_num)
    {
        //由于输出时作业号从1开始编号，而进程表中储存时从0开始编号，所以这里编号要-1
        id--;
        //后台进程转前台
        if (proc_list[id].pid && proc_list[id].isbg)
        {
            //更新进程表
            proc_list[id].isbg = 0;
            //停止的进程，更新进程表后发送SIGCONT信号令其继续运行
            if (proc_list[id].status == STOPPED)
                kill(proc_list[id].pid, SIGCONT), proc_list[id].status = RUNNING;
            //输出后台进程信息
            printf("[%d]%4d  %s  %s\n", id + 1, proc_list[id].pid, (proc_list[id].status == RUNNING) ? "Running" : "Stopped", proc_list[id].proc_name);
            //注册信号函数，用于捕捉Ctrl+Z输入
            signal(SIGTSTP, CtrlZHandler);
            int stat_val;
            //前台进程，父进程阻塞。这里用了WUNTRACED是为了在子进程在Ctrl+Z作用下停止的情况下也能正常返回
            waitpid(proc_list[id].pid, &stat_val, WUNTRACED);
            //恢复信号函数
            signal(SIGTSTP, SIG_DFL);
            if (WIFEXITED(stat_val)) //子进程正常退出（指正常通过exit()函数退出，或main()中return 0退出）
            {
                int exit_code = WEXITSTATUS(stat_val); //获取错误代码
                //err_proc(exit_code);                 //输出子进程错误信息（可选）
                proc_del(id);                          //从进程表中删除对应的进程
                return EXIT_OK;
            }
            else if (WIFSTOPPED(stat_val)) //子进程停止（指子进程在Ctrl+Z作用下停止）
            {
                //输出子进程信息
                printf("[%d]%4d  Stopped  %s\n", id + 1, proc_list[id].pid, proc_list[id].proc_name);
                return EXIT_OK;
            }
            else
                return SUBPROCESS_FAILURE; //子进程异常退出
        }
        return EXIT_OK;
    }
    else
        return ARG_WRONG;
}

//set指令
int exeset(int l, int r)
{
    if (r - l == 1) //无参数输出环境变量
        return exeenviron(l, r);
    if (r - l < 3)
        return ARG_TOO_FEW;
    else if (r - l > 3)
        return ARG_TOO_MANY;
    //有参数设置环境变量
    int res = setenv(arg[l + 1], arg[l + 2], 1);
    if (res == -1)
        return SET_ERROR; //设置失败
    else
        return EXIT_OK;
}

//unset指令
int exeunset(int l, int r)
{
    if (r - l < 2)
        return ARG_TOO_FEW;
    else if (r - l > 2)
        return ARG_TOO_MANY;
    //删除环境变量
    int res = unsetenv(arg[l + 1]);
    if (res == -1)
        return UNSET_ERROR; //删除失败
    else
        return EXIT_OK;
}

//umask指令
int exeumask(int l, int r)
{
    if (r - l < 2) //无参数输出旧掩码
    {
        mode_t mask;
        mask = umask(0002);     //先随便设一个新掩码，得到旧掩码
        umask(mask);            //再恢复掩码值
        printf("%04d\n", mask); //输出旧掩码值
        return EXIT_OK;
    }
    else if (r - l > 2)
        return ARG_TOO_MANY;
    //有参数设置新掩码
    umask(atoi(arg[l + 1]));
    return EXIT_OK;
}

//exec指令
int exeexec(int l, int r)
{
    //调用系统调用执行，执行结束后退出
    int res = execom(l + 1, r);
    err_proc(res);
    return QUIT;
}

//test指令
int exetest(int l, int r)
{
    if (r - l < 4)
        return ARG_TOO_FEW;
    if (r - l > 4)
        return ARG_TOO_MANY;
    //比较字符串
    if (strcmp(arg[l + 2], "=") == 0 || strcmp(arg[l + 2], "==") == 0)
    {
        printf(!strcmp(arg[l + 1], arg[l + 3]) ? "True\n" : "False\n");
    }
    else if (strcmp(arg[l + 2], "!=") == 0)
    {
        printf(strcmp(arg[l + 1], arg[l + 3]) ? "True\n" : "False\n");
    }
    else
        return ARG_WRONG;
    return EXIT_OK;
}

//shift指令
int exeshift(int l, int r)
{
    if (r - l > 2)
        return ARG_TOO_MANY;
    int num = 1; //默认移动1位
    if (r - l == 2)
        num = atoi(arg[l + 1]); //获取移动位数
    char tmp[MAX_ARG][BUF];
    int arg_num = 0; //参数个数
    //从标准输入读取参数
    while (scanf("%s", tmp[arg_num]) != EOF)
        arg_num++;
    //输出移位结果
    int i;
    for (i = num; i < arg_num; i++)
    {
        printf("%s", tmp[i]);
        if (i != arg_num - 1)
            printf(" ");
        else
            printf("\n");
    }
    return EXIT_OK;
}

//help指令
int exehelp(int l, int r)
{
    if (r - l < 2)
        return ARG_TOO_FEW;
    if (r - l > 2)
        return ARG_TOO_MANY;
    if (strcmp(arg[l + 1], "cd") == 0)
    {
        printf("cd -- Change directory\nUsage: cd $path\n");
    }
    else if (strcmp(arg[l + 1], "pwd") == 0)
    {
        printf("pwd -- Print working directory\nUsage: pwd\n");
    }
    else if (strcmp(arg[l + 1], "bg") == 0)
    {
        printf("bg -- Turn a process to be executed background\nUsage: bg <id> #<id> can be derived from 'jobs' command\n");
    }
    else if (strcmp(arg[l + 1], "clr") == 0)
    {
        printf("clr -- Clear the screen\nUsage: clr\n");
    }
    else if (strcmp(arg[l + 1], "time") == 0)
    {
        printf("time -- Print the current time\nUsage: time\n");
    }
    else if (strcmp(arg[l + 1], "dir") == 0)
    {
        printf("dir -- List the files under a given directory\nUsage: dir $path\n");
    }
    else if (strcmp(arg[l + 1], "environ") == 0)
    {
        printf("environ -- List all environment variables\nUsage: env\n");
    }
    else if (strcmp(arg[l + 1], "echo") == 0)
    {
        printf("echo -- Print the parameters and then print an enter\nUsage: echo [para1] [para2] ...\n");
    }
    else if (strcmp(arg[l + 1], "exit") == 0)
    {
        printf("exit -- Quit the shell\nUsage: exit\n");
    }
    else if (strcmp(arg[l + 1], "quit") == 0)
    {
        printf("quit -- Quit the shell\nUsage: quit\n");
    }
    else if (strcmp(arg[l + 1], "jobs") == 0)
    {
        printf("jobs -- Print all subprocesses\nUsage: jobs\n");
    }
    else if (strcmp(arg[l + 1], "fg") == 0)
    {
        printf("fg -- Turn a process to be executed foreground\nUsage: bg <id> #<id> can be derived from 'jobs' command\n");
    }
    else if (strcmp(arg[l + 1], "set") == 0)
    {
        printf("set -- Print all environment variables / Set the given environment variable\nUsage: set [$env_name $env_val]\n");
    }
    else if (strcmp(arg[l + 1], "unset") == 0)
    {
        printf("unset -- Delete the given environment variable\nUsage: unset [$env_name]\n");
    }
    else if (strcmp(arg[l + 1], "umask") == 0)
    {
        printf("umask -- Print the umask / Set the umask\nUsage: umask [$new_val]\n");
    }
    else if (strcmp(arg[l + 1], "test") == 0)
    {
        printf("test -- Compare the strings\nUsage: test $str1 {'=','!=','=='} $str2\n");
    }
    else if (strcmp(arg[l + 1], "shift") == 0)
    {
        printf("shift -- Shift parameters to left\nUsage: shift [$val] (default: $val = 1)\n");
    }
    else if (strcmp(arg[l + 1], "exec") == 0)
    {
        printf("exec -- Replace the current process with a given command\nUsage: exec $command\n");
    }
    else if (strcmp(arg[l + 1], "sleep") == 0)
    {
        printf("sleep -- Sleep for some time\nUsage: sleep [$time] (in seconds)\n");
    }
    else if (strcmp(arg[l + 1], "cat") == 0)
    {
        printf("cat -- Print a given file\nUsage: cat $path\n");
    }
    else if (strcmp(arg[l + 1], "more") == 0)
    {
        printf("more -- Filter the output\nUsage: more [$path] (or) $cmd ... | more \n");
    }
}

//sleep指令
int exesleep(int l, int r)
{
    if (r - l < 2)
        return ARG_TOO_FEW;
    if (r - l > 2)
        return ARG_TOO_MANY;
    //调用系统调用睡眠
    sleep(atoi(arg[l + 1]));
    return EXIT_OK;
}

//cat指令
int execat(int l, int r)
{
    if (r - l < 2)
        return ARG_TOO_FEW;
    if (r - l > 2)
        return ARG_TOO_MANY;
    FILE *fp;
    fp = fopen(arg[l + 1], "r"); //打开文件流
    if (fp == NULL)
        return ARG_WRONG; //文件打开失败，参数错误
    char line[BUF];
    while (fgets(line, BUF, fp))
    {
        printf("%s", line); //逐行输出文件内容
    }
    fclose(fp); //关闭文件流
    return EXIT_OK;
}

//more指令
int exemore(int l, int r)
{
    if (r - l > 2)
        return ARG_TOO_MANY;
    char line[BUF];
    int num_of_lines = 0; //当前已经打印的行数（从一屏幕的开始开始计算）
    if (r - l == 2)       //有参数，从文件中读入
    {
        FILE *fp;
        fp = fopen(arg[l + 1], "r"); //打开文件流
        if (fp == NULL)
            return ARG_WRONG;
        while (fgets(line, BUF, fp)) //从文件流中读入数据
        {
            if (num_of_lines == PAGE_LEN) //屏幕已满
            {
                printf("\033[32m\nmore?\033[0m"); //输出提示信息等待用户输入
                int reply;
                while ((reply = getc(stdin)) != EOF) //获得用户输入
                {
                    if (reply == 'q' || reply == ' ' || reply == '\n') //若不是这三种字符则输入不合法，要求用户继续输入
                    {
                        if (reply != '\n') //除回车外，要再额外读一个用户输入的回车符号
                            getc(stdin);
                        break;
                    }
                }
                if (reply == 'q') //字符q表示退出阅读
                    break;
                else if (reply == ' ') //空格表示显示下一屏
                    reply = PAGE_LEN;
                else if (reply == '\n') //回车表示显示下一行
                    reply = 1;
                num_of_lines -= reply;
            }
            //输出当前读到的行
            fputs(line, stdout);
            num_of_lines++;
        }
        fclose(fp);
        return EXIT_OK;
    }
    //无参数，用于管道，从重定向后的标准输入读（通常是管道的一端）
    //注意此时用户输入还是输入到屏幕中的，所以在读用户输入的时候，要根据备份的stdin文件描述符新建文件流，从中读取用户输入
    //详见下面的注释
    else
    {
        //调用fdopen，使用stdin的备份文件描述符打开文件流
        FILE *fp = fdopen(stdin_copy, "r");
        if (fp == NULL)
            return SUBPROCESS_FAILURE;
        while (fgets(line, BUF, stdin)) //从重定向后的标准输入（管道）中读取要查看的文件内容
        {
            if (num_of_lines == PAGE_LEN) //屏幕已满
            {
                printf("\033[32m\nmore?\033[0m"); //输出提示信息等待用户输入
                int reply;
                while ((reply = getc(fp)) != EOF) //从[屏幕]获得用户输入，注意这里的来源是fp，即使用stdin的备份文件描述符打开文件流
                {
                    if (reply == 'q' || reply == ' ' || reply == '\n') //若不是这三种字符则输入不合法，要求用户继续输入
                    {
                        if (reply != '\n') //除回车外，要再额外读一个用户输入的回车符号
                            getc(fp);
                        break;
                    }
                }
                if (reply == 'q') //字符q表示退出阅读
                    break;
                else if (reply == ' ') //空格表示显示下一屏
                    reply = PAGE_LEN;
                else if (reply == '\n') //回车表示显示下一行
                    reply = 1;
                num_of_lines -= reply;
            }
            fputs(line, stdout);
            num_of_lines++;
        }
        fclose(fp);
        return EXIT_OK;
    }
}