#
# Our gnu cross compiler
#
DEVC_PREFIX=m6811-elf-
CC=$(DEVC_PREFIX)gcc
AS=$(DEVC_PREFIX)as
AR=$(DEVC_PREFIX)ar
SIZE=$(DEVC_PREFIX)size
OBJCOPY=$(DEVC_PREFIX)objcopy
RM=rm -f

#
#
LDFLAGS = -m68hc11 -mshort -Wl,-m,m68hc11elfb

#
# LDFLAGS to use to build a bootstrap program.
#
BOOT_PROG_LDFLAGS=-nostdlib -nostartfiles $(DEF_LDFLAGS)

#
CFLAGS=$(TARGET_PROC) $(TARGET_INT) $(WARN) $(DEBUG) $(OPT)

ASFLAGS=$(TARGET_PROC)

#
# .elf is for the simulator and gdb
# .s19 is for some downloader and the simulator
# .b   is a binary dump
#
.SUFFIXES: .elf .s19 .b

#
# Options to creates the .s19 or .b files from the elf
#
OBJCOPY_FLAGS=--only-section=.text \
              --only-section=.rodata \
              --only-section=.vectors

#
# Rule to create an S19 file from an ELF file.
#
.elf.s19:
	$(OBJCOPY) --output-target=srec $(OBJCOPY_FLAGS) $< $*.s19

#
# Rule to create an binary dump from an ELF file.
#
.elf.b:
	$(OBJCOPY) --output-target=binary $(OBJCOPY_FLAGS) $< $*.b

all:: flash.s19


flash.elf: flash.o
	$(CC) $(LDFLAGS) $< -o $@ 

clean::
	$(RM) *.o
	$(RM) *.elf
	$(RM) *.s19
	$(RM) *.b
	$(RM) *.a
