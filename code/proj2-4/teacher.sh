#!/bin/bash
###############################
#程序名：teacher.sh （对应实验2第4题）
#作者：黄彦玮
#学号：3180102067
#说明：图书管理系统-教师部分
#完成时间：2020-07-31
###############################

#参数数量不等于2，异常错误
if [ $# -ne 2 ]
then
    exit 1
fi

account=$1
name=$2
typeset -i itemcnt=0
typeset -i itemcnttwo=0

#自定义读入，忽略回车，遇到输入的当行有字符即返回
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
            echo -e "\033[40;93m输入含非法字符，请重新输入！\033[0m"
        fi
    done
}

#日期格式检查
DateCheck(){
    #利用date命令判断日期是否合法
    if echo $1 | grep -Eq "[0-9]{4}-[0-9]{2}-[0-9]{2}" && date -d $1 +%Y%m%d > /dev/null 2>&1
    then 
        return 1
    else
        return 0
    fi
}

#读入时间
myReadTime(){
    #参数表示是否需要过滤'/'（用于编辑作业）
    tmp=$#
    while true
    do
        read Buffer
        #调用函数判断读入日期是否合法
        DateCheck $Buffer
        #日期是否合法
        isTimeOK=$?
        #无特殊过滤要求
        if [ $tmp -eq 0 ]
        then
            if [ $isTimeOK -ne 1 ] && [ $Buffer != '!' ] 
            then
                echo -e "\033[40;93m格式错误，请重新输入！\033[0m"
            else
                break
            fi
        else
            if [ $isTimeOK -ne 1 ] && [ $Buffer != '!' ] && [ $Buffer != '/' ]
            then
                echo -e "\033[40;93m格式错误，请重新输入！\033[0m"
            else
                break
            fi
        fi
    done
}

#新建/导入一名学生的账户（在新建账户和导入账户的函数中调用）
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
    #判断学生账户是否存在
    while read ac pw au nm
    do
        #账号已存在
        if [ $ac = $StudentId ]
        then
            flag=1
            #判断其他信息是否一致，若不一致则报错
            if [ $pw != $StudentPwd ] || [ $au -ne 3 ] || [ $nm != $StudentName ]
            then
                echo -e "\033[40;93m添加失败，账号信息与已有数据不符，请联系学生核对！\033[0m"
                return 0
            fi
            break
        fi
    done <${usr_file}
    #账号不存在，则需要先新建账号
    if [ $flag -eq 0 ]
    then
        echo $StudentId $StudentPwd 3 $StudentName >>${usr_file}
    fi
    #查询选课信息是否已经存在
    itemcnt=$(cat $cfile | grep "^$CourseId\ $StudentId$" | wc -l)
    #选课信息已经存在，报错
    if [ $itemcnt -ne 0 ]
    then
        echo -e "\033[40;93m添加失败，选课信息已存在！\033[0m"
        return 0
    fi
    #添加选课信息
    echo $CourseId $StudentId >> $cfile
    echo -e "\033[40;93m添加成功！\033[0m"
    return 1
}


#新建学生账户
CreateStudent(){
    CourseId=$1
    cfile="./selcourse"
    usr_file="./usr"
    while true
    do
        echo -e "\n"
        echo -e "\033[40;93m请输入学生学号（输入'!'取消）\033[0m"
        #读入学生学号
        myRead
        StudentId=$Buffer
        #学生学号为'!'则返回
        if [ $StudentId = '!' ]
        then
            return 0
        fi
        echo -e "\033[40;93m请输入学生姓名（输入'!'取消）\033[0m"
        #读入学生姓名
        myRead
        StudentName=$Buffer
        #学生姓名为'!'则返回
        if [ $StudentName = '!' ]
        then
            return 0
        fi
        echo -e "\033[40;93m请输入学生密码（输入'!'取消）\033[0m"
        #读入学生密码
        myRead
        StudentPwd=$Buffer
        #学生密码为'!'则返回
        if [ $StudentPwd = '!' ]
        then
            return 0
        fi
        #调用函数插入账户
        CreateOneStudent $StudentId $StudentPwd $StudentName $CourseId
    done
}

