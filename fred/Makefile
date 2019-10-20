#
# Our gnu cross compiler
#
DEVC_PREFIX=m6811-elf-
CC=$(DEVC_PREFIX)gcc
AS=$(DEVC_PREFIX)as
AR=$(DEVC_PREFIX)ar
SIZE=$(DEVC_PREFIX)size
OBJCOPY=$(DEVC_PREFIX)objcopy
OBJDUMP=$(DEVC_PREFIX)objdump
RM=rm -f

#
#
LDFLAGS = -m68hc11 -mshort -Wl,-m,m68hc11elfb -O

#
# LDFLAGS to use to build a bootstrap program.
#
BOOT_PROG_LDFLAGS=-nostdlib -nostartfiles $(DEF_LDFLAGS)

#
CFLAGS=-m68hc11 -mshort -O $(WARN) $(DEBUG) $(OPT)

ASFLAGS=-m68hc11

#
# .elf is for the simulator and gdb
# .s19 is for some downloader and the simulator
# .b   is a binary dump
#
.SUFFIXES: .elf .s19 .b .lis

#
# Options to creates the .s19 or .b files from the elf
#
OBJCOPY_FLAGS=--only-section=.text \
              --only-section=.rodata \
              --only-section=.vectors

#
# Default target
#
all:: fred.s19 fred.lis
              
#
# Source files
#
SRCS = main.c
ASBS = lcd.s timer.s lcdbuffer.s readanalog.s pwm.s sonar.s

#
# Dependencies
#
DEPS := $(SRCS:%.c=%.d)
OBJS := $(SRCS:%.c=%.o)

DEPS += $(ASBS:%.s=%.d)
OBJS += $(ASBS:%.s=%.o)

ifneq ($(MAKECMDGOALS),clean)
-include $(DEPS)
endif

#
# Rule to make dependency file
#
%.d: %.c
	@echo "Updating" $@
	@set -e; $(CC) -M $(CFLAGS) $< \
		| sed 's|\($*\)\.o[ :]*|\1.o $@ : |g' > $@; \
		[ -s $@ ] || rm -f $@

#
# Rule to assemble, and create dependency file at the same time
#
%.d: %.o

%.o: %.s
	$(AS) $(ASFLAGS) --MD $*.d -o $@ $<

#
# Rule to create an S19 file from an ELF file.
#
.elf.s19:
	$(OBJCOPY) --output-target=srec $(OBJCOPY_FLAGS) $< $*.s19

#
# Rule to create an binary dump from an ELF file.
#
.elf.b:
	$(OBJCOPY) --output-target=binary $(OBJCOPY_FLAGS) $<  $*.b

#
# Rule to make a disassemble listing
#
.elf.lis:
	$(OBJDUMP) -d $< > $*.lis


fred.elf: $(OBJS)
	$(CC) $(LDFLAGS) $^ -o $@ 

clean::
	$(RM) *.o
	$(RM) *.elf
	$(RM) *.s19
	$(RM) *.b
	$(RM) *.d
	$(RM) *.a
