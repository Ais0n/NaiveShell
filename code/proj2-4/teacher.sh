#!/bin/bash
###############################
#��������teacher.sh ����Ӧʵ��2��4�⣩
#���ߣ�������
#ѧ�ţ�3180102067
#˵����ͼ�����ϵͳ-��ʦ����
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
typeset -i itemcnttwo=0

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
        DateCheck $Buffer
        #�����Ƿ�Ϸ�
        isTimeOK=$?
        #���������Ҫ��
        if [ $tmp -eq 0 ]
        then
            if [ $isTimeOK -ne 1 ] && [ $Buffer != '!' ] 
            then
                echo -e "\033[40;93m��ʽ�������������룡\033[0m"
            else
                break
            fi
        else
            if [ $isTimeOK -ne 1 ] && [ $Buffer != '!' ] && [ $Buffer != '/' ]
            then
                echo -e "\033[40;93m��ʽ�������������룡\033[0m"
            else
                break
            fi
        fi
    done
}

#�½�/����һ��ѧ�����˻������½��˻��͵����˻��ĺ����е��ã�
CreateOneStudent(){
    StudentId=$1
    StudentPwd=$2
    StudentName=$3
    CourseId=$4
    cfile="./selcourse"
    usr_file="./usr"
    flag=0
    touch $cfile
    touch ${usr_file}
    #�ж�ѧ���˻��Ƿ����
    while read ac pw au nm
    do
        #�˺��Ѵ���
        if [ $ac = $StudentId ]
        then
            flag=1
            #�ж�������Ϣ�Ƿ�һ�£�����һ���򱨴�
            if [ $pw != $StudentPwd ] || [ $au -ne 3 ] || [ $nm != $StudentName ]
            then
                echo -e "\033[40;93m���ʧ�ܣ��˺���Ϣ���������ݲ���������ϵѧ���˶ԣ�\033[0m"
                return 0
            fi
            break
        fi
    done <${usr_file}
    #�˺Ų����ڣ�����Ҫ���½��˺�
    if [ $flag -eq 0 ]
    then
        echo $StudentId $StudentPwd 3 $StudentName >>${usr_file}
    fi
    #��ѯѡ����Ϣ�Ƿ��Ѿ�����
    itemcnt=$(cat $cfile | grep "^$CourseId\ $StudentId$" | wc -l)
    #ѡ����Ϣ�Ѿ����ڣ�����
    if [ $itemcnt -ne 0 ]
    then
        echo -e "\033[40;93m���ʧ�ܣ�ѡ����Ϣ�Ѵ��ڣ�\033[0m"
        return 0
    fi
    #���ѡ����Ϣ
    echo $CourseId $StudentId >> $cfile
    echo -e "\033[40;93m��ӳɹ���\033[0m"
    return 1
}


#�½�ѧ���˻�
CreateStudent(){
    CourseId=$1
    cfile="./selcourse"
    usr_file="./usr"
    while true
    do
        echo -e "\n"
        echo -e "\033[40;93m������ѧ��ѧ�ţ�����'!'ȡ����\033[0m"
        #����ѧ��ѧ��
        myRead
        StudentId=$Buffer
        #ѧ��ѧ��Ϊ'!'�򷵻�
        if [ $StudentId = '!' ]
        then
            return 0
        fi
        echo -e "\033[40;93m������ѧ������������'!'ȡ����\033[0m"
        #����ѧ������
        myRead
        StudentName=$Buffer
        #ѧ������Ϊ'!'�򷵻�
        if [ $StudentName = '!' ]
        then
            return 0
        fi
        echo -e "\033[40;93m������ѧ�����루����'!'ȡ����\033[0m"
        #����ѧ������
        myRead
        StudentPwd=$Buffer
        #ѧ������Ϊ'!'�򷵻�
        if [ $StudentPwd = '!' ]
        then
            return 0
        fi
        #���ú��������˻�
        CreateOneStudent $StudentId $StudentPwd $StudentName $CourseId
    done
}

