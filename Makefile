CC = gcc
CFLAGS += -m64 -std=c99 -Wall -Wshadow -Wpointer-arith -Wcast-qual \
          -Wstrict-prototypes -fPIC -g -O3 -mtune=native
SRCS = fe10.c \
       fe12.c \
       fe_convert.c \
       ge.c \
       scalarmult.c
OBJS := ${SRCS:.c=.o}

all: libref12.so

libref12.so: $(OBJS)
	$(CC) $(CFLAGS) -shared -o $@ $^ $(LDFLAGS) $(LDLIBS)

.PHONY: check
check: libref12.so
	sage -python test_all.py -v

.PHONY: clean
clean:
	$(RM) *.o *.gch *.a *.out *.so
