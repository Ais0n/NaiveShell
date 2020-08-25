#! /bin/bash
#��������test3.sh ����Ӧʵ��2��3�⣩
#���ߣ�������
#ѧ�ţ�3180102067

mode="-c"
#�жϲ�������
if test $# -eq 3  #��������Ϊ3����׽����
then
      if [[ $1 =~ -* ]]
      then
            if [[ $1 =~ a+ ]]
            then
                    displayall="-a"  #����-a����������ָ���л��õ� 
            fi
            if [[ $1 =~ s+ ]]
            then
                    mode="-s"  #����-s����������ָ���л��õ� 
            fi
            dir1=$2
            dir2=$3          #��������Ŀ¼������
      else
            echo "$1: Wrong Parameter!"
            exit 1
      fi
elif test $# -eq 2   #��������Ϊ2��Ĭ�ϲ�������
then
      dir1=$1
      dir2=$2           #��������Ŀ¼������
else
      echo "Wrong number of parameters!"
      exit 1
fi 

#CheckDir()��ͨ��ɨ�軷�������ж�Ŀ¼�Ƿ���ڣ�����Ŀ¼��չΪ����·��
CheckDir_ret=""
CheckDir(){
     dir_name=$1
     CheckDir_ret=""
     #�Ѿ��Ǿ���·������ֱ�ӷ���
     if [ -d ${dir_name} ]
     then
           CheckDir_ret=${dir_name}
           return 1
     fi
     #ɨ�軷������
     array=(${PATH/\:/ })  
     #˳����������������м��
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

#���ú�����������Ŀ¼��Ϊ����·��
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

#�������α���flag���ں���ѭ��
typeset -i flag=0

#����Ϊ������ģ���ջ��stacklen��ʾ��ջ����
typeset -i stacklen=0
#��ջ
push(){
      stack[$stacklen]=$1
      stacklen=$(($stacklen+1))
}
#��ջ���ֱ�ջ��Ԫ�ظ�ֵ��dir1��dir2
popdir1(){
      dir1=${stack[$(($stacklen-1))]}
      stacklen=$(($stacklen-1))
}
popdir2(){
      dir2=${stack[$(($stacklen-1))]}
      stacklen=$(($stacklen-1))
}

#����Ҫ�Ĵ����������ڽ�dir1ͬ����dir2
myRsyncCopy(){
      dir1=$1
      dir2=$2
      #Ԥ����ڶ���Ŀ¼�µ��ļ�����Ŀ¼
      for f in $(ls $displayall $dir2)
      do
            #.��..�����ļ������ⲻ��Ҫ�ƶ�����Ҫ����
            if [[ $f == '.' ]] || [[ $f == '..' ]]
            then
                   continue
            fi
            #���ڶ���Ŀ¼�µ������ļ�����Ŀ¼����������
            mv "$dir2/$f" "$dir2/TEMP_FILE_$f"
      done
      #ö�ٵ�һ���ļ����е��ļ��������ڶ����ļ�������֮��ƥ����ļ�
      for f in $(ls $displayall $dir1)
      do
            if [[ $f == '.' ]] || [[ $f == '..' ]]
            then
                   continue
            fi
            #flag���ڱ�ʾ�Ƿ��ҵ�����֮ƥ����ļ�
            flag=0
            #������Ŀ¼��changedir��ʾ��֮ƥ�����Ŀ¼
            changedir=""
            #ö�ٵڶ���Ŀ¼�µ��ļ�
            for g in $(ls $dir2)
            do
                 #�Ѿ�ƥ������ļ��Ͳ�������
                 if [[ $g =~ ^TEMP_FILE_ ]]
                 then
                     :
                 else
                     continue
                 fi

                 if test -d "$dir1/$f" && test -d "$dir2/$g"     #������Ŀ¼���ҵ�ƥ�����Ŀ¼
                 then
                     #�Ƚ�������Ŀ¼�µ�Ŀ¼���Ƿ���ͬ�����ݹ飩
                     diff "$dir1/$f" "$dir2/$g" 1>/dev/null
                     if test $? -eq 0    #ƥ��
                     then
                         flag=1
                         changedir=$g
                         break
                     fi
                 elif test -f "$dir1/$f" && test -f "$dir2/$g"     #�����ļ����ҵ�ƥ����ļ�
                 then
                     #�Ƚ������ļ��Ƿ���ͬ
                     diff -q "$dir1/$f" "$dir2/$g" 1>/dev/null
                     if test $? -eq 0    #ƥ��
                     then
                         flag=1
                         mv "$dir2/$g" "$dir2/$f"
                         break
                     fi
                 #�����ļ����Ͳ�ͬ����ƥ��
                 else 
                     continue
                 fi
            done

            if test -d "$dir1/$f"
            then
                 if test -n "$changedir"
                 then
                        #����Ŀ¼ƥ�䣬���޸��ļ�����ʾ�Ѿ�ƥ��
                        mv "$dir2/$changedir" "$dir2/$f"
                        #�ݹ���ú�������Ҫ�Ƚ������ļ������ִ����ջ��������ɺ���ȡ��
                        push "$dir1"
                        push "$dir2"
                        myRsyncCopy "$dir1/$f" "$dir2/$f"
                        popdir2
                        popdir1
                 else
                        #����ƥ�䣬ֱ�ӿ���
                        scp -r "$dir1/$f" "$dir2/$f"
                 fi
            elif test $flag -eq 0    #������ͨ�ļ�������ƥ�䣬ֱ�ӿ���
            then
                 scp "$dir1/$f" "$dir2/$f"
            fi
      done

      #ɾ���ڶ���Ŀ¼��δƥ�����ʱ�ļ�
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
      #ö�ٵ�һ���ļ����е��ļ��������ڶ����ļ�������֮��ƥ����ļ�
      for f in $(ls $displayall $dir1)
      do
            if [[ $f == '.' ]] || [[ $f == '..' ]]
            then
                   continue
            fi
            #flag���ڱ�ʾ�Ƿ��ҵ�����֮ƥ����ļ�
            flag=0
            #ö�ٵڶ���Ŀ¼�µ��ļ�
            for g in $(ls $displayall $dir2)
            do
                 if [[ $f != $g ]]
                 then
                     continue
                 fi

                 if test -d "$dir1/$f" && test -d "$dir2/$g"     #������Ŀ¼���ҵ�ƥ�����Ŀ¼
                 then
                         flag=1
                         break
                 elif test -f "$dir1/$f" && test -f "$dir2/$g"   #�����ļ����ҵ�ƥ����ļ�
                 then
                         flag=1
                         #�Ƚ��ļ��¾ɣ���˫��ͬ��
                         if test "$dir1/$f" -nt "$dir2/$g"
                         then 
                              scp "$dir1/$f" "$dir2/$f"
                         elif test "$dir1/$f" -ot "$dir2/$g"
                         then
                              scp "$dir2/$f" "$dir1/$f"
                         fi
                         #�޸�ƥ����ɵ��ļ����ļ�������������
                         mv "$dir1/$f" "$dir1/TEMP_FILE_$f"
                         mv "$dir2/$g" "$dir2/TEMP_FILE_$g"
                         break
                 fi
            done

            if test -d "$dir1/$f"
            then
                 if test $flag -eq 1
                 then
                        #����Ŀ¼ƥ�䣬���޸��ļ�����ʾ�Ѿ�ƥ��
                        mv "$dir1/$f" "$dir1/TEMP_FILE_$f"
                        mv "$dir2/$f" "$dir2/TEMP_FILE_$f"
                        #�ݹ���ú�������Ҫ�Ƚ������ļ������ִ����ջ��������ɺ���ȡ��
                        push "$dir1"
                        push "$dir2"
                        myRsyncSync "$dir1/TEMP_FILE_$f" "$dir2/TEMP_FILE_$f"
                        popdir2
                        popdir1
                 fi
            fi
      done
      
      #ɾ���ڶ���Ŀ¼��δƥ����ļ�
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
      
      #��dir1��δƥ��ĸ��Ƶ�dir2
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
      
      #��dir1�е���ƥ���ļ����ļ����Ļ�ԭ��
      for f in $(ls $displayall $dir1)
      do
            if [[ $f =~ TEMP_FILE_ ]]
            then
                 mv "$dir1/$f" "$dir1/${f:10}"   
            fi
      done

      #��dir2�е���ƥ���ļ����ļ����Ļ�ԭ��
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