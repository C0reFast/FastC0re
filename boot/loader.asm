;===========================================================================
;	loader.asm
;===========================================================================


org	0100h
	
	jmp	LBL_START
	
%include "fat12hdr.inc"
%include "load.inc"
%include "pm.inc"

;GDT------------------------------------------------------------------------
LBL_GDT:	  Descriptor 0,	      0, 0		
LBL_DESC_FLAT_C:  Descriptor 0,	0fffffh, DA_CR |DA_32|DA_LIMIT_4K
LBL_DESC_FLAT_RW: Descriptor 0,	0fffffh, DA_DRW|DA_32|DA_LIMIT_4K
LBL_DESC_VIDEO:   Descriptor 0B8000h,	 0ffffh, DA_DRW|DA_DPL3
;GDT------------------------------------------------------------------------
GdtLen	equ	$ - LBL_GDT
GdtPtr	dw	GdtLen - 1
		dd	BaseOfLoaderPhyAddr + LBL_GDT

;GDT选择子------------------------------------------------------------------
SelectorFlatC	equ	LBL_DESC_FLAT_C  - LBL_GDT
SelectorFlatRW	equ	LBL_DESC_FLAT_RW - LBL_GDT
SelectorVideo	equ	LBL_DESC_VIDEO   - LBL_GDT
;GDT选择子------------------------------------------------------------------

BaseOfStack	equ	0100h

LBL_START:
	mov	ax, cs
	mov	ds, ax
	mov	es, ax
	mov	ss, ax
	mov	sp, BaseOfStack

	mov	dh, 0
	call	DispStrRM

	;得到内存总数
	mov	ebx, 0
	mov	di, _MemChkBuf
.MemChkLoop:
	mov	eax, 0E820h
	mov	ecx, 20
	mov	edx, 0534D4150h
	int	15h
	jc	.MemChkFail
	add	di, 20
	inc	dword [_dwMCRNumber]
	cmp	ebx, 0
	jne	.MemChkLoop
	jmp	.MemChkOK
.MemChkFail:
	mov	dword [_dwMCRNumber], 0
.MemChkOK:

;在A盘根目录寻找kernel.bin
	mov	word [wSectorNo], SectorNoOfRootDirectory
	xor	ah, ah	;
	xor	dl, dl	;软驱复位
	int	13h	;

LBL_SEARCH_IN_ROOT_DIR_BEGIN:
	cmp	word [wRootDirSizeForLoop], 0
	jz	LBL_NO_KERNEL
	dec	word [wRootDirSizeForLoop]
	mov	ax, BaseOfKernelFile
	mov	es, ax
	mov	bx, OffsetOfKernelFile
	mov	ax, [wSectorNo]
	mov	cl, 1
	call	ReadSector

	mov	si, KernelFileName
	mov	di, OffsetOfKernelFile
	cld
	mov	dx, 10h
LBL_SEARCH_FOR_KERNEL:
	cmp	dx, 0
	jz	LBL_GOTO_NEXT_SECTOR_IN_ROOT_DIR
	dec	dx
	mov	cx, 11
LBL_CMP_FILENAME:
	cmp	cx, 0
	jz	LBL_FILENAME_FOUND
	dec	cx
	lodsb
	cmp	al, byte [es:di]
	jz	LBL_GO_ON
	jmp	LBL_DIFFERENT
LBL_GO_ON:
	inc	di
	jmp	LBL_CMP_FILENAME

LBL_DIFFERENT:
	and	di, 0FFE0h
	add	di, 20h
	mov	si, KernelFileName 
	jmp	LBL_SEARCH_FOR_KERNEL

LBL_GOTO_NEXT_SECTOR_IN_ROOT_DIR:
	add	word [wSectorNo], 1
	jmp	LBL_SEARCH_IN_ROOT_DIR_BEGIN

LBL_NO_KERNEL:
	mov	dh, 2
	call	DispStrRM
	jmp	$

