	org 07c00h
;==========================================================
BaseOfStack		equ 07c00h	;堆栈基地址（栈底）

BaseOfLoader		equ 09000h	;Loader.bin加载段地址
OffsetOfLoader		equ 0100h	;Loader.bin加载偏移地址

RootDirSectors		equ 14		;根目录占用空间
SectorNoOfRootDirectory equ 19		;Root Directory第一扇区号
SectorNoOfFAT1		equ 1		;FAT表1 第一扇区号（BPB_RsvdSecCnt）
DeltaSectorNo		equ 17		;= BPB_RsvdSecCnt + (BPB_NumFATs * FATSz) - 2
;文件的开始Sector号 = DirEntry中的开始Sector号 + 根目录占用Sector数目 + DeltaSectorNo
;==========================================================

	jmp short LBL_START
	nop


	;FAT12磁盘头
	BS_OEMName	DB 'C0reFast'	;OEM String
	BPB_BytesPerSec	DW 512		;每扇区字节数
	BPB_SecPerClus	DB 1		;每簇扇区数
	BPB_RsvdSecCnt	DW 1		;Boot占用扇区数
	BPB_NumFATs 	DB 2		;FAT表数
	BPB_RootEntCnt	DW 224		;根目录最大文件数
	BPB_TotSec16	DW 2880		;逻辑扇区总数
	BPB_Media	DB 0xF0		;媒体描述符
	BPB_FATSz16	DW 9		;每FAT扇区数
	BPB_SecPerTrk	DW 18		; 每磁道扇区数
	BPB_NumHeads	DW 2		;磁头数（记录面）
	BPB_HideSec	DD 0		;隐藏扇区数
	BPB_TotSec32 	DD 0		;
	BS_DrvNum	DB 0		;中断13的驱动器号
	BS_Reserved	DB 0		;保留
	BS_BootSig	DB 29h		;扩展引导标记（29h）
	BS_VolID 	DD 0		;卷序列号
	BS_VolLab	DB 'FastC0re0.1';卷标，11字节
	BS_FileSysType	DB 'FAT12   '	;文件系统类型，8字节
	
LBL_START:
	mov	ax, cs
	mov	ds, ax
	mov	es, ax
	mov	ss, ax
	mov	sp, BaseOfStack
	;清屏
	mov	ax, 0600h		;AH=6, AL=0
	mov	bx, 0700h		;黑底白字(BL = 07h)
	mov	cx, 0			;左上角: (0, 0)
	mov	dx, 0184fh		;右下角: (80, 50)
	int	10h			;int 10h

	mov	dh, 0			;"Booting.."
	call	DispStr			;显示字符串

	xor	ah, ah	;
	xor	dl, dl	;软驱复位
	int	13h	;

;在A盘根目录寻找Loader.bin
	mov	word [wSectorNo], SectorNoOfRootDirectory
LBL_SEARCH_IN_ROOT_DIR_BEGIN:
	cmp	word [wRootDirSizeForLoop], 0
	jz	LBL_NO_LOADER
	dec	word [wRootDirSizeForLoop]
	mov	ax, BaseOfLoader
	mov	es, ax
	mov	bx, OffsetOfLoader
	mov	ax, [wSectorNo]
	mov	cl, 1
	call	ReadSector

	mov	si, LoaderFileName
	mov	di, OffsetOfLoader
	cld
	mov	dx, 10h
LBL_SEARCH_FOR_LOADER:
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
;要找的LOADER.BIN
LBL_GO_ON:
	inc	di
	jmp	LBL_CMP_FILENAME

LBL_DIFFERENT:
	and	di, 0FFE0h
	add	di, 20h
	mov	si, LoaderFileName
	jmp	LBL_SEARCH_FOR_LOADER

LBL_GOTO_NEXT_SECTOR_IN_ROOT_DIR:
	add	word [wSectorNo], 1
	jmp	LBL_SEARCH_IN_ROOT_DIR_BEGIN

LBL_NO_LOADER:
	mov	dh, 2
	call	DispStr
	jmp	$

