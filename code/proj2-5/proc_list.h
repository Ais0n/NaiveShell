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
//进程表中的项
struct proc_item
{
    pid_t pid;           //进程编号（唯一）
    char proc_name[BUF]; //进程名
    int isbg;            //是否后台
    int status;          //进程状态
};
int proc_add(pid_t pid, char *proc_name, int isbg, int status);
void proc_del(int id);
void recycle_proc();
void CtrlZHandler(int sig);