LBL_FILENAME_FOUND:
	mov	ax, RootDirSectors
	and	di, 0FFF0h

	push	eax
	mov	eax, [es : di +01Ch]
	mov	dword [dwKernelSize], eax
	pop	eax

	add	di, 01Ah
	mov	cx, word [es:di]
	push	cx
	add	cx, ax
	add	cx, DeltaSectorNo
	mov	ax, BaseOfKernelFile
	mov	es, ax
	mov	bx, OffsetOfKernelFile
	mov	ax, cx

LBL_GO_ON_LOADING:
	push	ax
	push	bx
	mov	ah, 0Eh
	mov	al, '.'
	mov	bl, 0Fh
	int	10h
	pop	bx
	pop	ax

	mov	cl, 1
	call	ReadSector
	pop	ax
	call	GetFATEntry
	cmp	ax, 0FFFh
	jz	LBL_FILE_LOADED
	push	ax
	mov	dx, RootDirSectors
	add	ax, dx
	add	ax, DeltaSectorNo
	add	bx, [BPB_BytesPerSec]
	jmp	LBL_GO_ON_LOADING

LBL_FILE_LOADED:
	call	KillMotor

	mov	dh, 1
	call	DispStrRM

;准备跳入保护模式-----------------------------------------------------------

;加载GDTR
	lgdt	[GdtPtr]
;关中断
	cli
;打开地址线A20
	in	al, 92h
	or	al, 00000010b
	out	92h, al
;准备切换到保护模式
	mov	eax, cr0
	or	eax, 1
	mov	cr0, eax
;进入保护模式
	jmp	dword SelectorFlatC:(BaseOfLoaderPhyAddr+LBL_PM_START)
;-------------------------------------------------------------------------


;===========================================================================
;变量
;---------------------------------------------------------------------------
wRootDirSizeForLoop	dw	RootDirSectors	;根目录占用扇区数
wSectorNo		dw	0		;要读取的扇区号
bOdd			db	0		;奇偶
dwKernelSize		dd	0		;kernel.bin大小

;===========================================================================
;字符串
;---------------------------------------------------------------------------
KernelFileName		db	"KERNEL  BIN", 0	; kernel.bin文件名
; 为简化代码, 下面每个字符串的长度均为 MsgLength
MsgLength		equ	9
LoadMsg			db	"Loading.."; 9字节, 不够则用空格补齐. 序号 0
MsgReady		db	"Ready.   "; 9字节, 不够则用空格补齐. 序号 1
MsgError		db	"No KERNEL"; 9字节, 不够则用空格补齐. 序号 2
;===========================================================================

;---------------------------------------------------------------------------
; 函数名: DispStrRM
;---------------------------------------------------------------------------
DispStrRM:
	mov	ax, MsgLength
	mul	dh
	add	ax, LoadMsg
	mov	bp, ax			; ┓
	mov	ax, ds			; ┣ ES:BP = 串地址
	mov	es, ax			; ┛
	mov	cx, MsgLength		; CX = 串长度
	mov	ax, 01301h		; AH = 13,  AL = 01h
	mov	bx, 0007h		; 页号为0(BH = 0) 黑底白字(BL = 07h)
	mov	dl, 0
	add	dh, 3
	int	10h			; int 10h
	ret


;---------------------------------------------------------------------------
; 函数名: ReadSector
;---------------------------------------------------------------------------
ReadSector:
	push	bp
	mov	bp, sp
	sub	esp, 2			; 辟出两个字节的堆栈区域保存要读的扇区数: byte [bp-2]

	mov	byte [bp-2], cl
	push	bx			; 保存 bx
	mov	bl, [BPB_SecPerTrk]	; bl: 除数
	div	bl			; y 在 al 中, z 在 ah 中
	inc	ah			; z ++
	mov	cl, ah			; cl <- 起始扇区号
	mov	dh, al			; dh <- y
	shr	al, 1			; y >> 1 (其实是 y/BPB_NumHeads, 这里BPB_NumHeads=2)
	mov	ch, al			; ch <- 柱面号
	and	dh, 1			; dh & 1 = 磁头号
	pop	bx			; 恢复 bx
	; 至此, "柱面号, 起始扇区, 磁头号" 全部得到
	mov	dl, [BS_DrvNum]		; 驱动器号 (0 表示 A 盘)
