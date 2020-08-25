/*
程序名：main.c
作者：黄彦玮
学号：3180102067
说明：myshell主程序、用户交互模块
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

char usrname[BUF];            //用户名
char hostname[BUF];           //主机名
char dirname[BUF];            //当前目录名
char cmd_raw[BUF];            //命令源字符串
char cmd_file[MAX_LINE][BUF]; //命令集（从外部文件中读入的）

int stdin_copy; //stdin文件描述符的备份，用于重定向还原

void init();

int main(int argc, char *argv[])
{
    init();
    FILE *fp;
    //判断参数个数
    if (argc > 2)
    {
        printf("Error: Too many arguments!\n");
        return 0;
    }
    else if (argc == 2) //参数为2，从文件中读入
    {
        fp = fopen(argv[1], "r");
        if (fp == NULL)
        {
            printf("Error: The file '%s' cannot be opened!\n", argv[1]);
            return 0;
        }
        memset(cmd_file, 0, sizeof(cmd_file)); //清空命令集
        int lines = 0;
        while (fgets(cmd_file[lines], BUF, fp) != NULL)
            lines++;
        int i;
        for (i = 0; i < lines; i++)
        {
            //分割指令，返回值为参数个数
            int num = ssplit(cmd_file[i]);
            //执行指令
            int res = execom(0, num);
            //处理错误信息
            err_proc(res);
            //exit/quit指令退出shell
            if (res == QUIT)
                return 0;
            //回收僵尸进程
            recycle_proc();
        }
        return 0;
    }

    //以下为参数为1的情况，从标准输入中读入命令
    system("clear");
    //打印欢迎信息
    fprintf(stdout, "Welcome to Myshell v1.0 for Ubuntu!\nAuthor: Yanwei Huang\n");
    while (1)
    {
        //获取用户名
        if (getusername(usrname) == -1)
        {
            fprintf(stderr, "Error: Cannot get user name.");
            exit(USRNAME_FAILED);
        }
        //获取主机名
        if (gethostname(hostname, BUF) == -1)
        {
            fprintf(stderr, "Error: Cannot get host name.");
            exit(HOSTNAME_FAILED);
        }
        //获取当前目录
        if (getworkdir(dirname) == -1)
        {
            fprintf(stderr, "Error: Cannot get current path.");
            exit(CURPATH_FAILED);
        }
        //输出命令提示符
        fprintf(stdout, "\033[32m%s@%s\033[0m", usrname, hostname);
        fprintf(stdout, ":");
        fprintf(stdout, "\033[34m%s$ \033[0m", dirname);
        memset(cmd_raw, 0, sizeof(cmd_raw));
        //从标准输入中读入命令
        fgets(cmd_raw, BUF, stdin);
        //分割指令，返回值为参数个数
        int num = ssplit(cmd_raw);
        //执行指令
        int res = execom(0, num);
        //处理错误信息
        err_proc(res);
        //quit指令退出shell
        if (res == QUIT)
            return 0;
        //回收僵尸进程
        recycle_proc();
    }
    fprintf(stdout, "ByeBye\n\n");
    return 0;
}

//初始化，备份标准输入，用于重定向还原
void init()
{
    stdin_copy = dup(0);
    /*char *shell_env = getenv("SHELL");
    char *cur_path = getenv("PATH");
    char tmp[BUF];
    strcpy(tmp, shell_env);
    int len = strlen(tmp);
    strcpy(tmp + len, ":");
    len++;
    strcpy(tmp + len, cur_path);
    len = strlen(tmp);
    strcpy(tmp + len, "/myshell");
    setenv("SHELL", tmp, 1);*/
}

//获取用户名
int getusername(char *usr)
{
    struct passwd *pwd = getpwuid(getuid());
    strcpy(usr, pwd->pw_name);
}

//获取当前目录
int getworkdir(char *dir)
{
    char *tmp = getcwd(dir, BUF);
    if (tmp == NULL)
        return -1;
    return 0;
}

//错误信息处理
void err_proc(int err)
{
    switch (err)
    {
    case EXIT_OK:
    case QUIT:
        break;
    case ARG_TOO_MANY:
        fprintf(stderr, "Error: Too many arguments.\n");
        break;
    case ARG_TOO_FEW:
        fprintf(stderr, "Error: Too few arguments.\n");
        break;
    case ARG_WRONG:
        fprintf(stderr, "Error: Illegal argument.\n");
        break;
    case CURPATH_FAILED:
        fprintf(stderr, "Error: Cannot get current path.\n");
        break;
    case HOSTNAME_FAILED:
        fprintf(stderr, "Error: Cannot get host name.\n");
        break;
    case USRNAME_FAILED:
        fprintf(stderr, "Error: Cannot get user name.\n");
        break;
    case FORK_FAILURE:
        fprintf(stderr, "Error: Failed to fork a process.\n");
        break;
    case SUBPROCESS_FAILURE:
        fprintf(stderr, "Error: The subprocess exits unexpectedly.\n");
        break;
    case INFILE_MISSING:
        fprintf(stderr, "Error: Input file needed when redirecting standard input.\n");
        break;
    case OUTFILE_MISSING:
        fprintf(stderr, "Error: Output file needed when redirecting standard output.\n");
        break;
    case INFILE_DUPLICATED:
        fprintf(stderr, "Error: More than one option is given when redirecting standard input.\n");
        break;
    case OUTFILE_DUPLICATED:
        fprintf(stderr, "Error: More than one option is given when redirecting standard output.\n");
        break;
    case INFILE_NOT_EXIST:
        fprintf(stderr, "Error: Input file doesn't exist when redirecting standard input.\n");
        break;
    case INFILE_CANNOT_READ:
        fprintf(stderr, "Error: Input file cannot be read when redirecting standard input.\n");
        break;
    case OUTFILE_CANNOT_WRITE:
        fprintf(stderr, "Error: Output file cannot be written when redirecting standard output.\n");
        break;
    case HOME_CANNOT_GET:
        fprintf(stderr, "Error: Cannot get home path.\n");
        break;
    case SET_ERROR:
        fprintf(stderr, "Error: Failed to set the environment variable.\n");
        break;
    case UNSET_ERROR:
        fprintf(stderr, "Error: Failed to unset the environment variable.\n");
        break;
    case CMD_ILLEGAL:
        fprintf(stderr, "Error: Unidentified command type.\n");
        break;
    }
}
