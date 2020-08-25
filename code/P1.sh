#! /bin/bash
#��������test.sh ����Ӧʵ��2��1�⣩
#���ߣ������� 3180102067
#�жϲ��������Ƿ�Ϊ1�����������˳�
if test $# -ne 1
   then
        echo "Parameter should be only one!"
        exit 1
fi

#�����ļ���
dirname="$1"
#�������α������ֱ��ʾ��ͨ�ļ���Ŀ¼����ִ���ļ��ĸ�������ͨ�ļ����ֽ���
typeset -i num_of_normal=0
typeset -i num_of_dir=0
typeset -i num_of_exec=0
typeset -i sum=0
#����������ʱ����
typeset -i tmp=0

#�ж������Ŀ¼�Ƿ����
if [ -d $dirname ]
then
     #��ls -lָ���г���ϸ��Ϣ��ѡ��-��ͷ����ͨ�ļ�����grepͳ�ƺ���wc��������
     num_of_normal=$(ls -l $dirname | grep '^-' | wc -l)
     echo "number of normal files: ${num_of_normal}"
     #��ls -Fָ��ļ������/�ŵ���Ŀ¼����*�ŵ��ǿ�ִ���ļ�
     num_of_dir=$(ls -F $dirname | grep '/' | wc -l)
     echo "number of directories: ${num_of_dir}"
     num_of_exec=$(ls -F $dirname | grep '*' | wc -l)
     echo "number of executable files: ${num_of_exec}"
     #ö���ļ����µ��ļ�������ls -l��ʾ��ϸ��Ϣ
     for f in $(ls $dirname)
     do
         set -- $(ls -l $f)
         #���ݵ�һ���ֶεĵ�һ���ַ��ж��Ƿ�Ϊ��ͨ�ļ�
         if [[ $1="^-" ]]
         then
              #����Сת�����������
              tmp=$5
              sum=$(($sum+$tmp))
         fi
     done
     echo "the total bytes of normal files: $sum"
     #������ɣ���ȷ�˳�
     exit 0
else
     #��Ŀ¼�����ڣ����˳�
     echo "The directory doesn't exist."
     exit 1
fi