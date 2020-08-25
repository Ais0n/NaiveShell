/*
��������proc_list.c
���ߣ�������
ѧ�ţ�3180102067
˵����myshell����ģ�飨�������̱���źſ��ƣ�
���ʱ�䣺2020-08-18
*/
#include <string.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <signal.h>
#include <sys/wait.h>
#include <sys/signal.h>
#include <sys/types.h>
#include <sys/stat.h>
#include "proc_list.h"
#include "main.h"

struct proc_item proc_list[MAX_PROC];
int proc_num = 0;
//����̱��������
int proc_add(pid_t pid, char *proc_name, int isbg, int status)
{
    proc_list[proc_num].pid = pid;
    memset(proc_list[proc_num].proc_name, 0, sizeof(proc_list[proc_num].proc_name));
    strcpy(proc_list[proc_num].proc_name, proc_name);
    proc_list[proc_num].isbg = isbg;
    proc_list[proc_num++].status = status;
    return proc_num - 1;
}

//ɾ�����̱����±�Ϊid����
void proc_del(int id)
{
    int i;
    for (i = id; i < proc_num - 1; i++)
    {
        proc_list[i].pid = proc_list[i + 1].pid;
        proc_list[i].isbg = proc_list[i + 1].isbg;
        proc_list[i].status = proc_list[i + 1].status;
        strcpy(proc_list[i].proc_name, proc_list[i + 1].proc_name);
    }
    proc_num--;
}

//���ս�ʬ����
void recycle_proc()
{
    int i;
    for (i = 0; i < proc_num; i++)
    {
        int stat_val;
        //���ս�ʬ���̣�����⵽��������ֹ��waitpid�������Զ�����
        //ע������ʹ��WNOHANG��Ŀ����Ϊ���ڲ�����������¼�����״̬
        if (waitpid(proc_list[i].pid, &stat_val, WNOHANG) != 0)
        {
            printf("[Finished]%d\n", proc_list[i].pid);
            //�Ѿ���ֹ�Ľ��̣��ӽ��̱���ɾ��
            proc_del(i);
            i--;
        }
    }
}

//����Ctrl-Z�ź�
void CtrlZHandler(int sig)
{
    //���̱�Ϊ���򷵻�
    if (proc_num == 0)
        return;
    //��ȡ�ӽ��̵�pid��������SIGSTOP�źţ�����ֹͣ
    pid_t pid = proc_list[proc_num - 1].pid;
    kill(pid, SIGSTOP);
    //���½��̱�
    proc_list[proc_num - 1].status = STOPPED;
    proc_list[proc_num - 1].isbg = 1;
}
