NASM :=	  nasm -g -f elf64 $^

CFLAGS +=   -m64 -std=c99 -Wall -Wshadow -Wpointer-arith -Wcast-qual \
			-Wstrict-prototypes -fPIC -g -O2 -masm=intel -march=ivybridge

H_SRCS :=   fe_convert.h \
			fe10.h \
			fe12.h \
			ge.h \
			mxcsr.h
ASM_SCRS := fe12_squeeze.asm
C_SRCS :=   mxcsr.c \
            fe10.c \
			fe12_old.c \
			fe_convert.c \
			ge.c \
			scalarmult.c

ASM_OBJS := $(ASM_SCRS:%.asm=%.o)
C_OBJS :=   $(C_SRCS:%.c=%.o)


all: libref12.so

%.o: %.asm
	$(NASM) -g -f elf64 -l $(patsubst %.o,%.lst,$@) -o $@ $<

libref12.so: $(ASM_OBJS) $(C_OBJS)
	$(CC) $(CFLAGS) -shared -o $@ $^ $(LDFLAGS) $(LDLIBS)

.PHONY: check
check: libref12.so
	sage -python test_all.py -v

.PHONY: clean
clean:
	$(RM) *.o *.gch *.a *.out *.so *.d *.lst

%.d: %.asm
	$(NASM) -MT $(patsubst %.d,%.o,$@) -M $< >$@

%.d: %.c
	$(CC) $(CFLAGS) -M $< >$@

include $(ASM_SCRS:%.asm=%.d)
include $(C_SRCS:%.c=%.d)
