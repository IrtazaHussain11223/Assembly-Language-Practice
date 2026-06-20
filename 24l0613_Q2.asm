[org 0x100]
jmp start
makeBorders:
    mov ax, 0xB800
    mov es, ax
    xor si, si
    mov ah, 0x07
clear_loop:
    mov [es:si], byte ' '
    mov [es:si+1], ah
    add si, 2
    cmp si, 4000
    jb clear_loop
    mov bl, 0x4F
    mov bh, 0x9F
    xor si, si
outer_top_row:
    mov [es:si], byte 'A'
    mov [es:si+1], bl
    add si, 2
    cmp si, 0x00A0
    jb outer_top_row
    mov si, 0x00A0        
outer_sides:
    mov dx, 0x0FA0         
    sub dx, 0x00A0       
    cmp si, dx
    jge outer_bottom_row
    mov [es:si], byte 'A'
    mov [es:si+1], bl
    mov [es:si+0x009E], byte 'A'
    mov [es:si+0x009F], bl
    add si, 0x00A0
    jmp outer_sides
outer_bottom_row:
    mov dx, 0x0FA0
    sub dx, 0x00A0        
    mov si, dx
    mov cx, 0x50
outer_bottom_loop:
    mov [es:si], byte 'A'
    mov [es:si+1], bl
    add si, 2
    loop outer_bottom_loop
    mov si, 0x00A0        
    add si, 2              
inner_top_row:
    mov [es:si], byte 'B'
    mov [es:si+1], bh
    add si, 2
    mov dx, 0x00A0
    add dx, 0x009C        
    cmp si, dx
    jb inner_top_row
inner_sides:
    mov dx, 0x0FA0
    sub dx, 0x00A0
    sub dx, 0x00A2         
    cmp si, dx
    jge inner_bottom_row
    mov [es:si], byte 'B'
    mov [es:si+1], bh
    mov [es:si+0x0098], byte 'B'
    mov [es:si+0x0099], bh
    add si, 0x00A0
    jmp inner_sides
inner_bottom_row:
    mov dx, 0x0FA0
    sub dx, 0x00A0
    sub dx, 0x009C        
    mov si, dx
    mov cx, 0x4E
inner_bottom_loop:
    mov [es:si], byte 'B'
    mov [es:si+1], bh
    add si, 2
    loop inner_bottom_loop

    ret

start:
    call makeBorders

mov ax, 0x4C00
    int 0x21
