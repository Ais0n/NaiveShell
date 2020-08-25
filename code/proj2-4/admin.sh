#!/bin/bash
###############################
#��������admin.sh ����Ӧʵ��2��4�⣩
#���ߣ�������
#ѧ�ţ�3180102067
#˵����ͼ�����ϵͳ-����Ա����
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


#�½���ʦ�˻�
CreateTeacherAccount(){
    usr_file="./usr"
    touch ${usr_file}
    while true
    do
        echo -e "\n"
        echo -e "\033[40;93m�������ʦ���ţ�����'!'ȡ����\033[0m"
        #�����ʦ����
        myRead
        TeacherId=$Buffer
        #��ʦ����Ϊ'!'�򷵻�
        if [ $TeacherId = '!' ]
        then
            return 0
        fi
        echo -e "\033[40;93m�������ʦ����������'!'ȡ����\033[0m"
        #�����ʦ����
        myRead
        TeacherName=$Buffer
        #��ʦ����Ϊ'!'�򷵻�
        if [ $TeacherName = '!' ]
        then
            return 0
        fi
        echo -e "\033[40;93m�������ʦ���루����'!'ȡ����\033[0m"
        #�����ʦ����
        myRead
        TeacherPwd=$Buffer
        #��ʦ����Ϊ'!'�򷵻�
        if [ $TeacherPwd = '!' ]
        then
            return 0
        fi
        flag=0
        #ɨ���˺���Ϣ���ļ����ж��˺��Ƿ����
        while read ac pw au nm
        do
            #�˺��Ѵ��ڣ�����ʧ��
            if [ $ac = $TeacherId ]
            then
                flag=1
                echo -e "\033[40;93m���ʧ�ܣ��˺��Ѵ��ڣ�\033[0m"
                break
            fi
        done <${usr_file}
        #�˺Ų����ڣ�����ɹ�
        if [ $flag -eq 0 ]
        then
            echo $TeacherId $TeacherPwd 2 $TeacherName >>${usr_file}
            echo -e "\033[40;93m��ӳɹ���\033[0m"
        fi
    done
}

#�޸Ľ�ʦ�˻�
ModifyTeacherAccount(){
    usr_file="./usr"
    touch ${usr_file}
    while true
    do
        echo -e "\n"
        echo -e "\033[40;93m������Ҫ�޸ĵĽ�ʦ���ţ�����'!'ȡ����\033[0m"
        #�����ʦ����
        myRead
        TeacherId=$Buffer
        #��ʦ����Ϊ'!'�򷵻�
        if [ $TeacherId = '!' ]
        then
            return 0
        fi
        echo -e "\033[40;93m�������ʦ����������'!'ȡ��������'/'���޸Ĵ��\033[0m"
        #�����ʦ����
        myRead
        TeacherName=$Buffer
        #��ʦ����Ϊ'!'�򷵻�
        if [ $TeacherName = '!' ]
        then
            return 0
        fi
        echo -e "\033[40;93m�������ʦ���루����'!'ȡ��������'/'���޸Ĵ��\033[0m"
        #�����ʦ����
        myRead
        TeacherPwd=$Buffer
        #��ʦ����Ϊ'!'�򷵻�
        if [ $TeacherPwd = '!' ]
        then
            return 0
        fi
        flag=0
        #ɨ���˺���Ϣ���ļ����ж��˺��Ƿ����
        while read ac pw au nm
        do
            #�˺��Ѵ��ڣ��޸�
            if [ $ac = $TeacherId ]
            then
                flag=1
                #Ȩ�޷ǽ�ʦ��ɾ��ʧ��
                if [ $au -ne 2 ]
                then
                    echo -e "\033[40;93m�޸�ʧ�ܣ��������û��ǽ�ʦ�û���\033[0m" 
                else
                    #����Ϊ'/'���޸�
                    if [ $TeacherPwd != '/' ]
                    then
                        pw=$TeacherPwd
                    fi
                    if [ $TeacherName != '/' ]
                    then
                        nm=$TeacherName
                    fi
                    #��ɾ�����Ŷ�Ӧ����
                    cat ${usr_file} | grep -v "^$ac " >> ${usr_file}Tmp
                    mv ${usr_file}Tmp ${usr_file}
                    #������һ�б�ʾ�µ��˺���Ϣ
                    echo $ac $pw $au $nm >>${usr_file}
                    echo -e "\033[40;93m�޸ĳɹ���\033[0m" 
                fi
                break
            fi
        done <${usr_file}
        #�˺Ų����ڣ��޸�ʧ��
        if [ $flag -eq 0 ]
        then
            echo -e "\033[40;93m�޸�ʧ�ܣ��û���Ϣ�����ڣ�\033[0m"
        fi
    done
}

