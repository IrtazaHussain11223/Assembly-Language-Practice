[org 0x0100]

mov bx, num1
mov cx, 10 
mov ax, 0 

l1: add ax, [bx]
add bx, 2 
sub cx, 1
jnz l1 
mov [sum], ax 
mov ax, 0x4c00
int 0x21
num1: dw 1,2,3,4,5,1,2,3,4,5
sum: dw 0