.GoOnReading:
	mov	ah, 2			; 读
	mov	al, byte [bp-2]		; 读 al 个扇区
	int	13h
	jc	.GoOnReading		; 如果读取错误 CF 会被置为 1, 这时就不停地读, 直到正确为止

	add	esp, 2
	pop	bp

	ret

;---------------------------------------------------------------------------
; 函数名: GetFATEntry
;---------------------------------------------------------------------------
GetFATEntry:
	push	es
	push	bx
	push	ax
	mov	ax, BaseOfKernelFile
	sub	ax, 0100h
	mov	es, ax
	pop	ax
	mov	byte [bOdd], 0
	mov	bx, 3
	mul	bx
	mov	bx, 2
	div	bx
	cmp	dx, 0
	jz	LBL_EVEN
	mov	byte [bOdd], 1
LBL_EVEN:;偶数
	xor	dx, dx			
	mov	bx, [BPB_BytesPerSec]
	div	bx 
	push	dx
	mov	bx, 0
	add	ax, SectorNoOfFAT1
	mov	cl, 2
	call	ReadSector 
	pop	dx
	add	bx, dx
	mov	ax, [es:bx]
	cmp	byte [bOdd], 1
	jnz	LBL_EVEN_2
	shr	ax, 4
LBL_EVEN_2:
	and	ax, 0FFFh

LBL_GET_FAT_ENRY_OK:

	pop	bx
	pop	es
	ret
;---------------------------------------------------------------------------

;---------------------------------------------------------------------------
; 函数名: KillMotor
;---------------------------------------------------------------------------
KillMotor:
	push	dx
	mov	dx, 03F2h
	mov	al, 0
	out	dx, al
	pop	dx
	ret
;---------------------------------------------------------------------------


;从此以后代码在保护模式下运行-----------------------------------------------
[SECTION .s32]

ALIGN	32
[BITS	32]

LBL_PM_START:
	mov	ax, SelectorVideo
	mov	gs, ax
	mov	ax, SelectorFlatRW
	mov	ds, ax
	mov	es, ax
	mov	fs, ax
	mov	ss, ax
	mov	esp, TopOfStack

	push	szMemChkTitle
	call	DispStr
	add	esp, 4

	call	DispMemInfo
	call	SetupPaging

	call	InitKernel

;***********************************************************************
	jmp	SelectorFlatC:KernelEntryPointPhyAddr	;正式进入内核  *
;***********************************************************************


;---------------------------------------------------------------------------
;显示AL中的数字
;---------------------------------------------------------------------------
DispAL:
	push	ecx
	push	edx
	push	edi

	mov	edi, [dwDispPos]

	mov	ah, 0Fh
	mov	dl, al
	shr	al, 4
	mov	ecx, 2
.begin:
	and	al, 01111b
	cmp	al, 9
	ja	.1
	add	al, '0'
	jmp	.2
.1:
	sub	al, 0Ah
	add	al, 'A'
.2:
	mov	[gs:edi],ax
	add	edi, 2

	mov	al, dl
	loop	.begin

	mov	[dwDispPos], edi

	pop	edi
	pop	edx
	pop	ecx

	ret
;---------------------------------------------------------------------------

;---------------------------------------------------------------------------
;显示一个整形数
;---------------------------------------------------------------------------
DispInt:
	mov	eax, [esp + 4]
	shr	eax, 24
	call	DispAL

	mov	eax, [esp + 4]
	shr	eax, 16
	call	DispAL

	mov	eax, [esp + 4]
	shr	eax, 8
	call	DispAL

	mov	eax, [esp + 4]
	call	DispAL

	mov	ah, 07h
	mov	al, 'h'
	push	edi
	mov	edi, [dwDispPos]
	mov	[gs:edi], ax
	add	edi, 4
	mov	[dwDispPos], edi
	pop	edi

	ret
