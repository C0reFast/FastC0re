;===========================================================================
;	load.inc
;===========================================================================

BaseOfLoader		equ 	09000h	;Loader.bin加载段地址
OffsetOfLoader		equ 	0100h	;Loader.bin加载偏移地址

BaseOfLoaderPhyAddr	equ	BaseOfLoader * 10h	;Loader.bin加载物理地址 (= BaseOfLoader * 10h)


BaseOfKernelFile	equ	08000h	;kernel.bin加载段地址
OffsetOfKernelFile	equ	0h	;kernel.bin加载偏移地址

BaseOfKernelFilePhyAddr	equ	BaseOfKernelFile * 10h
KernelEntryPointPhyAddr	equ	030400h	; 注意：1、必须与 MAKEFILE 中参数 -Ttext 的值相等!!

PageDirBase		equ	200000h	; 页目录开始地址: 2M
PageTblBase		equ	201000h	; 页表开始地址:	2M + 4K