#修改学生账户
ModifyStudent(){
    usr_file="./usr"
    while true
    do
        echo -e "\n"
        echo -e "\033[40;93m请输入学生学号（输入'!'取消）\033[0m"
        #读入学生学号
        myRead
        StudentId=$Buffer
        #学生学号为'!'则返回
        if [ $StudentId = '!' ]
        then
            return 0
        fi
        echo -e "\033[40;93m请输入学生姓名（输入'!'取消，输入'/'不修改此项）\033[0m"
        #读入学生姓名
        myRead
        StudentName=$Buffer
        #学生姓名为'!'则返回
        if [ $StudentName = '!' ]
        then
            return 0
        fi
        echo -e "\033[40;93m请输入学生密码（输入'!'取消，输入'/'不修改此项）\033[0m"
        #读入学生密码
        myRead
        StudentPwd=$Buffer
        #学生密码为'!'则返回
        if [ $StudentPwd = '!' ]
        then
            return 0
        fi
        flag=0
        #判断学生账户是否存在
        while read ac pw au nm
        do
            #账号已存在
            if [ $ac = $StudentId ]
            then
                flag=1
                #特判不修改的情况
                if [ $StudentPwd != '/' ]
                then
                    pw=$StudentPwd
                fi
                if [ $StudentName != '/' ]
                then
                    nm=$StudentName
                fi
                #先删除旧信息，再添加新信息
                cat ${usr_file} | grep -v "^$ac" >> "${usr_file}Tmp"
                mv "${usr_file}Tmp" "${usr_file}" 
                echo $ac $pw $au $nm >> ${usr_file}
                echo -e "\033[40;93m修改成功！\033[0m"
                break
            fi
        done <${usr_file}
        #账号不存在，修改失败
        if [ $flag -eq 0 ]
        then
            echo -e "\033[40;93m修改失败，用户不存在！\033[0m"
        fi
    done
}

#删除学生账户
DeleteStudent(){
    CourseId=$1
    cfile="./selcourse"
    while true
    do
        echo -e "\n"
        echo -e "\033[40;93m请输入学生学号（输入'!'取消）\033[0m"
        #读入学生学号
        myRead
        StudentId=$Buffer
        #学生学号为'!'则返回
        if [ $StudentId = '!' ]
        then
            return 0
        fi
        #查询记录是否存在
        itemcnt=$(cat $cfile | grep "^$CourseId\ $StudentId$" | wc -l)
        #若不存在报错，若存在则删除
        if [ $itemcnt -eq 0 ]
        then
            echo -e "\033[40;93m删除失败，记录不存在！\033[0m"
        else
            cat $cfile | grep -v "^$CourseId\ $StudentId$" >> "${cfile}Tmp"
            mv "${cfile}Tmp" "${cfile}"
            echo -e "\033[40;93m删除成功！\033[0m"
        fi
    done
}

#导入学生账户
ImportStudent(){
    CourseId=$1
    cfile="./selcourse"
    while true
    do
        echo -e "\n"
        echo -e "\033[40;93m请输入要导入的文件路径（输入'!'取消）\033[0m"
        #读入文件路径
        myRead
        FilePath=$Buffer
        #文件路径为'!'则返回
        if [ $FilePath = '!' ]
        then
            return 0
        fi
        #文件不存在则报错
        if [ ! -f $FilePath ]
        then
            echo -e "\033[40;93m导入失败，文件不存在！\033[0m"
        fi
        #插入成功的记录数
        tmp=0
        #读取文件内容并尝试插入
        while read ac pw nm
        do
            echo -e "\033[40;93m正在尝试导入：$ac $nm\033[0m"
            #调用函数插入
            CreateOneStudent $ac $pw $nm $CourseId
            #插入成功，则加入统计信息
            if [ $? -eq 1 ]
            then
                ((tmp++))
            fi
        done <$FilePath
        echo -e "\033[40;93m导入完成，共成功导入 $tmp 条记录！\033[0m"
    done
}

