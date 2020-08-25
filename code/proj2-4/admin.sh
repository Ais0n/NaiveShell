#!/bin/bash
###############################
#程序名：admin.sh （对应实验2第4题）
#作者：黄彦玮
#学号：3180102067
#说明：图书管理系统-管理员部分
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


#新建教师账户
CreateTeacherAccount(){
    usr_file="./usr"
    touch ${usr_file}
    while true
    do
        echo -e "\n"
        echo -e "\033[40;93m请输入教师工号（输入'!'取消）\033[0m"
        #读入教师工号
        myRead
        TeacherId=$Buffer
        #教师工号为'!'则返回
        if [ $TeacherId = '!' ]
        then
            return 0
        fi
        echo -e "\033[40;93m请输入教师姓名（输入'!'取消）\033[0m"
        #读入教师姓名
        myRead
        TeacherName=$Buffer
        #教师姓名为'!'则返回
        if [ $TeacherName = '!' ]
        then
            return 0
        fi
        echo -e "\033[40;93m请输入教师密码（输入'!'取消）\033[0m"
        #读入教师密码
        myRead
        TeacherPwd=$Buffer
        #教师密码为'!'则返回
        if [ $TeacherPwd = '!' ]
        then
            return 0
        fi
        flag=0
        #扫描账号信息的文件，判断账号是否存在
        while read ac pw au nm
        do
            #账号已存在，插入失败
            if [ $ac = $TeacherId ]
            then
                flag=1
                echo -e "\033[40;93m添加失败，账号已存在！\033[0m"
                break
            fi
        done <${usr_file}
        #账号不存在，插入成功
        if [ $flag -eq 0 ]
        then
            echo $TeacherId $TeacherPwd 2 $TeacherName >>${usr_file}
            echo -e "\033[40;93m添加成功！\033[0m"
        fi
    done
}

#修改教师账户
ModifyTeacherAccount(){
    usr_file="./usr"
    touch ${usr_file}
    while true
    do
        echo -e "\n"
        echo -e "\033[40;93m请输入要修改的教师工号（输入'!'取消）\033[0m"
        #读入教师工号
        myRead
        TeacherId=$Buffer
        #教师工号为'!'则返回
        if [ $TeacherId = '!' ]
        then
            return 0
        fi
        echo -e "\033[40;93m请输入教师姓名（输入'!'取消，输入'/'不修改此项）\033[0m"
        #读入教师姓名
        myRead
        TeacherName=$Buffer
        #教师姓名为'!'则返回
        if [ $TeacherName = '!' ]
        then
            return 0
        fi
        echo -e "\033[40;93m请输入教师密码（输入'!'取消，输入'/'不修改此项）\033[0m"
        #读入教师密码
        myRead
        TeacherPwd=$Buffer
        #教师密码为'!'则返回
        if [ $TeacherPwd = '!' ]
        then
            return 0
        fi
        flag=0
        #扫描账号信息的文件，判断账号是否存在
        while read ac pw au nm
        do
            #账号已存在，修改
            if [ $ac = $TeacherId ]
            then
                flag=1
                #权限非教师，删除失败
                if [ $au -ne 2 ]
                then
                    echo -e "\033[40;93m修改失败，操作的用户非教师用户！\033[0m" 
                else
                    #若不为'/'则修改
                    if [ $TeacherPwd != '/' ]
                    then
                        pw=$TeacherPwd
                    fi
                    if [ $TeacherName != '/' ]
                    then
                        nm=$TeacherName
                    fi
                    #先删除工号对应的行
                    cat ${usr_file} | grep -v "^$ac " >> ${usr_file}Tmp
                    mv ${usr_file}Tmp ${usr_file}
                    #再新增一行表示新的账号信息
                    echo $ac $pw $au $nm >>${usr_file}
                    echo -e "\033[40;93m修改成功！\033[0m" 
                fi
                break
            fi
        done <${usr_file}
        #账号不存在，修改失败
        if [ $flag -eq 0 ]
        then
            echo -e "\033[40;93m修改失败，用户信息不存在！\033[0m"
        fi
    done
}