#�޸�ѧ���˻�
ModifyStudent(){
    usr_file="./usr"
    while true
    do
        echo -e "\n"
        echo -e "\033[40;93m������ѧ��ѧ�ţ�����'!'ȡ����\033[0m"
        #����ѧ��ѧ��
        myRead
        StudentId=$Buffer
        #ѧ��ѧ��Ϊ'!'�򷵻�
        if [ $StudentId = '!' ]
        then
            return 0
        fi
        echo -e "\033[40;93m������ѧ������������'!'ȡ��������'/'���޸Ĵ��\033[0m"
        #����ѧ������
        myRead
        StudentName=$Buffer
        #ѧ������Ϊ'!'�򷵻�
        if [ $StudentName = '!' ]
        then
            return 0
        fi
        echo -e "\033[40;93m������ѧ�����루����'!'ȡ��������'/'���޸Ĵ��\033[0m"
        #����ѧ������
        myRead
        StudentPwd=$Buffer
        #ѧ������Ϊ'!'�򷵻�
        if [ $StudentPwd = '!' ]
        then
            return 0
        fi
        flag=0
        #�ж�ѧ���˻��Ƿ����
        while read ac pw au nm
        do
            #�˺��Ѵ���
            if [ $ac = $StudentId ]
            then
                flag=1
                #���в��޸ĵ����
                if [ $StudentPwd != '/' ]
                then
                    pw=$StudentPwd
                fi
                if [ $StudentName != '/' ]
                then
                    nm=$StudentName
                fi
                #��ɾ������Ϣ�����������Ϣ
                cat ${usr_file} | grep -v "^$ac" >> "${usr_file}Tmp"
                mv "${usr_file}Tmp" "${usr_file}" 
                echo $ac $pw $au $nm >> ${usr_file}
                echo -e "\033[40;93m�޸ĳɹ���\033[0m"
                break
            fi
        done <${usr_file}
        #�˺Ų����ڣ��޸�ʧ��
        if [ $flag -eq 0 ]
        then
            echo -e "\033[40;93m�޸�ʧ�ܣ��û������ڣ�\033[0m"
        fi
    done
}

#ɾ��ѧ���˻�
DeleteStudent(){
    CourseId=$1
    cfile="./selcourse"
    while true
    do
        echo -e "\n"
        echo -e "\033[40;93m������ѧ��ѧ�ţ�����'!'ȡ����\033[0m"
        #����ѧ��ѧ��
        myRead
        StudentId=$Buffer
        #ѧ��ѧ��Ϊ'!'�򷵻�
        if [ $StudentId = '!' ]
        then
            return 0
        fi
        #��ѯ��¼�Ƿ����
        itemcnt=$(cat $cfile | grep "^$CourseId\ $StudentId$" | wc -l)
        #�������ڱ�����������ɾ��
        if [ $itemcnt -eq 0 ]
        then
            echo -e "\033[40;93mɾ��ʧ�ܣ���¼�����ڣ�\033[0m"
        else
            cat $cfile | grep -v "^$CourseId\ $StudentId$" >> "${cfile}Tmp"
            mv "${cfile}Tmp" "${cfile}"
            echo -e "\033[40;93mɾ���ɹ���\033[0m"
        fi
    done
}

#����ѧ���˻�
ImportStudent(){
    CourseId=$1
    cfile="./selcourse"
    while true
    do
        echo -e "\n"
        echo -e "\033[40;93m������Ҫ������ļ�·��������'!'ȡ����\033[0m"
        #�����ļ�·��
        myRead
        FilePath=$Buffer
        #�ļ�·��Ϊ'!'�򷵻�
        if [ $FilePath = '!' ]
        then
            return 0
        fi
        #�ļ��������򱨴�
        if [ ! -f $FilePath ]
        then
            echo -e "\033[40;93m����ʧ�ܣ��ļ������ڣ�\033[0m"
        fi
        #����ɹ��ļ�¼��
        tmp=0
        #��ȡ�ļ����ݲ����Բ���
        while read ac pw nm
        do
            echo -e "\033[40;93m���ڳ��Ե��룺$ac $nm\033[0m"
            #���ú�������
            CreateOneStudent $ac $pw $nm $CourseId
            #����ɹ��������ͳ����Ϣ
            if [ $? -eq 1 ]
            then
                ((tmp++))
            fi
        done <$FilePath
        echo -e "\033[40;93m������ɣ����ɹ����� $tmp ����¼��\033[0m"
    done
}