#按学号查询学生账户
QueryStudentById(){
    CourseId=$1
    cfile="./selcourse"
    usr_file="./usr"
    while true
    do
        echo -e "\n"
        echo -e "\033[40;93m请输入学生学号（输入'!'取消）\033[0m"
        #读入学生学号
        myRead
        StudentId=$Buffer
        #学生学号为'!'则返回
        if [ $StudentId = '!' ]
        then
            return 0
        fi
        flag=0
        #查询学生账户信息
        while read ac pw au nm
        do
            #学号符合，输出姓名信息
            if [ $ac = $StudentId ] && [ $au -eq 3 ]
            then
                flag=1
                echo -e "\033[40;93m学号：$ac 姓名：$nm\033[0m"
                break
            fi
        done <${usr_file}
        #账户不存在，报错
        if [ $flag -eq 0 ]
        then
            echo -e "\033[40;93m查询失败，用户不存在！\033[0m"
            continue
        fi
        #查询记录是否存在
        itemcnt=$(cat $cfile | grep "^$CourseId\ $StudentId$" | wc -l)
        #若信息存在说明已选课，反之未选课
        if [ $itemcnt -eq 0 ]
        then
            echo -e "\033[40;93m该学生未选课！\033[0m"
        else
            echo -e "\033[40;93m该学生已选课！\033[0m"
        fi
    done
}

#管理学生账户
ManS(){
    CourseId=$1
    while true
    do
        echo -e "\n"
        echo -e "\033[40;93m\t"1')'创建学生账户"\033[0m"
        echo -e "\033[40;93m\t"2')'修改学生账户"\033[0m"
        echo -e "\033[40;93m\t"3')'删除学生账户"\033[0m"
        echo -e "\033[40;93m\t"4')'导入学生账户到课程"\033[0m"
        echo -e "\033[40;93m\t"5')'按学号查询学生账户"\033[0m"
        echo -e "\033[40;93m\t"b')'返回上级"\033[0m"
        echo -e "\033[40;93m\t"q')'退出"\033[0m"
        echo -e "\n"
        echo -e "\033[40;93m"请选择："\033[0m"
        read choice
        case $choice in
            1)  CreateStudent $CourseId;;
            2)  ModifyStudent;;
            3)  DeleteStudent $CourseId;;
            4)  ImportStudent $CourseId;;
            5)  QueryStudentById $CourseId;;
            b)  return 0;;
            q)  exit 0;;
            *)  echo -e "\033[40;93m"输入非法，请重新输入！"\033[0m";;
        esac
    done
}

#新建课程信息
CreateCourseInfo(){
    CourseId=$1
    cfile="./courseinfo"
    #新建课程信息文件夹
    if [ ! -d $cfile ]
    then
        mkdir $cfile
    fi
    itemcnt=1
    #找到一个合适的编号
    while true
    do
        cfile="./courseinfo/course_${CourseId}_$itemcnt"
        if [ ! -f $cfile ]
        then
            echo -e "\033[40;93m"请键入信息，输入一行一个字符\'\!\'结束！"\033[0m"
            #读入信息内容
            while true
            do
                read tmp
                if [[ $tmp = '!' ]]
                then 
                    break
                fi
                #将新内容写入文件
                echo $tmp >> $cfile
            done
            echo -e "\033[40;93m"新建成功，当前信息编号为$itemcnt！"\033[0m"
            break
        fi
        ((itemcnt++))
    done
}

#编辑课程信息
EditCourseInfo(){
    CourseId=$1
    while true
    do
        echo -e "\n"
        echo -e "\033[40;93m请输入课程信息编号（输入'!'取消）\033[0m"
        #读入信息编号
        myRead
        CourseInfoId=$Buffer
        #信息编号为'!'则返回
        if [ $CourseInfoId = '!' ]
        then
            return 0
        fi
        cfile="./courseinfo/course_${CourseId}_$CourseInfoId"
        #若信息文件存在则可以编辑，否则报错
        if [ -f $cfile ]
        then
            vi $cfile
            echo -e "\033[40;93m"编辑成功！"\033[0m"
        else
            echo -e "\033[40;93m"编辑失败，信息不存在！"\033[0m"
        fi
    done
}

