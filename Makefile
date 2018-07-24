CFLAGS += -m64 -std=c99 -Wall -Wshadow -Wpointer-arith -Wcast-qual \
          -Wstrict-prototypes -fPIC -g -O2 -masm=intel -march=ivybridge
SRCS = fe10.c \
       fe12.asm \
       fe12_old.c \
       fe_convert.c \
       ge.c \
       scalarmult.c
OBJS := fe10.o \
        fe12.o \
        fe12_old.o \
        fe_convert.o \
        ge.o \
        scalarmult.o

all: libref12.so

%.o: %.asm
	nasm -g -f elf64 -l $%.lst $^

libref12.so: $(OBJS)
	$(CC) $(CFLAGS) -shared -o $@ $^ $(LDFLAGS) $(LDLIBS)

.PHONY: check
check: libref12.so
	sage -python test_all.py -v

.PHONY: clean
clean:
	$(RM) *.o *.gch *.a *.out *.so
