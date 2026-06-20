[org0x0100]
jmp start
 array db 0xA7, 0xA3, 0x94, 0xFF, 0x00
 count db 5
start:
 mov si,array
 mov di,array
 mov cl,[count]

loop:
 mov al,[si]
 mov bl,al
 mov dl,0
 mov dh,8

bit_loop:
 and bl,1
 jz skip
 inc dl

skip:
 shr bl,1
 dec dh
 jnz bit_loop
 
 test dl,1 ; to check if no of 1s is even or odd even or
 jnz odd
 mov [di],al
 inc di 
 
odd:
 inc si
 dec cl
 jnz loop

fill:
cmp di,array+5
jae end
mov byte[di],0
inc di
jmp fill
end: 
mov ax,0x4c00
int 0x21


 