#删除课程信息
DeleteCourseInfo(){
    CourseId=$1
    while true
    do
        echo -e "\n"
        echo -e "\033[40;93m请输入课程信息编号（输入'!'取消）\033[0m"
        #读入信息编号
        myRead
        CourseInfoId=$Buffer
        #信息编号为'!'则返回
        if [ $CourseInfoId = '!' ]
        then
            return 0
        fi
        cfile="./courseinfo/course_${CourseId}_$CourseInfoId"
        #判断信息文件是否存在，若是则删除，否则报错
        if [ -f $cfile ]
        then
            rm $cfile
            echo -e "\033[40;93m"删除成功！"\033[0m"
        else
            echo -e "\033[40;93m"删除失败，信息不存在！"\033[0m"
        fi
    done
}

#显示课程信息
ListCourseInfo(){
    CourseId=$1
    cfile="./courseinfo"
    #文件夹不存在，直接返回
    if [ ! -d $cfile ]
    then
        echo -e "\033[40;93m"查询失败，无课程信息！"\033[0m"
        return 0
    fi
    #统计有多少条对应课程号的信息
    itemcnt=0
    #扫描文件夹下所有对应课程号的信息文件
    for cinfo in $(ls $cfile)
    do
        if [[ $cinfo =~ ^course\_${CourseId}\_  ]]
        then
            ((itemcnt++))
            #输出文件内容
            echo -e "\033[40;93m"${cinfo#course\_${CourseId}\_}\: ; cat "./courseinfo/$cinfo"; echo -e "\033[0m"
        fi
    done
    #若无课程信息，输出提示
    if [ $itemcnt -eq 0 ]
    then
        echo -e "\033[40;93m"查询失败，无课程信息！"\033[0m"
    fi
}

#管理课程信息
ManCInfo(){
    CourseId=$1
    while true
    do
        echo -e "\n"
        echo -e "\033[40;93m\t"1')'新建课程信息"\033[0m"
        echo -e "\033[40;93m\t"2')'编辑课程信息"\033[0m"
        echo -e "\033[40;93m\t"3')'删除课程信息"\033[0m"
        echo -e "\033[40;93m\t"4')'显示课程信息"\033[0m"
        echo -e "\033[40;93m\t"b')'返回上级"\033[0m"
        echo -e "\033[40;93m\t"q')'退出"\033[0m"
        echo -e "\n"
        echo -e "\033[40;93m"请选择："\033[0m"
        read choice
        case $choice in
            1)  CreateCourseInfo $CourseId;;
            2)  EditCourseInfo $CourseId;;
            3)  DeleteCourseInfo $CourseId;;
            4)  ListCourseInfo $CourseId;;
            b)  return 0;;
            q)  exit 0;;
            *)  echo -e "\033[40;93m"输入非法，请重新输入！"\033[0m";;
        esac
    done
}

#新建作业实验
CreateHW(){
    CourseId=$1
    cfile="./hw"
    #新建作业文件夹
    if [ ! -d $cfile ]
    then
        mkdir $cfile
    fi
    touch "${cfile}/catalog"
    #输入起止日期
    echo -e "\n"
    echo -e "\033[40;93m请输入起始日期（格式为YYYY-MM-DD，输入'!'取消）\033[0m"
    myReadTime
    StartTime=$Buffer
    #日期'!'则返回
    if [ $StartTime = '!' ]
    then
        return 0
    fi
    #输入结束日期
    echo -e "\033[40;93m请输入结束日期（格式为YYYY-MM-DD，输入'!'取消）\033[0m"
    myReadTime
    EndTime=$Buffer
    #日期'!'则返回
    if [ $EndTime = '!' ]
    then
        return 0
    fi
    itemcnt=1
    #找到一个合适的编号
    while true
    do
        cfile="./hw/course_${CourseId}_$itemcnt"
        #文件不存在说明找到了
        if [ ! -f $cfile ]
        then
            echo -e "\033[40;93m"请键入信息，输入一行一个字符\'\!\'结束！"\033[0m"
            #读入作业信息
            while true
            do
                read tmp
                if [[ $tmp = '!' ]]
                then 
                    break
                fi
                #将新信息写入文件
                echo $tmp >> $cfile
            done
            #将起止时间写入catalog
            echo $CourseId $itemcnt $StartTime $EndTime >> $"./hw/catalog"
            echo -e "\033[40;93m"新建成功，当前作业编号为$itemcnt！"\033[0m"
            break
        fi
        ((itemcnt++))
    done
}