;---------------------------------------------------------------------------

;---------------------------------------------------------------------------
;显示一个字符串
;---------------------------------------------------------------------------
DispStr:
	push	ebp
	mov	ebp, esp
	push	ebx
	push	esi
	push	edi

	mov	esi, [ebp + 8]
	mov	edi, [dwDispPos]
	mov	ah, 0Fh
.1:
	lodsb
	test	al, al
	jz	.2
	cmp	al, 0Ah	;是否是回车
	jnz	.3
	push	eax
	mov	eax, edi
	mov	bl, 160
	div	bl
	and	eax, 0FFh
	inc	eax
	mov	bl, 160
	mul	bl
	mov	edi, eax
	pop	eax
	jmp	.1
.3:
	mov	[gs:edi], ax
	add	edi, 2
	jmp	.1
.2:
	mov	[dwDispPos], edi

	pop	edi
	pop	esi
	pop	ebx
	pop	ebp
	
	ret
;---------------------------------------------------------------------------

;---------------------------------------------------------------------------
;换行
;---------------------------------------------------------------------------
DispReturn:
	push	szReturn
	call	DispStr
	add	esp, 4

	ret
;---------------------------------------------------------------------------


;---------------------------------------------------------------------------
;内存拷贝 void* MemCpy(void* es:pDest, void* ds:pSrc, int iSize)
;---------------------------------------------------------------------------
MemCpy:
	push	ebp
	mov	ebp, esp

	push	esi
	push	edi
	push	ecx

	mov	edi, [ebp + 8]	;Destination
	mov	esi, [ebp + 12]	;Source
	mov	ecx, [ebp + 16]	;Counter

.1:
	cmp	ecx, 0
	jz	.2

	mov	al, [ds:esi]
	inc	esi

	mov	byte [es:edi], al
	inc	edi

	dec	ecx
	jmp	.1
.2:
	mov	eax, [ebp + 8]	;返回值

	pop	ecx
	pop	edi
	pop	esi
	mov	esp, ebp
	pop	ebp

	ret
;---------------------------------------------------------------------------


;---------------------------------------------------------------------------
;显示内存信息
;---------------------------------------------------------------------------
DispMemInfo:
	push	esi
	push	edi
	push	ecx

	mov	esi, MemChkBuf
	mov	ecx, [dwMCRNumber]
.loop:
	mov	edx, 5
	mov	edi, ARDStruct
.1:
	push	dword [esi]
	call	DispInt
	pop	eax
	stosd
	add	esi, 4
	dec	edx
	cmp	edx, 0
	jnz	.1
	call	DispReturn
	cmp	dword [dwType], 1
	jne	.2
	mov	eax, [dwBaseAddrLow]
	add	eax, [dwLengthLow]
	cmp	eax, [dwMemSize]
	jb	.2
	mov	[dwMemSize], eax
.2:
	loop	.loop

	call	DispReturn
	push	szRAMSize
	call	DispStr
	add	esp, 4

	push	dword [dwMemSize]
	call	DispInt
	add	esp, 4

	pop	ecx
	pop	edi
	pop	esi
	ret
;---------------------------------------------------------------------------


;---------------------------------------------------------------------------
;启动分页机制
;---------------------------------------------------------------------------
SetupPaging:
	;根据内存大小计算应初始化多少PDE以及多少页表
	xor	edx, edx
	mov	eax, [dwMemSize]
	mov	ebx, 400000h	;4M
	div	ebx
	mov	ecx, eax	;页表个数
	test	edx, edx
	jz	.no_remainder
	inc	ecx
.no_remainder:
	push	ecx
	;初始化页目录
	mov	ax, SelectorFlatRW
	mov	es, ax
	mov	edi, PageDirBase
	xor	eax, eax
	mov	eax, PageTblBase|PG_P|PG_USU|PG_RWW