#��ѧ�Ų�ѯѧ���˻�
QueryStudentById(){
    CourseId=$1
    cfile="./selcourse"
    usr_file="./usr"
    while true
    do
        echo -e "\n"
        echo -e "\033[40;93m������ѧ��ѧ�ţ�����'!'ȡ����\033[0m"
        #����ѧ��ѧ��
        myRead
        StudentId=$Buffer
        #ѧ��ѧ��Ϊ'!'�򷵻�
        if [ $StudentId = '!' ]
        then
            return 0
        fi
        flag=0
        #��ѯѧ���˻���Ϣ
        while read ac pw au nm
        do
            #ѧ�ŷ��ϣ����������Ϣ
            if [ $ac = $StudentId ] && [ $au -eq 3 ]
            then
                flag=1
                echo -e "\033[40;93mѧ�ţ�$ac ������$nm\033[0m"
                break
            fi
        done <${usr_file}
        #�˻������ڣ�����
        if [ $flag -eq 0 ]
        then
            echo -e "\033[40;93m��ѯʧ�ܣ��û������ڣ�\033[0m"
            continue
        fi
        #��ѯ��¼�Ƿ����
        itemcnt=$(cat $cfile | grep "^$CourseId\ $StudentId$" | wc -l)
        #����Ϣ����˵����ѡ�Σ���֮δѡ��
        if [ $itemcnt -eq 0 ]
        then
            echo -e "\033[40;93m��ѧ��δѡ�Σ�\033[0m"
        else
            echo -e "\033[40;93m��ѧ����ѡ�Σ�\033[0m"
        fi
    done
}

#����ѧ���˻�
ManS(){
    CourseId=$1
    while true
    do
        echo -e "\n"
        echo -e "\033[40;93m\t"1')'����ѧ���˻�"\033[0m"
        echo -e "\033[40;93m\t"2')'�޸�ѧ���˻�"\033[0m"
        echo -e "\033[40;93m\t"3')'ɾ��ѧ���˻�"\033[0m"
        echo -e "\033[40;93m\t"4')'����ѧ���˻����γ�"\033[0m"
        echo -e "\033[40;93m\t"5')'��ѧ�Ų�ѯѧ���˻�"\033[0m"
        echo -e "\033[40;93m\t"b')'�����ϼ�"\033[0m"
        echo -e "\033[40;93m\t"q')'�˳�"\033[0m"
        echo -e "\n"
        echo -e "\033[40;93m"��ѡ��"\033[0m"
        read choice
        case $choice in
            1)  CreateStudent $CourseId;;
            2)  ModifyStudent;;
            3)  DeleteStudent $CourseId;;
            4)  ImportStudent $CourseId;;
            5)  QueryStudentById $CourseId;;
            b)  return 0;;
            q)  exit 0;;
            *)  echo -e "\033[40;93m"����Ƿ������������룡"\033[0m";;
        esac
    done
}

#�½��γ���Ϣ
CreateCourseInfo(){
    CourseId=$1
    cfile="./courseinfo"
    #�½��γ���Ϣ�ļ���
    if [ ! -d $cfile ]
    then
        mkdir $cfile
    fi
    itemcnt=1
    #�ҵ�һ�����ʵı��
    while true
    do
        cfile="./courseinfo/course_${CourseId}_$itemcnt"
        if [ ! -f $cfile ]
        then
            echo -e "\033[40;93m"�������Ϣ������һ��һ���ַ�\'\!\'������"\033[0m"
            #������Ϣ����
            while true
            do
                read tmp
                if [[ $tmp = '!' ]]
                then 
                    break
                fi
                #��������д���ļ�
                echo $tmp >> $cfile
            done
            echo -e "\033[40;93m"�½��ɹ�����ǰ��Ϣ���Ϊ$itemcnt��"\033[0m"
            break
        fi
        ((itemcnt++))
    done
}

