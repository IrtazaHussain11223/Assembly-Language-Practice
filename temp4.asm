org 0x0100
jmp game_start

; -------------------------
; Variables
; -------------------------
star_row        db 24
star_col        db 40
star_dir        db 3        ; 0=up,1=down,2=left,3=right
timer_count     db 0

prev_int08_off  dw 0
prev_int08_seg  dw 0

movement_table:
    db 0, 1      ; right
    db 0, -1     ; left
    db 1, 0      ; down
    db -1, 0     ; up

msg_victory db 'Game Win! $'
msg_defeat  db 'Game Lost $'

; -------------------------
; compute_offset
; -------------------------
compute_offset:
    push ax
    push bx
    push dx
    mov ax, cx
    mov bx, 80
    mul bx
    pop dx
    add ax, dx
    shl ax, 1
    mov di, ax
    pop bx
    pop ax
    ret

; -------------------------
; clear_screen_routine
; -------------------------
clear_screen_routine:
    push ax
    push cx
    push di
    mov ax, 0xB800
    mov es, ax
    xor di, di
    mov ax, 0x0720
    mov cx, 2000
    rep stosw
    pop di
    pop cx
    pop ax
    ret

; -------------------------
; draw_walls
; -------------------------
draw_walls:
    push ax
    push cx
    push di
    mov ax, 0xB800
    mov es, ax

    ; Right boundary
    mov cx, 25
    mov di, 79*2
right_wall:
    mov ax, 0x2220
    mov [es:di], ax
    add di, 160
    loop right_wall

    ; Horizontal wall row5, col10-30
    mov cx, 21
    mov di, (5*80 + 10)*2
horiz_wall:
    mov ax, 0x2220
    stosw
    loop horiz_wall

    ; Vertical wall col20, rows10-15
    mov cx, 6
    mov di, (10*80 + 20)*2
vert_wall:
    mov ax, 0x2220
    mov [es:di], ax
    add di, 160
    loop vert_wall

    ; Extra horizontal wall row15, col40-55
    mov cx, 16
    mov di, (15*80 + 40)*2
extra_horiz:
    mov ax, 0x2220
    stosw
    loop extra_horiz

    ; Extra vertical wall col60, rows5-12
    mov cx, 8
    mov di, (5*80 + 60)*2
extra_vert:
    mov ax, 0x2220
    mov [es:di], ax
    add di, 160
    loop extra_vert

    pop di
    pop cx
    pop ax
    ret

; -------------------------
; place_goal_routine
; -------------------------
place_goal_routine:
    push ax
    push di
    mov ax, 0xB800
    mov es, ax
    mov di, (2*80 + 70)*2
    mov ax, 0x4420
    stosw
    pop di
    pop ax
    ret

; -------------------------
; place_star
; -------------------------
place_star:
    push ax
    push cx
    push dx
    push di
    mov al, [star_row]
    xor ah, ah
    mov cx, ax
    mov dl, [star_col]
    xor dh, dh
    call compute_offset
    mov ax, 0xB800
    mov es, ax
    mov ax, 0x1F2A
    mov [es:di], ax
    pop di
    pop dx
    pop cx
    pop ax
    ret

; -------------------------
; read_keys
; -------------------------
read_keys:
    mov ah, 1
    int 0x16
    jz rk_done
    mov ah, 0
    int 0x16
    mov al, ah
    cmp al, 0x4D           ; Right Arrow
    je rk_right
    cmp al, 0x4B           ; Left
    je rk_left
    cmp al, 0x50           ; Down
    je rk_down
    cmp al, 0x48           ; Up
    je rk_up
rk_done:
    ret
rk_up:    mov byte [star_dir],3
          ret
rk_down:  mov byte [star_dir],2
          ret
rk_left:  mov byte [star_dir],1
          ret
rk_right: mov byte [star_dir],0
          ret

; -------------------------
; move_star
; -------------------------
move_star:
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    mov al, [star_row]
    mov bl, [star_col]
    mov cl, [star_dir]
    xor ch, ch
    shl cx, 1
    mov si, movement_table
    add si, cx

    ; dy
    mov cl, [si]
    add al, cl
    cmp al, 0
    jl set_row0
    cmp al, 24
    jg set_row24
    jmp dy_done
set_row0:  mov al, 0
           jmp dy_done
set_row24: mov al, 24
dy_done:
    mov [star_row], al

    ; dx
    mov cl, [si+1]
    add bl, cl
    cmp bl, 0
    jl set_col0
    cmp bl, 79
    jg set_col79
    jmp dx_done
set_col0:  mov bl, 0
           jmp dx_done
set_col79: mov bl, 79
dx_done:
    mov [star_col], bl

    ; collision check
    mov cl, [star_row]
    xor ch, ch
    mov dl, [star_col]
    xor dh, dh
    call compute_offset
    mov ax, 0xB800
    mov es, ax
    mov al, [es:di+1]
    cmp al, 0x22
    je lost_game
    cmp al, 0x44
    je won_game

    ; draw star
    mov ax, 0x1F2A
    mov [es:di], ax

    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; -------------------------
; timer_interrupt
; -------------------------
timer_interrupt:
    pusha
    push ds
    push es

    mov ax, cs
    mov ds, ax

    inc byte [timer_count]
    cmp byte [timer_count], 2
    jl ti_skip
    mov byte [timer_count], 0
    call move_star
ti_skip:
    mov al, 20h
    out 20h, al

    pushf
    call far [prev_int08_off]

    pop es
    pop ds
    popa
    iret

; -------------------------
; Game end
; -------------------------
lost_game:
    mov dx, msg_defeat
    mov ah, 09h
    int 21h
    call restore_exit

won_game:
    mov dx, msg_victory
    mov ah, 09h
    int 21h
    call restore_exit

; -------------------------
; restore_IVT_and_exit
; -------------------------
restore_exit:
    cli
    mov ax, 0
    mov es, ax
    mov ax, [prev_int08_off]
    mov [es:20h], ax
    mov ax, [prev_int08_seg]
    mov [es:22h], ax
    sti
    mov ax, 4C00h
    int 21h

; -------------------------
; Start
; -------------------------
game_start:
    mov ax, cs
    mov ds, ax

    call clear_screen_routine
    call draw_walls
    call place_goal_routine
    call place_star

    ; Save old INT 08h
    mov ax, 0
    mov es, ax
    mov ax, [es:20h]
    mov [prev_int08_off], ax
    mov ax, [es:22h]
    mov [prev_int08_seg], ax

    ; Set new timer
    cli
    mov dx, timer_interrupt
    mov ax, cs
    mov bx, 0
    mov es, bx
    mov [es:20h], dx
    mov [es:22h], ax
    sti

main_loop:
    call read_keys
    jmp main_loop
