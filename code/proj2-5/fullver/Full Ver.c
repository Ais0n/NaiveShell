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

#define BUF 50
#define MAX_PROC 64
#define MAX_ARG 20
#define MAX_LINE 64

enum ErrMsg
{
    EXIT_OK,
    CURPATH_FAILED,
    HOSTNAME_FAILED,
    USRNAME_FAILED,
    ARG_TOO_MANY,
    ARG_TOO_FEW,
    ARG_WRONG,
    QUIT,
    FORK_FAILURE,
    SUBPROCESS_FAILURE,
    INFILE_MISSING,
    OUTFILE_MISSING,
    INFILE_DUPLICATED,
    OUTFILE_DUPLICATED,
    INFILE_NOT_EXIST,
    INFILE_CANNOT_READ,
    OUTFILE_CANNOT_WRITE,
    HOME_CANNOT_GET,
    SET_ERROR,
    UNSET_ERROR,
    CMD_ILLEGAL
};

enum ProcStatus
{
    RUNNING,
    STOPPED
};

struct proc_item
{
    pid_t pid;
    char proc_name[BUF];
    int isbg;
    int status;
};
int proc_add(pid_t pid, char *proc_name, int isbg, int status);
void proc_del(int id);

char usrname[BUF];
char hostname[BUF];
char dirname[BUF];
char cmd_raw[BUF];
char cmd_file[MAX_LINE][BUF];
char arg[MAX_ARG][BUF];
struct proc_item proc_list[MAX_PROC];
int proc_num = 0;
extern char **environ; //环境变量
int stdin_copy;

int getusername(char *usr);
int getworkdir(char *dir);
int ssplit(char *cmd_raw);
int execom(int l, int r);
int execd(int l, int r);
int exedir(int l, int r);
int exetime(int l, int r);
int exepwd(int l, int r);
int execom_without_pipe(int l, int r);
int exeenviron(int l, int r);
int exeecho(int l, int r);
int exeexit(int l, int r);
int exejobs(int l, int r);
int exebg(int l, int r);
int exefg(int l, int r);
int exeset(int l, int r);
int exeunset(int l, int r);
int exeumask(int l, int r);
int exeexec(int l, int r);
int exetest(int l, int r);
int exeshift(int l, int r);
int exehelp(int l, int r);
int exesleep(int l, int r);
void errproc(int err);
void recycle_proc();
void CtrlZHandler(int sig);
void init();

int main(int argc, char *argv[])
{
    init();
    FILE *fp;
    if (argc > 2)
    {
        printf("Error: Too many arguments!\n");
        return 0;
    }
    else if (argc == 2)
    {
        fp = fopen(argv[1], "r");
        if (fp == NULL)
        {
            printf("Error: The file '%s' cannot be opened!\n", argv[1]);
            return 0;
        }
        memset(cmd_file, 0, sizeof(cmd_file));
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
            //quit指令退出shell
            if (res == QUIT)
                return 0;
            recycle_proc();
        }
        return 0;
    }
    system("clear");
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
        fprintf(stdout, "\033[32m%s@%s\033[0m", usrname, hostname);
        fprintf(stdout, ":");
        fprintf(stdout, "\033[34m%s$ \033[0m", dirname);
        memset(cmd_raw, 0, sizeof(cmd_raw));
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
        recycle_proc();
    }
    fprintf(stdout, "ByeBye\n\n");
    return 0;
}

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

