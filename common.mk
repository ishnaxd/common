# Copyright lowRISC contributors.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

COMMON_DIR := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

COMMON_SRCS = $(wildcard $(COMMON_DIR)/*.c)
INCLUDES := -I$(COMMON_DIR) \
			-I$(PROGRAM_DIR)/inc \
			-I$(PROGRAM_DIR)/inc/layers \
			-I$(PROGRAM_DIR)/port \
			-I$(PROGRAM_DIR)/keyword_spotting \
			-I/home/ishna/FYP/ibex/lowrisc-toolchain-gcc-rv32imcb-20240206-1/lib/gcc/riscv32-unknown-elf/10.2.0/include-fixed/
			
			
			
		


EXTRA_SRCS := $(wildcard $(PROGRAM_DIR)/src/backends/*.c) \
			  $(wildcard $(PROGRAM_DIR)/src/core/*.c) \
			  $(wildcard $(PROGRAM_DIR)/src/layers/*.c) \
			  $(wildcard $(PROGRAM_DIR)/port/*.c) \
			  $(wildcard $(PROGRAM_DIR)/keyword_spotting/*.c)

INCS := -I$(COMMON_DIR) -I$(INCLUDES)

# ARCH = rv32im # to disable compressed instructions
ARCH ?= rv32im

# ifdef PROGRAM
# PROGRAM_C := $(PROGRAM).c
# endif
PROGRAM_C := nnom_.c
SRCS = $(COMMON_SRCS) $(PROGRAM_C) $(EXTRA_SRCS)

C_SRCS = $(filter %.c, $(SRCS))
ASM_SRCS = $(filter %.S, $(SRCS))

CC = riscv32-unknown-elf-gcc

CROSS_COMPILE = $(patsubst %-gcc,%-,$(CC))
OBJCOPY ?= $(CROSS_COMPILE)objcopy
OBJDUMP ?= $(CROSS_COMPILE)objdump

LINKER_SCRIPT ?= $(COMMON_DIR)/link.ld
CRT ?= $(COMMON_DIR)/crt0.S
CFLAGS ?= -march=$(ARCH) -mabi=ilp32 -static -mcmodel=medany -Wall -g -Os\
	-fvisibility=hidden -nostdlib -fno-builtin -nostartfiles -ffreestanding -ffunction-sections -fdata-sections $(PROGRAM_CFLAGS) 
# CFLAGS ?= -march=$(ARCH) -mabi=ilp32 -static -mcmodel=medany -Wall -g -Os\
# 	-fvisibility=hidden -nostdlib -nostartfiles -ffreestanding $(PROGRAM_CFLAGS) 
# CFLAGS += -pg
# LDFLAGS += -pg
LIBRARY_PATH := /home/ishna/FYP/ibex/lowrisc-toolchain-gcc-rv32imcb-20240206-1/riscv32-unknown-elf/lib

LIBS :=  -lm -lgcc 
OBJS := ${C_SRCS:.c=.o} ${ASM_SRCS:.S=.o} ${CRT:.S=.o}
DEPS = $(OBJS:%.o=%.d)

ifdef PROGRAM
OUTFILES := $(PROGRAM).elf $(PROGRAM).vmem $(PROGRAM).bin
else
OUTFILES := $(OBJS)
endif

all: $(OUTFILES)

ifdef PROGRAM
$(PROGRAM).elf: $(OBJS) $(LINKER_SCRIPT)
	$(CC) $(CFLAGS) -T $(LINKER_SCRIPT) $(OBJS) $(LIBS) -L$(LIBRARY_PATH) -o $@ $(LIBS)

.PHONY: disassemble
disassemble: $(PROGRAM).dispcount_enable(0);

 
endif

%.dis: %.elf
	$(OBJDUMP) -hDx --wide $^ > $@

# Note: this target requires the srecord package to be installed.
# XXX: This could be replaced by objcopy once
# https://sourceware.org/bugzilla/show_bug.cgi?id=19921
# is widely available.
%.vmem: %.bin
	srec_cat $^ -binary -offset 0x0000 -byte-swap 4 -o $@ -vmem

%.bin: %.elf
	$(OBJCOPY) -O binary $^ $@

%.o: %.c
	$(CC) $(CFLAGS) -MMD -c $(INCS) -o $@ $<

%.o: %.S
	$(CC) $(CFLAGS) -MMD -c $(INCS) -o $@ $<

clean:
	$(RM) -f $(OBJS) $(DEPS)

distclean: clean
	$(RM) -f $(OUTFILES)
