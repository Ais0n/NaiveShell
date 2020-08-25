#!/bin/bash
###############################
#��������student.sh ����Ӧʵ��2��4�⣩
#���ߣ�������
#ѧ�ţ�3180102067
#˵����ͼ�����ϵͳ-ѧ������
#���ʱ�䣺2020-07-31
###############################

#��������������2���쳣����
if [ $# -ne 2 ]
then
    exit 1
fi

account=$1
name=$2
typeset -i itemcnt=0

#�Զ�����룬���Իس�����������ĵ������ַ�������
myRead(){
    while true
    do
        read Buffer
        if [ -n $Buffer ]
        then
            break
        fi
        if [[ $Buffer =~ \ + ]] 
        then
            echo -e "\033[40;93m���뺬�Ƿ��ַ������������룡\033[0m"
        fi
    done
}

#���ڸ�ʽ���
DateCheck(){
    #����date�����ж������Ƿ�Ϸ�
    if echo $1 | grep -Eq "[0-9]{4}-[0-9]{2}-[0-9]{2}" && date -d $1 +%Y%m%d > /dev/null 2>&1
    then 
        return 1
    else
        return 0
    fi
}

#����ʱ��
myReadTime(){
    #������ʾ�Ƿ���Ҫ����'/'�����ڱ༭��ҵ��
    tmp=$#
    while true
    do
        read Buffer
        #���ú����ж϶��������Ƿ�Ϸ�
        DataCheck $Buffer
        #���������Ҫ��
        if [ $tmp -eq 0 ]
        then
            if [ $? -ne 1 ] && [ $Buffer != '!' ] 
            then
                echo -e "\033[40;93m��ʽ�������������룡\033[0m"
            else
                break
            fi
        else
            if [ $? -ne 1 ] && [ $Buffer != '!' ] && [ $Buffer != '/' ]
            then
                echo -e "\033[40;93m��ʽ�������������룡\033[0m"
            else
                break
            fi
        fi
    done
}

#��ѯ��ҵ�Ƿ����&�Ƿ�����Ч��
checkHW(){
    CourseId=$1
    HWId=$2
    while read cid aid st ed
    do
        #��catalog�ļ��в�ѯ��ҵ��Ϣ
        if [ $cid = $CourseId ] && [ $aid = $HWId ]
        then
            #��õ�ǰʱ�䣬��ת����ʱ���
            currenttime=$(date +%s)
            #����ʼʱ��ͽ���ʱ�䶼ת����ʱ���
            sttime=$(date -d "$st" +%s)
            edtime=$(date -d "$ed" +%s)
            if [ $currenttime -ge $sttime ] && [ $currenttime -le $edtime ]
            then
                return 1
            fi
        fi
    done <"./hw/catalog"
    return 0
}


#�½���ҵ
CreateWork(){
    CourseId=$1
    while true
    do
        echo -e "\033[40;93m��������ҵ��ţ�����'!'���أ���\033[0m"
        myRead
        HWId=$Buffer
        if [[ $HWId = '!' ]]
        then
            return 0
        fi
        #�ж���ҵ�Ƿ�����ҿ��ύ
        checkHW $CourseId $HWId
        #��ҵ�Ϸ�
        if [ $? -eq 1 ]
        then
            path="./submit/hw_${CourseId}_${HWId}_$account"
            if [ ! -f $path ]
            then
                touch $path
                echo -e "\033[40;93m"�������Ϣ������һ��һ���ַ�\'\!\'������"\033[0m"
                #������Ϣ����
                while true
                do
                    read tmp
                    if [[ $tmp = '!' ]]
                    then 
                        break
                    fi
                    #����Ϣд���Ӧ�ļ�
                    echo $tmp >> $path
                done
                echo -e "\033[40;93m"�½��ɹ�����ҵ�ѱ�����$path��"\033[0m"
            else
                echo -e "\033[40;93m"�½�ʧ�ܣ���ҵ�Ѵ��ڣ�"\033[0m"
            fi
        else
            #��ҵ���Ϸ�����������
            echo -e "\033[40;93m�½�ʧ�ܣ���ҵ�����ڻ����ύʱ�䣡\033[0m"
        fi
    done
}

#�༭��ҵ
EditWork(){
    CourseId=$1
    while true
    do
        echo -e "\033[40;93m��������ҵ��ţ�����'!'���أ���\033[0m"
        myRead
        HWId=$Buffer
        if [[ $HWId = '!' ]]
        then
            return 0
        fi
        #�ж���ҵ�Ƿ�����ҿ��ύ
        checkHW $CourseId $HWId
        #��ҵ�Ϸ�
        if [ $? -eq 1 ]
        then
            path="./submit/hw_${CourseId}_${HWId}_$account"
            if [ -f $path ]
            then
                vi $path
                echo -e "\033[40;93m"�༭�ɹ���"\033[0m"
            else
                echo -e "\033[40;93m"�༭ʧ�ܣ���ҵ�����ڣ�"\033[0m"
            fi
        else
            #��ҵ���Ϸ�����������
            echo -e "\033[40;93m�½�ʧ�ܣ���ҵ�����ڻ����ύʱ�䣡\033[0m"
        fi
    done
}

#ɾ����ҵ
DeleteWork()
{
    CourseId=$1
    while true
    do
        echo -e "\033[40;93m��������ҵ��ţ�����'!'���أ���\033[0m"
        myRead
        HWId=$Buffer
        if [[ $HWId = '!' ]]
        then
            return 0
        fi
        #�ж���ҵ�Ƿ�����ҿ��ύ
        checkHW $CourseId $Buffer
        #��ҵ�Ϸ�
        if [ $? -eq 1 ]
        then
            path="./submit/hw_${CourseId}_${HWId}_$account"
            #��ҵ����
            if [ -f $path ]
            then
                rm $path
                echo -e "\033[40;93m"ɾ���ɹ���"\033[0m"
            else
                echo -e "\033[40;93m"ɾ��ʧ�ܣ���ҵ�����ڣ�"\033[0m"
            fi
        else
            #��ҵ���Ϸ�����������
            echo -e "\033[40;93m�½�ʧ�ܣ���ҵ�����ڻ����ύʱ�䣡\033[0m" 
        fi
    done
}

#��ѯ��ҵ
QueryWork(){
    CourseId=$1
    cfile="./hw/catalog"
    while read cid aid st ed
    do
        #�γ̺Ų�������ֱ������
        if [[ $cid != $CourseId ]]
        then
            continue
        fi
        path="./submit/hw_${CourseId}_${aid}_$account"
        if [ -f $path ]
        then
            isfinished="���ύ��·��Ϊ$path"
        else
            isfinished="δ�ύ"
        fi
        echo -e "\033[40;93m"��ҵ��ţ�$aid ��ʼ���ڣ�$st �������ڣ�$ed"\033[0m"
        echo -e "\033[40;93m"��ҵ״̬��$isfinished"\033[0m"
        echo -e "\033[40;93m"; cat "./hw/course_${cid}_${aid}"; echo -e "\033[0m"
    done <$cfile
}

#�޸�����
ChangePwd(){
    cfile="./usr"
    touch cfile
    if [ $account = "super" ]
    then
        echo -e "\033[40;93m��ǰ�˻������޸����룡\033[0m" 
        return 0
    fi
    while true
    do
        echo -e "\n"
        echo -e "\033[40;93m����������루����'!'ȡ����\033[0m"
        read -s oldpwd
        echo
        if [[ $oldpwd = '!' ]]
        then
            return 0
        fi
        echo -e "\033[40;93m�����������루����'!'ȡ����\033[0m"
        read -s newpwd
        echo
        if [[ $newpwd = '!' ]]
        then
            return 0
        fi
        #ɨ���˺���Ϣ���ļ����Ա��˺�����
        while read ac pw au nm
        do
            if [[ $ac = $account ]]
            then
                if [[ $pw = $oldpwd ]]
                then
                    pw=$newpwd
                    #�Ӿ��ļ���ɾ��ԭ��Ϣ
                    cat $cfile | grep -v "^$account" > "${cfile}Tmp"
                    mv "${cfile}Tmp" "$cfile"
                    #������Ϣ�����ļ����
                    echo $ac $pw $au $nm >> "$cfile"
                    echo -e "\033[40;93m�޸ĳɹ���\033[0m"
                    return 0
                else
                    echo -e "\033[40;93m�޸�ʧ�ܣ����������\033[0m"
                    break
                fi
            fi
        done <${cfile} 
    done
}

#������ҵ
ManWork(){
    CourseId=$1
    #���submit�ļ��в����ڵĻ�Ҫ�ȴ���
    if [ ! -d "./submit" ]
    then
        mkdir "./submit"
    fi
    while true
    do
        echo -e "\n"
        echo -e "\033[40;93m\t"1\)�½���ҵ"\033[0m"
        echo -e "\033[40;93m\t"2\)�༭��ҵ"\033[0m"
        echo -e "\033[40;93m\t"3\)ɾ����ҵ"\033[0m"
        echo -e "\033[40;93m\t"4\)��ѯ��ҵ"\033[0m"
        echo -e "\033[40;93m\t"b\)�����ϼ�"\033[0m"
        echo -e "\033[40;93m\t"q\)�˳�"\033[0m"
        echo -e "\n"
        echo -e "\033[40;93m"��ѡ��"\033[0m"
        read choice
            case $choice in
                1)  CreateWork $CourseId;;
                2)  EditWork $CourseId;;
                3)  DeleteWork $CourseId;;
                4)  QueryWork $CourseId;;
                b)  return 0;;
                q)  exit 0;;
                *)  echo -e "\033[40;93m"����Ƿ������������룡"\033[0m";;
            esac
    done
}

