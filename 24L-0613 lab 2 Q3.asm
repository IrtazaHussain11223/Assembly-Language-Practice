[org 0x0100]

source db 1,2,3,4,5,6    
dest   dw 0,0,0,0,0,0    
mov ax, 0x4c00
    int 0x21