//==========================================================================
//	proto.h
//==========================================================================


//klib.asm
void	out_byte(u16 port, u8 value);
u8	in_byte(u16 port);
void	disp_str(char* info);
void	disp_color_str(char* info, int color);

//protect.c
void	init_prot();
u32	seg2phys(u16 seg);

//klib.c
void	delay(int time);

//kernel.asm
void	restart();

//main.c
void 	TestA();
void 	TestB();
void 	TestC();

//i8259.c
void put_irq_handler(int irq, irq_handler handler);
void spurious_irq(int irq);

//clock.c
void clock_handler(int irq);


/* 以下是系统调用相关 */

//proc.c
int     sys_get_ticks();        /* sys_call */

//syscall.asm
void    sys_call();             /* int_handler */
int     get_ticks();

