CC := gcc

all: debexec-preload.so

debexec-preload.so: debexec-preload.c
	$(CC) -shared -fPIC debexec-preload.c -o debexec-preload.so -ldl

clean:
	rm debexec-preload.so