.1:
	stosd
	add	eax, 4096
	loop	.1
	
	;初始化页表
	pop	eax
	mov	ebx, 1024
	mul	ebx
	mov	ecx, eax
	mov	edi, PageTblBase
	xor	eax, eax
	mov	eax, PG_P|PG_USU|PG_RWW
.2:
	stosd
	add	eax, 4096
	loop	.2

	mov	eax, PageDirBase
	mov	cr3, eax
	mov	eax, cr0
	or	eax, 80000000h
	mov	cr0, eax
	jmp	short .3
.3:
	nop
	
	ret
;---------------------------------------------------------------------------


;---------------------------------------------------------------------------
;内核初始化，将Kernel.bin内容整理后放入新位置
;---------------------------------------------------------------------------
InitKernel:
	xor	esi, esi
	mov	cx, word [BaseOfKernelFilePhyAddr + 2Ch]
	movzx	ecx, cx
	mov	esi, [BaseOfKernelFilePhyAddr + 1Ch]
	add	esi, BaseOfKernelFilePhyAddr
.Begin:
	mov	eax, [esi + 0]
	cmp	eax, 0
	jz	.NoAction
	push	dword [esi + 010h]
	mov	eax, [esi + 04h]
	add	eax, BaseOfKernelFilePhyAddr
	push	eax
	push	dword [esi + 08h]
	call	MemCpy
	add	esp, 12
.NoAction:
	add	esi, 020h
	dec	ecx
	jnz	.Begin

	ret
;---------------------------------------------------------------------------


























; SECTION .data1------------------------------------------------------------
[SECTION .data1]

ALIGN	32

LBL_DATA:
; 实模式下使用这些符号
; 字符串
_szMemChkTitle:		db	"BaseAddrL BaseAddrH LengthLow LengthHigh   Type", 0Ah, 0
_szRAMSize:		db	"RAM size:", 0
_szReturn:		db	0Ah, 0
;变量
_dwMCRNumber:		dd	0	; Memory Check Result
_dwDispPos:		dd	(80 * 6 + 0) * 2	; 屏幕第 6 行, 第 0 列。
_dwMemSize:		dd	0
;-------------------------------------------------------------------
_ARDStruct:			; Address Range Descriptor Structure
	_dwBaseAddrLow:		dd	0
	_dwBaseAddrHigh:	dd	0
	_dwLengthLow:		dd	0
	_dwLengthHigh:		dd	0
	_dwType:		dd	0
;-------------------------------------------------------------------
_MemChkBuf:	times	256	db	0

;保护模式下使用这些符号
szMemChkTitle		equ	BaseOfLoaderPhyAddr + _szMemChkTitle
szRAMSize		equ	BaseOfLoaderPhyAddr + _szRAMSize
szReturn		equ	BaseOfLoaderPhyAddr + _szReturn
dwDispPos		equ	BaseOfLoaderPhyAddr + _dwDispPos
dwMemSize		equ	BaseOfLoaderPhyAddr + _dwMemSize
dwMCRNumber		equ	BaseOfLoaderPhyAddr + _dwMCRNumber
;--------------------------------------------------------------------
ARDStruct		equ	BaseOfLoaderPhyAddr + _ARDStruct
	dwBaseAddrLow	equ	BaseOfLoaderPhyAddr + _dwBaseAddrLow
	dwBaseAddrHigh	equ	BaseOfLoaderPhyAddr + _dwBaseAddrHigh
	dwLengthLow	equ	BaseOfLoaderPhyAddr + _dwLengthLow
	dwLengthHigh	equ	BaseOfLoaderPhyAddr + _dwLengthHigh
	dwType		equ	BaseOfLoaderPhyAddr + _dwType
;--------------------------------------------------------------------
MemChkBuf		equ	BaseOfLoaderPhyAddr + _MemChkBuf


; 堆栈就在数据段的末尾
StackSpace:	times	1000h	db	0
TopOfStack	equ	BaseOfLoaderPhyAddr + $	; 栈顶
;------------------------------------------------------------------------------------------------------------------

