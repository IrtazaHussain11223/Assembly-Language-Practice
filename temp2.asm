org 0x0100
jmp game_start

; --------------------------------------------------------
; VARIABLES
; --------------------------------------------------------

star_row        db 24     ; current row of the star
star_col        db 40     ; current column of the star
star_dir        db 3      ; movement direction (0=right,1=left,2=down,3=up)
timer_count     db 0      ; used for slowing star movement in timer interrupt

prev_int08_off  dw 0      ; previous INT 08h offset
prev_int08_seg  dw 0      ; previous INT 08h segment

; Movement table: dy, dx pairs for each direction
; order: right, left, down, up
movement_table:
    db 0, 1      ; right  (dy=0,  dx=+1)
    db 0, -1     ; left   (dy=0,  dx=-1)
    db 1, 0      ; down   (dy=+1, dx=0)
    db -1, 0     ; up     (dy=-1, dx=0)

msg_victory db 'Game Win! $'
msg_defeat  db 'Game Lost $'

; --------------------------------------------------------
; COMPUTE VIDEO MEMORY OFFSET FOR (row = CX, col = DX)
; --------------------------------------------------------
compute_offset:
    push ax
    push bx
    push dx

    mov ax, cx        ; AX = row
    mov bx, 80        ; 80 columns
    mul bx            ; AX = row * 80  (compute base row offset)

    pop dx            ; restore DX = column
    add ax, dx        ; AX = row*80 + col
    shl ax, 1         ; each cell = 2 bytes in B800h text mode
    mov di, ax        ; final offset in DI

    pop bx
    pop ax
    ret

; --------------------------------------------------------
; CLEAR SCREEN (fills screen with spaces)
; --------------------------------------------------------
clear_screen_routine:
    push ax
    push cx
    push di

    mov ax, 0xB800
    mov es, ax        ; ES -> video memory
    xor di, di        ; start at offset 0

    mov ax, 0x0720    ; char=' ', attr=07
    mov cx, 2000      ; 80*25 = 2000 characters
    rep stosw         ; fill screen

    pop di
    pop cx
    pop ax
    ret

; --------------------------------------------------------
; DRAW ALL WALLS
; --------------------------------------------------------
draw_walls:
    push ax
    push cx
    push di

    mov ax, 0xB800
    mov es, ax

    ; -------------------------------
    ; Right boundary wall (column 79)
    ; -------------------------------
    mov cx, 25
    mov di, 79*2

right_wall:
    mov ax, 0x2220    ; attribute 22h, char=space (visual wall color)
    mov [es:di], ax
    add di, 160       ; go one row down
    loop right_wall

    ; -------------------------------------
    ; Horizontal wall on row 5, columns 10-30
    ; -------------------------------------
    mov cx, 21
    mov di, (5*80 + 10)*2
horiz_wall:
    mov ax, 0x2220
    stosw
    loop horiz_wall

    ; -------------------------------------
    ; Vertical wall column 20, rows 10-15
    ; -------------------------------------
    mov cx, 6
    mov di, (10*80 + 20)*2
vert_wall:
    mov ax, 0x2220
    mov [es:di], ax
    add di, 160
    loop vert_wall

    ; -------------------------------------
    ; Extra horizontal wall row 15, col 40-55
    ; -------------------------------------
    mov cx, 16
    mov di, (15*80 + 40)*2
extra_horiz:
    mov ax, 0x2220
    stosw
    loop extra_horiz

    ; -------------------------------------
    ; Extra vertical wall col 60, rows 5-12
    ; -------------------------------------
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

; --------------------------------------------------------
; PLACE GOAL MARKER (D = goal color)
; --------------------------------------------------------
place_goal_routine:
    push ax
    push di
    mov ax, 0xB800
    mov es, ax

    mov di, (2*80 + 70)*2   ; goal position
    mov ax, 0x4420          ; attribute=44h, char=' '
    stosw

    pop di
    pop ax
    ret

; --------------------------------------------------------
; DRAW THE STAR
; --------------------------------------------------------
place_star:
    push ax
    push cx
    push dx
    push di

    mov al, [star_row]
    xor ah, ah
    mov cx, ax             ; row in CX

    mov dl, [star_col]
    xor dh, dh             ; column in DX

    call compute_offset    ; DI = offset

    mov ax, 0xB800
    mov es, ax

    mov ax, 0x1F2A         ; color 1Fh, char='*' (2Ah)
    mov [es:di], ax        ; draw star

    pop di
    pop dx
    pop cx
    pop ax
    ret

; --------------------------------------------------------
; READ ARROW KEYS (non-blocking)
; --------------------------------------------------------
read_keys:
    mov ah, 1
    int 0x16               ; check key available
    jz rk_done             ; no key → exit

    mov ah, 0
    int 0x16               ; read key
    mov al, ah             ; scan code in AH → AL

    cmp al, 0x4D           ; →
    je rk_right
    cmp al, 0x4B           ; ←
    je rk_left
    cmp al, 0x50           ; ↓
    je rk_down
    cmp al, 0x48           ; ↑
    je rk_up

rk_done:
    ret

rk_up:    mov byte [star_dir],3  ; up
          ret
rk_down:  mov byte [star_dir],2  ; down
          ret
rk_left:  mov byte [star_dir],1  ; left
          ret
rk_right: mov byte [star_dir],0  ; right
          ret

; --------------------------------------------------------
; MOVE STAR (called by timer interrupt)
; --------------------------------------------------------
move_star:
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    ; load current pos
    mov al, [star_row]
    mov bl, [star_col]

    ; get movement vector
    mov cl, [star_dir]
    xor ch, ch
    shl cx, 1                 ; each entry = 2 bytes
    mov si, movement_table
    add si, cx                ; SI points to dy,dx

    ; -------- Update row (dy) --------
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

    ; -------- Update column (dx) --------
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

    ; -------- Collision detection --------
    mov cl, [star_row]
    xor ch, ch
    mov dl, [star_col]
    xor dh, dh

    call compute_offset
    mov ax, 0xB800
    mov es, ax

    mov al, [es:di+1]        ; attribute byte → check color

    cmp al, 0x22             ; wall color?
    je lost_game

    cmp al, 0x44             ; goal color?
    je won_game

    ; draw star at updated position
    mov ax, 0x1F2A
    mov [es:di], ax

    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; --------------------------------------------------------
; TIMER INTERRUPT (INT 08h)
; --------------------------------------------------------
timer_interrupt:
    pusha
    push ds
    push es

    mov ax, cs
    mov ds, ax              ; DS = CS so we can access variables

    inc byte [timer_count]
    cmp byte [timer_count], 2
    jl ti_skip              ; only move every 2 ticks
    mov byte [timer_count], 0

    call move_star          ; move it

ti_skip:
    mov al, 20h
    out 20h, al             ; send EOI to PIC

    pushf
    call far [prev_int08_off] ; chain to old interrupt

    pop es
    pop ds
    popa
    iret

; --------------------------------------------------------
; GAME RESULT HANDLERS
; --------------------------------------------------------
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

; --------------------------------------------------------
; RESTORE OLD IVT AND EXIT
; --------------------------------------------------------
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

; --------------------------------------------------------
; PROGRAM START
; --------------------------------------------------------
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

    ; Install new INT 08h
    cli
    mov dx, timer_interrupt
    mov ax, cs
    mov bx, 0
    mov es, bx
    mov [es:20h], dx
    mov [es:22h], ax
    sti

main_loop:
    call read_keys          ; non-blocking input
    jmp main_loop           ; infinite loop
