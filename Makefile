CC = clang
CFLAGS += -m64 -std=c99 -pedantic -Wall -Wshadow -Wpointer-arith -Wcast-qual \
          -Wstrict-prototypes -Wmissing-prototypes -fPIC -g -O3
SRCS = fe10.c \
       fe12.c \
       fe_convert.c \
       ge.c
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
