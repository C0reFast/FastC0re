//==========================================================================
//  proc.h
//==========================================================================

#ifndef _FASTC0RE_PROC_H_
#define _FASTC0RE_PROC_H_

typedef struct s_stackframe {
    u32 gs; 
    u32 fs;
    u32 es;
    u32 ds;
    u32 edi;
    u32 esi;
    u32 ebp;
    u32 kernel_esp;
    u32 ebx;    
    u32 edx;
    u32 ecx;
    u32 eax;
    u32 retaddr;
    u32 eip;
    u32 cs;
    u32 eflags;
    u32 esp;
    u32 ss;
}STACK_FRAME;

typedef struct s_proc {
    STACK_FRAME regs;          //process registers saved in stack frame

    u16 ldt_sel;               //gdt selector giving ldt base and limit 
    DESCRIPTOR ldts[LDT_SIZE]; //local descriptors for code and data

    int ticks;                 //remained ticks
    int priority;

    u32 pid;                   //process id passed in from MM
    char p_name[16];           //name of the process
}PROCESS;

typedef struct s_task {
    task_f  initial_eip;
    int stacksize;
    char    name[32];
}TASK;

//进程数量
#define NR_TASKS    3

//进程栈
#define STACK_SIZE_TESTA    0x8000
#define STACK_SIZE_TESTB    0x8000
#define STACK_SIZE_TESTC    0x8000

#define STACK_SIZE_TOTAL    (STACK_SIZE_TESTA + \
                STACK_SIZE_TESTB + \
                STACK_SIZE_TESTC)

#endif
