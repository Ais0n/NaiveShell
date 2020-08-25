#!/bin/bash
###############################
#程序名：main.sh （对应实验2第4题）
#作者：黄彦玮
#学号：3180102067
#说明：图书管理系统-主程序
#完成时间：2020-07-31
###############################

#权限：1:管理员 2:教师 3:学生 
#检查账号密码是否匹配
check_pwd(){
    p_account=$1
    p_passwd=$2
    #超级管理员特判
    if [ $p_account = 'super' ] && [ $p_passwd = 'super' ]
    then
        name='super'
        return 1
    fi
    #判断账号信息是否存在
    usr_file="./usr"
    if [ ! -f $usr_file ]
    then
        return 0
    fi
    #扫描账号信息的文件，对比账号密码
    while read ac pw au nm
    do
        if [ $ac = $p_account ] && [ $pw = $p_passwd ]
        then
            name=$nm
            return $au
        fi
    done <${usr_file}
    return 0
}

clear
echo -e "\n\n \t\t \033[40;93m =====欢迎来到教务管理系统=====\033[0m \t\t"
while true
do
    #读入账号
    echo -e "\033[40;93m请输入账号: \033[0m"
    #用户没输入就一直读
    while true
    do
        read account
        if test -n $account
        then
            break
        fi
    done
    #读入密码
    echo -e "\033[40;93m请输入密码: \033[0m"
    while true
    do
        read -s passwd
        if test -n $passwd
        then
            break
        fi
    done
    echo
    #检查账号密码是否匹配
    check_pwd $account $passwd
    auth=$?
    #账号不存在或密码错误
    if [ $auth -eq 0 ]
    then
        echo -e "\033[40;93m用户不存在或密码错误！\033[0m"
    else
        break
    fi
done

#根据权限执行不同的脚本
case $auth in
    1) ./admin.sh $account $name;;
    2) ./teacher.sh $account $name;;
    3) ./student.sh $account $name;;
esac