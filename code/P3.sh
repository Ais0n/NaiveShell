#! /bin/bash
#程序名：test3.sh （对应实验2第3题）
#作者：黄彦玮
#学号：3180102067

mode="-c"
#判断参数个数
if test $# -eq 3  #参数个数为3，捕捉参数
then
      if [[ $1 =~ -* ]]
      then
            if [[ $1 =~ a+ ]]
            then
                    displayall="-a"  #储存-a参数，后续指令中会用到 
            fi
            if [[ $1 =~ s+ ]]
            then
                    mode="-s"  #储存-s参数，后续指令中会用到 
            fi
            dir1=$2
            dir2=$3          #储存两个目录的名字
      else
            echo "$1: Wrong Parameter!"
            exit 1
      fi
elif test $# -eq 2   #参数个数为2，默认不带参数
then
      dir1=$1
      dir2=$2           #储存两个目录的名字
else
      echo "Wrong number of parameters!"
      exit 1
fi 

#CheckDir()：通过扫描环境变量判断目录是否存在，并将目录扩展为绝对路径
CheckDir_ret=""
CheckDir(){
     dir_name=$1
     CheckDir_ret=""
     #已经是绝对路径，则直接返回
     if [ -d ${dir_name} ]
     then
           CheckDir_ret=${dir_name}
           return 1
     fi
     #扫描环境变量
     array=(${PATH/\:/ })  
     #顺序遍历环境变量进行检查
     for Env_var in ${array[@]}
     do
           if [ -d "${Env_var}/${dir_name}" ]
           then
                   CheckDir_ret="${Env_var}/${dir_name}}"
                   return 1
           fi
     done
     return 0
}

#调用函数，将两个目录变为绝对路径
CheckDir $dir1
if test $? -eq 0
then
      echo "$dir1: Directory cannot be found!"
      exit 1
fi
dir1=${CheckDir_ret}
CheckDir $dir2
if test $? -eq 0
then
      echo "$dir2: Directory cannot be found!"
      exit 1
fi
dir2=${CheckDir_ret}

#定义整形变量flag用于后续循环
typeset -i flag=0

#以下为用数组模拟堆栈，stacklen表示堆栈长度
typeset -i stacklen=0
#入栈
push(){
      stack[$stacklen]=$1
      stacklen=$(($stacklen+1))
}
#出栈，分别将栈顶元素赋值给dir1和dir2
popdir1(){
      dir1=${stack[$(($stacklen-1))]}
      stacklen=$(($stacklen-1))
}
popdir2(){
      dir2=${stack[$(($stacklen-1))]}
      stacklen=$(($stacklen-1))
}

#最主要的处理函数，用于将dir1同步到dir2
myRsyncCopy(){
      dir1=$1
      dir2=$2
      #预处理第二个目录下的文件和子目录
      for f in $(ls $displayall $dir2)
      do
            #.和..两个文件夹特殊不需要移动，需要特判
            if [[ $f == '.' ]] || [[ $f == '..' ]]
            then
                   continue
            fi
            #将第二个目录下的所有文件和子目录重命名备用
            mv "$dir2/$f" "$dir2/TEMP_FILE_$f"
      done
      #枚举第一个文件夹中的文件，搜索第二个文件夹中与之相匹配的文件
      for f in $(ls $displayall $dir1)
      do
            if [[ $f == '.' ]] || [[ $f == '..' ]]
            then
                   continue
            fi
            #flag用于表示是否找到了与之匹配的文件
            flag=0
            #对于子目录，changedir表示与之匹配的子目录
            changedir=""
            #枚举第二个目录下的文件
            for g in $(ls $dir2)
            do
                 #已经匹配过的文件就不考虑了
                 if [[ $g =~ ^TEMP_FILE_ ]]
                 then
                     :
                 else
                     continue
                 fi

                 if test -d "$dir1/$f" && test -d "$dir2/$g"     #对于子目录，找到匹配的子目录
                 then
                     #比较两个子目录下的目录名是否相同（不递归）
                     diff "$dir1/$f" "$dir2/$g" 1>/dev/null
                     if test $? -eq 0    #匹配
                     then
                         flag=1
                         changedir=$g
                         break
                     fi
                 elif test -f "$dir1/$f" && test -f "$dir2/$g"     #对于文件，找到匹配的文件
                 then
                     #比较两个文件是否相同
                     diff -q "$dir1/$f" "$dir2/$g" 1>/dev/null
                     if test $? -eq 0    #匹配
                     then
                         flag=1
                         mv "$dir2/$g" "$dir2/$f"
                         break
                     fi
                 #两个文件类型不同，不匹配
                 else 
                     continue
                 fi
            done

            if test -d "$dir1/$f"
            then
                 if test -n "$changedir"
                 then
                        #若子目录匹配，则修改文件名表示已经匹配
                        mv "$dir2/$changedir" "$dir2/$f"
                        #递归调用函数，需要先将两个文件夹名字存入堆栈，调用完成后再取出
                        push "$dir1"
                        push "$dir2"
                        myRsyncCopy "$dir1/$f" "$dir2/$f"
                        popdir2
                        popdir1
                 else
                        #若无匹配，直接拷贝
                        scp -r "$dir1/$f" "$dir2/$f"
                 fi
            elif test $flag -eq 0    #对于普通文件，若无匹配，直接拷贝
            then
                 scp "$dir1/$f" "$dir2/$f"
            fi
      done

      #删除第二个目录下未匹配的临时文件
      for f in $(ls $dir2)
      do
           if [[ $f =~ ^TEMP_FILE_ ]]
           then
                 rm -r "$dir2/$f"    
           fi
      done
}

