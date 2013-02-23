;===========================================================================
;	fat12hdr.inc
;===========================================================================


;FAT12磁盘头
;---------------------------------------------------------------------------
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
;---------------------------------------------------------------------------

; 基于 FAT12 头的一些常量定义
;---------------------------------------------------------------------------
	FATSz			equ 9		; BPB_FATSz16
	RootDirSectors		equ 14		;根目录占用空间
	SectorNoOfRootDirectory equ 19		;Root Directory第一扇区号
	SectorNoOfFAT1		equ 1		;FAT表1 第一扇区号（BPB_RsvdSecCnt）
	DeltaSectorNo		equ 17		;= BPB_RsvdSecCnt + (BPB_NumFATs * FATSz) - 2
						;文件的开始Sector号 = DirEntry中的开始Sector号 + 根目录占用Sector数目 + DeltaSectorNo
;---------------------------------------------------------------------------
