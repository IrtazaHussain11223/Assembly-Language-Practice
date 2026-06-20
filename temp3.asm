org 0x0100
jmp prog_start

; -------------------------
; Variables
; -------------------------
player_row    db 24
player_col    db 40
player_dir    db 3        ; 0=up,1=down,2=left,3=right
tick_counter  db 0

old_int_offset  dw 0
old_int_segment dw 0

dir_table:
    db -1, 0    ; up
    db  1, 0    ; down
    db  0, -1   ; left
    db  0, 1    ; right

msg_win  db 'Game Win! $'
msg_lose db 'Game Lost $'

; -------------------------
; calc_vid_offset
; Computes DI = (row*80 + col)*2
; Expects: CX=row, DX=col
; -------------------------
calc_vid_offset:
    push ax
    push bx
    push dx            ; save col
    mov ax, cx         ; AX = row
    mov bx, 80
    mul bx             ; DX:AX = AX * 80
    pop dx             ; DX = col
    add ax, dx         ; AX = row*80 + col
    shl ax, 1          ; 2 bytes per char cell
    mov di, ax
    pop bx
    pop ax
    ret

; -------------------------
; clear_screen
; -------------------------
clear_screen:
    push ax
    push cx
    push di
    mov ax, 0xB800
    mov es, ax
    xor di, di
    mov ax, 0x0720     ; ' ' with attribute 07
    mov cx, 2000       ; 80*25
    rep stosw
    pop di
    pop cx
    pop ax
    ret

; -------------------------
; draw_obstacles
; -------------------------
draw_obstacles:
    push ax
    push cx
    push di
    mov ax, 0xB800
    mov es, ax

    ; Right boundary col79
    mov cx, 25
    mov di, 79*2
right_loop:
    mov ax, 0x2220
    mov [es:di], ax
    add di, 80*2
    loop right_loop

    ; Horizontal bar row5, col10-30
    mov cx, 21
    mov di, (5*80 + 10)*2
horiz1:
    mov ax, 0x2220
    stosw
    loop horiz1

    ; Vertical bar col20, rows10-15
    mov cx, 6
    mov di, (10*80 + 20)*2
vert1:
    mov ax, 0x2220
    mov [es:di], ax
    add di, 80*2
    loop vert1

    ; ===============================
    ; NEW OBSTACLE #1 (Horizontal)
    ; Row 15, col 40–55
    ; ===============================
    mov cx, 16            ; length 16 (40 to 55)
    mov di, (15*80 + 40)*2
new_horiz:
    mov ax, 0x2220
    stosw
    loop new_horiz

    ; ===============================
    ; NEW OBSTACLE #2 (Vertical)
    ; Column 60, rows 5–12
    ; ===============================
    mov cx, 8             ; rows 5 to 12
    mov di, (5*80 + 60)*2
new_vert:
    mov ax, 0x2220
    mov [es:di], ax
    add di, 80*2
    loop new_vert

    pop di
    pop cx
    pop ax
    ret
; -------------------------
; place_goal
; -------------------------
place_goal:
    push ax
    push di
    mov ax, 0xB800
    mov es, ax
    mov di, (2*80 + 70)*2  ; goal at row 2, col 70
    mov ax, 0x4420         ; ' ' with attribute 44
    stosw
    pop di
    pop ax
    ret

; -------------------------
; place_player
; -------------------------
place_player:
    push ax
    push cx
    push dx
    push di
    mov al, [player_row]
    xor ah, ah
    mov cx, ax
    mov dl, [player_col]
    xor dh, dh
    call calc_vid_offset
    mov ax, 0xB800
    mov es, ax
    mov ax, 0x1F2A         ; '*' with bright white on blue
    mov [es:di], ax
    pop di
    pop dx
    pop cx
    pop ax
    ret

; -------------------------
; poll_keys
; -------------------------
poll_keys:
    mov ah, 1
    int 0x16
    jz pk_done
    mov ah, 0
    int 0x16
    mov al, ah             ; scan code in AH
    cmp al, 0x48
    je pk_up
    cmp al, 0x50
    je pk_down
    cmp al, 0x4B
    je pk_left
    cmp al, 0x4D
    je pk_right
pk_done:
    ret
pk_up:    mov byte [player_dir],0
          ret
pk_down:  mov byte [player_dir],1
          ret
pk_left:  mov byte [player_dir],2
          ret
pk_right: mov byte [player_dir],3
          ret

; -------------------------
; update_position
; -------------------------
update_position:
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    mov al, [player_row]
    mov bl, [player_col]
    mov cl, [player_dir]
    xor ch, ch
    shl cx, 1
    mov si, dir_table
    add si, cx

    ; dy
    mov cl, [si]
    add al, cl
    cmp al, 0
    jl set0row
    cmp al, 24
    jg set24row
    jmp dy_done
set0row:  mov al, 0
          jmp dy_done
set24row: mov al, 24
dy_done:
    mov [player_row], al

    ; dx
    mov cl, [si+1]
    add bl, cl
    cmp bl, 0
    jl set0col
    cmp bl, 79
    jg set79col
    jmp dx_done
set0col:  mov bl, 0
          jmp dx_done
set79col: mov bl, 79
dx_done:
    mov [player_col], bl

    ; check video memory at current cell
    mov cl, [player_row]
    xor ch, ch
    mov dl, [player_col]
    xor dh, dh
    call calc_vid_offset
    mov ax, 0xB800
    mov es, ax
    mov al, [es:di+1]      ; attribute byte
    cmp al, 0x22           ; obstacle attr
    je game_lost
    cmp al, 0x44           ; goal attr
    je game_won

    ; draw player
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
; Timer interrupt handler
; -------------------------
timer_handler:
    pusha
    push ds
    push es

    mov ax, cs
    mov ds, ax            ; ensure DS points to our data

    inc byte [tick_counter]
    cmp byte [tick_counter], 2
    jl th_skip
    mov byte [tick_counter], 0
    call update_position
th_skip:
    mov al, 20h
    out 20h, al           ; EOI to PIC

    ; chain to old INT 08h safely
    pushf
    call far [old_int_offset]  ; m16:16 pointer (offset+segment)

    pop es
    pop ds
    popa
    iret

; -------------------------
; Game won/lost
; -------------------------
game_lost:
    mov dx, msg_lose
    mov ah, 09h
    int 21h
    call restore_exit

game_won:
    mov dx, msg_win
    mov ah, 09h
    int 21h
    call restore_exit

; -------------------------
; Restore IVT and exit
; -------------------------
restore_exit:
    cli
    mov ax, 0
    mov es, ax
    mov ax, [old_int_offset]
    mov [es:20h], ax
    mov ax, [old_int_segment]
    mov [es:22h], ax
    sti
    mov ax, 4C00h
    int 21h

; -------------------------
; Program start
; -------------------------
prog_start:
    mov ax, cs
    mov ds, ax

    call clear_screen
    call draw_obstacles
    call place_goal
    call place_player

    ; save old INT 08h
    mov ax, 0
    mov es, ax
    mov ax, [es:20h]
    mov [old_int_offset], ax
    mov ax, [es:22h]
    mov [old_int_segment], ax

    ; set new timer (NASM-safe)
    cli
    mov dx, timer_handler    ; offset of handler
    mov ax, cs               ; segment of handler
    mov bx, 0
    mov es, bx               ; ES = 0000h (IVT base)
    mov [es:20h], dx         ; INT 08h offset
    mov [es:22h], ax         ; INT 08h segment
    sti

main_loop:
    call poll_keys
    jmp main_loop