#删除教师账户
DeleteTeacherAccount(){
    usr_file="./usr"
    touch ${usr_file}
    while true
    do
        echo -e "\n"
        echo -e "\033[40;93m请输入要删除的教师工号（输入'!'取消）\033[0m"
        #读入教师工号
        myRead
        TeacherId=$Buffer
        #教师工号为'!'则返回
        if [ $TeacherId = '!' ]
        then
            return 0
        fi
        flag=0
        #扫描账号信息的文件，判断账号是否存在
        while read ac pw au nm
        do
            #账号已存在，删除
            if [ $ac = $TeacherId ]
            then
                flag=1
                if [ $au -ne 2 ]
                then
                    echo -e "\033[40;93m删除失败，操作的用户非教师用户！\033[0m"
                else
                    #删除工号对应的行
                    cat ${usr_file} | grep -v "^$TeacherId " >> ${usr_file}Tmp
                    mv ${usr_file}Tmp ${usr_file}
                    echo -e "\033[40;93m删除成功！\033[0m"
                fi
                break
            fi
        done <${usr_file}
        #账号不存在，删除失败
        if [ $flag -eq 0 ]
        then
            echo -e "\033[40;93m删除失败，用户不存在！\033[0m"
        fi
    done
}

#按账号查询教师
QueryTeacherAccountById(){
    usr_file="./usr"
    touch ${usr_file}
    while true
    do
        echo -e "\n"
        echo -e "\033[40;93m请输入教师工号（输入'!'取消）\033[0m"
        #读入教师工号
        myRead
        TeacherId=$Buffer
        #教师工号为'!'则返回
        if [ $TeacherId = '!' ]
        then
            return 0
        fi
        #满足要求的记录数
        itemcnt=0
        #扫描账号信息的文件，判断账号是否存在
        while read ac pw au nm
        do
            #账号已存在且权限正确，输出相关信息
            if [[ $ac =~ $TeacherId ]] && [ $au -eq 2 ]
            then
                ((itemcnt++))
                echo -e "\033[40;93m工号：$ac  姓名：$nm\033[0m"
            fi
        done <${usr_file}
        #无符号要求信息，查询失败
        if [ $itemcnt -eq 0 ]
        then
            echo -e "\033[40;93m查询失败，无相关用户！\033[0m"
        #查询成功，输出信息总数
        else
            echo -e "\033[40;93m查询成功，共 $itemcnt 条信息！\033[0m"
        fi
    done
}

#按姓名查询教师
QueryTeacherAccountByName(){
    usr_file="./usr"
    touch ${usr_file}
    while true
    do
        echo -e "\n"
        echo -e "\033[40;93m请输入教师姓名（输入'!'取消）\033[0m"
        #读入教师姓名
        myRead
        TeacherName=$Buffer
        #教师工号为'!'则返回
        if [ $TeacherName = '!' ]
        then
            return 0
        fi
        #满足要求的记录数
        itemcnt=0
        #扫描账号信息的文件，判断账号是否存在
        while read ac pw au nm
        do
            #账号已存在且权限正确，输出相关信息
            if [[ $nm =~ $TeacherName ]] && [ $au -eq 2 ]
            then
                ((itemcnt++))
                echo -e "\033[40;93m工号：$ac  姓名：$nm\033[0m"
            fi
        done <${usr_file}
        #无符号要求信息，查询失败
        if [ $itemcnt -eq 0 ]
        then
            echo -e "\033[40;93m查询失败，无相关用户！\033[0m"
        #查询成功，输出信息总数
        else
            echo -e "\033[40;93m查询成功，共 $itemcnt 条信息！\033[0m"
        fi
    done
}

#查询全部教师账户
QueryTeacherAccountALL(){
    usr_file="./usr"
    touch ${usr_file}
    #满足要求的记录数
    itemcnt=0
    #扫描账号信息的文件，判断账号是否存在
    while read ac pw au nm
    do
        #账号已存在且权限正确，输出相关信息
        if [ $au -eq 2 ]
        then
            ((itemcnt++))
            echo -e "\033[40;93m工号：$ac  姓名：$nm\033[0m"
        fi
    done <${usr_file}
    #无符号要求信息，查询失败
    if [ $itemcnt -eq 0 ]
    then
        echo -e "\033[40;93m查询失败，无相关用户！\033[0m"
    #查询成功，输出信息总数
    else
        echo -e "\033[40;93m查询成功，共 $itemcnt 条记录！\033[0m"
        return 0
    fi
    return 0
}

