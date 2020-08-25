/*
��������main.c
���ߣ�������
ѧ�ţ�3180102067
˵����myshell�������û�����ģ��
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
#include "main.h"
#include "proc_list.h"
#include "controller.h"

char usrname[BUF];            //�û���
char hostname[BUF];           //������
char dirname[BUF];            //��ǰĿ¼��
char cmd_raw[BUF];            //����Դ�ַ���
char cmd_file[MAX_LINE][BUF]; //��������ⲿ�ļ��ж���ģ�

int stdin_copy; //stdin�ļ��������ı��ݣ������ض���ԭ

void init();

int main(int argc, char *argv[])
{
    init();
    FILE *fp;
    //�жϲ�������
    if (argc > 2)
    {
        printf("Error: Too many arguments!\n");
        return 0;
    }
    else if (argc == 2) //����Ϊ2�����ļ��ж���
    {
        fp = fopen(argv[1], "r");
        if (fp == NULL)
        {
            printf("Error: The file '%s' cannot be opened!\n", argv[1]);
            return 0;
        }
        memset(cmd_file, 0, sizeof(cmd_file)); //������
        int lines = 0;
        while (fgets(cmd_file[lines], BUF, fp) != NULL)
            lines++;
        int i;
        for (i = 0; i < lines; i++)
        {
            //�ָ�ָ�����ֵΪ��������
            int num = ssplit(cmd_file[i]);
            //ִ��ָ��
            int res = execom(0, num);
            //���������Ϣ
            err_proc(res);
            //exit/quitָ���˳�shell
            if (res == QUIT)
                return 0;
            //���ս�ʬ����
            recycle_proc();
        }
        return 0;
    }

    //����Ϊ����Ϊ1��������ӱ�׼�����ж�������
    system("clear");
    //��ӡ��ӭ��Ϣ
    fprintf(stdout, "Welcome to Myshell v1.0 for Ubuntu!\nAuthor: Yanwei Huang\n");
    while (1)
    {
        //��ȡ�û���
        if (getusername(usrname) == -1)
        {
            fprintf(stderr, "Error: Cannot get user name.");
            exit(USRNAME_FAILED);
        }
        //��ȡ������
        if (gethostname(hostname, BUF) == -1)
        {
            fprintf(stderr, "Error: Cannot get host name.");
            exit(HOSTNAME_FAILED);
        }
        //��ȡ��ǰĿ¼
        if (getworkdir(dirname) == -1)
        {
            fprintf(stderr, "Error: Cannot get current path.");
            exit(CURPATH_FAILED);
        }
        //���������ʾ��
        fprintf(stdout, "\033[32m%s@%s\033[0m", usrname, hostname);
        fprintf(stdout, ":");
        fprintf(stdout, "\033[34m%s$ \033[0m", dirname);
        memset(cmd_raw, 0, sizeof(cmd_raw));
        //�ӱ�׼�����ж�������
        fgets(cmd_raw, BUF, stdin);
        //�ָ�ָ�����ֵΪ��������
        int num = ssplit(cmd_raw);
        //ִ��ָ��
        int res = execom(0, num);
        //���������Ϣ
        err_proc(res);
        //quitָ���˳�shell
        if (res == QUIT)
            return 0;
        //���ս�ʬ����
        recycle_proc();
    }
    fprintf(stdout, "ByeBye\n\n");
    return 0;
}

//��ʼ�������ݱ�׼���룬�����ض���ԭ
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

//��ȡ�û���
int getusername(char *usr)
{
    struct passwd *pwd = getpwuid(getuid());
    strcpy(usr, pwd->pw_name);
}

//��ȡ��ǰĿ¼
int getworkdir(char *dir)
{
    char *tmp = getcwd(dir, BUF);
    if (tmp == NULL)
        return -1;
    return 0;
}

//������Ϣ����
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