#ɾ����ʦ�˻�
DeleteTeacherAccount(){
    usr_file="./usr"
    touch ${usr_file}
    while true
    do
        echo -e "\n"
        echo -e "\033[40;93m������Ҫɾ���Ľ�ʦ���ţ�����'!'ȡ����\033[0m"
        #�����ʦ����
        myRead
        TeacherId=$Buffer
        #��ʦ����Ϊ'!'�򷵻�
        if [ $TeacherId = '!' ]
        then
            return 0
        fi
        flag=0
        #ɨ���˺���Ϣ���ļ����ж��˺��Ƿ����
        while read ac pw au nm
        do
            #�˺��Ѵ��ڣ�ɾ��
            if [ $ac = $TeacherId ]
            then
                flag=1
                if [ $au -ne 2 ]
                then
                    echo -e "\033[40;93mɾ��ʧ�ܣ��������û��ǽ�ʦ�û���\033[0m"
                else
                    #ɾ�����Ŷ�Ӧ����
                    cat ${usr_file} | grep -v "^$TeacherId " >> ${usr_file}Tmp
                    mv ${usr_file}Tmp ${usr_file}
                    echo -e "\033[40;93mɾ���ɹ���\033[0m"
                fi
                break
            fi
        done <${usr_file}
        #�˺Ų����ڣ�ɾ��ʧ��
        if [ $flag -eq 0 ]
        then
            echo -e "\033[40;93mɾ��ʧ�ܣ��û������ڣ�\033[0m"
        fi
    done
}

#���˺Ų�ѯ��ʦ
QueryTeacherAccountById(){
    usr_file="./usr"
    touch ${usr_file}
    while true
    do
        echo -e "\n"
        echo -e "\033[40;93m�������ʦ���ţ�����'!'ȡ����\033[0m"
        #�����ʦ����
        myRead
        TeacherId=$Buffer
        #��ʦ����Ϊ'!'�򷵻�
        if [ $TeacherId = '!' ]
        then
            return 0
        fi
        #����Ҫ��ļ�¼��
        itemcnt=0
        #ɨ���˺���Ϣ���ļ����ж��˺��Ƿ����
        while read ac pw au nm
        do
            #�˺��Ѵ�����Ȩ����ȷ����������Ϣ
            if [[ $ac =~ $TeacherId ]] && [ $au -eq 2 ]
            then
                ((itemcnt++))
                echo -e "\033[40;93m���ţ�$ac  ������$nm\033[0m"
            fi
        done <${usr_file}
        #�޷���Ҫ����Ϣ����ѯʧ��
        if [ $itemcnt -eq 0 ]
        then
            echo -e "\033[40;93m��ѯʧ�ܣ�������û���\033[0m"
        #��ѯ�ɹ��������Ϣ����
        else
            echo -e "\033[40;93m��ѯ�ɹ����� $itemcnt ����Ϣ��\033[0m"
        fi
    done
}

#��������ѯ��ʦ
QueryTeacherAccountByName(){
    usr_file="./usr"
    touch ${usr_file}
    while true
    do
        echo -e "\n"
        echo -e "\033[40;93m�������ʦ����������'!'ȡ����\033[0m"
        #�����ʦ����
        myRead
        TeacherName=$Buffer
        #��ʦ����Ϊ'!'�򷵻�
        if [ $TeacherName = '!' ]
        then
            return 0
        fi
        #����Ҫ��ļ�¼��
        itemcnt=0
        #ɨ���˺���Ϣ���ļ����ж��˺��Ƿ����
        while read ac pw au nm
        do
            #�˺��Ѵ�����Ȩ����ȷ����������Ϣ
            if [[ $nm =~ $TeacherName ]] && [ $au -eq 2 ]
            then
                ((itemcnt++))
                echo -e "\033[40;93m���ţ�$ac  ������$nm\033[0m"
            fi
        done <${usr_file}
        #�޷���Ҫ����Ϣ����ѯʧ��
        if [ $itemcnt -eq 0 ]
        then
            echo -e "\033[40;93m��ѯʧ�ܣ�������û���\033[0m"
        #��ѯ�ɹ��������Ϣ����
        else
            echo -e "\033[40;93m��ѯ�ɹ����� $itemcnt ����Ϣ��\033[0m"
        fi
    done
}