#查询教师账户
QueryTeacherAccount(){
    while true
    do
        echo -e "\n"
        echo -e "\033[40;93m\t"1\)按工号查找"\033[0m"
        echo -e "\033[40;93m\t"2\)按姓名查找"\033[0m"
        echo -e "\033[40;93m\t"3\)查找全部记录"\033[0m"
        echo -e "\033[40;93m\t"b\)返回上级"\033[0m"
        echo -e "\033[40;93m\t"q\)退出"\033[0m"
        echo -e "\n"
        echo -e "\033[40;93m"请选择："\033[0m"
        read choice
            case $choice in
                1)  QueryTeacherAccountById;;
                2)  QueryTeacherAccountByName;;
                3)  QueryTeacherAccountALL;;
                b)  return 0;;
                q)  exit 0;;
                *)  echo -e "\033[40;93m"输入非法，请重新输入！"\033[0m";;
            esac
    done
}

#教师信息管理
ManT(){
    while true
    do
        echo -e "\n"
        echo -e "\033[40;93m\t"1\)创建教师账号"\033[0m"
        echo -e "\033[40;93m\t"2\)修改教师信息"\033[0m"
        echo -e "\033[40;93m\t"3\)删除教师账号"\033[0m"
        echo -e "\033[40;93m\t"4\)查询教师信息"\033[0m"
        echo -e "\033[40;93m\t"b\)返回上级"\033[0m"
        echo -e "\033[40;93m\t"q\)退出"\033[0m"
        echo -e "\n"
        echo -e "\033[40;93m"请选择："\033[0m"
        read choice
        case $choice in
            1)  CreateTeacherAccount;;
            2)  ModifyTeacherAccount;;
            3)  DeleteTeacherAccount;;
            4)  QueryTeacherAccount;;
            b)  return 0;;
            q)  exit 0;;
            *)  echo -e "\033[40;93m"输入非法，请重新输入！"\033[0m";;
        esac
    done
}

#新建课程
CreateCourse(){
    cfile="./course"
    touch $cfile
    while true
    do
        echo -e "\n"
        echo -e "\033[40;93m请输入课程号（输入'!'取消）\033[0m"
        #读入课程号
        myRead
        CourseId=$Buffer
        #教师姓名为'!'则返回
        if [ $CourseId = '!' ]
        then
            return 0
        fi
        echo -e "\033[40;93m请输入课程名称（输入'!'取消）\033[0m"
        #读入课程名称
        myRead
        CourseName=$Buffer
        #课程号名称'!'则返回
        if [ $CourseName = '!' ]
        then
            return 0
        fi
        flag=0
        #扫描课程信息的文件，判断课程是否存在
        while read cid nm
        do
            #课程已存在
            if [ $cid = $CourseId ]
            then
                flag=1
                echo -e "\033[40;93m添加失败，课程号已存在！\033[0m"
                break
            fi
        done <${cfile}
        
        #课程不存在，添加课程
        if [ $flag -eq 0 ] 
        then
            #将新课程添加到数据文件的末尾
            echo $CourseId $CourseName >> $cfile
            echo -e "\033[40;93m添加成功！\033[0m"
        fi
    done
}

#修改课程
ModifyCourse(){
    cfile="./course"
    touch $cfile
    while true
    do
        echo -e "\n"
        echo -e "\033[40;93m请输入课程号（输入'!'取消）\033[0m"
        #读入课程号
        myRead
        CourseId=$Buffer
        #教师姓名为'!'则返回
        if [[ $CourseId = '!' ]]
        then
            return 0
        fi
        echo -e "\033[40;93m请输入课程名称（输入'!'取消，输入'/'不修改此项）\033[0m"
        #读入课程名称
        myRead
        CourseName=$Buffer
        #课程号名称'!'则返回
        if [[ $CourseName = '!' ]]
        then
            return 0
        fi
        flag=0
        #扫描课程信息的文件，判断课程是否存在
        while read cid nm
        do
            #课程存在，进行修改
            if [ $cid = $CourseId ]
            then
                flag=1
                if [[ $CourseName != '/' ]]
                then
                    nm=$CourseName
                fi
                #先删除课程号对应的行
                cat $cfile | grep -v "^$cid " >> ${cfile}Tmp
                mv ${cfile}Tmp ${cfile}
                #再新增一行表示新的账号信息
                echo $cid $nm >>${cfile}
                echo -e "\033[40;93m修改成功！\033[0m" 
                break
            fi
        done <${cfile}
        #课程不存在，修改失败
        if [ $flag -eq 0 ] 
        then
            echo -e "\033[40;93m修改失败，课程不存在！\033[0m"
        fi
    done
}

