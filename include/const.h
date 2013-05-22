//==========================================================================
//	const.h
//==========================================================================

#ifndef	_FASTC0RE_CONST_H_
#define	_FASTC0RE_CONST_H_

#define EXTERN extern

//Boolean
#define TRUE	1
#define FALSE	0


//GDT 和 IDT 中描述符的个数
#define	GDT_SIZE	128
#define	IDT_SIZE	256

//权限
#define	PRIVILEGE_KRNL	0
#define	PRIVILEGE_TASK	1
#define	PRIVILEGE_USER	3

//RPL
#define	RPL_KRNL	SA_RPL0
#define	RPL_TASK	SA_RPL1
#define	RPL_USER	SA_RPL3

//8259A中断控制端口
#define INT_M_CTL     0x20 
#define INT_M_CTLMASK 0x21
#define INT_S_CTL     0xA0
#define INT_S_CTLMASK 0xA1

//8253/8254 PIT (Programmable Interval Timer)
#define TIMER0         0x40
#define TIMER_MODE     0x43
#define RATE_GENERATOR 0x34
#define TIMER_FREQ     1193182L
#define HZ             100

//硬件中断
#define	NR_IRQ		16	/* Number of IRQs */
#define	CLOCK_IRQ	0
#define	KEYBOARD_IRQ	1
#define	CASCADE_IRQ	2	/* cascade enable for 2nd AT controller */
#define	ETHER_IRQ	3	/* default ethernet interrupt vector */
#define	SECONDARY_IRQ	3	/* RS232 interrupt vector for port 2 */
#define	RS232_IRQ	4	/* RS232 interrupt vector for port 1 */
#define	XT_WINI_IRQ	5	/* xt winchester */
#define	FLOPPY_IRQ	6	/* floppy disk */
#define	PRINTER_IRQ	7
#define	AT_WINI_IRQ	14	/* at winchester */

//系统调用
#define NR_SYS_CALL	1

#endif
