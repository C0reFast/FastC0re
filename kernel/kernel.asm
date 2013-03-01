;===========================================================================
;	kernel.asm
;===========================================================================

SELECTOR_KERNEL_CS	equ	8

extern	cstart	;导入函数
extern	gdt_ptr	;导入全局变量

[section .bss]
StackSpace	resb	2 * 1024
StackTop:	;栈顶

	
[section .text]	;

global	_start	;导出_start

_start:
	mov	esp, StackTop	;堆栈在bss段中，将esp从Loader移到Kernel

	sgdt	[gdt_ptr]
	call	cstart
	lgdt	[gdt_ptr]

	jmp	SELECTOR_KERNEL_CS:csinit

csinit:
	push	0
	popfd

	hlt