#�༭�γ���Ϣ
EditCourseInfo(){
    CourseId=$1
    while true
    do
        echo -e "\n"
        echo -e "\033[40;93m������γ���Ϣ��ţ�����'!'ȡ����\033[0m"
        #������Ϣ���
        myRead
        CourseInfoId=$Buffer
        #��Ϣ���Ϊ'!'�򷵻�
        if [ $CourseInfoId = '!' ]
        then
            return 0
        fi
        cfile="./courseinfo/course_${CourseId}_$CourseInfoId"
        #����Ϣ�ļ���������Ա༭�����򱨴�
        if [ -f $cfile ]
        then
            vi $cfile
            echo -e "\033[40;93m"�༭�ɹ���"\033[0m"
        else
            echo -e "\033[40;93m"�༭ʧ�ܣ���Ϣ�����ڣ�"\033[0m"
        fi
    done
}

#ɾ���γ���Ϣ
DeleteCourseInfo(){
    CourseId=$1
    while true
    do
        echo -e "\n"
        echo -e "\033[40;93m������γ���Ϣ��ţ�����'!'ȡ����\033[0m"
        #������Ϣ���
        myRead
        CourseInfoId=$Buffer
        #��Ϣ���Ϊ'!'�򷵻�
        if [ $CourseInfoId = '!' ]
        then
            return 0
        fi
        cfile="./courseinfo/course_${CourseId}_$CourseInfoId"
        #�ж���Ϣ�ļ��Ƿ���ڣ�������ɾ�������򱨴�
        if [ -f $cfile ]
        then
            rm $cfile
            echo -e "\033[40;93m"ɾ���ɹ���"\033[0m"
        else
            echo -e "\033[40;93m"ɾ��ʧ�ܣ���Ϣ�����ڣ�"\033[0m"
        fi
    done
}

#��ʾ�γ���Ϣ
ListCourseInfo(){
    CourseId=$1
    cfile="./courseinfo"
    #�ļ��в����ڣ�ֱ�ӷ���
    if [ ! -d $cfile ]
    then
        echo -e "\033[40;93m"��ѯʧ�ܣ��޿γ���Ϣ��"\033[0m"
        return 0
    fi
    #ͳ���ж�������Ӧ�γ̺ŵ���Ϣ
    itemcnt=0
    #ɨ���ļ��������ж�Ӧ�γ̺ŵ���Ϣ�ļ�
    for cinfo in $(ls $cfile)
    do
        if [[ $cinfo =~ ^course\_${CourseId}\_  ]]
        then
            ((itemcnt++))
            #����ļ�����
            echo -e "\033[40;93m"${cinfo#course\_${CourseId}\_}\: ; cat "./courseinfo/$cinfo"; echo -e "\033[0m"
        fi
    done
    #���޿γ���Ϣ�������ʾ
    if [ $itemcnt -eq 0 ]
    then
        echo -e "\033[40;93m"��ѯʧ�ܣ��޿γ���Ϣ��"\033[0m"
    fi
}

#����γ���Ϣ
ManCInfo(){
    CourseId=$1
    while true
    do
        echo -e "\n"
        echo -e "\033[40;93m\t"1')'�½��γ���Ϣ"\033[0m"
        echo -e "\033[40;93m\t"2')'�༭�γ���Ϣ"\033[0m"
        echo -e "\033[40;93m\t"3')'ɾ���γ���Ϣ"\033[0m"
        echo -e "\033[40;93m\t"4')'��ʾ�γ���Ϣ"\033[0m"
        echo -e "\033[40;93m\t"b')'�����ϼ�"\033[0m"
        echo -e "\033[40;93m\t"q')'�˳�"\033[0m"
        echo -e "\n"
        echo -e "\033[40;93m"��ѡ��"\033[0m"
        read choice
        case $choice in
            1)  CreateCourseInfo $CourseId;;
            2)  EditCourseInfo $CourseId;;
            3)  DeleteCourseInfo $CourseId;;
            4)  ListCourseInfo $CourseId;;
            b)  return 0;;
            q)  exit 0;;
            *)  echo -e "\033[40;93m"����Ƿ������������룡"\033[0m";;
        esac
    done
}

