/*
��������mycmd.c
���ߣ�������
ѧ�ţ�3180102067
˵����myshell����ִ��ģ��
���ʱ�䣺2020-08-18
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
extern char **environ;                       //��������
extern char dirname[BUF];                    //��ǰĿ¼����
extern int proc_num;                         //���̱��С
extern char arg[MAX_ARG][BUF];               //�ָ�������
extern struct proc_item proc_list[MAX_PROC]; //���̱�
extern int stdin_copy;                       //stdin�ļ��������ı���

//cdָ��
int execd(int l, int r)
{
    //��������������ͬ
    if (r - l > 2)
        return ARG_TOO_MANY; //��������
    if (r - l == 2)          //2������ʱ���޸�Ŀ¼��������ӦĿ¼
    {
        int res = chdir(arg[l + 1]);
        if (res)
            return ARG_WRONG; //��������·���򲻿���
    }
    else //1������ʱ���л�����Ŀ¼
    {
        int res = chdir(getenv("HOME"));
        if (res)
            return HOME_CANNOT_GET; //�޷���ȡ��Ŀ¼·��
    }
    return EXIT_OK; //�����˳�
}

//clrָ��
int execlr(int l, int r)
{
    if (r - l > 1)
        return ARG_TOO_MANY;
    //����
    printf("\033[1H\033[2J");
    return EXIT_OK;
}

//pwdָ��
int exepwd(int l, int r)
{
    if (r - l > 1)
        return ARG_TOO_MANY;
    //��ȡ��ǰĿ¼����
    if (getworkdir(dirname) == -1)
        return CURPATH_FAILED; //�޷���ȡ��ǰ·��
    //�����ǰĿ¼����
    printf("%s\n", dirname);
    return EXIT_OK;
}

//timeָ��
int exetime(int l, int r)
{
    if (r - l > 1)
        return ARG_TOO_MANY;
    time_t *timep = malloc(sizeof(*timep));
    //��ȡʱ�����ת�����ַ���ʽ
    time(timep);
    char *s = ctime(timep);
    printf("%s", s);
    return EXIT_OK;
}

//dirָ��
int exedir(int l, int r)
{
    if (r - l > 2)
        return ARG_TOO_MANY;
    else if (r - l < 2)
        return ARG_TOO_FEW; //��������
    DIR *dp;
    struct dirent *entry;
    struct stat statbuf;
    //����ϵͳ���ã��½�Ŀ¼��
    if ((dp = opendir(arg[l + 1])) == NULL)
        return ARG_WRONG;
    //�л�����Ӧ�ļ���
    chdir(arg[l + 1]);
    //���δ�Ŀ¼���ж�ȡĿ¼���ļ���Ϣ
    while ((entry = readdir(dp)) != NULL)
    {
        //��ȡ�ļ����ԣ�d_name���ļ�����statbuf���ļ����ԣ�����statbuf.st_mode���ļ�����
        lstat(entry->d_name, &statbuf);
        //���ݲ�ͬ���ļ����Ͳ�ȡ��ͬ�������ʽ
        if (S_ISDIR(statbuf.st_mode)) //Ŀ¼����ɫ
        {
            if (strcmp(entry->d_name, ".") == 0 || strcmp(entry->d_name, "..") == 0)
                continue;
            printf("\033[34m%s$ \033[0m\n", entry->d_name);
        }
        else if (S_ISLNK(statbuf.st_mode)) //�������ӣ���ɫ
        {
            printf("\033[32m%s$ \033[0m\n", entry->d_name);
        }
        else if (S_ISREG(statbuf.st_mode)) //��ͨ�ļ�����ɫ
        {
            printf("%s\n", entry->d_name);
        }
        else //�����ļ�����ɫ
        {
            printf("\033[31m%s$ \033[0m\n", entry->d_name);
        }
    }
    //�ر�Ŀ¼��
    closedir(dp);
    return EXIT_OK;
}

//environָ��
int exeenviron(int l, int r)
{
    if (r - l > 1)
        return ARG_TOO_MANY;
    //��ָ�򻷾��������ⲿ����environ�в��϶�ȡ����������Ϣ
    char **env = environ;
    while (*env)
    {
        printf("%s\n", *env);
        env++;
    }
    return EXIT_OK;
}

//echoָ��
int exeecho(int l, int r)
{
    if (r - l == 1) //�޲���ֱ������س�
        printf("\n");
    else //�в�����˳���������������ո�ϲ�
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

//exitָ���quitָ��
int exeexit(int l, int r)
{
    return QUIT; //�˳�Shell
}

//jobsָ��
int exejobs(int l, int r)
{
    if (r - l > 1)
        return ARG_TOO_MANY;
    int i;
    //�������̱���ӡ������Ϣ
    for (i = 0; i < proc_num; i++)
    {
        printf("[%d]%4d  %s  %s\n", i + 1, proc_list[i].pid, (proc_list[i].status == RUNNING) ? "Running" : "Stopped", proc_list[i].proc_name);
    }
    return EXIT_OK;
}

//bgָ��
int exebg(int l, int r)
{
    if (r - l > 2)
        return ARG_TOO_MANY;
    if (r - l < 2)
        return ARG_TOO_FEW;
    //���û��������ҵ��ת����int����
    int id = atoi(arg[l + 1]);
    if (id > 0 && id <= proc_num)
    {
        //�������ʱ��ҵ�Ŵ�1��ʼ��ţ������̱��д���ʱ��0��ʼ��ţ�����������Ҫ-1
        id--;
        //����ֹͣ�Ľ��̣��ȸ��½��̱�Ȼ�����䷢��SITCONT�ź������������
        if (proc_list[id].pid && proc_list[id].status == STOPPED)
        {
            proc_list[id].status = RUNNING;
            proc_list[id].isbg = 1; //��̨����
            kill(proc_list[id].pid, SIGCONT);
            //���������Ϣ
            printf("[%d]  %s\n", proc_list[id].pid, proc_list[id].proc_name);
        }
        return EXIT_OK;
    }
    else
        return ARG_WRONG;
}

//fgָ��
int exefg(int l, int r)
{
    if (r - l > 2)
        return ARG_TOO_MANY;
    if (r - l < 2)
        return ARG_TOO_FEW;
    //���û��������ҵ��ת����int����
    int id = atoi(arg[l + 1]);
    if (id > 0 && id <= proc_num)
    {
        //�������ʱ��ҵ�Ŵ�1��ʼ��ţ������̱��д���ʱ��0��ʼ��ţ�����������Ҫ-1
        id--;
        //��̨����תǰ̨
        if (proc_list[id].pid && proc_list[id].isbg)
        {
            //���½��̱�
            proc_list[id].isbg = 0;
            //ֹͣ�Ľ��̣����½��̱����SIGCONT�ź������������
            if (proc_list[id].status == STOPPED)
                kill(proc_list[id].pid, SIGCONT), proc_list[id].status = RUNNING;
            //�����̨������Ϣ
            printf("[%d]%4d  %s  %s\n", id + 1, proc_list[id].pid, (proc_list[id].status == RUNNING) ? "Running" : "Stopped", proc_list[id].proc_name);
            //ע���źź��������ڲ�׽Ctrl+Z����
            signal(SIGTSTP, CtrlZHandler);
            int stat_val;
            //ǰ̨���̣���������������������WUNTRACED��Ϊ�����ӽ�����Ctrl+Z������ֹͣ�������Ҳ����������
            waitpid(proc_list[id].pid, &stat_val, WUNTRACED);
            //�ָ��źź���
            signal(SIGTSTP, SIG_DFL);
            if (WIFEXITED(stat_val)) //�ӽ��������˳���ָ����ͨ��exit()�����˳�����main()��return 0�˳���
            {
                int exit_code = WEXITSTATUS(stat_val); //��ȡ�������
                //err_proc(exit_code);                 //����ӽ��̴�����Ϣ����ѡ��
                proc_del(id);                          //�ӽ��̱���ɾ����Ӧ�Ľ���
                return EXIT_OK;
            }
            else if (WIFSTOPPED(stat_val)) //�ӽ���ֹͣ��ָ�ӽ�����Ctrl+Z������ֹͣ��
            {
                //����ӽ�����Ϣ
                printf("[%d]%4d  Stopped  %s\n", id + 1, proc_list[id].pid, proc_list[id].proc_name);
                return EXIT_OK;
            }
            else
                return SUBPROCESS_FAILURE; //�ӽ����쳣�˳�
        }
        return EXIT_OK;
    }
    else
        return ARG_WRONG;
}

//setָ��
int exeset(int l, int r)
{
    if (r - l == 1) //�޲��������������
        return exeenviron(l, r);
    if (r - l < 3)
        return ARG_TOO_FEW;
    else if (r - l > 3)
        return ARG_TOO_MANY;
    //�в������û�������
    int res = setenv(arg[l + 1], arg[l + 2], 1);
    if (res == -1)
        return SET_ERROR; //����ʧ��
    else
        return EXIT_OK;
}

//unsetָ��
int exeunset(int l, int r)
{
    if (r - l < 2)
        return ARG_TOO_FEW;
    else if (r - l > 2)
        return ARG_TOO_MANY;
    //ɾ����������
    int res = unsetenv(arg[l + 1]);
    if (res == -1)
        return UNSET_ERROR; //ɾ��ʧ��
    else
        return EXIT_OK;
}

//umaskָ��
int exeumask(int l, int r)
{
    if (r - l < 2) //�޲������������
    {
        mode_t mask;
        mask = umask(0002);     //�������һ�������룬�õ�������
        umask(mask);            //�ٻָ�����ֵ
        printf("%04d\n", mask); //���������ֵ
        return EXIT_OK;
    }
    else if (r - l > 2)
        return ARG_TOO_MANY;
    //�в�������������
    umask(atoi(arg[l + 1]));
    return EXIT_OK;
}

//execָ��
int exeexec(int l, int r)
{
    //����ϵͳ����ִ�У�ִ�н������˳�
    int res = execom(l + 1, r);
    err_proc(res);
    return QUIT;
}

//testָ��
int exetest(int l, int r)
{
    if (r - l < 4)
        return ARG_TOO_FEW;
    if (r - l > 4)
        return ARG_TOO_MANY;
    //�Ƚ��ַ���
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

//shiftָ��
int exeshift(int l, int r)
{
    if (r - l > 2)
        return ARG_TOO_MANY;
    int num = 1; //Ĭ���ƶ�1λ
    if (r - l == 2)
        num = atoi(arg[l + 1]); //��ȡ�ƶ�λ��
    char tmp[MAX_ARG][BUF];
    int arg_num = 0; //��������
    //�ӱ�׼�����ȡ����
    while (scanf("%s", tmp[arg_num]) != EOF)
        arg_num++;
    //�����λ���
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

//helpָ��
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

//sleepָ��
int exesleep(int l, int r)
{
    if (r - l < 2)
        return ARG_TOO_FEW;
    if (r - l > 2)
        return ARG_TOO_MANY;
    //����ϵͳ����˯��
    sleep(atoi(arg[l + 1]));
    return EXIT_OK;
}

//catָ��
int execat(int l, int r)
{
    if (r - l < 2)
        return ARG_TOO_FEW;
    if (r - l > 2)
        return ARG_TOO_MANY;
    FILE *fp;
    fp = fopen(arg[l + 1], "r"); //���ļ���
    if (fp == NULL)
        return ARG_WRONG; //�ļ���ʧ�ܣ���������
    char line[BUF];
    while (fgets(line, BUF, fp))
    {
        printf("%s", line); //��������ļ�����
    }
    fclose(fp); //�ر��ļ���
    return EXIT_OK;
}

//moreָ��
int exemore(int l, int r)
{
    if (r - l > 2)
        return ARG_TOO_MANY;
    char line[BUF];
    int num_of_lines = 0; //��ǰ�Ѿ���ӡ����������һ��Ļ�Ŀ�ʼ��ʼ���㣩
    if (r - l == 2)       //�в��������ļ��ж���
    {
        FILE *fp;
        fp = fopen(arg[l + 1], "r"); //���ļ���
        if (fp == NULL)
            return ARG_WRONG;
        while (fgets(line, BUF, fp)) //���ļ����ж�������
        {
            if (num_of_lines == PAGE_LEN) //��Ļ����
            {
                printf("\033[32m\nmore?\033[0m"); //�����ʾ��Ϣ�ȴ��û�����
                int reply;
                while ((reply = getc(stdin)) != EOF) //����û�����
                {
                    if (reply == 'q' || reply == ' ' || reply == '\n') //�������������ַ������벻�Ϸ���Ҫ���û���������
                    {
                        if (reply != '\n') //���س��⣬Ҫ�ٶ����һ���û�����Ļس�����
                            getc(stdin);
                        break;
                    }
                }
                if (reply == 'q') //�ַ�q��ʾ�˳��Ķ�
                    break;
                else if (reply == ' ') //�ո��ʾ��ʾ��һ��
                    reply = PAGE_LEN;
                else if (reply == '\n') //�س���ʾ��ʾ��һ��
                    reply = 1;
                num_of_lines -= reply;
            }
            //�����ǰ��������
            fputs(line, stdout);
            num_of_lines++;
        }
        fclose(fp);
        return EXIT_OK;
    }
    //�޲��������ڹܵ������ض����ı�׼�������ͨ���ǹܵ���һ�ˣ�
    //ע���ʱ�û����뻹�����뵽��Ļ�еģ������ڶ��û������ʱ��Ҫ���ݱ��ݵ�stdin�ļ��������½��ļ��������ж�ȡ�û�����
    //��������ע��
    else
    {
        //����fdopen��ʹ��stdin�ı����ļ����������ļ���
        FILE *fp = fdopen(stdin_copy, "r");
        if (fp == NULL)
            return SUBPROCESS_FAILURE;
        while (fgets(line, BUF, stdin)) //���ض����ı�׼���루�ܵ����ж�ȡҪ�鿴���ļ�����
        {
            if (num_of_lines == PAGE_LEN) //��Ļ����
            {
                printf("\033[32m\nmore?\033[0m"); //�����ʾ��Ϣ�ȴ��û�����
                int reply;
                while ((reply = getc(fp)) != EOF) //��[��Ļ]����û����룬ע���������Դ��fp����ʹ��stdin�ı����ļ����������ļ���
                {
                    if (reply == 'q' || reply == ' ' || reply == '\n') //�������������ַ������벻�Ϸ���Ҫ���û���������
                    {
                        if (reply != '\n') //���س��⣬Ҫ�ٶ����һ���û�����Ļس�����
                            getc(fp);
                        break;
                    }
                }
                if (reply == 'q') //�ַ�q��ʾ�˳��Ķ�
                    break;
                else if (reply == ' ') //�ո��ʾ��ʾ��һ��
                    reply = PAGE_LEN;
                else if (reply == '\n') //�س���ʾ��ʾ��һ��
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