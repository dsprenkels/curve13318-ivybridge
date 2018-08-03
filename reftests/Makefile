NASM :=	  nasm -g -f elf64 $^

CFLAGS +=   -m64 -std=c99 -Wall -Wshadow -Wpointer-arith -Wcast-qual \
			-Wstrict-prototypes -fPIC -g -O2 -masm=intel -march=ivybridge

H_SRCS :=   fe.h
ASM_SCRS := fe12_mul_1.asm
C_SRCS :=   fe12_mul_1_ref.c

ASM_OBJS := $(ASM_SCRS:%.asm=%.o)
C_OBJS :=   $(C_SRCS:%.c=%.o)

%.o: %.asm
	$(NASM) -g -f elf64 -l $(patsubst %.o,%.lst,$@) -o $@ $<

libreftests.so: $(ASM_OBJS) $(C_OBJS)
	$(CC) $(CFLAGS) -shared -o $@ $^ $(LDFLAGS) $(LDLIBS)

.PHONY: check
check: libreftests.so
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
