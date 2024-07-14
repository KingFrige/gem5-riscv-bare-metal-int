SHELL = /bin/sh
ARCH = riscv64-unknown-linux-gnu
CC = $(ARCH)-gcc
LD = $(ARCH)-ld
OBJCOPY = $(ARCH)-objcopy
OBJDUMP = $(ARCH)-objdump
IDIR = inc
SDIR = src
BDIR = build
CFLAGS = -Wall -mcmodel=medany -g -I $(IDIR) -O0
SFLAGS = -g -I $(IDIR)
S_SRCS = $(wildcard $(SDIR)/*.s)
C_SRCS = $(wildcard $(SDIR)/*.c)
S_OBJS = $(S_SRCS:$(SDIR)/%.s=$(BDIR)/%_asm.o)
C_OBJS = $(C_SRCS:$(SDIR)/%.c=$(BDIR)/%.o)


all: kernel.img

kernel.img: kernel.elf
	$(OBJCOPY) kernel.elf -I binary kernel.img

kernel.elf: $(S_OBJS) link.ld $(C_OBJS)
	$(LD) -T link.ld -o kernel.elf $(S_OBJS) $(C_OBJS)
	$(OBJDUMP) -S -D kernel.elf > kernel.dump

$(BDIR)/%.o: $(SDIR)/%.c
	$(CC) $(CFLAGS) -c $< -o $@

$(BDIR)/%_asm.o: $(SDIR)/%.s
	$(CC) $(SFLAGS) -c $< -o $@

clean:
	rm -f $(BDIR)/*_asm.o $(BDIR)/*.o kernel.elf kernel.img kernel.dump

run: kernel.img
	qemu-system-riscv64 -M virt -kernel kernel.img -bios none -serial stdio -display none

debug: all
	terminator -e "qemu-system-riscv64 -M virt -kernel kernel.img -bios none -serial stdio -s -S" --new-tab
	terminator -e "riscv64-linux-gnu-gdb -x debug.txt" --new-tab