LBL_FILENAME_FOUND:
	mov	ax, RootDirSectors
	and	di, 0FFE0h
	add	di, 01Ah
	mov	cx, word [es:di]
	push	cx
	add	cx, ax
	add	cx, DeltaSectorNo
	mov	ax, BaseOfLoader
	mov	es, ax
	mov	bx, OffsetOfLoader
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
	mov	dh, 1
	call	DispStr

;**********************************************************
	jmp	BaseOfLoader:OffsetOfLoader

;**********************************************************



;==========================================================
;变量
;----------------------------------------------------------
wRootDirSizeForLoop	dw	RootDirSectors	;根目录占用扇区数，循环中递减至0
wSectorNo		dw	0		;要读取的扇区号
bOdd			db	0		;奇偶

;==========================================================
;字符串
;----------------------------------------------------------
LoaderFileName		db	"LOADER  BIN", 0	; Loader.bin文件名
; 为简化代码, 下面每个字符串的长度均为 MsgLength
MsgLength		equ	9
BootMsg			db	"Booting  "; 9字节, 不够则用空格补齐. 序号 0
MsgReady		db	"Ready.   "; 9字节, 不够则用空格补齐. 序号 1
MsgError		db	"No LOADER"; 9字节, 不够则用空格补齐. 序号 2
;==========================================================

;----------------------------------------------------------------------------
; 函数名: DispStr
;----------------------------------------------------------------------------
; 作用:
;	显示一个字符串, 函数开始时 dh 中应该是字符串序号(0-based)
DispStr:
	mov	ax, MsgLength
	mul	dh
	add	ax, BootMsg
	mov	bp, ax			; ┓
	mov	ax, ds			; ┣ ES:BP = 串地址
	mov	es, ax			; ┛
	mov	cx, MsgLength		; CX = 串长度
	mov	ax, 01301h		; AH = 13,  AL = 01h
	mov	bx, 0007h		; 页号为0(BH = 0) 黑底白字(BL = 07h)
	mov	dl, 0
	int	10h			; int 10h
	ret


;----------------------------------------------------------
; 函数名: ReadSector
;----------------------------------------------------------
; 作用:
;	从第 ax 个 Sector 开始, 将 cl 个 Sector 读入 es:bx 中
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

;----------------------------------------------------------
; 函数名: GetFATEntry
;----------------------------------------------------------
; 作用:
;	找到序号为 ax 的 Sector 在 FAT 中的条目, 结果放在 ax 中
;	需要注意的是, 中间需要读 FAT 的扇区到 es:bx 处, 所以函数一开始保存了 es 和 bx
GetFATEntry:
	push	es
	push	bx
	push	ax
	mov	ax, BaseOfLoader; `.
	sub	ax, 0100h	;  | 在 BaseOfLoader 后面留出 4K 空间用于存放 FAT
	mov	es, ax		; /
	pop	ax
	mov	byte [bOdd], 0
	mov	bx, 3
	mul	bx			; dx:ax = ax * 3
	mov	bx, 2
	div	bx			; dx:ax / 2  ==>  ax <- 商, dx <- 余数
	cmp	dx, 0
	jz	LBL_EVEN
	mov	byte [bOdd], 1
LBL_EVEN:;偶数
	; 现在 ax 中是 FATEntry 在 FAT 中的偏移量,下面来
	; 计算 FATEntry 在哪个扇区中(FAT占用不止一个扇区)
	xor	dx, dx			
	mov	bx, [BPB_BytesPerSec]
	div	bx ; dx:ax / BPB_BytsPerSec
		   ;  ax <- 商 (FATEntry 所在的扇区相对于 FAT 的扇区号)
		   ;  dx <- 余数 (FATEntry 在扇区内的偏移)。
	push	dx
	mov	bx, 0 ; bx <- 0 于是, es:bx = (BaseOfLoader - 100):00
	add	ax, SectorNoOfFAT1 ; 此句之后的 ax 就是 FATEntry 所在的扇区号
	mov	cl, 2
	call	ReadSector ; 读取 FATEntry 所在的扇区, 一次读两个, 避免在边界
			   ; 发生错误, 因为一个 FATEntry 可能跨越两个扇区
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
;----------------------------------------------------------

times 	510-($-$$)	db	0	; 填充剩下的空间，使生成的二进制代码恰好为512字节
dw 	0xaa55				; 结束标志