#��ѯȫ����ʦ�˻�
QueryTeacherAccountALL(){
    usr_file="./usr"
    touch ${usr_file}
    #����Ҫ��ļ�¼��
    itemcnt=0
    #ɨ���˺���Ϣ���ļ����ж��˺��Ƿ����
    while read ac pw au nm
    do
        #�˺��Ѵ�����Ȩ����ȷ����������Ϣ
        if [ $au -eq 2 ]
        then
            ((itemcnt++))
            echo -e "\033[40;93m���ţ�$ac  ������$nm\033[0m"
        fi
    done <${usr_file}
    #�޷���Ҫ����Ϣ����ѯʧ��
    if [ $itemcnt -eq 0 ]
    then
        echo -e "\033[40;93m��ѯʧ�ܣ�������û���\033[0m"
    #��ѯ�ɹ��������Ϣ����
    else
        echo -e "\033[40;93m��ѯ�ɹ����� $itemcnt ����¼��\033[0m"
        return 0
    fi
    return 0
}

#��ѯ��ʦ�˻�
QueryTeacherAccount(){
    while true
    do
        echo -e "\n"
        echo -e "\033[40;93m\t"1\)�����Ų���"\033[0m"
        echo -e "\033[40;93m\t"2\)����������"\033[0m"
        echo -e "\033[40;93m\t"3\)����ȫ����¼"\033[0m"
        echo -e "\033[40;93m\t"b\)�����ϼ�"\033[0m"
        echo -e "\033[40;93m\t"q\)�˳�"\033[0m"
        echo -e "\n"
        echo -e "\033[40;93m"��ѡ��"\033[0m"
        read choice
            case $choice in
                1)  QueryTeacherAccountById;;
                2)  QueryTeacherAccountByName;;
                3)  QueryTeacherAccountALL;;
                b)  return 0;;
                q)  exit 0;;
                *)  echo -e "\033[40;93m"����Ƿ������������룡"\033[0m";;
            esac
    done
}

#��ʦ��Ϣ����
ManT(){
    while true
    do
        echo -e "\n"
        echo -e "\033[40;93m\t"1\)������ʦ�˺�"\033[0m"
        echo -e "\033[40;93m\t"2\)�޸Ľ�ʦ��Ϣ"\033[0m"
        echo -e "\033[40;93m\t"3\)ɾ����ʦ�˺�"\033[0m"
        echo -e "\033[40;93m\t"4\)��ѯ��ʦ��Ϣ"\033[0m"
        echo -e "\033[40;93m\t"b\)�����ϼ�"\033[0m"
        echo -e "\033[40;93m\t"q\)�˳�"\033[0m"
        echo -e "\n"
        echo -e "\033[40;93m"��ѡ��"\033[0m"
        read choice
        case $choice in
            1)  CreateTeacherAccount;;
            2)  ModifyTeacherAccount;;
            3)  DeleteTeacherAccount;;
            4)  QueryTeacherAccount;;
            b)  return 0;;
            q)  exit 0;;
            *)  echo -e "\033[40;93m"����Ƿ������������룡"\033[0m";;
        esac
    done
}

#�½��γ�
CreateCourse(){
    cfile="./course"
    touch $cfile
    while true
    do
        echo -e "\n"
        echo -e "\033[40;93m������γ̺ţ�����'!'ȡ����\033[0m"
        #����γ̺�
        myRead
        CourseId=$Buffer
        #��ʦ����Ϊ'!'�򷵻�
        if [ $CourseId = '!' ]
        then
            return 0
        fi
        echo -e "\033[40;93m������γ����ƣ�����'!'ȡ����\033[0m"
        #����γ�����
        myRead
        CourseName=$Buffer
        #�γ̺�����'!'�򷵻�
        if [ $CourseName = '!' ]
        then
            return 0
        fi
        flag=0
        #ɨ��γ���Ϣ���ļ����жϿγ��Ƿ����
        while read cid nm
        do
            #�γ��Ѵ���
            if [ $cid = $CourseId ]
            then
                flag=1
                echo -e "\033[40;93m���ʧ�ܣ��γ̺��Ѵ��ڣ�\033[0m"
                break
            fi
        done <${cfile}
        
        #�γ̲����ڣ���ӿγ�
        if [ $flag -eq 0 ] 
        then
            #���¿γ���ӵ������ļ���ĩβ
            echo $CourseId $CourseName >> $cfile
            echo -e "\033[40;93m��ӳɹ���\033[0m"
        fi
    done
}

