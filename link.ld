/* Copyright lowRISC contributors.
   Licensed under the Apache License, Version 2.0, see LICENSE for details.
   SPDX-License-Identifier: Apache-2.0 */

OUTPUT_ARCH(riscv)


MEMORY
{
/* Change this if you'd like different sizes. Arty A7-100(35) has a maximum of 607.5KB(225KB)
   BRAM space. Configuration below is for maximum BRAM capacity with Artya A7-35 while letting
   CoreMark run (.vmem of 152.8KB).
*/
    ram         : ORIGIN = 0x00100000, LENGTH = 0xfffff 
    /* 192 kB */
    /*stack       : ORIGIN = 0x00150000, LENGTH = 0x8000 */
    
    
     /* 32 kB */
}

 /* 8K - minimum stack space to reserve */
/* Stack information variables */
/*_min_stack      = 0x2000;  */
/*_stack_len     = LENGTH(stack);*/
/*_stack_start   = ORIGIN(stack) + LENGTH(stack);*/

_entry_point = _vectors_start + 0x80;
ENTRY(_entry_point)

/* The tohost address is used by Spike for a magic "stop me now" message. This
   is set to equal SIM_CTRL_CTRL (see simple_system_regs.h), which has that
   effect in simple_system simulations. Note that it must be 8-byte aligned.

   We don't read data back from Spike, so fromhost is set to some dummy value:
   we place it just above the top of the stack.
 */
/*tohost   = 0x20008;
fromhost = _stack_start + 0x10;*/

SECTIONS
{
    .vectors :
    {
        . = ALIGN(4);
		_vectors_start = .;
        KEEP(*(.vectors))
		_vectors_end = .;
    } > ram

    .text : {
        . = ALIGN(4);
        *(.text)
        *(.text.*)
    }  > ram

    .rodata : {
        . = ALIGN(4);
        /* Small RO data before large RO data */
        *(.srodata)
        *(.srodata.*)
        *(.rodata);
        *(.rodata.*)
    } > ram

    .data : {
        . = ALIGN(4);
        /* Small data before large data */
        *(.sdata)
        *(.sdata.*)
        *(.data);
        *(.data.*)
    } > ram

    .bss :
    {
        . = ALIGN(4);
        _bss_start = .;
        /* Small BSS before large BSS */
        *(.sbss)
        *(.sbss.*)
        *(.bss)
        *(.bss.*)
        *(COMMON)
        _bss_end = .;
    } > ram

	.heap : ALIGN(4)
	{
		*(.heap)
		KEEP(*(.heap))
		. = . + 300K;
	} > ram


    /* ensure there is enough room for stack */
    .stack : 
	{   
        . = . + 500k;
		. = ALIGN(4);
        _stack_start = .;
		KEEP(*(.stack))
		_stack_end = .;
	} > ram
    
    PROVIDE(_stack_size = SIZEOF(.stack));
	PROVIDE(_stack_end = ADDR(.stack));
	PROVIDE(_stack_start = _stack_end + _stack_size);

    PROVIDE(_heap_start = ADDR(.heap));
	PROVIDE(_heap_size = SIZEOF(.heap));
	PROVIDE(_heap_end = _heap_start + _heap_size - 1);

}


