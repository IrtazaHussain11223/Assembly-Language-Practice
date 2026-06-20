; multitasking and dynamic thread registration (8-task limit)
; assemble: nasm -f bin example11_2.asm -o example11_2.com

org 0x0100
jmp start

; PCB layout (per thread, 16 words = 32 bytes):
; ax,bx,cx,dx,si,di,bp,sp,ip,cs,ds,ss,es,flags,next,dummy
; 0,  2,  4,  6,  8, 10, 12, 14, 16, 18, 20, 22, 24,  26 ,  28 ,  30

pcb:     times 8*16   dw 0      ; space for 8 PCBs (each 32 bytes)
stack:   times 8*256  dw 0      ; space for 8 stacks (each 512 bytes)
nextpcb: dw 1                   ; index of next free pcb (0 is root scheduler PCB)
current: dw 0                   ; index of current pcb
lineno:  dw 0                   ; line number for next thread

;;;;; printnum (from example 10.1) ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; subroutine to print a number on screen
; parameters (stack): [bp+8]=row, [bp+6]=col, [bp+4]=number
printnum:
    push bp
    mov bp, sp
    push es
    push ax
    push bx
    push cx
    push dx
    push di

    mov di, 80              ; columns per row
    mov ax, [bp+8]          ; row
    mul di                  ; row * 80
    mov di, ax
    add di, [bp+6]          ; + column
    shl di, 1               ; word offset (char+attr)
    add di, 8               ; to end of number (right-align 4 digits)

    mov ax, 0xb800
    mov es, ax              ; video memory segment

    mov ax, [bp+4]          ; number to print
    mov bx, 16              ; base 16 (hex)
    mov cx, 4               ; 4 digits

nextdigit:
    mov dx, 0
    div bx                  ; ax / 16, remainder in dl
    add dl, 0x30            ; '0'..'9'
    cmp dl, 0x39
    jbe skipalpha
    add dl, 7               ; 'A'..'F'
skipalpha:
    mov dh, 0x07            ; attribute
    mov [es:di], dx         ; write char+attr
    sub di, 2               ; move left
    loop nextdigit

    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    pop es
    pop bp
    ret 6

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; mytask subroutine to be run as a thread
; parameter (stack): [bp+4] = line number
mytask:
    push bp
    mov bp, sp
    sub sp, 2               ; local variable (word) at [bp-2]
    push ax
    push bx

    mov ax, [bp+4]          ; line number
    mov bx, 70              ; column 70
    mov word [bp-2], 0      ; initialize counter

printagain:
    push ax                 ; row
    push bx                 ; col
    push word [bp-2]        ; number
    call printnum
    inc word [bp-2]
    jmp printagain          ; infinite

    pop bx
    pop ax
    mov sp, bp
    pop bp
    ret

; subroutine to register a new thread
; parameters (stack): [bp+8]=segment, [bp+6]=offset, [bp+4]=param
initpcb:
    push bp
    mov bp, sp
    push ax
    push bx
    push cx
    push si

    mov bx, [nextpcb]       ; next available pcb index
    cmp bx, 8               ; cap at 8 tasks
    je init_exit            ; if full, exit

    mov cl, 5
    shl bx, cl              ; bx = index * 32 (pcb stride)

    mov ax, [bp+8]          ; thread CS
    mov [pcb+bx+18], ax
    mov ax, [bp+6]          ; thread IP
    mov [pcb+bx+16], ax

    mov [pcb+bx+22], ds     ; SS = our DS (stack segment)

    mov si, [nextpcb]       ; compute stack top for this thread
    mov cl, 9
    shl si, cl              ; si = index * 512
    add si, 256*2 + stack   ; end of stack (word-addressed)
    mov ax, [bp+4]          ; parameter for subroutine
    sub si, 2               ; push param
    mov [si], ax
    sub si, 2               ; space for return address (dummy)
    mov [pcb+bx+14], si     ; SP

    mov word [pcb+bx+26], 0x0200 ; flags (IF set)

    mov ax, [pcb+28]        ; link into run queue (after root)
    mov [pcb+bx+28], ax     ; new.next = root.next
    mov ax, [nextpcb]
    mov [pcb+28], ax        ; root.next = new

    inc word [nextpcb]      ; consume this PCB slot

init_exit:
    pop si
    pop cx
    pop bx
    pop ax
    pop bp
    ret 6

; timer interrupt service routine (INT 8)
timer:
    push ds
    push bx
    push cs
    pop ds                  ; ds = code/data segment

    mov bx, [current]       ; current thread index

    ; bx *= 32 (pcb stride)
    shl bx, 1
    shl bx, 1
    shl bx, 1
    shl bx, 1
    shl bx, 1

    ; save current context
    mov [pcb+bx+0], ax
    mov [pcb+bx+4], cx
    mov [pcb+bx+6], dx
    mov [pcb+bx+8], si
    mov [pcb+bx+10], di
    mov [pcb+bx+12], bp
    mov [pcb+bx+24], es
    pop ax                  ; original bx from stack
    mov [pcb+bx+2], ax
    pop ax                  ; original ds from stack
    mov [pcb+bx+20], ax
    pop ax                  ; original ip from stack
    mov [pcb+bx+16], ax
    pop ax                  ; original cs from stack
    mov [pcb+bx+18], ax
    pop ax                  ; original flags from stack
    mov [pcb+bx+26], ax
    mov [pcb+bx+22], ss
    mov [pcb+bx+14], sp

    ; advance to next PCB
    mov bx, [pcb+bx+28]     ; next index
    mov [current], bx

    mov cl, 5
    shl bx, cl              ; bx = index * 32

    ; load next context
    mov cx, [pcb+bx+4]
    mov dx, [pcb+bx+6]
    mov si, [pcb+bx+8]
    mov di, [pcb+bx+10]
    mov bp, [pcb+bx+12]
    mov es, [pcb+bx+24]
    mov ss, [pcb+bx+22]
    mov sp, [pcb+bx+14]

    push word [pcb+bx+26]   ; flags
    push word [pcb+bx+18]   ; cs
    push word [pcb+bx+16]   ; ip
    push word [pcb+bx+20]   ; ds

    mov al, 0x20
    out 0x20, al            ; EOI to PIC

    mov ax, [pcb+bx+0]
    mov bx, [pcb+bx+2]
    pop ds
    iret

start:
    xor ax, ax
    mov es, ax              ; ES -> IVT
    cli
    mov word [es:8*4], timer
    mov [es:8*4+2], cs      ; hook INT 8
    sti

nextkey:
    xor ah, ah              ; BIOS: get keystroke (service 0)
    int 0x16

    ; Optional guard: ignore extra registrations after 8 tasks
    mov ax, [nextpcb]
    cmp ax, 8
    jae nextkey

    push cs                 ; target CS
    mov ax, mytask          ; target IP
    push ax
    push word [lineno]      ; parameter: row number
    call initpcb

    inc word [lineno]
    jmp nextkey