#编辑作业实验
EditHW(){
    CourseId=$1
    while true
    do
        echo -e "\n"
        echo -e "\033[40;93m请输入作业实验编号（输入'!'取消）\033[0m"
        #读入作业编号
        myRead
        HWId=$Buffer
        #作业编号为'!'则返回
        if [ $HWId = '!' ]
        then
            return 0
        fi
        echo -e "\033[40;93m请输入作业起始时间（格式为YYYY-MM-DD，输入'!'取消，输入'/'不修改此项）\033[0m"
        #特殊过滤，需要过滤'/'号用于特殊判断，因此需要带参数，下同
        myReadTime 0
        StartTime=$Buffer
        #起始时间为'!'则返回
        if [ $StartTime = '!' ]
        then
            return 0
        fi
        echo -e "\033[40;93m请输入作业结束时间（格式为YYYY-MM-DD，输入'!'取消，输入'/'不修改此项）\033[0m"
        myReadTime 0
        EndTime=$Buffer
        #起始时间为'!'则返回
        if [ $EndTime = '!' ]
        then
            return 0
        fi
        cfile="./hw/course_${CourseId}_$HWId"
        #若信息文件存在则可以编辑，否则报错
        if [ -f $cfile ]
        then
            vi $cfile
            while read cid aid st ed
            do
                #从catalog文件中查询到作业原来的起止时间
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
            #从旧文件中删除相关信息，再将更新后的信息写到文件末尾
            cat "./hw/catalog" | grep -v "^$CourseId\ $HWId" >> "./hw/catalogTmp"
            mv "./hw/catalogTmp" "./hw/catalog"
            echo $CourseId $HWId $StartTime $EndTime >> "./hw/catalog"
            echo -e "\033[40;93m"编辑成功！"\033[0m"
        else
            echo -e "\033[40;93m"编辑失败，信息不存在！"\033[0m"
        fi
    done
}

#删除作业实验
DeleteHW(){
    CourseId=$1
    while true
    do
        echo -e "\n"
        echo -e "\033[40;93m请输入作业实验编号（输入'!'取消）\033[0m"
        #读入作业编号
        myRead
        HWId=$Buffer
        #作业编号为'!'则返回
        if [[ $HWId = '!' ]]
        then
            return 0
        fi
        
        cfile="./hw/course_${CourseId}_$HWId"
        #若信息文件存在则删除，否则报错
        if [ -f $cfile ]
        then
            #删除作业文件
            rm $cfile
            #从catalog中删除相关信息
            cat "./hw/catalog" | grep -v "${CourseId}\ $HWId" >> "./hw/catalogTmp"
            mv "./hw/catalogTmp" "./hw/catalog"
            #还要从submit里删除所有提交信息
            #如果submit文件夹不存在的话要先创建
            if [ ! -d "./submit" ]
            then
                mkdir "./submit"
            fi
            #再从submit文件夹中搜索对应的文件
            find "./submit" -type f -name "${CourseId}_${HWId}" | xargs rm 2>/dev/null
            echo -e "\033[40;93m"删除成功！"\033[0m"
        else
            echo -e "\033[40;93m"删除失败，作业不存在！"\033[0m"
        fi
    done
}

