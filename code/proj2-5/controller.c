/*
��������controller.c
���ߣ�������
ѧ�ţ�3180102067
˵����myshell�����������̿���ģ��
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
#include "mycmd.h"

char arg[MAX_ARG][BUF];
extern int stdin_copy;
extern struct proc_item proc_list[MAX_PROC];

//������ո�ָ�
int ssplit(char *cmd_raw)
{
    memset(arg, 0, sizeof(arg));
    //i:Դ�ַ����±� len:Դ�ַ������� num:�������� tmp:��ǰ�������� flag:��ǰɨ�赽���ַ��Ƿ��ǲ�����һ����
    int i = 0, len = strlen(cmd_raw), num = 0, tmp = 0, flag = 0;
    for (; i < len; i++)
    {
        if (cmd_raw[i] == ' ' || cmd_raw[i] == '\n') //�ո��س���־��һ�������Ľ���
        {
            flag = 0;
            tmp = 0;
        }
        else
        {
            if (!flag) //flag=0˵����ǰ�������ַ����²����ĵ�һ���ַ�
            {
                flag = 1;
                num++;
            }
            arg[num - 1][tmp++] = cmd_raw[i];
        }
    }
    return num;
}

//ִ����������±귶ΧΪ[l,r)
int execom(int l, int r)
{
    if (l >= r)
        return EXIT_OK; //�����˳�
    int pip_pos;        //pip_pos:�������ҵ�һ���ܵ����ŵ�λ��
    //�ж��������Ƿ��йܵ�����
    for (pip_pos = l; pip_pos < r; pip_pos++)
    {
        if (strcmp(arg[pip_pos], "|") == 0)
            break;
    }
    //�ܵ������������������Ҳ඼�ǲ��Ϸ���
    if (pip_pos == l || pip_pos == r - 1)
        return ARG_TOO_FEW; //��������
    else if (pip_pos == r)  //�޹ܵ��������޹ܵ�ִ�к���
        return execom_without_pipe(l, r);
    int file_pipes[2];         //�ܵ��ļ�������
    pid_t fork_result;         //�½����ӽ��̵Ľ��̱��pid
    if (pipe(file_pipes) == 0) //�½��ܵ�
    {
        fork_result = fork();  //�½��ӽ���
        if (fork_result == -1) //�½�����ʧ��
            return FORK_FAILURE;
        else if (fork_result == 0) //�ӽ���
        {
            close(file_pipes[0]);                      //�رչܵ�����ˣ���Ϊ�����õ�
            dup2(file_pipes[1], 1);                    //����׼����ض���ܵ������
            int res = execom_without_pipe(l, pip_pos); //ִ�йܵ���������ָ��
            close(file_pipes[1]);                      //ִ����ɣ��رչܵ��ļ�������
            err_proc(res);                             //���������Ϣ
            exit(res);                                 //ִ����ɣ���ֹ���̣����ش������
        }
        else //������
        {
            close(file_pipes[1]); //�رչܵ�����ˣ���Ϊ�����õ�
            int stat_val;
            //ǰ̨���̣�����������
            waitpid(fork_result, &stat_val, WUNTRACED);
            if (WIFEXITED(stat_val)) //�ӽ��������˳���ָ����ͨ��exit()�����˳�����main()��return 0�˳���
            {
                int exit_code = WEXITSTATUS(stat_val); //��ȡ�ӽ��̴�����루��exit()�е�ֵ��
                if (exit_code != EXIT_OK)              //�ӽ��̵�ָ��û������ִ��
                {
                    close(file_pipes[0]); //�رչܵ������
                    return exit_code;     //���ش������
                }
                else //�ӽ�������ִ�����
                {
                    dup2(file_pipes[0], 0);           //�ض����׼���뵽�ܵ�����ˣ����������̾Ϳ��Զ����ӽ������������
                    int res = execom(pip_pos + 1, r); //�ݹ�ִ�к���ָ��
                    close(file_pipes[0]);             //�رչܵ������
                    dup2(stdin_copy, 0);              //�ָ��ض��򣬽�0���ļ��������ض��򵽱�׼����ı���
                    return res;
                }
            }
            else
                return SUBPROCESS_FAILURE; //�ӽ�����ֹ���쳣�˳�
        }
    }
}

//ִ�в����ܵ���ָ������±귶ΧΪ[l,r)
int execom_without_pipe(int l, int r)
{
    if (l >= r)
        return EXIT_OK;
    /*��������ض�����*/
    int i;
    char infile[BUF];                          //�ض��������ļ���
    char outfile[BUF];                         //�ض�������ļ���
    int outflag = 0;                           //�ض������Ϊ">"ʱΪ0��Ϊ">>"ʱΪ1
    int isbg = (strcmp(arg[r - 1], "&") == 0); //�Ƿ��Ǻ�ָ̨�������Ϊ1
    int newr = r;                              //ָ�����ض���ǰ���±�
    memset(infile, 0, sizeof(infile));
    memset(outfile, 0, sizeof(outfile));
    //�ж��������Ƿ����ض���
    for (i = l; i < r; i++)
    {
        if (strcmp(arg[i], "<") == 0) //�ض�������
        {
            if (i + 1 >= r)
                return INFILE_MISSING; //�����ļ�������
            else if (infile[0])
                return INFILE_DUPLICATED; //�ж�������ض���
            else
                strcpy(infile, arg[i + 1]);
            if (newr == r)
                newr = i;
        }
        if (strcmp(arg[i], ">") == 0 || strcmp(arg[i], ">>") == 0) //�ض������
        {
            if (strcmp(arg[i], ">>") == 0)
                outflag = 1;
            if (i + 1 >= r)
                return OUTFILE_MISSING; //����ļ�������
            else if (outfile[0])
                return OUTFILE_DUPLICATED; //�ж������ض���
            else
                strcpy(outfile, arg[i + 1]);
            if (newr == r)
                newr = i;
        }
    }
    if (strcmp(arg[newr - 1], "&") == 0)
        newr--;
    if (infile[0]) //�����ض������
    {
        if (access(infile, F_OK) == -1)
            return INFILE_NOT_EXIST; //�����ļ�������
        else if (access(infile, R_OK) == -1)
            return INFILE_CANNOT_READ; //�����ļ�û�ж�Ȩ��
    }
    if (outfile[0]) //����ض������
    {
        if (access(outfile, F_OK) != -1 && access(outfile, W_OK) == -1)
            return OUTFILE_CANNOT_WRITE; //����ļ����ڵ�û��дȨ��
    }

    /*ָ��ִ��*/

    /*��ִ���ڲ�ָ�����Ҫ�ڸ�����ִ�е�ָ�*/
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

    /*�ⲿָ������ӽ��̺�ִ��*/
    //�ȴ����ض���
    int in_fd = 0, out_fd = 1;
    if (infile[0]) //�����ض������
    {
        in_fd = open(infile, O_RDONLY); //�������ļ�
        if (in_fd == -1)
            return INFILE_CANNOT_READ; //�����ļ��޷���
    }
    if (outfile[0])
    {
        //��������ļ���outflag = 1ʱ�򿪵��ļ��Ǹ���ģʽ������Ϊ�ض�ģʽ
        if (outflag)
            out_fd = open(outfile, O_WRONLY | O_APPEND | O_CREAT /*, S_IRUSR | S_IWUSR | S_IRGRP | S_IWGRP | S_IROTH | S_IWOTH*/);
        else
            out_fd = open(outfile, O_WRONLY | O_TRUNC | O_CREAT /*, S_IRUSR | S_IWUSR | S_IRGRP | S_IWGRP | S_IROTH | S_IWOTH*/);
        if (out_fd == -1)
            return OUTFILE_CANNOT_WRITE; //����ļ����ڵ���дȨ��
    }

    //�����ӽ���
    pid_t fork_result;
    fork_result = fork();
    if (fork_result == -1) //��������ʧ��
        return FORK_FAILURE;
    else if (fork_result == 0) //�ӽ���
    {
        //ʵ���ض���
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
        //ִ��ָ��
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
        else //�ⲿ����
        {
            char *tmp[MAX_ARG]; //��ȡ�ⲿ����
            int i;
            for (i = l; i < r; i++)
            {
                tmp[i - l] = (char *)malloc(BUF);
                strcpy(tmp[i - l], arg[i]);
            }
            tmp[r - l] = NULL;
            //����ϵͳ����ִ���ⲿ����
            int res = execvp(arg[l], tmp);
            if (res == -1)
                exit(CMD_ILLEGAL); //ִ��ʧ�ܣ�ָ�����Ͳ��Ϸ�
            exit(0);
        }
    }
    else //������
    {
        int workid = proc_add(fork_result, arg[l], isbg, RUNNING);
        if (!isbg) //ǰ̨������Ҫ�ȴ�����
        {
            //ע���źź��������ڲ�׽Ctrl+Z����
            signal(SIGTSTP, CtrlZHandler);
            int stat_val;
            //ǰ̨���̣���������������������WUNTRACED��Ϊ�����ӽ�����Ctrl+Z������ֹͣ�������Ҳ����������
            waitpid(fork_result, &stat_val, WUNTRACED);
            //�ָ��źź���
            signal(SIGTSTP, SIG_DFL);
            if (WIFEXITED(stat_val)) //�ӽ��������˳���ָ����ͨ��exit()�����˳�����main()��return 0�˳���
            {
                int exit_code = WEXITSTATUS(stat_val); //��ȡ�������
                //err_proc(exit_code);                 //����ӽ��̴�����Ϣ����ѡ��
                proc_del(workid);                      //�ӽ��̱���ɾ����Ӧ�Ľ���
                return EXIT_OK;
            }
            else if (WIFSTOPPED(stat_val)) //�ӽ���ֹͣ��ָ�ӽ�����Ctrl+Z������ֹͣ��
            {
                //����ӽ�����Ϣ
                printf("[%d]%4d  Stopped  %s\n", workid + 1, proc_list[workid].pid, proc_list[workid].proc_name);
                return EXIT_OK;
            }
            else
                return SUBPROCESS_FAILURE; //�ӽ����쳣�˳�
        }
        else
        {
            //��̨����ֱ�Ӵ�ӡ������Ϣ
            printf("[%d]%4d  %s  %s\n", workid + 1, proc_list[workid].pid, (proc_list[workid].status == RUNNING) ? "Running" : "Stopped", proc_list[workid].proc_name);
            return EXIT_OK;
        }
    }
}