#删除课程
DeleteCourse(){
    cfile="./course"
    touch $cfile
    while true
    do
        echo -e "\n"
        echo -e "\033[40;93m请输入课程号（输入'!'取消）\033[0m"
        #读入课程号
        myRead
        CourseId=$Buffer
        #课程号为'!'则返回
        if [[ $CourseId = '!' ]]
        then
            return 0
        fi
        flag=0
        #扫描账号信息的文件，判断账号是否存在
        while read cid nm
        do
            #账号已存在，删除
            if [ $cid = $CourseId ]
            then
                flag=1
                #删除账号对应的行
                cat $cfile | grep -v "^$CourseId " >> ${cfile}Tmp
                mv ${cfile}Tmp ${cfile}
                echo -e "\033[40;93m删除成功！\033[0m"
                break
            fi
        done <${cfile}
        #账号不存在，删除失败
        if [ $flag -eq 0 ]
        then
            echo -e "\033[40;93m删除失败，课程不存在！\033[0m"
        fi
    done
}

#按课程号查询课程
QueryCourseById(){
    cfile="./course"
    touch $cfile
    while true
    do
        echo -e "\n"
        echo -e "\033[40;93m请输入课程号（输入'!'取消）\033[0m"
        #读入课程号
        myRead
        CourseId=$Buffer
        #课程号为'!'则返回
        if [ $CourseId = '!' ]
        then
            return 0
        fi
        #符合条件的记录数
        itemcnt=0
        #扫描课程信息的文件
        while read cid nm
        do
            #课程存在，输出记录
            if [[ $cid =~ $CourseId ]]
            then
                ((itemcnt++))
                echo -e "\033[40;93m$cid $nm\033[0m"
            fi
        done <${cfile}
        #课程不存在，删除失败
        if [ $itemcnt -eq 0 ]
        then
            echo -e "\033[40;93m查询失败，无相关课程！\033[0m"
        else
            echo -e "\033[40;93m查询成功，共 $itemcnt 条记录！\033[0m"
        fi
    done
}

#按课程名查询课程
QueryCourseByName(){
    cfile="./course"
    touch $cfile
    while true
    do
        echo -e "\n"
        echo -e "\033[40;93m请输入课程名称（输入'!'取消）\033[0m"
        #读入课程名称
        myRead
        CourseName=$Buffer
        #课程名称为'!'则返回
        if [ $CourseName = '!' ]
        then
            return 0
        fi
        #符合条件的记录数
        itemcnt=0
        #扫描课程信息的文件
        while read cid nm
        do
            #课程存在，输出记录
            if [[ $nm =~ $CourseName ]]
            then
                ((itemcnt++))
                echo -e "\033[40;93m$cid $nm\033[0m"
            fi
        done <${cfile}
        #课程不存在
        if [ $itemcnt -eq 0 ]
        then
            echo -e "\033[40;93m查询失败，无相关课程！\033[0m"
        else
            echo -e "\033[40;93m查询成功，共 $itemcnt 条记录！\033[0m"
        fi
    done
}

#查询全部课程
QueryCourseALL(){
    cfile="./course"
    touch $cfile
    while true
    do
        #符合条件的记录数
        itemcnt=0
        #扫描课程信息的文件
        while read cid nm
        do
            #输出记录
            ((itemcnt++))
            echo -e "\033[40;93m$cid $nm\033[0m"
        done <${cfile}
        #课程不存在
        if [ $itemcnt -eq 0 ]
        then
            echo -e "\033[40;93m查询失败，无相关课程！\033[0m"
        else
            echo -e "\033[40;93m查询成功，共 $itemcnt 条记录！\033[0m"
            return 0
        fi
    done
}

#查询课程信息
QueryCourse(){
    while true
    do
        echo -e "\n"
        echo -e "\033[40;93m\t"1\)按课程号查找"\033[0m"
        echo -e "\033[40;93m\t"2\)按课程名查找"\033[0m"
        echo -e "\033[40;93m\t"3\)查询所有课程"\033[0m"
        echo -e "\033[40;93m\t"b\)返回上级"\033[0m"
        echo -e "\033[40;93m\t"q\)退出"\033[0m"
        echo -e "\n"
        echo -e "\033[40;93m"请选择："\033[0m"
        read choice
        case $choice in
            1)  QueryCourseById;;
            2)  QueryCourseByName;;
            3)  QueryCourseALL;;
            b)  return 0;;
            q)  exit 0;;
            *)  echo -e "\033[40;93m"输入非法，请重新输入！"\033[0m";;
        esac
    done
}

