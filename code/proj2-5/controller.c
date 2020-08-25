/*
程序名：controller.c
作者：黄彦玮
学号：3180102067
说明：myshell命令解析与进程控制模块
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
#include "main.h"
#include "proc_list.h"
#include "controller.h"
#include "mycmd.h"

char arg[MAX_ARG][BUF];
extern int stdin_copy;
extern struct proc_item proc_list[MAX_PROC];

//将命令按空格分割
int ssplit(char *cmd_raw)
{
    memset(arg, 0, sizeof(arg));
    //i:源字符串下标 len:源字符串长度 num:参数个数 tmp:当前参数长度 flag:当前扫描到的字符是否是参数的一部分
    int i = 0, len = strlen(cmd_raw), num = 0, tmp = 0, flag = 0;
    for (; i < len; i++)
    {
        if (cmd_raw[i] == ' ' || cmd_raw[i] == '\n') //空格或回车标志着一个参数的结束
        {
            flag = 0;
            tmp = 0;
        }
        else
        {
            if (!flag) //flag=0说明当前读到的字符是新参数的第一个字符
            {
                flag = 1;
                num++;
            }
            arg[num - 1][tmp++] = cmd_raw[i];
        }
    }
    return num;
}

//执行命令，参数下标范围为[l,r)
int execom(int l, int r)
{
    if (l >= r)
        return EXIT_OK; //正常退出
    int pip_pos;        //pip_pos:从左至右第一个管道符号的位置
    //判断命令中是否含有管道符号
    for (pip_pos = l; pip_pos < r; pip_pos++)
    {
        if (strcmp(arg[pip_pos], "|") == 0)
            break;
    }
    //管道符号在最左侧或者最右侧都是不合法的
    if (pip_pos == l || pip_pos == r - 1)
        return ARG_TOO_FEW; //参数过少
    else if (pip_pos == r)  //无管道，调用无管道执行函数
        return execom_without_pipe(l, r);
    int file_pipes[2];         //管道文件描述符
    pid_t fork_result;         //新建的子进程的进程编号pid
    if (pipe(file_pipes) == 0) //新建管道
    {
        fork_result = fork();  //新建子进程
        if (fork_result == -1) //新建进程失败
            return FORK_FAILURE;
        else if (fork_result == 0) //子进程
        {
            close(file_pipes[0]);                      //关闭管道读入端，因为不会用到
            dup2(file_pipes[1], 1);                    //将标准输出重定向管道输出端
            int res = execom_without_pipe(l, pip_pos); //执行管道符号左侧的指令
            close(file_pipes[1]);                      //执行完成，关闭管道文件描述符
            err_proc(res);                             //处理错误信息
            exit(res);                                 //执行完成，终止进程，返回错误代码
        }
        else //父进程
        {
            close(file_pipes[1]); //关闭管道输出端，因为不会用到
            int stat_val;
            //前台进程，父进程阻塞
            waitpid(fork_result, &stat_val, WUNTRACED);
            if (WIFEXITED(stat_val)) //子进程正常退出（指正常通过exit()函数退出，或main()中return 0退出）
            {
                int exit_code = WEXITSTATUS(stat_val); //获取子进程错误代码（即exit()中的值）
                if (exit_code != EXIT_OK)              //子进程的指令没有正常执行
                {
                    close(file_pipes[0]); //关闭管道读入端
                    return exit_code;     //返回错误代码
                }
                else //子进程正常执行完成
                {
                    dup2(file_pipes[0], 0);           //重定向标准输入到管道读入端，这样父进程就可以读入子进程输出的数据
                    int res = execom(pip_pos + 1, r); //递归执行后续指令
                    close(file_pipes[0]);             //关闭管道输入端
                    dup2(stdin_copy, 0);              //恢复重定向，将0号文件描述符重定向到标准输入的备份
                    return res;
                }
            }
            else
                return SUBPROCESS_FAILURE; //子进程终止或异常退出
        }
    }
}

//执行不带管道的指令，参数下标范围为[l,r)
int execom_without_pipe(int l, int r)
{
    if (l >= r)
        return EXIT_OK;
    /*输入输出重定向处理*/
    int i;
    char infile[BUF];                          //重定向输入文件名
    char outfile[BUF];                         //重定向输出文件名
    int outflag = 0;                           //重定向符号为">"时为0，为">>"时为1
    int isbg = (strcmp(arg[r - 1], "&") == 0); //是否是后台指令，若是则为1
    int newr = r;                              //指令在重定向前的下标
    memset(infile, 0, sizeof(infile));
    memset(outfile, 0, sizeof(outfile));
    //判断命令中是否含有重定向
    for (i = l; i < r; i++)
    {
        if (strcmp(arg[i], "<") == 0) //重定向输入
        {
            if (i + 1 >= r)
                return INFILE_MISSING; //输入文件不存在
            else if (infile[0])
                return INFILE_DUPLICATED; //有多个输入重定向
            else
                strcpy(infile, arg[i + 1]);
            if (newr == r)
                newr = i;
        }
        if (strcmp(arg[i], ">") == 0 || strcmp(arg[i], ">>") == 0) //重定向输出
        {
            if (strcmp(arg[i], ">>") == 0)
                outflag = 1;
            if (i + 1 >= r)
                return OUTFILE_MISSING; //输出文件不存在
            else if (outfile[0])
                return OUTFILE_DUPLICATED; //有多个输出重定向
            else
                strcpy(outfile, arg[i + 1]);
            if (newr == r)
                newr = i;
        }
    }
    if (strcmp(arg[newr - 1], "&") == 0)
        newr--;
    if (infile[0]) //输入重定向存在
    {
        if (access(infile, F_OK) == -1)
            return INFILE_NOT_EXIST; //输入文件不存在
        else if (access(infile, R_OK) == -1)
            return INFILE_CANNOT_READ; //输入文件没有读权限
    }
    if (outfile[0]) //输出重定向存在
    {
        if (access(outfile, F_OK) != -1 && access(outfile, W_OK) == -1)
            return OUTFILE_CANNOT_WRITE; //输出文件存在但没有写权限
    }

    /*指令执行*/

    /*先执行内部指令（必须要在父进程执行的指令）*/
    if (strcmp(arg[l], "cd") == 0)
        return execd(l, newr);
    if (strcmp(arg[l], "clr") == 0)
        return execlr(l, newr);
    if (strcmp(arg[l], "quit") == 0 || strcmp(arg[l], "exit") == 0)
        return exeexit(l, newr);
    if (strcmp(arg[l], "bg") == 0)
        return exebg(l, newr);
    if (strcmp(arg[l], "fg") == 0)
        return exefg(l, newr);
    if (strcmp(arg[l], "set") == 0)
        return exeset(l, newr);
    if (strcmp(arg[l], "unset") == 0)
        return exeunset(l, newr);
    if (strcmp(arg[l], "umask") == 0)
        return exeumask(l, newr);
    if (strcmp(arg[l], "exec") == 0)
        return exeexec(l, newr);

    /*外部指令，创建子进程后执行*/
    //先处理重定向
    int in_fd = 0, out_fd = 1;
    if (infile[0]) //输入重定向存在
    {
        in_fd = open(infile, O_RDONLY); //打开输入文件
        if (in_fd == -1)
            return INFILE_CANNOT_READ; //输入文件无法打开
    }
    if (outfile[0])
    {
        //创建输出文件，outflag = 1时打开的文件是附加模式，否则为截断模式
        if (outflag)
            out_fd = open(outfile, O_WRONLY | O_APPEND | O_CREAT /*, S_IRUSR | S_IWUSR | S_IRGRP | S_IWGRP | S_IROTH | S_IWOTH*/);
        else
            out_fd = open(outfile, O_WRONLY | O_TRUNC | O_CREAT /*, S_IRUSR | S_IWUSR | S_IRGRP | S_IWGRP | S_IROTH | S_IWOTH*/);
        if (out_fd == -1)
            return OUTFILE_CANNOT_WRITE; //输出文件存在但无写权限
    }

    //创建子进程
    pid_t fork_result;
    fork_result = fork();
    if (fork_result == -1) //创建进程失败
        return FORK_FAILURE;
    else if (fork_result == 0) //子进程
    {
        //实现重定向
        if (infile[0])
        {
            close(0);
            dup(in_fd);
        }
        if (outfile[0])
        {
            close(1);
            dup(out_fd);
        }
        //执行指令
        if (strcmp(arg[l], "pwd") == 0)
            err_proc(exepwd(l, newr)), exit(0);
        else if (strcmp(arg[l], "dir") == 0)
            err_proc(exedir(l, newr)), exit(0);
        else if (strcmp(arg[l], "echo") == 0)
            err_proc(exeecho(l, newr)), exit(0);
        else if (strcmp(arg[l], "environ") == 0)
            err_proc(exeenviron(l, newr)), exit(0);
        else if (strcmp(arg[l], "help") == 0)
            err_proc(exehelp(l, newr)), exit(0);
        else if (strcmp(arg[l], "jobs") == 0)
            err_proc(exejobs(l, newr)), exit(0);
        else if (strcmp(arg[l], "shift") == 0)
            err_proc(exeshift(l, newr)), exit(0);
        else if (strcmp(arg[l], "test") == 0)
            err_proc(exetest(l, newr)), exit(0);
        else if (strcmp(arg[l], "time") == 0)
            err_proc(exetime(l, newr)), exit(0);
        else if (strcmp(arg[l], "sleep") == 0)
            err_proc(exesleep(l, newr)), exit(0);
        else if (strcmp(arg[l], "cat") == 0)
            err_proc(execat(l, newr)), exit(0);
        else if (strcmp(arg[l], "more") == 0)
            err_proc(exemore(l, newr)), exit(0);
        else //外部命令
        {
            char *tmp[MAX_ARG]; //提取外部命令
            int i;
            for (i = l; i < r; i++)
            {
                tmp[i - l] = (char *)malloc(BUF);
                strcpy(tmp[i - l], arg[i]);
            }
            tmp[r - l] = NULL;
            //调用系统调用执行外部命令
            int res = execvp(arg[l], tmp);
            if (res == -1)
                exit(CMD_ILLEGAL); //执行失败，指令类型不合法
            exit(0);
        }
    }
    else //父进程
    {
        int workid = proc_add(fork_result, arg[l], isbg, RUNNING);
        if (!isbg) //前台进程需要等待结束
        {
            //注册信号函数，用于捕捉Ctrl+Z输入
            signal(SIGTSTP, CtrlZHandler);
            int stat_val;
            //前台进程，父进程阻塞。这里用了WUNTRACED是为了在子进程在Ctrl+Z作用下停止的情况下也能正常返回
            waitpid(fork_result, &stat_val, WUNTRACED);
            //恢复信号函数
            signal(SIGTSTP, SIG_DFL);
            if (WIFEXITED(stat_val)) //子进程正常退出（指正常通过exit()函数退出，或main()中return 0退出）
            {
                int exit_code = WEXITSTATUS(stat_val); //获取错误代码
                //err_proc(exit_code);                 //输出子进程错误信息（可选）
                proc_del(workid);                      //从进程表中删除对应的进程
                return EXIT_OK;
            }
            else if (WIFSTOPPED(stat_val)) //子进程停止（指子进程在Ctrl+Z作用下停止）
            {
                //输出子进程信息
                printf("[%d]%4d  Stopped  %s\n", workid + 1, proc_list[workid].pid, proc_list[workid].proc_name);
                return EXIT_OK;
            }
            else
                return SUBPROCESS_FAILURE; //子进程异常退出
        }
        else
        {
            //后台进程直接打印进程信息
            printf("[%d]%4d  %s  %s\n", workid + 1, proc_list[workid].pid, (proc_list[workid].status == RUNNING) ? "Running" : "Stopped", proc_list[workid].proc_name);
            return EXIT_OK;
        }
    }
}