#显示作业实验
ListHW(){
    CourseId=$1
    cfile="./hw/catalog"
    while read cid aid st ed
    do
        #课程号不符合则直接跳过
        if [ $cid != $CourseId ]
        then
            continue
        fi
        echo -e "\033[40;93m"作业编号：$aid 起始日期：$st 结束日期：$ed"\033[0m"
        echo -e "\033[40;93m"; cat "./hw/course_${cid}_${aid}"; echo -e "\033[0m"
        echo
    done <$cfile
}

#查询学生作业完成情况
QueryStudentHW(){
    CourseId=$1
    while true
    do
        echo -e "\n"
        echo -e "\033[40;93m请输入作业实验编号（输入'!'取消）\033[0m"
        #读入作业编号
        myRead
        HWId=$Buffer
        #作业编号为'!'则返回
        if [ $HWId = '!' ]
        then
            return 0
        fi
        echo -e "\033[40;93m请输入学生学号（输入'!'取消）\033[0m"
        #读入学号
        myRead
        Sid=$Buffer
        #学号为'!'则返回
        if [ $Sid = '!' ]
        then
            return 0
        fi

        cfile="./submit/hw_${CourseId}_${HWId}_$Sid"
        #若信息文件存在则显示
        if [ -f $cfile ]
        then
            echo -e "\033[40;93m"; cat $cfile ; echo -e "\033[0m"
        else
            echo -e "\033[40;93m"查找失败，作业不存在或学生未递交！"\033[0m"
        fi
    done
}

#打印学生作业完成情况
ListStudentHW(){
    CourseId=$1
    while true
    do
        echo -e "\n"
        echo -e "\033[40;93m请输入作业实验编号（输入'!'取消）\033[0m"
        #读入作业编号
        myRead
        HWId=$Buffer
        #作业编号为'!'则返回
        if [ $HWId = '!' ]
        then
            return 0
        fi
        #已完成作业人数
        itemcnt=0
        #选课人数
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
                    echo -e "\033[40;93m学号：$sid 状态：已提交\033[0m"
                else
                    echo -e "\033[40;93m学号：$sid 状态：未提交\033[0m"
                fi
            fi
        done <"./selcourse"
        echo -e "\033[40;93m共有$itemcnttwo名学生选课，其中完成作业$itemcnt人！\033[0m"
    done
}

#管理作业实验
ManA(){
    CourseId=$1
    while true
    do
        echo -e "\n"
        echo -e "\033[40;93m\t"1')'新建作业实验"\033[0m"
        echo -e "\033[40;93m\t"2')'编辑作业实验"\033[0m"
        echo -e "\033[40;93m\t"3')'删除作业实验"\033[0m"
        echo -e "\033[40;93m\t"4')'显示作业实验"\033[0m"
        echo -e "\033[40;93m\t"5')'查看学生作业"\033[0m"
        echo -e "\033[40;93m\t"6')'打印学生完成情况"\033[0m"
        echo -e "\033[40;93m\t"b')'返回上级"\033[0m"
        echo -e "\033[40;93m\t"q')'退出"\033[0m"
        echo -e "\n"
        echo -e "\033[40;93m"请选择："\033[0m"
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
            *)  echo -e "\033[40;93m"输入非法，请重新输入！"\033[0m";;
        esac
    done
}

#管理所开课程
ManC(){
    CourseId=$1
    while true
    do
        echo -e "\n"
        echo -e "\033[40;93m\t"1')'管理学生账户"\033[0m"
        echo -e "\033[40;93m\t"2')'管理课程信息"\033[0m"
        echo -e "\033[40;93m\t"3')'布置作业或实验"\033[0m"
        echo -e "\033[40;93m\t"b')'返回上级"\033[0m"
        echo -e "\033[40;93m\t"q')'退出"\033[0m"
        echo -e "\n"
        echo -e "\033[40;93m"请选择："\033[0m"
        read choice
        case $choice in
            1)  ManS $CourseId;;
            2)  ManCInfo $CourseId;;
            3)  ManA $CourseId;;
            b)  return 0;;
            q)  exit 0;;
            *)  echo -e "\033[40;93m"输入非法，请重新输入！"\033[0m";;
        esac
    done
}