#绑定课程和教师账号
LinkCourseAndTeacher(){
    cfile="./givecourse"
    touch $cfile
    while true
    do
        echo -e "\n"
        echo -e "\033[40;93m请输入课程号（输入'!'取消）\033[0m"
        #读入课程号
        myRead
        CourseId=$Buffer
        #教师姓名为'!'则返回
        if [ $CourseId = '!' ]
        then
            return 0
        fi
        echo -e "\033[40;93m请输入教师账号（输入'!'取消）\033[0m"
        #读入教师账号
        myRead
        TeacherId=$Buffer
        #课程号名称'!'则返回
        if [ $TeacherId = '!' ]
        then
            return 0
        fi
        #检查课程是否存在
        flag=$(cat "./course" | grep "^$CourseId" | wc -l)
        if [ $flag -eq 0 ]
        then
            echo -e "\033[40;93m课程不存在！\033[0m"
            continue
        fi
        #检查教师是否存在
        flag=$(cat "./usr" | grep "^$TeacherId" | wc -l)
        if [ $flag -eq 0 ]
        then
            echo -e "\033[40;93m教师不存在！\033[0m"
            continue
        fi
        #扫描选课信息的文件
        itemcnt=$(cat $cfile | grep "^$CourseId\ $TeacherId" | wc -l)
        #选课信息不存在，添加信息
        if [ $itemcnt -eq 0 ] 
        then
            #将新课程添加到数据文件的末尾
            echo $CourseId $TeacherId >> $cfile
            echo -e "\033[40;93m添加成功！\033[0m"
        else
            echo -e "\033[40;93m添加失败，记录已存在！\033[0m"
        fi
    done
}

#解绑课程与教师账号
CancelLinkCourseAndTeacher(){
    cfile="./givecourse"
    touch $cfile
    while true
    do
        echo -e "\n"
        echo -e "\033[40;93m请输入课程号（输入'!'取消）\033[0m"
        #读入课程号
        myRead
        CourseId=$Buffer
        #教师姓名为'!'则返回
        if [ $CourseId = '!' ]
        then
            return 0
        fi
        echo -e "\033[40;93m请输入教师账号（输入'!'取消）\033[0m"
        #读入教师账号
        myRead
        TeacherId=$Buffer
        #课程号名称'!'则返回
        if [ $TeacherId = '!' ]
        then
            return 0
        fi
        flag=0
        #扫描选课信息的文件
        itemcnt=$(cat $cfile | grep "^$CourseId\ $TeacherId" | wc -l)
        #选课信息不存在，删除失败
        if [ $itemcnt -eq 0 ] 
        then
            echo -e "\033[40;93m删除失败，记录不存在！\033[0m"
        else
            #利用反向选择删除绑定信息
            cat $cfile | grep -v "^$CourseId\ $TeacherId" >> "${cfile}tmp"
            mv "${cfile}tmp" "$cfile"
            echo -e "\033[40;93m删除成功！\033[0m"
        fi
    done
}

#课程信息管理
ManC(){
    while true
    do
        echo -e "\n"
        echo -e "\033[40;93m\t"1\)创建课程"\033[0m"
        echo -e "\033[40;93m\t"2\)修改课程"\033[0m"
        echo -e "\033[40;93m\t"3\)删除课程"\033[0m"
        echo -e "\033[40;93m\t"4\)查询课程"\033[0m"
        echo -e "\033[40;93m\t"5\)绑定课程与教师账户"\033[0m"
        echo -e "\033[40;93m\t"6\)解绑课程与教师账户"\033[0m"
        echo -e "\033[40;93m\t"b\)返回上级"\033[0m"
        echo -e "\033[40;93m\t"q\)退出"\033[0m"
        echo -e "\n"
        echo -e "\033[40;93m"请选择："\033[0m"
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
            *)  echo -e "\033[40;93m"输入非法，请重新输入！"\033[0m";;
        esac
    done
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
echo -e "\n\n \t  \033[40;93m=====当前登录账号：$account  当前权限：管理员=====\033[0m"

while true
do
    echo -e "\n"
    echo -e "\033[40;93m\t"1\)管理教师信息"\033[0m"
    echo -e "\033[40;93m\t"2\)管理课程信息"\033[0m"
    echo -e "\033[40;93m\t"3\)修改用户密码"\033[0m"
    echo -e "\033[40;93m\t"q\)退出"\033[0m"
    echo -e "\n"
    echo -e "\033[40;93m"请选择："\033[0m"
    read choice
        case $choice in
            1)  ManT;;
            2)  ManC;;
            3)  ChangePwd;;
            q)  exit 0;;
            *)  echo -e "\033[40;93m"输入非法，请重新输入！"\033[0m";;
        esac
done