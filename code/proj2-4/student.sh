#!/bin/bash
###############################
#程序名：student.sh （对应实验2第4题）
#作者：黄彦玮
#学号：3180102067
#说明：图书管理系统-学生部分
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
        DataCheck $Buffer
        #无特殊过滤要求
        if [ $tmp -eq 0 ]
        then
            if [ $? -ne 1 ] && [ $Buffer != '!' ] 
            then
                echo -e "\033[40;93m格式错误，请重新输入！\033[0m"
            else
                break
            fi
        else
            if [ $? -ne 1 ] && [ $Buffer != '!' ] && [ $Buffer != '/' ]
            then
                echo -e "\033[40;93m格式错误，请重新输入！\033[0m"
            else
                break
            fi
        fi
    done
}

#查询作业是否存在&是否在有效期
checkHW(){
    CourseId=$1
    HWId=$2
    while read cid aid st ed
    do
        #从catalog文件中查询作业信息
        if [ $cid = $CourseId ] && [ $aid = $HWId ]
        then
            #获得当前时间，并转化成时间戳
            currenttime=$(date +%s)
            #将开始时间和结束时间都转化成时间戳
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


#新建作业
CreateWork(){
    CourseId=$1
    while true
    do
        echo -e "\033[40;93m请输入作业编号（输入'!'返回）！\033[0m"
        myRead
        HWId=$Buffer
        if [[ $HWId = '!' ]]
        then
            return 0
        fi
        #判断作业是否存在且可提交
        checkHW $CourseId $HWId
        #作业合法
        if [ $? -eq 1 ]
        then
            path="./submit/hw_${CourseId}_${HWId}_$account"
            if [ ! -f $path ]
            then
                touch $path
                echo -e "\033[40;93m"请键入信息，输入一行一个字符\'\!\'结束！"\033[0m"
                #读入信息内容
                while true
                do
                    read tmp
                    if [[ $tmp = '!' ]]
                    then 
                        break
                    fi
                    #将信息写入对应文件
                    echo $tmp >> $path
                done
                echo -e "\033[40;93m"新建成功，作业已保存至$path！"\033[0m"
            else
                echo -e "\033[40;93m"新建失败，作业已存在！"\033[0m"
            fi
        else
            #作业不合法，重新输入
            echo -e "\033[40;93m新建失败，作业不存在或不在提交时间！\033[0m"
        fi
    done
}

#编辑作业
EditWork(){
    CourseId=$1
    while true
    do
        echo -e "\033[40;93m请输入作业编号（输入'!'返回）！\033[0m"
        myRead
        HWId=$Buffer
        if [[ $HWId = '!' ]]
        then
            return 0
        fi
        #判断作业是否存在且可提交
        checkHW $CourseId $HWId
        #作业合法
        if [ $? -eq 1 ]
        then
            path="./submit/hw_${CourseId}_${HWId}_$account"
            if [ -f $path ]
            then
                vi $path
                echo -e "\033[40;93m"编辑成功！"\033[0m"
            else
                echo -e "\033[40;93m"编辑失败，作业不存在！"\033[0m"
            fi
        else
            #作业不合法，重新输入
            echo -e "\033[40;93m新建失败，作业不存在或不在提交时间！\033[0m"
        fi
    done
}

#删除作业
DeleteWork()
{
    CourseId=$1
    while true
    do
        echo -e "\033[40;93m请输入作业编号（输入'!'返回）！\033[0m"
        myRead
        HWId=$Buffer
        if [[ $HWId = '!' ]]
        then
            return 0
        fi
        #判断作业是否存在且可提交
        checkHW $CourseId $Buffer
        #作业合法
        if [ $? -eq 1 ]
        then
            path="./submit/hw_${CourseId}_${HWId}_$account"
            #作业存在
            if [ -f $path ]
            then
                rm $path
                echo -e "\033[40;93m"删除成功！"\033[0m"
            else
                echo -e "\033[40;93m"删除失败，作业不存在！"\033[0m"
            fi
        else
            #作业不合法，重新输入
            echo -e "\033[40;93m新建失败，作业不存在或不在提交时间！\033[0m" 
        fi
    done
}

#查询作业
QueryWork(){
    CourseId=$1
    cfile="./hw/catalog"
    while read cid aid st ed
    do
        #课程号不符合则直接跳过
        if [[ $cid != $CourseId ]]
        then
            continue
        fi
        path="./submit/hw_${CourseId}_${aid}_$account"
        if [ -f $path ]
        then
            isfinished="已提交，路径为$path"
        else
            isfinished="未提交"
        fi
        echo -e "\033[40;93m"作业编号：$aid 起始日期：$st 结束日期：$ed"\033[0m"
        echo -e "\033[40;93m"作业状态：$isfinished"\033[0m"
        echo -e "\033[40;93m"; cat "./hw/course_${cid}_${aid}"; echo -e "\033[0m"
    done <$cfile
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

#管理作业
ManWork(){
    CourseId=$1
    #如果submit文件夹不存在的话要先创建
    if [ ! -d "./submit" ]
    then
        mkdir "./submit"
    fi
    while true
    do
        echo -e "\n"
        echo -e "\033[40;93m\t"1\)新建作业"\033[0m"
        echo -e "\033[40;93m\t"2\)编辑作业"\033[0m"
        echo -e "\033[40;93m\t"3\)删除作业"\033[0m"
        echo -e "\033[40;93m\t"4\)查询作业"\033[0m"
        echo -e "\033[40;93m\t"b\)返回上级"\033[0m"
        echo -e "\033[40;93m\t"q\)退出"\033[0m"
        echo -e "\n"
        echo -e "\033[40;93m"请选择："\033[0m"
        read choice
            case $choice in
                1)  CreateWork $CourseId;;
                2)  EditWork $CourseId;;
                3)  DeleteWork $CourseId;;
                4)  QueryWork $CourseId;;
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
    cfile="./selcourse"
    #选课数量
    itemcnt=0
    #选课课程号与名称列表
    courselist=()
    namelist=()
    while read cid sid
    do
        if [ $account = $sid ]
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
        echo -e "\033[40;93m"您暂无选课，请联系教师添加！"\033[0m"
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
                ManWork ${courselist[$choice]}
            else 
                echo -e "\033[40;93m"输入非法，请重新输入！"\033[0m"
            fi
        done 
    fi
}


clear
echo -e "\n\n \t\t    \033[40;93m =====欢迎您，$name！=====\033[0m"
echo -e "\n\n \t  \033[40;93m=====当前登录账号：$account  当前权限：学生=====\033[0m"

while true
do
    echo -e "\n"
    echo -e "\033[40;93m\t"1\)选择课程"\033[0m"
    echo -e "\033[40;93m\t"2\)修改用户密码"\033[0m"
    echo -e "\033[40;93m\t"q\)退出"\033[0m"
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