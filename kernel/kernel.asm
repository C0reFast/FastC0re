;===========================================================================
;   kernel.asm
;===========================================================================

%include "sconst.inc"

;导入函数
extern  cstart
extern  kernel_main
extern  exception_handler
extern  spurious_irq
extern  clock_handler
extern  disp_str
extern  delay
extern  irq_table

;导入全局变量
extern  gdt_ptr
extern  idt_ptr
extern  p_proc_ready
extern  tss
extern  disp_pos
extern  k_reenter
extern  sys_call_table

bits 32

[SECTION .data]
clock_int_msg   db  "^", 0

[section .bss]
StackSpace  resb    2 * 1024
StackTop:   ;栈顶

    
[section .text] ;

global  _start  ;导出_start

global  restart
global  sys_call

global  divide_error
global  single_step_exception
global  nmi
global  breakpoint_exception
global  overflow
global  bounds_check
global  inval_opcode
global  copr_not_available
global  double_fault
global  copr_seg_overrun
global  inval_tss
global  segment_not_present
global  stack_exception
global  general_protection
global  page_fault
global  copr_error
global  hwint00
global  hwint01
global  hwint02
global  hwint03
global  hwint04
global  hwint05
global  hwint06
global  hwint07
global  hwint08
global  hwint09
global  hwint10
global  hwint11
global  hwint12
global  hwint13
global  hwint14
global  hwint15

_start:
    mov esp, StackTop   ;堆栈在bss段中，将esp从Loader移到Kernel
    
    mov dword [disp_pos], 0
    sgdt    [gdt_ptr]   ;cstart()用到
    call    cstart
    lgdt    [gdt_ptr]

    lidt    [idt_ptr]

    jmp SELECTOR_KERNEL_CS:csinit

csinit:
    xor eax, eax
    mov ax, SELECTOR_TSS
    ltr ax
    jmp kernel_main


;中断和异常--硬件中断
;-----------------------------------------
%macro  hwint_master    1
    call    save
    in  al, INT_M_CTLMASK
    or  al, (1 << %1)
    out INT_M_CTLMASK, al
    mov al, EOI
    out INT_M_CTL, al
    sti
    push    %1
    call    [irq_table + 4 * %1]
    pop ecx
    cli
    in  al, INT_M_CTLMASK
    and al, ~(1 << %1)
    out INT_M_CTLMASK, al
    ret
%endmacro
;-----------------------------------------

AlIGN   16
hwint00:
    hwint_master    0

AlIGN   16
hwint01:
    hwint_master    1

AlIGN   16
hwint02:
    hwint_master    2

AlIGN   16
hwint03:
    hwint_master    3

AlIGN   16
hwint04:
    hwint_master    4

AlIGN   16
hwint05:
    hwint_master    5

AlIGN   16
hwint06:
    hwint_master    6

AlIGN   16
hwint07:
    hwint_master    7

;-----------------------------------------
%macro  hwint_slave 1
    push    %1
    call    spurious_irq
    add esp, 4
    hlt
%endmacro
;-----------------------------------------

AlIGN   16
hwint08:
    hwint_slave 8

AlIGN   16
hwint09:
    hwint_slave 9

AlIGN   16
hwint10:
    hwint_slave 10

AlIGN   16
hwint11:
    hwint_slave 11

AlIGN   16
hwint12:
    hwint_slave 12

AlIGN   16
hwint13:
    hwint_slave 13

AlIGN   16
hwint14:
    hwint_slave 14

AlIGN   16
hwint15:
    hwint_slave 15


;中断和异常--异常
divide_error:
    push    0xFFFFFFFF
    push    0
    jmp exception

single_step_exception:
    push    0xFFFFFFFF
    push    1
    jmp exception

nmi:
    push    0xFFFFFFFF
    push    2
    jmp exception

breakpoint_exception:
    push    0xFFFFFFFF
    push    3
    jmp exception

overflow:
    push    0xFFFFFFFF
    push    4
    jmp exception

bounds_check:
    push    0xFFFFFFFF
    push    5
    jmp exception

inval_opcode:
    push    0xFFFFFFFF
    push    6
    jmp exception

copr_not_available:
    push    0xFFFFFFFF
    push    7
    jmp exception

double_fault:
    push    8
    jmp exception

copr_seg_overrun:
    push    0xFFFFFFFF
    push    9
    jmp exception

inval_tss:
    push    10
    jmp exception

segment_not_present:
    push    11
    jmp exception

stack_exception:
    push    12
    jmp exception

general_protection:
    push    13
    jmp exception

page_fault:
    push    14
    jmp exception

copr_error:
    push    0xFFFFFFFF
    push    16
    jmp exception


exception:
    call    exception_handler
    add esp, 4*2
    hlt

;---------------------------------------------------------------------------
;   save
;---------------------------------------------------------------------------
save:
    pushad
    push    ds
    push    es
    push    fs
    push    gs
    mov     dx, ss
    mov     ds, dx
    mov     es, dx

    mov     esi, esp

    inc     dword [k_reenter]
    cmp     dword [k_reenter], 0
    jne     .1
    mov     esp, StackTop

    push    restart
    jmp     [esi + RETADR - P_STACKBASE]
.1:
    push    restart_reenter
    jmp     [esi + RETADR - P_STACKBASE]

;---------------------------------------------------------------------------
;   sys_call
;---------------------------------------------------------------------------
sys_call:
    call    save

    sti

    call    [sys_call_table + eax * 4]
    mov     [esi + EAXREG - P_STACKBASE], eax

    cli

    ret

;---------------------------------------------------------------------------
;   restart
;---------------------------------------------------------------------------
restart:
    mov     esp, [p_proc_ready]
    lldt    [esp + P_LDT_SEL]
    lea     eax, [esp + P_STACKTOP]
    mov     dword [tss + TSS3_S_SP0], eax
restart_reenter:
    dec     dword [k_reenter]
    pop     gs
    pop     fs
    pop     es
    pop     ds
    popad
    add     esp, 4
    iretd