//将命令按空格分割
int ssplit(char *cmd_raw)
{
    memset(arg, 0, sizeof(arg));
    //i:源字符串下标 len:源字符串长度 num:参数个数 tmp:当前参数长度 flag:当前扫描到的字符是否是参数的一部分
    int i = 0, len = strlen(cmd_raw), num = 0, tmp = 0, flag = 0;
    for (; i < len; i++)
    {
        if (cmd_raw[i] == ' ' || cmd_raw[i] == '\n')
        {
            flag = 0;
            tmp = 0;
        }
        else
        {
            if (!flag)
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
        return EXIT_OK;
    int pip_pos;
    for (pip_pos = l; pip_pos < r; pip_pos++)
    {
        if (strcmp(arg[pip_pos], "|") == 0)
            break;
    }
    if (pip_pos == l || pip_pos == r - 1)
        return ARG_TOO_FEW;
    else if (pip_pos == r)
        return execom_without_pipe(l, r);
    int file_pipes[2];
    pid_t fork_result;
    if (pipe(file_pipes) == 0)
    {
        fork_result = fork();
        if (fork_result == -1)
            return FORK_FAILURE;
        else if (fork_result == 0) //子进程
        {
            close(file_pipes[0]);
            dup2(file_pipes[1], 1); //将标准输出重定向管道输出端
            int res = execom_without_pipe(l, pip_pos);
            close(file_pipes[1]);
            err_proc(res);
            exit(res);
        }
        else //父进程
        {
            //int workid = proc_add(fork_result, arg[l], !strcmp(arg[pip_pos-1],"&"), RUNNING);
            close(file_pipes[1]);
            int stat_val;
            waitpid(fork_result, &stat_val, WUNTRACED);
            if (WIFEXITED(stat_val)) //子进程正常退出
            {
                int exit_code = WEXITSTATUS(stat_val);
                if (exit_code != EXIT_OK) //子进程的指令没有正常执行
                {
                    close(file_pipes[0]);
                    return exit_code;
                }
                else
                {
                    dup2(file_pipes[0], 0);
                    int res = execom(pip_pos + 1, r); //递归执行后续指令
                    close(file_pipes[0]);
                    dup2(stdin_copy, 0);
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
    char infile[BUF];
    char outfile[BUF];
    int outflag;                               //重定向符号为">"时为0，为">>"时为1
    int isbg = (strcmp(arg[r - 1], "&") == 0); //是否是后台指令，若是则为1
    int newr = r;                              //指令在重定向前的下标
    memset(infile, 0, sizeof(infile));
    memset(outfile, 0, sizeof(outfile));
    for (i = l; i < r; i++)
    {
        if (strcmp(arg[i], "<") == 0)
        {
            if (i + 1 >= r)
                return INFILE_MISSING;
            else if (infile[0])
                return INFILE_DUPLICATED;
            else
                strcpy(infile, arg[i + 1]);
            if (newr == r)
                newr = i;
        }
        if (strcmp(arg[i], ">") == 0 || strcmp(arg[i], ">>") == 0)
        {
            if (strcmp(arg[i], ">>") == 0)
                outflag = 1;
            if (i + 1 >= r)
                return OUTFILE_MISSING;
            else if (outfile[0])
                return OUTFILE_DUPLICATED;
            else
                strcpy(outfile, arg[i + 1]);
            if (newr == r)
                newr = i;
        }
    }
    if (strcmp(arg[newr - 1], "&") == 0)
        newr--;
    if (infile[0])
    {
        if (access(infile, F_OK) == -1)
            return INFILE_NOT_EXIST;
        else if (access(infile, R_OK) == -1)
            return INFILE_CANNOT_READ;
    }
    if (outfile[0])
    {
        if (access(outfile, F_OK) != -1 && access(outfile, W_OK) == -1)
            return OUTFILE_CANNOT_WRITE;
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
    if (infile[0])
    {
        in_fd = open(infile, O_RDONLY);
        if (in_fd == -1)
            return INFILE_CANNOT_READ;
    }
    if (outfile[0])
    {
        if (outflag)
            out_fd = open(outfile, O_WRONLY | O_APPEND | O_CREAT /*, S_IRUSR | S_IWUSR | S_IRGRP | S_IWGRP | S_IROTH | S_IWOTH*/);
        else
            out_fd = open(outfile, O_WRONLY | O_TRUNC | O_CREAT /*, S_IRUSR | S_IWUSR | S_IRGRP | S_IWGRP | S_IROTH | S_IWOTH*/);
        if (out_fd == -1)
            return OUTFILE_CANNOT_WRITE;
    }

    //创建子进程
    pid_t fork_result;
    fork_result = fork();
    if (fork_result == -1)
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
        else //外部命令
        {
            char *tmp[MAX_ARG];
            int i;
            for (i = l; i < r; i++)
            {
                tmp[i - l] = (char *)malloc(BUF);
                strcpy(tmp[i - l], arg[i]);
            }
            tmp[r - l] = NULL;
            int res = execvp(arg[l], tmp);
            if (res == -1)
                exit(CMD_ILLEGAL);
            exit(0);
        }
    }
    else //父进程
    {
        int workid = proc_add(fork_result, arg[l], isbg, RUNNING);
        if (!isbg) //前台进程需要等待结束
        {
            signal(SIGTSTP, CtrlZHandler);
            int stat_val;
            waitpid(fork_result, &stat_val, WUNTRACED);
            signal(SIGTSTP, SIG_DFL);
            if (WIFEXITED(stat_val)) //子进程正常退出
            {
                int exit_code = WEXITSTATUS(stat_val);
                err_proc(exit_code);
                proc_del(workid);
                return EXIT_OK;
            }
            else if (WIFSTOPPED(stat_val))
            {
                printf("[%d]%4d  Stopped  %s\n", workid + 1, proc_list[workid].pid, proc_list[workid].proc_name);
                return EXIT_OK;
            }
            else
                return SUBPROCESS_FAILURE; //子进程异常退出
        }
        else
        {
            printf("[%d]%4d  %s  %s\n", workid + 1, proc_list[workid].pid, (proc_list[workid].status == RUNNING) ? "Running" : "Stopped", proc_list[workid].proc_name);
            return EXIT_OK;
        }
    }
}

//cd指令
int execd(int l, int r)
{
    if (r - l > 2)
        return ARG_TOO_MANY;
    if (r - l == 2)
    {
        int res = chdir(arg[l + 1]);
        if (res)
            return ARG_WRONG;
    }
    else
    {
        int res = chdir(getenv("HOME"));
        if (res)
            return HOME_CANNOT_GET;
    }
    return EXIT_OK;
}

//clr指令
int execlr(int l, int r)
{
    if (r - l > 1)
        return ARG_TOO_MANY;
    printf("\033[1H\033[2J");
    return EXIT_OK;
}

//pwd指令
int exepwd(int l, int r)
{
    if (r - l > 1)
        return ARG_TOO_MANY;
    if (getworkdir(dirname) == -1)
        return CURPATH_FAILED;
    printf("%s\n", dirname);
    return EXIT_OK;
}

//time指令
int exetime(int l, int r)
{
    if (r - l > 1)
        return ARG_TOO_MANY;
    time_t *timep = malloc(sizeof(*timep));
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
        return ARG_TOO_FEW;
    DIR *dp;
    struct dirent *entry;
    struct stat statbuf;
    if ((dp = opendir(arg[l + 1])) == NULL)
        return ARG_WRONG;
    chdir(arg[l + 1]);
    while ((entry = readdir(dp)) != NULL)
    {
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
    closedir(dp);
    return EXIT_OK;
}

//environ指令
int exeenviron(int l, int r)
{
    if (r - l > 1)
        return ARG_TOO_MANY;
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
    if (r - l == 1)
        printf("\n");
    else
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
    return QUIT;
}

//jobs指令
int exejobs(int l, int r)
{
    if (r - l > 1)
        return ARG_TOO_MANY;
    int i;
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
    int id = atoi(arg[l + 1]);
    if (id > 0 && id <= proc_num)
    {
        id--;
        if (proc_list[id].pid && proc_list[id].status == STOPPED)
        {
            proc_list[id].status = RUNNING;
            proc_list[id].isbg = 1;
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
    int id = atoi(arg[l + 1]);
    if (id > 0 && id <= proc_num)
    {
        id--;
        if (proc_list[id].pid && proc_list[id].isbg)
        {
            proc_list[id].isbg = 0;
            if (proc_list[id].status == STOPPED)
                kill(proc_list[id].pid, SIGCONT), proc_list[id].status = RUNNING;
            printf("[%d]%4d  %s  %s\n", id + 1, proc_list[id].pid, (proc_list[id].status == RUNNING) ? "Running" : "Stopped", proc_list[id].proc_name);
            signal(SIGTSTP, CtrlZHandler);
            int stat_val;
            waitpid(proc_list[id].pid, &stat_val, WUNTRACED);
            signal(SIGTSTP, SIG_DFL);
            if (WIFEXITED(stat_val)) //子进程正常退出
            {
                int exit_code = WEXITSTATUS(stat_val);
                proc_del(id);
                return EXIT_OK;
            }
            else if (WIFSTOPPED(stat_val))
            {
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
    if (r - l == 1)
        return exeenviron(l, r);
    if (r - l < 3)
        return ARG_TOO_FEW;
    else if (r - l > 3)
        return ARG_TOO_MANY;
    printf("OK\n");
    int res = setenv(arg[l + 1], arg[l + 2], 1);
    printf("%s\n", getenv(arg[l + 1]));
    if (res == -1)
        return SET_ERROR;
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
    int res = unsetenv(arg[l + 1]);
    if (res == -1)
        return UNSET_ERROR;
    else
        return EXIT_OK;
}

//umask指令
int exeumask(int l, int r)
{
    if (r - l < 2)
    {
        mode_t mask;
        mask = umask(0002);
        umask(mask);
        printf("%04d\n", mask);
        return EXIT_OK;
    }
    else if (r - l > 2)
        return ARG_TOO_MANY;
    umask(atoi(arg[l + 1]));
    return EXIT_OK;
}

//exec指令
int exeexec(int l, int r)
{
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
    if (strcmp(arg[l + 2], "=") == 0 || strcmp(arg[l + 2], "==") == 0)
    {
        return strcmp(arg[l + 1], arg[l + 3]) == 0;
    }
    else if (strcmp(arg[l + 2], "!=") == 0)
    {
        return strcmp(arg[l + 1], arg[l + 3]) != 0;
    }
    else if (strcmp(arg[l + 2], "<") < 0)
    {
        return strcmp(arg[l + 1], arg[l + 3]) < 0;
    }
    else if (strcmp(arg[l + 2], ">") < 0)
    {
        return strcmp(arg[l + 1], arg[l + 3]) > 0;
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
    int num = 1;
    if (r - l == 2)
        num = atoi(arg[l + 1]);
    char tmp[MAX_ARG][BUF];
    int arg_num = 0;
    while (scanf("%s", tmp[arg_num]) != EOF)
        arg_num++;
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
        printf("cd -- Change directory\nUsage: cd <path>\n");
    }
    else if (strcmp(arg[l + 1], "pwd") == 0)
    {
        printf("pwd -- Print working directory\nUsage: pwd\n");
    }
    else if (strcmp(arg[l + 1], "bg") == 0)
    {
        printf("bg -- Turn a process to be executed background\nUsage: bg <id> #<id> can be derived from 'job' command\n");
    }
}

//sleep指令
int exesleep(int l, int r)
{
    if (r - l < 2)
        return ARG_TOO_FEW;
    if (r - l > 2)
        return ARG_TOO_MANY;
    sleep(atoi(arg[l + 1]));
    return EXIT_OK;
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
        if (waitpid(proc_list[i].pid, &stat_val, WNOHANG) != 0)
        {
            printf("[Finished]%d\n", proc_list[i].pid);
            proc_del(i);
            i--;
        }
    }
}

//处理Ctrl-Z信号
void CtrlZHandler(int sig)
{
    if (proc_num == 0)
        return;
    pid_t pid = proc_list[proc_num - 1].pid;
    kill(pid, SIGSTOP);
    proc_list[proc_num - 1].status = STOPPED;
    proc_list[proc_num - 1].isbg = 1;
}