#�½���ҵʵ��
CreateHW(){
    CourseId=$1
    cfile="./hw"
    #�½���ҵ�ļ���
    if [ ! -d $cfile ]
    then
        mkdir $cfile
    fi
    touch "${cfile}/catalog"
    #������ֹ����
    echo -e "\n"
    echo -e "\033[40;93m��������ʼ���ڣ���ʽΪYYYY-MM-DD������'!'ȡ����\033[0m"
    myReadTime
    StartTime=$Buffer
    #����'!'�򷵻�
    if [ $StartTime = '!' ]
    then
        return 0
    fi
    #�����������
    echo -e "\033[40;93m������������ڣ���ʽΪYYYY-MM-DD������'!'ȡ����\033[0m"
    myReadTime
    EndTime=$Buffer
    #����'!'�򷵻�
    if [ $EndTime = '!' ]
    then
        return 0
    fi
    itemcnt=1
    #�ҵ�һ�����ʵı��
    while true
    do
        cfile="./hw/course_${CourseId}_$itemcnt"
        #�ļ�������˵���ҵ���
        if [ ! -f $cfile ]
        then
            echo -e "\033[40;93m"�������Ϣ������һ��һ���ַ�\'\!\'������"\033[0m"
            #������ҵ��Ϣ
            while true
            do
                read tmp
                if [[ $tmp = '!' ]]
                then 
                    break
                fi
                #������Ϣд���ļ�
                echo $tmp >> $cfile
            done
            #����ֹʱ��д��catalog
            echo $CourseId $itemcnt $StartTime $EndTime >> $"./hw/catalog"
            echo -e "\033[40;93m"�½��ɹ�����ǰ��ҵ���Ϊ$itemcnt��"\033[0m"
            break
        fi
        ((itemcnt++))
    done
}

#�༭��ҵʵ��
EditHW(){
    CourseId=$1
    while true
    do
        echo -e "\n"
        echo -e "\033[40;93m��������ҵʵ���ţ�����'!'ȡ����\033[0m"
        #������ҵ���
        myRead
        HWId=$Buffer
        #��ҵ���Ϊ'!'�򷵻�
        if [ $HWId = '!' ]
        then
            return 0
        fi
        echo -e "\033[40;93m��������ҵ��ʼʱ�䣨��ʽΪYYYY-MM-DD������'!'ȡ��������'/'���޸Ĵ��\033[0m"
        #������ˣ���Ҫ����'/'�����������жϣ������Ҫ����������ͬ
        myReadTime 0
        StartTime=$Buffer
        #��ʼʱ��Ϊ'!'�򷵻�
        if [ $StartTime = '!' ]
        then
            return 0
        fi
        echo -e "\033[40;93m��������ҵ����ʱ�䣨��ʽΪYYYY-MM-DD������'!'ȡ��������'/'���޸Ĵ��\033[0m"
        myReadTime 0
        EndTime=$Buffer
        #��ʼʱ��Ϊ'!'�򷵻�
        if [ $EndTime = '!' ]
        then
            return 0
        fi
        cfile="./hw/course_${CourseId}_$HWId"
        #����Ϣ�ļ���������Ա༭�����򱨴�
        if [ -f $cfile ]
        then
            vi $cfile
            while read cid aid st ed
            do
                #��catalog�ļ��в�ѯ����ҵԭ������ֹʱ��
                if [[ $cid = $CourseId ]] && [[ $aid = $HWId ]]
                then
                    if [[ $StartTime = '/' ]]
                    then
                        StartTime=$st
                    fi
                    if [[ $EndTime = '/' ]]
                    then
                        EndTime=$ed
                    fi
                    break
                fi
            done <"./hw/catalog"
            #�Ӿ��ļ���ɾ�������Ϣ���ٽ����º����Ϣд���ļ�ĩβ
            cat "./hw/catalog" | grep -v "^$CourseId\ $HWId" >> "./hw/catalogTmp"
            mv "./hw/catalogTmp" "./hw/catalog"
            echo $CourseId $HWId $StartTime $EndTime >> "./hw/catalog"
            echo -e "\033[40;93m"�༭�ɹ���"\033[0m"
        else
            echo -e "\033[40;93m"�༭ʧ�ܣ���Ϣ�����ڣ�"\033[0m"
        fi
    done
}

