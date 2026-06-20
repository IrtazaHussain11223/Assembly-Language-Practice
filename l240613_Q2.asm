org 0x0100

jmp start

set1 db -3, -1, 2, 5, 6, 8, 9
size1 db 7
set2 db -2, 2, 6, 7, 9
size2 db 5
union db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
usize db 0

start:
    mov si, set1         
    mov di, set2         
    mov bx, union        
    mov cl, [size1]      
    mov ch, [size2]      

next_compare:
    cmp cl, 0
    je copy_set2
    cmp ch, 0
    je copy_set1

    mov al, [si]         
    mov dl, [di]         
    cmp al, dl
    jl from_set1         
    jg from_set2         

   
    mov [bx], al
    inc bx
    inc si
    inc di
    dec cl
    dec ch
    jmp store_next

from_set1:
    mov [bx], al
    inc bx
    inc si
    dec cl
    jmp store_next

from_set2:
    mov [bx], dl
    inc bx
    inc di
    dec ch

store_next:
    inc byte [usize]
    jmp next_compare

copy_set1:
    cmp cl, 0
    je done
copy1_loop:
    mov al, [si]
    mov [bx], al
    inc bx
    inc si
    inc byte [usize]
    dec cl
    jnz copy1_loop
    jmp done

copy_set2:
    cmp ch, 0
    je done
copy2_loop:
    mov dl, [di]
    mov [bx], dl
    inc bx
    inc di
    inc byte [usize]
    dec ch
    jnz copy2_loop

done:
    mov ax, 0x4c00
    int 0x21
