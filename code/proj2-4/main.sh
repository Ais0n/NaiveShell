#!/bin/bash
###############################
#��������main.sh ����Ӧʵ��2��4�⣩
#���ߣ�������
#ѧ�ţ�3180102067
#˵����ͼ�����ϵͳ-������
#���ʱ�䣺2020-07-31
###############################

#Ȩ�ޣ�1:����Ա 2:��ʦ 3:ѧ�� 
#����˺������Ƿ�ƥ��
check_pwd(){
    p_account=$1
    p_passwd=$2
    #��������Ա����
    if [ $p_account = 'super' ] && [ $p_passwd = 'super' ]
    then
        name='super'
        return 1
    fi
    #�ж��˺���Ϣ�Ƿ����
    usr_file="./usr"
    if [ ! -f $usr_file ]
    then
        return 0
    fi
    #ɨ���˺���Ϣ���ļ����Ա��˺�����
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
echo -e "\n\n \t\t \033[40;93m =====��ӭ�����������ϵͳ=====\033[0m \t\t"
while true
do
    #�����˺�
    echo -e "\033[40;93m�������˺�: \033[0m"
    #�û�û�����һֱ��
    while true
    do
        read account
        if test -n $account
        then
            break
        fi
    done
    #��������
    echo -e "\033[40;93m����������: \033[0m"
    while true
    do
        read -s passwd
        if test -n $passwd
        then
            break
        fi
    done
    echo
    #����˺������Ƿ�ƥ��
    check_pwd $account $passwd
    auth=$?
    #�˺Ų����ڻ��������
    if [ $auth -eq 0 ]
    then
        echo -e "\033[40;93m�û������ڻ��������\033[0m"
    else
        break
    fi
done

#����Ȩ��ִ�в�ͬ�Ľű�
case $auth in
    1) ./admin.sh $account $name;;
    2) ./teacher.sh $account $name;;
    3) ./student.sh $account $name;;
esac