#ɾ����ҵʵ��
DeleteHW(){
    CourseId=$1
    while true
    do
        echo -e "\n"
        echo -e "\033[40;93m��������ҵʵ���ţ�����'!'ȡ����\033[0m"
        #������ҵ���
        myRead
        HWId=$Buffer
        #��ҵ���Ϊ'!'�򷵻�
        if [[ $HWId = '!' ]]
        then
            return 0
        fi
        
        cfile="./hw/course_${CourseId}_$HWId"
        #����Ϣ�ļ�������ɾ�������򱨴�
        if [ -f $cfile ]
        then
            #ɾ����ҵ�ļ�
            rm $cfile
            #��catalog��ɾ�������Ϣ
            cat "./hw/catalog" | grep -v "${CourseId}\ $HWId" >> "./hw/catalogTmp"
            mv "./hw/catalogTmp" "./hw/catalog"
            #��Ҫ��submit��ɾ�������ύ��Ϣ
            #���submit�ļ��в����ڵĻ�Ҫ�ȴ���
            if [ ! -d "./submit" ]
            then
                mkdir "./submit"
            fi
            #�ٴ�submit�ļ�����������Ӧ���ļ�
            find "./submit" -type f -name "${CourseId}_${HWId}" | xargs rm 2>/dev/null
            echo -e "\033[40;93m"ɾ���ɹ���"\033[0m"
        else
            echo -e "\033[40;93m"ɾ��ʧ�ܣ���ҵ�����ڣ�"\033[0m"
        fi
    done
}

#��ʾ��ҵʵ��
ListHW(){
    CourseId=$1
    cfile="./hw/catalog"
    while read cid aid st ed
    do
        #�γ̺Ų�������ֱ������
        if [ $cid != $CourseId ]
        then
            continue
        fi
        echo -e "\033[40;93m"��ҵ��ţ�$aid ��ʼ���ڣ�$st �������ڣ�$ed"\033[0m"
        echo -e "\033[40;93m"; cat "./hw/course_${cid}_${aid}"; echo -e "\033[0m"
        echo
    done <$cfile
}

#��ѯѧ����ҵ������
QueryStudentHW(){
    CourseId=$1
    while true
    do
        echo -e "\n"
        echo -e "\033[40;93m��������ҵʵ���ţ�����'!'ȡ����\033[0m"
        #������ҵ���
        myRead
        HWId=$Buffer
        #��ҵ���Ϊ'!'�򷵻�
        if [ $HWId = '!' ]
        then
            return 0
        fi
        echo -e "\033[40;93m������ѧ��ѧ�ţ�����'!'ȡ����\033[0m"
        #����ѧ��
        myRead
        Sid=$Buffer
        #ѧ��Ϊ'!'�򷵻�
        if [ $Sid = '!' ]
        then
            return 0
        fi

        cfile="./submit/hw_${CourseId}_${HWId}_$Sid"
        #����Ϣ�ļ���������ʾ
        if [ -f $cfile ]
        then
            echo -e "\033[40;93m"; cat $cfile ; echo -e "\033[0m"
        else
            echo -e "\033[40;93m"����ʧ�ܣ���ҵ�����ڻ�ѧ��δ�ݽ���"\033[0m"
        fi
    done
}

