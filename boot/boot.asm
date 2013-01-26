org 07c00h

	jmp short LBL_START
	nop

	;FAT12文件头
	BS_OEMName	DB 'C0reFast'	;OEM String
	BPB_BytePerSec	DW 512		;每扇区字节数
	BPB_SecPerClus	DB 1		;每簇扇区数
	BPB_RsvdSecCnt	DW 1		;Boot占用扇区数
	BPB_NumFATs 	DB 2		;FAT表数
	BPB_RootEntCnt	DW 224		;根目录最大文件数
	BPB_TotSec16	DW 2280		;逻辑扇区总数
	BPB_Media	DB 0xF0		;媒体描述符
	BPB_FATSz16	DW 9		;每FAT扇区数
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
	Call	DispStr			;调用显示字符串
	jmp	$			;死循环
DispStr:
	mov	ax, BootMsg
	mov	bp, ax			; ES:BP = 串地址
	mov	cx, 16			; CX = 串长度
	mov	ax, 01301h		; AH = 13,  AL = 01h
	mov	bx, 000ch		; 页号为0(BH = 0) 黑底红字(BL = 0Ch,高亮)
	mov	dl, 0
	int	10h			; int 10h
	ret
BootMsg:		db	"Hello, FastC0re!"
times 	510-($-$$)	db	0	; 填充剩下的空间，使生成的二进制代码恰好为512字节
dw 	0xaa55				; 结束标志
