/*
程序名：proc_list.c
作者：黄彦玮
学号：3180102067
说明：myshell辅助模块（包括进程表和信号控制）
完成时间：2020-08-18
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
//向进程表里添加项
int proc_add(pid_t pid, char *proc_name, int isbg, int status)
{
    proc_list[proc_num].pid = pid;
    memset(proc_list[proc_num].proc_name, 0, sizeof(proc_list[proc_num].proc_name));
    strcpy(proc_list[proc_num].proc_name, proc_name);
    proc_list[proc_num].isbg = isbg;
    proc_list[proc_num++].status = status;
    return proc_num - 1;
}

//删除进程表中下标为id的项
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

//回收僵尸进程
void recycle_proc()
{
    int i;
    for (i = 0; i < proc_num; i++)
    {
        int stat_val;
        //回收僵尸进程，若检测到进程已终止则waitpid函数会自动回收
        //注意这里使用WNOHANG，目的是为了在不阻塞的情况下检查进程状态
        if (waitpid(proc_list[i].pid, &stat_val, WNOHANG) != 0)
        {
            printf("[Finished]%d\n", proc_list[i].pid);
            //已经终止的进程，从进程表中删除
            proc_del(i);
            i--;
        }
    }
}

//处理Ctrl-Z信号
void CtrlZHandler(int sig)
{
    //进程表为空则返回
    if (proc_num == 0)
        return;
    //获取子进程的pid，并发送SIGSTOP信号，令其停止
    pid_t pid = proc_list[proc_num - 1].pid;
    kill(pid, SIGSTOP);
    //更新进程表
    proc_list[proc_num - 1].status = STOPPED;
    proc_list[proc_num - 1].isbg = 1;
}