#�޸Ŀγ�
ModifyCourse(){
    cfile="./course"
    touch $cfile
    while true
    do
        echo -e "\n"
        echo -e "\033[40;93m������γ̺ţ�����'!'ȡ����\033[0m"
        #����γ̺�
        myRead
        CourseId=$Buffer
        #��ʦ����Ϊ'!'�򷵻�
        if [[ $CourseId = '!' ]]
        then
            return 0
        fi
        echo -e "\033[40;93m������γ����ƣ�����'!'ȡ��������'/'���޸Ĵ��\033[0m"
        #����γ�����
        myRead
        CourseName=$Buffer
        #�γ̺�����'!'�򷵻�
        if [[ $CourseName = '!' ]]
        then
            return 0
        fi
        flag=0
        #ɨ��γ���Ϣ���ļ����жϿγ��Ƿ����
        while read cid nm
        do
            #�γ̴��ڣ������޸�
            if [ $cid = $CourseId ]
            then
                flag=1
                if [[ $CourseName != '/' ]]
                then
                    nm=$CourseName
                fi
                #��ɾ���γ̺Ŷ�Ӧ����
                cat $cfile | grep -v "^$cid " >> ${cfile}Tmp
                mv ${cfile}Tmp ${cfile}
                #������һ�б�ʾ�µ��˺���Ϣ
                echo $cid $nm >>${cfile}
                echo -e "\033[40;93m�޸ĳɹ���\033[0m" 
                break
            fi
        done <${cfile}
        #�γ̲����ڣ��޸�ʧ��
        if [ $flag -eq 0 ] 
        then
            echo -e "\033[40;93m�޸�ʧ�ܣ��γ̲����ڣ�\033[0m"
        fi
    done
}

#ɾ���γ�
DeleteCourse(){
    cfile="./course"
    touch $cfile
    while true
    do
        echo -e "\n"
        echo -e "\033[40;93m������γ̺ţ�����'!'ȡ����\033[0m"
        #����γ̺�
        myRead
        CourseId=$Buffer
        #�γ̺�Ϊ'!'�򷵻�
        if [[ $CourseId = '!' ]]
        then
            return 0
        fi
        flag=0
        #ɨ���˺���Ϣ���ļ����ж��˺��Ƿ����
        while read cid nm
        do
            #�˺��Ѵ��ڣ�ɾ��
            if [ $cid = $CourseId ]
            then
                flag=1
                #ɾ���˺Ŷ�Ӧ����
                cat $cfile | grep -v "^$CourseId " >> ${cfile}Tmp
                mv ${cfile}Tmp ${cfile}
                echo -e "\033[40;93mɾ���ɹ���\033[0m"
                break
            fi
        done <${cfile}
        #�˺Ų����ڣ�ɾ��ʧ��
        if [ $flag -eq 0 ]
        then
            echo -e "\033[40;93mɾ��ʧ�ܣ��γ̲����ڣ�\033[0m"
        fi
    done
}

#���γ̺Ų�ѯ�γ�
QueryCourseById(){
    cfile="./course"
    touch $cfile
    while true
    do
        echo -e "\n"
        echo -e "\033[40;93m������γ̺ţ�����'!'ȡ����\033[0m"
        #����γ̺�
        myRead
        CourseId=$Buffer
        #�γ̺�Ϊ'!'�򷵻�
        if [ $CourseId = '!' ]
        then
            return 0
        fi
        #���������ļ�¼��
        itemcnt=0
        #ɨ��γ���Ϣ���ļ�
        while read cid nm
        do
            #�γ̴��ڣ������¼
            if [[ $cid =~ $CourseId ]]
            then
                ((itemcnt++))
                echo -e "\033[40;93m$cid $nm\033[0m"
            fi
        done <${cfile}
        #�γ̲����ڣ�ɾ��ʧ��
        if [ $itemcnt -eq 0 ]
        then
            echo -e "\033[40;93m��ѯʧ�ܣ�����ؿγ̣�\033[0m"
        else
            echo -e "\033[40;93m��ѯ�ɹ����� $itemcnt ����¼��\033[0m"
        fi
    done
}