#���γ̺Ų�ѯ�γ�
QueryCourseById(){
    CourseId=$1
    cfile="./course"
    touch $cfile
    Buffer=""
    #ɨ��γ���Ϣ���ļ�
    while read cid nm
    do
        #�γ̴��ڣ������¼
        if [[ $cid =~ $CourseId ]]
        then
            Buffer=$nm
            return 0
        fi
    done <${cfile}
}


#ѡ��γ�
ChooseCourse(){
    cfile="./selcourse"
    #ѡ������
    itemcnt=0
    #ѡ�ογ̺��������б�
    courselist=()
    namelist=()
    while read cid sid
    do
        if [ $account = $sid ]
        then
            #��ȡ�γ�����
            QueryCourseById $cid
            CourseName=$Buffer
            #���γ̺źͿγ����ƴ�������
            courselist[$itemcnt]=$cid
            namelist[$itemcnt]=$Buffer
            ((itemcnt++))
            echo -e "\033[40;93m"$itemcnt')' $cid $CourseName"\033[0m"
        fi
    done <$cfile
    if [ $itemcnt -eq 0 ]
    then
        echo -e "\033[40;93m"������ѡ�Σ�����ϵ��ʦ��ӣ�"\033[0m"
        return 0
    else
        echo -e "\033[40;93m"����ǰ����$itemcnt�ſγ̣���ѡ�񣺣�����'!'���أ�"\033[0m"
        while true
        do
            read choice
            #ѡ��Ϊ'!'�򷵻�
            if [ $choice = '!' ]
            then
                return 0
            fi
            #ѡ��Ϸ������пγ̲���
            if [ "$choice" -gt 0 ] && [ "$choice" -le $itemcnt ] 2>/dev/null ;then 
                ((choice--))
                echo -e "\033[40;93m"��ǰ�����γ̣�${courselist[$choice]} ${namelist[$choice]}"\033[0m"
                ManWork ${courselist[$choice]}
            else 
                echo -e "\033[40;93m"����Ƿ������������룡"\033[0m"
            fi
        done 
    fi
}


clear
echo -e "\n\n \t\t    \033[40;93m =====��ӭ����$name��=====\033[0m"
echo -e "\n\n \t  \033[40;93m=====��ǰ��¼�˺ţ�$account  ��ǰȨ�ޣ�ѧ��=====\033[0m"

while true
do
    echo -e "\n"
    echo -e "\033[40;93m\t"1\)ѡ��γ�"\033[0m"
    echo -e "\033[40;93m\t"2\)�޸��û�����"\033[0m"
    echo -e "\033[40;93m\t"q\)�˳�"\033[0m"
    echo -e "\n"
    echo -e "\033[40;93m"��ѡ��"\033[0m"
    read choice
        case $choice in
            1)  ChooseCourse;;
            2)  ChangePwd;;
            q)  exit 0;;
            *)  echo -e "\033[40;93m"����Ƿ������������룡"\033[0m";;
        esac
done