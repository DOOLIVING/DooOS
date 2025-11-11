org 0x7C00
bits 16

start:
    jmp 0x0000:main

main:
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00

    ; Очистка экрана
    mov ax, 0x0003
    int 0x10

    mov si, loading_msg
    call print_string

    ; Загрузка ядра (32 сектора = 16KB)
    mov ah, 0x02
    mov al, 32
    mov ch, 0
    mov cl, 2
    mov dh, 0
    mov dl, 0
    mov bx, 0x7E00
    int 0x13
    jc error

    jmp 0x7E00

error:
    mov si, err_msg
    call print_string
    jmp $

print_string:
    mov ah, 0x0E
.loop:
    lodsb
    test al, al
    jz .done
    int 0x10
    jmp .loop
.done:
    ret

loading_msg db "Loading DooOS...", 0x0D, 0x0A, 0
err_msg db "Disk error!", 0

times 510-($-$$) db 0
dw 0xAA55