#���γ�����ѯ�γ�
QueryCourseByName(){
    cfile="./course"
    touch $cfile
    while true
    do
        echo -e "\n"
        echo -e "\033[40;93m������γ����ƣ�����'!'ȡ����\033[0m"
        #����γ�����
        myRead
        CourseName=$Buffer
        #�γ�����Ϊ'!'�򷵻�
        if [ $CourseName = '!' ]
        then
            return 0
        fi
        #���������ļ�¼��
        itemcnt=0
        #ɨ��γ���Ϣ���ļ�
        while read cid nm
        do
            #�γ̴��ڣ������¼
            if [[ $nm =~ $CourseName ]]
            then
                ((itemcnt++))
                echo -e "\033[40;93m$cid $nm\033[0m"
            fi
        done <${cfile}
        #�γ̲�����
        if [ $itemcnt -eq 0 ]
        then
            echo -e "\033[40;93m��ѯʧ�ܣ�����ؿγ̣�\033[0m"
        else
            echo -e "\033[40;93m��ѯ�ɹ����� $itemcnt ����¼��\033[0m"
        fi
    done
}

#��ѯȫ���γ�
QueryCourseALL(){
    cfile="./course"
    touch $cfile
    while true
    do
        #���������ļ�¼��
        itemcnt=0
        #ɨ��γ���Ϣ���ļ�
        while read cid nm
        do
            #�����¼
            ((itemcnt++))
            echo -e "\033[40;93m$cid $nm\033[0m"
        done <${cfile}
        #�γ̲�����
        if [ $itemcnt -eq 0 ]
        then
            echo -e "\033[40;93m��ѯʧ�ܣ�����ؿγ̣�\033[0m"
        else
            echo -e "\033[40;93m��ѯ�ɹ����� $itemcnt ����¼��\033[0m"
            return 0
        fi
    done
}

#��ѯ�γ���Ϣ
QueryCourse(){
    while true
    do
        echo -e "\n"
        echo -e "\033[40;93m\t"1\)���γ̺Ų���"\033[0m"
        echo -e "\033[40;93m\t"2\)���γ�������"\033[0m"
        echo -e "\033[40;93m\t"3\)��ѯ���пγ�"\033[0m"
        echo -e "\033[40;93m\t"b\)�����ϼ�"\033[0m"
        echo -e "\033[40;93m\t"q\)�˳�"\033[0m"
        echo -e "\n"
        echo -e "\033[40;93m"��ѡ��"\033[0m"
        read choice
        case $choice in
            1)  QueryCourseById;;
            2)  QueryCourseByName;;
            3)  QueryCourseALL;;
            b)  return 0;;
            q)  exit 0;;
            *)  echo -e "\033[40;93m"����Ƿ������������룡"\033[0m";;
        esac
    done
}

#�󶨿γ̺ͽ�ʦ�˺�
LinkCourseAndTeacher(){
    cfile="./givecourse"
    touch $cfile
    while true
    do
        echo -e "\n"
        echo -e "\033[40;93m������γ̺ţ�����'!'ȡ����\033[0m"
        #����γ̺�
        myRead
        CourseId=$Buffer
        #��ʦ����Ϊ'!'�򷵻�
        if [ $CourseId = '!' ]
        then
            return 0
        fi
        echo -e "\033[40;93m�������ʦ�˺ţ�����'!'ȡ����\033[0m"
        #�����ʦ�˺�
        myRead
        TeacherId=$Buffer
        #�γ̺�����'!'�򷵻�
        if [ $TeacherId = '!' ]
        then
            return 0
        fi
        #���γ��Ƿ����
        flag=$(cat "./course" | grep "^$CourseId" | wc -l)
        if [ $flag -eq 0 ]
        then
            echo -e "\033[40;93m�γ̲����ڣ�\033[0m"
            continue
        fi
        #����ʦ�Ƿ����
        flag=$(cat "./usr" | grep "^$TeacherId" | wc -l)
        if [ $flag -eq 0 ]
        then
            echo -e "\033[40;93m��ʦ�����ڣ�\033[0m"
            continue
        fi
        #ɨ��ѡ����Ϣ���ļ�
        itemcnt=$(cat $cfile | grep "^$CourseId\ $TeacherId" | wc -l)
        #ѡ����Ϣ�����ڣ������Ϣ
        if [ $itemcnt -eq 0 ] 
        then
            #���¿γ���ӵ������ļ���ĩβ
            echo $CourseId $TeacherId >> $cfile
            echo -e "\033[40;93m��ӳɹ���\033[0m"
        else
            echo -e "\033[40;93m���ʧ�ܣ���¼�Ѵ��ڣ�\033[0m"
        fi
    done
}

