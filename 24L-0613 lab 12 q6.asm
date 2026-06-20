; Falling star multitasking demo (8-task limit)
; Assemble: nasm -f bin falling_star.asm -o falling_star.com

org 0x0100
jmp start

; PCB layout (16 words = 32 bytes each)
pcb:     times 8*16   dw 0
stack:   times 8*256  dw 0
nextpcb: dw 1
current: dw 0
starcol: dw 80        ; starting column for first star

;;;; printchar: print a single character at row,col
; params: [bp+8]=row, [bp+6]=col, [bp+4]=char
printchar:
    push bp
    mov bp, sp
    push es
    push ax
    push bx
    push di

    mov di, 80
    mov ax, [bp+8]    ; row
    mul di
    mov di, ax
    add di, [bp+6]    ; col
    shl di, 1

    mov ax, 0xb800
    mov es, ax
    mov ax, [bp+4]
    mov ah, 0x07      ; attribute
    mov [es:di], ax

    pop di
    pop bx
    pop ax
    pop es
    pop bp
    ret 6

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; star task: falls from row 0 to 24 in infinite loop
; param: [bp+4] = column
star_task:
    push bp
    mov bp, sp
    sub sp, 2         ; local var: row counter
    push ax
    push bx

    mov bx, [bp+4]    ; column
    mov word [bp-2], 0 ; row=0

fall_loop:
    ; erase previous row (optional: space)
    cmp word [bp-2], 0
    je skip_erase
    mov ax, ' '       ; space char
    push word [bp-2]  ; row
    dec word [bp-2]
    push bx           ; col
    push ax
    call printchar
    inc word [bp-2]
skip_erase:

    ; draw star '*'
    mov ax, '*'       
    push word [bp-2]  ; row
    push bx           ; col
    push ax
    call printchar

    ; advance row
    inc word [bp-2]
    cmp word [bp-2], 25
    jl fall_loop
    mov word [bp-2], 0 ; reset to top
    jmp fall_loop

    pop bx
    pop ax
    mov sp, bp
    pop bp
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; initpcb: register new thread
; params: [bp+8]=segment, [bp+6]=offset, [bp+4]=param
initpcb:
    push bp
    mov bp, sp
    push ax
    push bx
    push cx
    push si

    mov bx, [nextpcb]
    cmp bx, 8
    je init_exit

    mov cl, 5
    shl bx, cl        ; bx = index*32

    mov ax, [bp+8]
    mov [pcb+bx+18], ax
    mov ax, [bp+6]
    mov [pcb+bx+16], ax
    mov [pcb+bx+22], ds

    mov si, [nextpcb]
    mov cl, 9
    shl si, cl
    add si, 256*2+stack
    mov ax, [bp+4]
    sub si, 2
    mov [si], ax
    sub si, 2
    mov [pcb+bx+14], si

    mov word [pcb+bx+26], 0x0200

    mov ax, [pcb+28]
    mov [pcb+bx+28], ax
    mov ax, [nextpcb]
    mov [pcb+28], ax
    inc word [nextpcb]

init_exit:
    pop si
    pop cx
    pop bx
    pop ax
    pop bp
    ret 6

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; timer ISR (same as before)
timer:
    push ds
    push bx
    push cs
    pop ds

    mov bx, [current]
    shl bx, 1
    shl bx, 1
    shl bx, 1
    shl bx, 1
    shl bx, 1

    mov [pcb+bx+0], ax
    mov [pcb+bx+4], cx
    mov [pcb+bx+6], dx
    mov [pcb+bx+8], si
    mov [pcb+bx+10], di
    mov [pcb+bx+12], bp
    mov [pcb+bx+24], es
    pop ax
    mov [pcb+bx+2], ax
    pop ax
    mov [pcb+bx+20], ax
    pop ax
    mov [pcb+bx+16], ax
    pop ax
    mov [pcb+bx+18], ax
    pop ax
    mov [pcb+bx+26], ax
    mov [pcb+bx+22], ss
    mov [pcb+bx+14], sp

    mov bx, [pcb+bx+28]
    mov [current], bx

    mov cl, 5
    shl bx, cl

    mov cx, [pcb+bx+4]
    mov dx, [pcb+bx+6]
    mov si, [pcb+bx+8]
    mov di, [pcb+bx+10]
    mov bp, [pcb+bx+12]
    mov es, [pcb+bx+24]
    mov ss, [pcb+bx+22]
    mov sp, [pcb+bx+14]

    push word [pcb+bx+26]
    push word [pcb+bx+18]
    push word [pcb+bx+16]
    push word [pcb+bx+20]

    mov al, 0x20
    out 0x20, al

    mov ax, [pcb+bx+0]
    mov bx, [pcb+bx+2]
    pop ds
    iret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start:
    xor ax, ax
    mov es, ax
    cli
    mov word [es:8*4], timer
    mov [es:8*4+2], cs
    sti

nextkey:
    xor ah, ah
    int 0x16             ; wait for keypress
    cmp al, '8'
    jne nextkey

    mov ax, [nextpcb]
    cmp ax, 8
    jae nextkey

    push cs
    mov ax, star_task
    push ax
    push word [starcol]   ; column parameter
    call initpcb

    sub word [starcol], 5 ; next star column
    jmp nextkey
