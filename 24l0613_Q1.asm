[org 0x100]
jmp start:
num1 dw 0xD6A5
res db 0,0,0,0,0,0

splitoctal:
 push ax
 push bx
 push cx
 push dx
 push si
 push di
 push bp
 mov bp,sp
 mov dx,[bp+16] ; as we had loaded other regsiters we need to add in bp to get the data
 mov bx,[bp+18]

 mov al, dh      ; high byte
call convertbyte

 mov al, dl      ; low byte
call convertbyte

 pop bp
 pop di
 pop si
 pop dx
 pop cx
 pop bx
 pop ax
 add sp, 4           
 ret
convertbyte:
 push ax
    push cx
    push dx

    mov cl, al ; for left part
    and cl, 0xC0
    shr cl, 6
    add cl, '0' ; convetrs to ascii
    mov [bx], cl
    inc bx

    mov cl, al ; for middle
    and cl, 0x38
    shr cl, 3
    add cl, '0'
    mov [bx], cl
    inc bx

    mov cl, al ; for right
    and cl, 007h       
    add cl, '0'
    mov [bx], cl
    inc bx

    pop dx
    pop cx
    pop ax
    ret



start:
 mov ax, [num1]
 mov di, res
 push di
 push ax 
 call splitoctal
 mov ax, 0x4c00
 int 0x21
