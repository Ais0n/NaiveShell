#! /bin/bash
#��������test2.sh ����Ӧʵ��2��2�⣩
#���ߣ������� 3180102067

echo "������һ���ַ�����"
#��ȡ�ַ���
read str
#�õ��ַ�������
typeset -i len=${#str}
#ѭ�����ñ���
typeset -i i=0
#ö��ÿ���ַ�
for (( i=0; i<len; i++ ))
do
    tmpchar=${str:$i:1}
    #����ǰ�ַ�Ϊ�ո����ʾ�ַ���������ֱ���˳�ѭ��
    if [[ $tmpchar = ' ' ]]
    then
         break
    #���е��Ǻź��ʺŵ��������Ϊ�������ַ���������ʽ�п��Դ����ַ�
    elif [[ $tmpchar = '*' ]] || [[ $tmpchar = '?' ]]
    then
         :
    elif [[ ${tmpchar}==[a-zA-Z] ]]
    then
         #��Ӣ����ĸ��������˺���ַ���
         newstr="$newstr$tmpchar"
    fi
done

#��ȡ���˺���ַ�������
len=${#newstr}
#������˺��ǿմ���ֱ���˳�
if (( $len == 0 ))
then
    echo "True"
    exit 0
fi

for (( i=0; i<len; i++ ))
do
    tmp1=${newstr:$i:1}
    tmp2=${newstr:(($len-$i-1)):1}
    #����ͷ��ʼ����ÿ���ַ��Ƚ��Ƿ�һ��
    if [[ $tmp1 != $tmp2 ]]
    then
       #��һ��ֱ�ӷ���
       echo "False"
       exit 0
    fi
done

#�Ƚ���ɣ��ַ����ǻ��Ĵ�
echo "True"
exit 0