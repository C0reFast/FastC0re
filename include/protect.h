//==========================================================================
//	protect.h
//==========================================================================

#ifndef	_FASTC0RE_PROTECT_H_
#define	_FASTC0RE_PROTECT_H_

/* 存储段描述符/系统段描述符 */
typedef struct s_descriptor	//共 8 个字节
{
	u16	limit_low;
	u16	base_low;
	u8	base_mid;
	u8	attr1;
	u8	limit_high_attr2;
	u8	base_high;
}DESCRIPTOR;



#endif