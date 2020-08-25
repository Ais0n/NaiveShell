#pragma once
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/wait.h>
#include <sys/signal.h>
#include <sys/types.h>
#include <sys/stat.h>
#include "main.h"
//���̱��е���
struct proc_item
{
    pid_t pid;           //���̱�ţ�Ψһ��
    char proc_name[BUF]; //������
    int isbg;            //�Ƿ��̨
    int status;          //����״̬
};
int proc_add(pid_t pid, char *proc_name, int isbg, int status);
void proc_del(int id);
void recycle_proc();
void CtrlZHandler(int sig);