#��ӡѧ����ҵ������
ListStudentHW(){
    CourseId=$1
    while true
    do
        echo -e "\n"
        echo -e "\033[40;93m��������ҵʵ���ţ�����'!'ȡ����\033[0m"
        #������ҵ���
        myRead
        HWId=$Buffer
        #��ҵ���Ϊ'!'�򷵻�
        if [ $HWId = '!' ]
        then
            return 0
        fi
        #�������ҵ����
        itemcnt=0
        #ѡ������
        itemcnt2=0
        while read cid sid
        do
            if [ $cid = $CourseId ]
            then
                ((itemcnttwo++))
                tmp=`find "./submit" -name "hw_${CourseId}_${HWId}_$sid" | wc -l`
                if [ $tmp -ne 0 ]
                then
                    ((itemcnt++))
                    echo -e "\033[40;93mѧ�ţ�$sid ״̬�����ύ\033[0m"
                else
                    echo -e "\033[40;93mѧ�ţ�$sid ״̬��δ�ύ\033[0m"
                fi
            fi
        done <"./selcourse"
        echo -e "\033[40;93m����$itemcnttwo��ѧ��ѡ�Σ����������ҵ$itemcnt�ˣ�\033[0m"
    done
}

#������ҵʵ��
ManA(){
    CourseId=$1
    while true
    do
        echo -e "\n"
        echo -e "\033[40;93m\t"1')'�½���ҵʵ��"\033[0m"
        echo -e "\033[40;93m\t"2')'�༭��ҵʵ��"\033[0m"
        echo -e "\033[40;93m\t"3')'ɾ����ҵʵ��"\033[0m"
        echo -e "\033[40;93m\t"4')'��ʾ��ҵʵ��"\033[0m"
        echo -e "\033[40;93m\t"5')'�鿴ѧ����ҵ"\033[0m"
        echo -e "\033[40;93m\t"6')'��ӡѧ��������"\033[0m"
        echo -e "\033[40;93m\t"b')'�����ϼ�"\033[0m"
        echo -e "\033[40;93m\t"q')'�˳�"\033[0m"
        echo -e "\n"
        echo -e "\033[40;93m"��ѡ��"\033[0m"
        read choice
        case $choice in
            1)  CreateHW $CourseId;;
            2)  EditHW $CourseId;;
            3)  DeleteHW $CourseId;;
            4)  ListHW $CourseId;;
            5)  QueryStudentHW $CourseId;;
            6)  ListStudentHW $CourseId;;
            b)  return 0;;
            q)  exit 0;;
            *)  echo -e "\033[40;93m"����Ƿ������������룡"\033[0m";;
        esac
    done
}

#���������γ�
ManC(){
    CourseId=$1
    while true
    do
        echo -e "\n"
        echo -e "\033[40;93m\t"1')'����ѧ���˻�"\033[0m"
        echo -e "\033[40;93m\t"2')'����γ���Ϣ"\033[0m"
        echo -e "\033[40;93m\t"3')'������ҵ��ʵ��"\033[0m"
        echo -e "\033[40;93m\t"b')'�����ϼ�"\033[0m"
        echo -e "\033[40;93m\t"q')'�˳�"\033[0m"
        echo -e "\n"
        echo -e "\033[40;93m"��ѡ��"\033[0m"
        read choice
        case $choice in
            1)  ManS $CourseId;;
            2)  ManCInfo $CourseId;;
            3)  ManA $CourseId;;
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
    cfile="./givecourse"
    #��������
    itemcnt=0
    #���ογ̺��������б�
    courselist=()
    namelist=()
    while read cid tid
    do
        if [ $account = $tid ]
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
        echo -e "\033[40;93m"�����޿��Σ�����ϵ����Ա��ӣ�"\033[0m"
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
                ManC ${courselist[$choice]}
            else 
                echo -e "\033[40;93m"����Ƿ������������룡"\033[0m"
            fi
        done 
    fi
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
echo -e "\n\n \t  \033[40;93m=====��ǰ��¼�˺ţ�$account  ��ǰȨ�ޣ���ʦ=====\033[0m"

while true
do
    echo -e "\n"
    echo -e "\033[40;93m\t"1')'���������γ�"\033[0m"
    echo -e "\033[40;93m\t"2')'�޸��û�����"\033[0m"
    echo -e "\033[40;93m\t"q')'�˳�"\033[0m"
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