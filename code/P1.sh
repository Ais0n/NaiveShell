#! /bin/bash
#程序名：test.sh （对应实验2第1题）
#作者：黄彦玮 3180102067
#判断参数个数是否为1，若不是则退出
if test $# -ne 1
   then
        echo "Parameter should be only one!"
        exit 1
fi

#储存文件名
dirname="$1"
#定义整形变量，分别表示普通文件、目录、可执行文件的个数、普通文件总字节数
typeset -i num_of_normal=0
typeset -i num_of_dir=0
typeset -i num_of_exec=0
typeset -i sum=0
#定义整形临时变量
typeset -i tmp=0

#判断输入的目录是否存在
if [ -d $dirname ]
then
     #用ls -l指令列出详细信息后，选择-开头的普通文件，用grep统计后用wc计算行数
     num_of_normal=$(ls -l $dirname | grep '^-' | wc -l)
     echo "number of normal files: ${num_of_normal}"
     #用ls -F指令，文件名后加/号的是目录，加*号的是可执行文件
     num_of_dir=$(ls -F $dirname | grep '/' | wc -l)
     echo "number of directories: ${num_of_dir}"
     num_of_exec=$(ls -F $dirname | grep '*' | wc -l)
     echo "number of executable files: ${num_of_exec}"
     #枚举文件夹下的文件，并用ls -l显示详细信息
     for f in $(ls $dirname)
     do
         set -- $(ls -l $f)
         #根据第一个字段的第一个字符判断是否为普通文件
         if [[ $1="^-" ]]
         then
              #将大小转成整数后相加
              tmp=$5
              sum=$(($sum+$tmp))
         fi
     done
     echo "the total bytes of normal files: $sum"
     #处理完成，正确退出
     exit 0
else
     #若目录不存在，则退出
     echo "The directory doesn't exist."
     exit 1
fi