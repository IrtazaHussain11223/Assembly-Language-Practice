org 0x0100
jmp start_game

player_row db 24
player_col db 40
player_dir db 3
tick_count db 0
old_int_offset dw 0
old_int_segment dw 0

; --- Place goal ---
place_goal:
    push ax
    push es
    mov ax,0xb800
    mov es,ax
    mov di,0
    mov ax,0x4F20
    stosw
    pop es
    pop ax
    ret

; --- Timer interrupt handler ---
timer_interrupt:
    pusha
    push ds
    push es
    inc byte [tick_count]
    cmp byte [tick_count],2
    jl skip_move
    mov byte [tick_count],0
    call move_player
skip_move:
    mov al,0x20
    out 0x20,al
    pop es
    pop ds
    popa
    iret

; --- Place obstacles ---
place_walls:
    push ax
    push cx
    push di
    push es
    mov ax,0xb800
    mov es,ax
    mov cx,25
    xor di,di
right_column:
    mov word [es:di+156],0x2F20
    add di,160
    loop right_column
    mov cx,16
    mov di,(3*80+5)*2
top_row:
    mov ax,0x2F20
    stosw
    loop top_row
    mov cx,16
    mov di,(10*80+25)*2
middle_row:
    mov ax,0x2F20
    stosw
    loop middle_row
    mov cx,11
    mov di,(5*80+15)*2
left_column:
    mov ax,0x2F20
    mov word [es:di],ax
    add di,160
    loop left_column
    mov cx,11
    mov di,(8*80+50)*2
middle_column:
    mov ax,0x2F20
    mov word [es:di],ax
    add di,160
    loop middle_column
    mov di,(12*80+35)*2
single_ob1:
    mov ax,0x2F20
    mov [es:di],ax
    mov di,(18*80+10)*2
single_ob2:
    mov ax,0x2F20
    mov [es:di],ax
    mov di,(20*80+60)*2
single_ob3:
    mov ax,0x2F20
    mov [es:di],ax
    pop es
    pop di
    pop cx
    pop ax
    ret

; --- Clear screen ---
clear_screen:
    push es
    push ax
    push cx
    push di
    mov ax,0xb800
    mov es,ax
    xor di,di
    mov ax,0xF020
    mov cx,2000
    cld
    rep stosw
    pop di
    pop cx
    pop ax
    pop es
    ret

; --- Place player ---
place_player:
    push ax
    push es
    mov ax,0xb800
    mov es,ax
    mov al,[player_row]
    mov ah,0
    mov bl,80
    mul bl
    mov dl,[player_col]
    mov dh,0
    add ax,dx
    shl ax,1
    mov di,ax
    mov ax,0x1A2A
    stosw
    pop es
    pop ax
    ret

; --- Keyboard input ---
keyboard_input:
    mov ah,1
    int 0x16
    jz no_key
    mov ah,0
    int 0x16
    mov al,ah
    cmp al,0x48
    je move_up
    cmp al,0x50
    je move_down
    cmp al,0x4B
    je move_left
    cmp al,0x4D
    je move_right
no_key:
    ret
move_up:
    mov byte [player_dir],0
    ret
move_down:
    mov byte [player_dir],1
    ret
move_left:
    mov byte [player_dir],2
    ret
move_right:
    mov byte [player_dir],3
    ret

; --- Move player ---
move_player:
    pusha
    push es
    mov al,[player_dir]
    mov bl,[player_row]
    mov bh,[player_col]
    cmp al,0
    je up_move
    cmp al,1
    je down_move
    cmp al,2
    je left_move
    cmp al,3
    je right_move
next_move:
    jmp continue_move
up_move:
    dec bl
    jmp next_move
down_move:
    inc bl
    jmp next_move
left_move:
    dec bh
    jmp next_move
right_move:
    inc bh
continue_move:
    cmp bl,0
    jl no_move
    cmp bl,24
    jg no_move
    cmp bh,0
    jl no_move
    cmp bh,79
    jg no_move

    mov ax,0xb800
    mov es,ax
    mov al,bl
    mov ah,0
    mov cl,80
    mul cl
    mov dl,bh
    mov dh,0
    add ax,dx
    shl ax,1
    mov di,ax
    mov ax,[es:di]
    mov cl,ah
    cmp cl,0x2F
    je game_lost
    cmp cl,0x4F
    je game_won

    mov al,[player_row]
    mov ah,0
    mov cl,80
    mul cl
    mov dl,[player_col]
    mov dh,0
    add ax,dx
    shl ax,1
    mov di,ax
    mov ax,0xF020
    stosw

    mov al,bl
    mov ah,0
    mov cl,80
    mul cl
    mov dl,bh
    mov dh,0
    add ax,dx
    shl ax,1
    mov di,ax
    mov ax,0x1A2A
    stosw
    mov [player_row],bl
    mov [player_col],bh

no_move:
    pop es
    popa
    ret

game_lost:
    mov dx,msg_lost
    mov ah,09h
    int 21h
    jmp $

game_won:
    mov dx,msg_win
    mov ah,09h
    int 21h
    jmp $

; --- Messages ---
msg_lost db 'Game Lost $'
msg_win db 'Game Win! $'

; --- Start program ---
start_game:
    call clear_screen
    call place_walls
    call place_goal
    call place_player
    mov ax,0
    mov es,ax
    cli
    mov ax,word [es:0x0020+2]
    mov [old_int_segment],ax
    mov ax,word [es:0x0020]
    mov [old_int_offset],ax
    mov dx,timer_interrupt
    mov ax,cs
    mov word [es:0x0020+2],ax
    mov word [es:0x0020],dx
    sti

game_loop:
    call keyboard_input
    jmp game_loop