myRsyncSync(){
      dir1=$1
      dir2=$2
      #枚举第一个文件夹中的文件，搜索第二个文件夹中与之相匹配的文件
      for f in $(ls $displayall $dir1)
      do
            if [[ $f == '.' ]] || [[ $f == '..' ]]
            then
                   continue
            fi
            #flag用于表示是否找到了与之匹配的文件
            flag=0
            #枚举第二个目录下的文件
            for g in $(ls $displayall $dir2)
            do
                 if [[ $f != $g ]]
                 then
                     continue
                 fi

                 if test -d "$dir1/$f" && test -d "$dir2/$g"     #对于子目录，找到匹配的子目录
                 then
                         flag=1
                         break
                 elif test -f "$dir1/$f" && test -f "$dir2/$g"   #对于文件，找到匹配的文件
                 then
                         flag=1
                         #比较文件新旧，并双向同步
                         if test "$dir1/$f" -nt "$dir2/$g"
                         then 
                              scp "$dir1/$f" "$dir2/$f"
                         elif test "$dir1/$f" -ot "$dir2/$g"
                         then
                              scp "$dir2/$f" "$dir1/$f"
                         fi
                         #修改匹配完成的文件的文件名，用于区分
                         mv "$dir1/$f" "$dir1/TEMP_FILE_$f"
                         mv "$dir2/$g" "$dir2/TEMP_FILE_$g"
                         break
                 fi
            done

            if test -d "$dir1/$f"
            then
                 if test $flag -eq 1
                 then
                        #若子目录匹配，则修改文件名表示已经匹配
                        mv "$dir1/$f" "$dir1/TEMP_FILE_$f"
                        mv "$dir2/$f" "$dir2/TEMP_FILE_$f"
                        #递归调用函数，需要先将两个文件夹名字存入堆栈，调用完成后再取出
                        push "$dir1"
                        push "$dir2"
                        myRsyncSync "$dir1/TEMP_FILE_$f" "$dir2/TEMP_FILE_$f"
                        popdir2
                        popdir1
                 fi
            fi
      done
      
      #删除第二个目录下未匹配的文件
      for f in $(ls $displayall $dir2)
      do
            if [ $f == . ] || [ $f == .. ]
            then 
                 continue
            fi
            if [[ $f =~ ^TEMP_FILE_ ]]
            then
                 :
            else
                 rm "$dir2/$f"
            fi
      done
      
      #将dir1中未匹配的复制到dir2
      for f in $(ls $displayall $dir1)
      do
            if [ $f == . ] || [ $f == .. ]
            then 
                 continue
            fi
            if [[ $f =~ ^TEMP_FILE_ ]]
            then
                 :
            elif test -d "$dir1/$f"
            then
                 scp -r "$dir1/$f" "$dir2/$f"
            else
                 scp "$dir1/$f" "$dir2/$f"
            fi
      done
      
      #将dir1中的已匹配文件的文件名改回原名
      for f in $(ls $displayall $dir1)
      do
            if [[ $f =~ TEMP_FILE_ ]]
            then
                 mv "$dir1/$f" "$dir1/${f:10}"   
            fi
      done

      #将dir2中的已匹配文件的文件名改回原名
      for f in $(ls $displayall $dir2)
      do
            if [[ $f =~ TEMP_FILE_ ]]
            then
                 mv "$dir2/$f" "$dir2/${f:10}"   
            fi
      done
}

if [[ $mode == -c ]] 
then
      myRsyncCopy $dir1 $dir2
else
      myRsyncSync $dir1 $dir2
fi