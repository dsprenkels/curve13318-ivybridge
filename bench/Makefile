NASM :=	  nasm -g -f elf64 $^

CFLAGS +=   -m64 -std=c99 -Wall -Wshadow -Wpointer-arith -Wcast-qual \
			-Wstrict-prototypes -fPIC -g -O2 -masm=intel -march=ivybridge

BENCHMARKS := squeeze
ASM_SCRS := $(wildcard *.asm)
C_SRCS :=   $(wildcard *.c)
ASM_OBJS := $(ASM_SCRS:%.asm=%.o)
C_OBJS :=   $(C_SRCS:%.c=%.o)

run: $(patsubst %,run_%,$(BENCHMARKS))

run_%: %
	./$(patsubst run_%,%,$@)
	rm $(patsubst run_%,%,$@)

all: $(BENCHMARKS)

$(BENCHMARKS): $(patsubst %,%.o,$@) main.o

.PHONY: setup
setup:
	# Disable turboboost
	echo '1' | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo >/dev/null
	# Disable hyperthreading cores
	echo '0' | sudo tee /sys/devices/system/cpu/cpu4/online >/dev/null
	echo '0' | sudo tee /sys/devices/system/cpu/cpu5/online >/dev/null
	echo '0' | sudo tee /sys/devices/system/cpu/cpu6/online >/dev/null
	echo '0' | sudo tee /sys/devices/system/cpu/cpu7/online >/dev/null
	# Disable cpu scaling
	echo 'performance' | sudo tee /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor >/dev/null
	echo 'performance' | sudo tee /sys/devices/system/cpu/cpu1/cpufreq/scaling_governor >/dev/null
	echo 'performance' | sudo tee /sys/devices/system/cpu/cpu2/cpufreq/scaling_governor >/dev/null
	echo 'performance' | sudo tee /sys/devices/system/cpu/cpu3/cpufreq/scaling_governor >/dev/null

.PHONY: unsetup
unsetup:
	# Enable cpu scaling
	echo 'powersave' | sudo tee /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor >/dev/null
	echo 'powersave' | sudo tee /sys/devices/system/cpu/cpu1/cpufreq/scaling_governor >/dev/null
	echo 'powersave' | sudo tee /sys/devices/system/cpu/cpu2/cpufreq/scaling_governor >/dev/null
	echo 'powersave' | sudo tee /sys/devices/system/cpu/cpu3/cpufreq/scaling_governor >/dev/null
	# Enable hyperthreading cores
	echo '1' | sudo tee /sys/devices/system/cpu/cpu4/online >/dev/null
	echo '1' | sudo tee /sys/devices/system/cpu/cpu5/online >/dev/null
	echo '1' | sudo tee /sys/devices/system/cpu/cpu6/online >/dev/null
	echo '1' | sudo tee /sys/devices/system/cpu/cpu7/online >/dev/null
	# Enable turboboost
	echo '0' | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo >/dev/null

%.o: %.asm
	$(NASM) -g -f elf64 -l $(patsubst %.o,%.lst,$@) -o $@ $<

%.d: %.asm
	$(NASM) -MT $(patsubst %.d,%.o,$@) -M $< >$@

%.d: %.c
	$(CC) $(CFLAGS) -M $< >$@

.PHONY: clean
clean:
	$(RM) *.o *.gch *.a *.out *.so *.d *.lst

include $(ASM_SCRS:%.asm=%.d)
include $(C_SRCS:%.c=%.d)
