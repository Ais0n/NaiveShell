myshell: main.o proc_list.o controller.o mycmd.o
	gcc main.o proc_list.o controller.o mycmd.o -o myshell

main.o: main.h main.c proc_list.h
	gcc -c main.c -o main.o

controller.o: main.h mycmd.h proc_list.h controller.c controller.h
	gcc -c controller.c -o controller.o

mycmd.o: mycmd.c main.h proc_list.h mycmd.h
	gcc -c mycmd.c -o mycmd.o

proc_list.o: proc_list.h proc_list.c main.h
	gcc -c proc_list.c -o proc_list.o

clean:
	@rm -f *.o myshell
