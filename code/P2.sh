#! /bin/bash
#程序名：test2.sh （对应实验2第2题）
#作者：黄彦玮 3180102067

echo "请输入一个字符串："
#读取字符串
read str
#得到字符串长度
typeset -i len=${#str}
#循环所用变量
typeset -i i=0
#枚举每个字符
for (( i=0; i<len; i++ ))
do
    tmpchar=${str:$i:1}
    #若当前字符为空格则表示字符串结束，直接退出循环
    if [[ $tmpchar = ' ' ]]
    then
         break
    #特判掉星号和问号的情况，因为这两个字符在正则表达式中可以代替字符
    elif [[ $tmpchar = '*' ]] || [[ $tmpchar = '?' ]]
    then
         :
    elif [[ ${tmpchar}==[a-zA-Z] ]]
    then
         #是英文字母，加入过滤后的字符串
         newstr="$newstr$tmpchar"
    fi
done

#获取过滤后的字符串长度
len=${#newstr}
#如果过滤后是空串，直接退出
if (( $len == 0 ))
then
    echo "True"
    exit 0
fi

for (( i=0; i<len; i++ ))
do
    tmp1=${newstr:$i:1}
    tmp2=${newstr:(($len-$i-1)):1}
    #从两头开始遍历每个字符比较是否一致
    if [[ $tmp1 != $tmp2 ]]
    then
       #不一致直接返回
       echo "False"
       exit 0
    fi
done

#比较完成，字符串是回文串
echo "True"
exit 0