#���γ����ʦ�˺�
CancelLinkCourseAndTeacher(){
    cfile="./givecourse"
    touch $cfile
    while true
    do
        echo -e "\n"
        echo -e "\033[40;93m������γ̺ţ�����'!'ȡ����\033[0m"
        #����γ̺�
        myRead
        CourseId=$Buffer
        #��ʦ����Ϊ'!'�򷵻�
        if [ $CourseId = '!' ]
        then
            return 0
        fi
        echo -e "\033[40;93m�������ʦ�˺ţ�����'!'ȡ����\033[0m"
        #�����ʦ�˺�
        myRead
        TeacherId=$Buffer
        #�γ̺�����'!'�򷵻�
        if [ $TeacherId = '!' ]
        then
            return 0
        fi
        flag=0
        #ɨ��ѡ����Ϣ���ļ�
        itemcnt=$(cat $cfile | grep "^$CourseId\ $TeacherId" | wc -l)
        #ѡ����Ϣ�����ڣ�ɾ��ʧ��
        if [ $itemcnt -eq 0 ] 
        then
            echo -e "\033[40;93mɾ��ʧ�ܣ���¼�����ڣ�\033[0m"
        else
            #���÷���ѡ��ɾ������Ϣ
            cat $cfile | grep -v "^$CourseId\ $TeacherId" >> "${cfile}tmp"
            mv "${cfile}tmp" "$cfile"
            echo -e "\033[40;93mɾ���ɹ���\033[0m"
        fi
    done
}

#�γ���Ϣ����
ManC(){
    while true
    do
        echo -e "\n"
        echo -e "\033[40;93m\t"1\)�����γ�"\033[0m"
        echo -e "\033[40;93m\t"2\)�޸Ŀγ�"\033[0m"
        echo -e "\033[40;93m\t"3\)ɾ���γ�"\033[0m"
        echo -e "\033[40;93m\t"4\)��ѯ�γ�"\033[0m"
        echo -e "\033[40;93m\t"5\)�󶨿γ����ʦ�˻�"\033[0m"
        echo -e "\033[40;93m\t"6\)���γ����ʦ�˻�"\033[0m"
        echo -e "\033[40;93m\t"b\)�����ϼ�"\033[0m"
        echo -e "\033[40;93m\t"q\)�˳�"\033[0m"
        echo -e "\n"
        echo -e "\033[40;93m"��ѡ��"\033[0m"
        read choice
        case $choice in
            1)  CreateCourse;;
            2)  ModifyCourse;;
            3)  DeleteCourse;;
            4)  QueryCourse;;
            5)  LinkCourseAndTeacher;;
            6)  CancelLinkCourseAndTeacher;;
            b)  return 0;;
            q)  exit 0;;
            *)  echo -e "\033[40;93m"����Ƿ������������룡"\033[0m";;
        esac
    done
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

clear
echo -e "\n\n \t\t    \033[40;93m =====��ӭ����$name��=====\033[0m"
echo -e "\n\n \t  \033[40;93m=====��ǰ��¼�˺ţ�$account  ��ǰȨ�ޣ�����Ա=====\033[0m"

while true
do
    echo -e "\n"
    echo -e "\033[40;93m\t"1\)�����ʦ��Ϣ"\033[0m"
    echo -e "\033[40;93m\t"2\)����γ���Ϣ"\033[0m"
    echo -e "\033[40;93m\t"3\)�޸��û�����"\033[0m"
    echo -e "\033[40;93m\t"q\)�˳�"\033[0m"
    echo -e "\n"
    echo -e "\033[40;93m"��ѡ��"\033[0m"
    read choice
        case $choice in
            1)  ManT;;
            2)  ManC;;
            3)  ChangePwd;;
            q)  exit 0;;
            *)  echo -e "\033[40;93m"����Ƿ������������룡"\033[0m";;
        esac
done