//==========================================================================
//	start.c
//==========================================================================

#include "type.h"
#include "const.h"
#include "protect.h"

void* memcpy(void* pDst, void* pSrc, int iSize);
void disp_str(char* str);

u8		gdt_ptr[6];
DESCRIPTOR	gdt[GDT_SIZE];


//--------------------------------------------------------------------------
//	cstart
//--------------------------------------------------------------------------

void cstart()
{
	disp_str("\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n--cstart-begins--\n");
	//将 LOADER 中的 GDT 复制到新的 GDT 中
	memcpy(&gdt,
		(void*)(*((u32*)(&gdt_ptr[2]))),
		*((u16*)(&gdt_ptr[0])) + 1
	      );
	u16* p_gdt_limit = (u16*)(&gdt_ptr[0]);
	u32* p_gdt_base  = (u32*)(&gdt_ptr[2]);

	*p_gdt_limit = GDT_SIZE * sizeof(DESCRIPTOR) - 1;
	*p_gdt_base  = (u32)&gdt;

	disp_str("--cstart-ends--\n");
}