#pragma once
#define BUF 100
#define MAX_PROC 64
#define MAX_ARG 20
#define MAX_LINE 64
#define PAGE_LEN 22

//´íÎó´úÂë
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

//ÔËÐÐ×´Ì¬
enum ProcStatus
{
    RUNNING,
    STOPPED
};

int getusername(char *usr);
int getworkdir(char *dir);
void errproc(int err);