#按课程号查询课程
QueryCourseById(){
    CourseId=$1
    cfile="./course"
    touch $cfile
    Buffer=""
    #扫描课程信息的文件
    while read cid nm
    do
        #课程存在，输出记录
        if [[ $cid =~ $CourseId ]]
        then
            Buffer=$nm
            return 0
        fi
    done <${cfile}
}

#选择课程
ChooseCourse(){
    cfile="./givecourse"
    #开课数量
    itemcnt=0
    #开课课程号与名称列表
    courselist=()
    namelist=()
    while read cid tid
    do
        if [ $account = $tid ]
        then
            #获取课程名称
            QueryCourseById $cid
            CourseName=$Buffer
            #将课程号和课程名称存入数组
            courselist[$itemcnt]=$cid
            namelist[$itemcnt]=$Buffer
            ((itemcnt++))
            echo -e "\033[40;93m"$itemcnt')' $cid $CourseName"\033[0m"
        fi
    done <$cfile
    if [ $itemcnt -eq 0 ]
    then
        echo -e "\033[40;93m"您暂无开课，请联系管理员添加！"\033[0m"
        return 0
    else
        echo -e "\033[40;93m"您当前共有$itemcnt门课程，请选择：（输入'!'返回）"\033[0m"
        while true
        do
            read choice
            #选择为'!'则返回
            if [ $choice = '!' ]
            then
                return 0
            fi
            #选择合法，进行课程操作
            if [ "$choice" -gt 0 ] && [ "$choice" -le $itemcnt ] 2>/dev/null ;then 
                ((choice--))
                echo -e "\033[40;93m"当前操作课程：${courselist[$choice]} ${namelist[$choice]}"\033[0m"
                ManC ${courselist[$choice]}
            else 
                echo -e "\033[40;93m"输入非法，请重新输入！"\033[0m"
            fi
        done 
    fi
}

#修改密码
ChangePwd(){
    cfile="./usr"
    touch cfile
    if [ $account = "super" ]
    then
        echo -e "\033[40;93m当前账户不可修改密码！\033[0m" 
        return 0
    fi
    while true
    do
        echo -e "\n"
        echo -e "\033[40;93m请输入旧密码（输入'!'取消）\033[0m"
        read -s oldpwd
        echo
        if [[ $oldpwd = '!' ]]
        then
            return 0
        fi
        echo -e "\033[40;93m请输入新密码（输入'!'取消）\033[0m"
        read -s newpwd
        echo
        if [[ $newpwd = '!' ]]
        then
            return 0
        fi
        #扫描账号信息的文件，对比账号密码
        while read ac pw au nm
        do
            if [[ $ac = $account ]]
            then
                if [[ $pw = $oldpwd ]]
                then
                    pw=$newpwd
                    #从旧文件中删除原信息
                    cat $cfile | grep -v "^$account" > "${cfile}Tmp"
                    mv "${cfile}Tmp" "$cfile"
                    #将新信息附到文件最后
                    echo $ac $pw $au $nm >> "$cfile"
                    echo -e "\033[40;93m修改成功！\033[0m"
                    return 0
                else
                    echo -e "\033[40;93m修改失败，旧密码错误！\033[0m"
                    break
                fi
            fi
        done <${cfile} 
    done
}

clear
echo -e "\n\n \t\t    \033[40;93m =====欢迎您，$name！=====\033[0m"
echo -e "\n\n \t  \033[40;93m=====当前登录账号：$account  当前权限：教师=====\033[0m"

while true
do
    echo -e "\n"
    echo -e "\033[40;93m\t"1')'管理所开课程"\033[0m"
    echo -e "\033[40;93m\t"2')'修改用户密码"\033[0m"
    echo -e "\033[40;93m\t"q')'退出"\033[0m"
    echo -e "\n"
    echo -e "\033[40;93m"请选择："\033[0m"
    read choice
        case $choice in
            1)  ChooseCourse;;
            2)  ChangePwd;;
            q)  exit 0;;
            *)  echo -e "\033[40;93m"输入非法，请重新输入！"\033[0m";;
        esac
done