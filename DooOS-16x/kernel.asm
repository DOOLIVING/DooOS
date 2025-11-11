; ==================================================================
; DooOS Kernel
; Copyright (C) 2025 DOOLIVING
;
; Provides shell interface and file system operations
; Features:
;   - Interactive shell with commands
;   - Simple file system with file creation/editing
;   - .doo program execution
;   - Colorful output via INT 0x21 API
;
; Includes x16-PRos Kernel Output API by PRoX2011
; API License: MIT
; ==================================================================

org 0x7E00
bits 16

start:
    mov ax, 0
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    call api_output_init

    mov ah, 0x06
    int 0x21


    mov bl, 0x09
    mov ah, 0x07
    int 0x21

    mov si, os_art
    mov ah, 0x01
    int 0x21

    mov si, welcome_msg
    mov ah, 0x0B
    int 0x21

    call init_filesystem
    call init_fat12_readonly

shell_loop:
    mov si, prompt_prefix
    mov ah, 0x0A
    int 0x21

    mov si, prompt
    mov ah, 0x0E
    int 0x21

    mov di, command_buffer
    call read_string

    mov si, command_buffer
    call process_command
    jmp shell_loop

process_command:
    cmp byte [si], 0
    je .empty_cmd

    mov di, cmd_help
    call compare_string
    jc .cmd_help

    mov di, cmd_create
    call compare_string
    jc .cmd_create_simple

    mov di, cmd_edit
    call compare_string
    jc .cmd_edit_file

    mov di, cmd_files
    call compare_string
    jc .cmd_files_hybrid

    mov di, cmd_open
    call compare_string
    jc .cmd_open_hybrid

    mov di, cmd_run
    call compare_string
    jc .cmd_run_hybrid

    mov di, cmd_reboot
    call compare_string
    jc .cmd_reboot

    mov di, cmd_clear
    call compare_string
    jc .cmd_clear

    mov si, unknown_cmd
    mov ah, 0x0C
    int 0x21
    ret

.empty_cmd:
    ret

.cmd_help:
    call show_help
    ret

.cmd_create_simple:
    call create_file_simple
    ret

.cmd_edit_file:
    call edit_file
    ret

.cmd_files_hybrid:
    call list_files_hybrid
    ret

.cmd_open_hybrid:
    call open_file_hybrid
    ret

.cmd_run_hybrid:
    call run_program_hybrid
    ret

.cmd_clear:
    mov ah, 0x06
    int 0x21
    ret

.cmd_reboot:
    mov si, rebooting_msg
    mov ah, 0x0D
    int 0x21
    mov cx, 0xFFFF
.delay:
    loop .delay
    int 0x19

show_help:
    mov si, help_header
    mov ah, 0x0B
    int 0x21

    mov si, help_help
    mov ah, 0x0A
    int 0x21

    mov si, help_create
    mov ah, 0x0A
    int 0x21

    mov si, help_edit
    mov ah, 0x0A
    int 0x21

    mov si, help_files
    mov ah, 0x0A
    int 0x21

    mov si, help_open
    mov ah, 0x0A
    int 0x21

    mov si, help_run
    mov ah, 0x0A
    int 0x21

    mov si, help_clear
    mov ah, 0x0A
    int 0x21

    mov si, help_reboot
    mov ah, 0x0A
    int 0x21

    ret

; ==================================================================
; ПРОСТАЯ ФС В ПАМЯТИ (для записи и редактирования)
; ==================================================================

file_system_start equ 0xA000
max_files equ 10
file_entry_size equ 128

init_filesystem:
    mov di, file_system_start
    mov cx, max_files * file_entry_size
    xor al, al
    rep stosb
    mov word [file_count], 0
    ret

create_file_simple:
    mov si, enter_filename
    mov ah, 0x0E
    int 0x21
    mov di, filename_buffer
    call read_string

    cmp byte [filename_buffer], 0
    je .no_name

    mov bx, file_system_start
    mov cx, max_files
.check_existing:
    cmp byte [bx], 0
    je .next_check

    mov si, filename_buffer
    mov di, bx
    call compare_string
    jc .file_exists

.next_check:
    add bx, file_entry_size
    loop .check_existing

    mov bx, file_system_start
    mov cx, max_files
.find_slot:
    cmp byte [bx], 0
    je .found_slot
    add bx, file_entry_size
    loop .find_slot

    mov si, no_space_msg
    mov ah, 0x0C
    int 0x21
    ret

.file_exists:
    mov si, file_exists_msg
    mov ah, 0x0C
    int 0x21
    ret

.found_slot:
    mov si, filename_buffer
    mov di, bx
    call copy_string


    mov si, enter_content
    mov ah, 0x0E
    int 0x21
    mov di, file_content_buffer
    call read_string

    mov di, bx
    add di, 16
    mov si, file_content_buffer
    call copy_string

    inc word [file_count]

    mov si, file_created
    mov ah, 0x0A
    int 0x21
    ret

.no_name:
    mov si, no_name_msg
    mov ah, 0x0C
    int 0x21
    ret

edit_file:
    mov si, enter_filename
    mov ah, 0x0E
    int 0x21
    mov di, filename_buffer
    call read_string

    cmp byte [filename_buffer], 0
    je .no_name


    mov bx, file_system_start
    mov cx, max_files
.find_file:
    cmp byte [bx], 0
    je .next_file

    mov si, filename_buffer
    mov di, bx
    call compare_string
    jc .file_found

.next_file:
    add bx, file_entry_size
    loop .find_file

    mov si, file_not_found
    mov ah, 0x0C
    int 0x21
    ret

.file_found:
    mov si, current_content_msg
    mov ah, 0x0B ; Голубой
    int 0x21

    mov si, bx
    add si, 16
    mov ah, 0x01 ; Белый
    int 0x21

    mov ah, 0x05
    int 0x21

    mov si, enter_new_content
    mov ah, 0x0E ; Желтый
    int 0x21

    mov di, file_content_buffer
    call read_string

    mov di, bx
    add di, 16
    mov si, file_content_buffer
    call copy_string

    mov si, file_updated
    mov ah, 0x0A ; Зеленый
    int 0x21
    ret

.no_name:
    mov si, no_name_msg
    mov ah, 0x0C ; Красный
    int 0x21
    ret

; ==================================================================
; FAT12 ТОЛЬКО ДЛЯ ЧТЕНИЯ
; ==================================================================

init_fat12_readonly:

    mov ax, 19
    mov cx, 14
    mov bx, fat12_root_buffer
    call read_sectors_simple
    ret

read_sectors_simple:
    pusha
    mov [sector_count], cx
    mov [buffer_offset], bx
    mov [current_lba], ax

.next_sector:
    mov ax, [current_lba]
    mov bx, ax
    mov dx, 0
    div word [sectors_per_track]
    inc dl
    mov cl, dl

    mov ax, bx
    mov dx, 0
    div word [sectors_per_track]
    mov dx, 0
    div word [heads_per_cylinder]
    mov dh, dl
    mov ch, al

    mov di, 3

.retry:
    mov ah, 0x02
    mov al, 1
    mov dl, 0
    mov bx, [buffer_offset]
    int 0x13
    jnc .success

    dec di
    jz .error
    mov ah, 0x00
    int 0x13
    jmp .retry

.success:
    inc word [current_lba]
    add word [buffer_offset], 512
    dec word [sector_count]
    jnz .next_sector

    popa
    ret

.error:

    popa
    ret

; ==================================================================
; ГИБРИДНЫЕ ФУНКЦИИ
; ==================================================================

list_files_hybrid:
    mov si, files_header
    mov ah, 0x0B ;
    int 0x21


    mov si, fat12_files_header
    mov ah, 0x0D
    int 0x21

    mov di, fat12_root_buffer
    mov cx, 224

.list_fat12:
    cmp byte [di], 0
    je .next_fat12
    cmp byte [di], 0xE5
    je .next_fat12

    mov si, file_prefix
    mov ah, 0x0D
    int 0x21

    mov si, di
    mov ah, 0x01
    int 0x21

    mov ah, 0x05
    int 0x21

.next_fat12:
    add di, 32
    loop .list_fat12

    mov si, memory_files_header
    mov ah, 0x0E
    int 0x21

    mov cx, [file_count]
    test cx, cx
    jnz .show_memory_files

    mov si, no_files_msg
    mov ah, 0x0C
    int 0x21
    ret

.show_memory_files:
    mov bx, file_system_start
    mov cx, max_files

.show_loop:
    cmp byte [bx], 0
    je .next_memory_file

    mov si, file_prefix
    mov ah, 0x0E ; Желтый
    int 0x21

    mov si, bx
    mov ah, 0x01 ; Белый
    int 0x21

    mov ah, 0x05
    int 0x21

.next_memory_file:
    add bx, file_entry_size
    loop .show_loop
    ret

open_file_hybrid:
    mov si, enter_filename
    mov ah, 0x0E
    int 0x21
    mov di, filename_buffer
    call read_string

    cmp byte [filename_buffer], 0
    je .no_name

    mov bx, file_system_start
    mov cx, max_files
.find_memory:
    cmp byte [bx], 0
    je .next_memory

    mov si, filename_buffer
    mov di, bx
    call compare_string
    jc .found_memory

.next_memory:
    add bx, file_entry_size
    loop .find_memory

    mov di, fat12_root_buffer
    mov cx, 224
.find_fat12:
    cmp byte [di], 0
    je .next_fat12
    cmp byte [di], 0xE5
    je .next_fat12

    mov si, filename_buffer
    push di
    mov cx, 11
    repe cmpsb
    pop di
    je .found_fat12

.next_fat12:
    add di, 32
    loop .find_fat12

    mov si, file_not_found
    mov ah, 0x0C ; Красный
    int 0x21
    ret

.found_memory:

    mov si, file_content_header
    mov ah, 0x0B ; Голубой
    int 0x21

    mov si, bx
    add si, 16
    mov ah, 0x01 ; Белый
    int 0x21

    mov ah, 0x05
    int 0x21
    ret

.found_fat12:

    mov si, file_content_header
    mov ah, 0x0B ; Голубой
    int 0x21

    mov si, fat12_file_msg
    mov ah, 0x0D ; Фиолетовый
    int 0x21

    mov ah, 0x05
    int 0x21
    ret

.no_name:
    mov si, no_name_msg
    mov ah, 0x0C ; Красный
    int 0x21
    ret

run_program_hybrid:
    mov si, enter_filename
    mov ah, 0x0E ; Желтый
    int 0x21
    mov di, filename_buffer
    call read_string

    cmp byte [filename_buffer], 0
    je .no_name

    mov bx, file_system_start
    mov cx, max_files
.find_file:
    cmp byte [bx], 0
    je .next_file

    mov si, filename_buffer
    mov di, bx
    call compare_string
    jc .file_found

.next_file:
    add bx, file_entry_size
    loop .find_file

    mov si, file_not_found
    mov ah, 0x0C ; Красный
    int 0x21
    ret

.file_found:

    mov si, bx
    call get_file_extension
    mov di, doo_extension
    call compare_string
    jc .valid_extension

    mov si, not_program_msg
    mov ah, 0x0C ; Красный
    int 0x21
    ret

.valid_extension:
    mov si, bx
    add si, 16
    mov di, program_buffer
    call copy_string

    mov si, running_program_msg
    mov ah, 0x0A ; Зеленый
    int 0x21

    mov si, program_buffer
    call execute_program
    ret

.no_name:
    mov si, no_name_msg
    mov ah, 0x0C ; Красный
    int 0x21
    ret



get_file_extension:
    push si
.find_dot:
    mov al, [si]
    test al, al
    jz .no_extension
    cmp al, '.'
    je .found_dot
    inc si
    jmp .find_dot

.found_dot:
    pop ax
    ret

.no_extension:
    pop si
    mov si, empty_string
    ret

execute_program:
    mov di, program_buffer
.program_loop:
    mov al, [di]
    test al, al
    jz .program_done

    cmp al, ' '
    je .next_char
    cmp al, 0x0D
    je .next_char
    cmp al, 0x0A
    je .next_char

    mov si, di
    mov bx, cmd_print
    call compare_string_prefix
    jc .do_print

    mov si, unknown_program_cmd
    mov ah, 0x0C ; Красный
    int 0x21
    mov si, di
    mov ah, 0x01 ; Белый
    int 0x21
    mov ah, 0x05
    int 0x21
    ret

.do_print:
    add di, 5

.skip_spaces:
    mov al, [di]
    cmp al, ' '
    jne .check_dash
    inc di
    jmp .skip_spaces

.check_dash:
    cmp al, '-'
    jne .invalid_print
    inc di

.skip_spaces2:
    mov al, [di]
    cmp al, ' '
    jne .print_text
    inc di
    jmp .skip_spaces2

.print_text:
    mov si, di
.print_loop:
    mov al, [di]
    cmp al, 0
    je .program_done
    cmp al, 0x0D
    je .next_line
    cmp al, 0x0A
    je .next_line
    inc di
    jmp .print_loop

.next_line:
    mov byte [di], 0
    mov ah, 0x09 ; Синий
    int 0x21
    mov ah, 0x05
    int 0x21
    inc di
    jmp .program_loop

.invalid_print:
    mov si, invalid_print_msg
    mov ah, 0x0C ; Красный
    int 0x21
    ret

.next_char:
    inc di
    jmp .program_loop

.program_done:
    mov si, program_end_msg
    mov ah, 0x0A ; Зеленый
    int 0x21
    ret

string_length:
    mov cx, 0
.count_loop:
    cmp byte [si], 0
    je .done_count
    inc si
    inc cx
    jmp .count_loop
.done_count:
    ret

compare_string_prefix:
    push si
    push di
.comp_loop:
    mov al, [si]
    mov bl, [di]
    cmp al, bl
    jne .comp_not_equal
    test bl, bl
    jz .comp_equal
    inc si
    inc di
    jmp .comp_loop
.comp_equal:
    pop di
    pop si
    stc
    ret
.comp_not_equal:
    pop di
    pop si
    clc
    ret

read_string:
    mov cx, 0
.read_loop:
    mov ah, 0x00
    int 0x16

    cmp al, 0x0D
    je .read_done

    cmp al, 0x08
    je .read_backspace

    cmp cx, 63
    jae .read_loop

    stosb
    inc cx

    push si
    push di
    push cx

    mov si, char_buffer
    mov [si], al
    mov ah, 0x0F
    int 0x21

    pop cx
    pop di
    pop si

    jmp .read_loop

.read_backspace:
    test cx, cx
    jz .read_loop

    dec di
    dec cx

    push si
    mov si, backspace_seq
    mov ah, 0x0F
    int 0x21
    pop si

    jmp .read_loop

.read_done:
    mov al, 0
    stosb
    mov ah, 0x05
    int 0x21
    ret

compare_string:
    push si
    push di
.comp_loop:
    mov al, [si]
    mov bl, [di]
    cmp al, bl
    jne .comp_not_equal
    test al, al
    jz .comp_equal
    inc si
    inc di
    jmp .comp_loop
.comp_equal:
    pop di
    pop si
    stc
    ret
.comp_not_equal:
    pop di
    pop si
    clc
    ret

copy_string:
.copy_loop:
    mov al, [si]
    mov [di], al
    inc si
    inc di
    test al, al
    jnz .copy_loop
    ret

current_color db 0x0F

api_output_init:
    pusha
    push es
    xor ax, ax
    mov es, ax
    mov word [es:0x21*4], int21_handler
    mov word [es:0x21*4+2], cs
    mov ax, 0x0003
    int 0x10
    pop es
    popa
    ret

int21_handler:
    pusha
    cmp ah, 0x00
    je .init
    cmp ah, 0x01
    je .print_string
    cmp ah, 0x02
    je .print_string_green
    cmp ah, 0x03
    je .print_string_cyan
    cmp ah, 0x04
    je .print_string_red
    cmp ah, 0x05
    je .print_newline
    cmp ah, 0x06
    je .clear_screen
    cmp ah, 0x07
    je .set_color
    cmp ah, 0x08
    je .print_colored
    cmp ah, 0x09
    je .print_string_blue
    cmp ah, 0x0A
    je .print_string_bright_green
    cmp ah, 0x0B
    je .print_string_bright_cyan
    cmp ah, 0x0C
    je .print_string_bright_red
    cmp ah, 0x0D
    je .print_string_magenta
    cmp ah, 0x0E
    je .print_string_yellow
    cmp ah, 0x0F
    je .print_string_bright_white
    jmp .done

.init:
    mov ax, 0x0003
    int 0x10
    jmp .done

.print_string:
    mov ah, 0x0E
    mov bl, 0x0F
    jmp .print_char

.print_string_green:
    mov ah, 0x0E
    mov bl, 0x02
    jmp .print_char

.print_string_blue:
    mov ah, 0x0E
    mov bl, 0x01
    jmp .print_char

.print_string_bright_green:
    mov ah, 0x0E
    mov bl, 0x0A
    jmp .print_char

.print_string_bright_cyan:
    mov ah, 0x0E
    mov bl, 0x0B
    jmp .print_char

.print_string_bright_red:
    mov ah, 0x0E
    mov bl, 0x0C
    jmp .print_char

.print_string_magenta:
    mov ah, 0x0E
    mov bl, 0x0D
    jmp .print_char

.print_string_yellow:
    mov ah, 0x0E
    mov bl, 0x0E
    jmp .print_char

.print_string_bright_white:
    mov ah, 0x0E
    mov bl, 0x0F
    jmp .print_char

.print_string_cyan:
    mov ah, 0x0E
    mov bl, 0x03
    jmp .print_char

.print_string_red:
    mov ah, 0x0E
    mov bl, 0x04
    jmp .print_char

.print_char:
    lodsb
    cmp al, 0
    je .done
    cmp al, 0x0A
    je .handle_newline
    int 0x10
    jmp .print_char
.handle_newline:
    mov al, 0x0D
    int 0x10
    mov al, 0x0A
    int 0x10
    jmp .print_char

.print_newline:
    mov ah, 0x0E
    mov al, 0x0D
    int 0x10
    mov al, 0x0A
    int 0x10
    jmp .done

.clear_screen:
    mov ax, 0x0003
    int 0x10
    jmp .done

.set_color:
    mov [current_color], bl
    jmp .done

.print_colored:
    mov ah, 0x0E
    mov bl, [current_color]
.print_colored_char:
    lodsb
    cmp al, 0
    je .done
    cmp al, 0x0A
    je .handle_colored_newline
    int 0x10
    jmp .print_colored_char
.handle_colored_newline:
    mov al, 0x0D
    int 0x10
    mov al, 0x0A
    int 0x10
    jmp .print_colored_char

.done:
    popa
    iret



sectors_per_track dw 18
heads_per_cylinder dw 2


file_count dw 0
sector_count dw 0
buffer_offset dw 0
current_lba dw 0

os_art:
    db '=========================================', 0x0D, 0x0A
    db '  _____           _     ___  ___         ', 0x0D, 0x0A
    db ' |  _  |___ ___  |_|___|   ||   |___ ___ ', 0x0D, 0x0A
    db ' |     | . | . | | | . | | || | | . | . |', 0x0D, 0x0A
    db ' |__|__|___|_  |_| |___|_|_||___|___|_  |', 0x0D, 0x0A
    db '           |___|                     |___|', 0x0D, 0x0A
    db '=========================================', 0x0D, 0x0A, 0

welcome_msg db 'Welcome to DooOS Hybrid File System!', 0x0D, 0x0A
            db 'Type "help" for available commands', 0x0D, 0x0A, 0
prompt_prefix db '[', 0
prompt db 'DooOS>', 0
prompt_suffix db '] $ ', 0
rebooting_msg db 'System rebooting...', 0

cmd_help db 'help', 0
cmd_create db 'create', 0
cmd_edit db 'edit', 0
cmd_files db 'files', 0
cmd_open db 'open', 0
cmd_run db 'run', 0
cmd_reboot db 'reboot', 0
cmd_clear db 'clear', 0

cmd_print db 'print', 0

doo_extension db '.doo', 0


unknown_cmd db 'Error: Unknown command!', 0
unknown_program_cmd db 'Error: Unknown program command: ', 0
invalid_print_msg db 'Error: Invalid print command syntax!', 0
program_end_msg db 'Program finished successfully', 0


enter_filename db 'Enter filename: ', 0
enter_content db 'Enter content: ', 0
enter_new_content db 'Enter new content: ', 0
file_created db 'Success: File created!', 0
file_updated db 'Success: File updated!', 0
file_exists_msg db 'Error: File already exists!', 0
current_content_msg db 'Current content:', 0
no_space_msg db 'Error: No space for new file!', 0
no_name_msg db 'Error: Empty filename!', 0
files_header db 'All files:', 0x0D, 0x0A, 0
fat12_files_header db 'FAT12 files:', 0x0D, 0x0A, 0
memory_files_header db 'Memory files:', 0x0D, 0x0A, 0
no_files_msg db 'No files found', 0
file_prefix db '- ', 0
file_not_found db 'Error: File not found!', 0
file_content_header db 'File content:', 0
fat12_file_msg db '[FAT12 file - read only]', 0
running_program_msg db 'Running program...', 0
not_program_msg db 'Error: File is not a .doo program!', 0

help_header db 'Available commands:', 0x0D, 0x0A, 0
help_help db '  help    - Show this help message', 0x0D, 0x0A, 0
help_create db '  create  - Create a new file (in memory)', 0x0D, 0x0A, 0
help_edit db '  edit    - Edit file content (memory files)', 0x0D, 0x0A, 0
help_files db '  files   - List all files', 0x0D, 0x0A, 0
help_open db '  open    - Open and view a file', 0x0D, 0x0A, 0
help_run db '  run     - Run a .doo program', 0x0D, 0x0A, 0
help_clear db '  clear   - Clear screen', 0x0D, 0x0A, 0
help_reboot db '  reboot  - Reboot the system', 0x0D, 0x0A, 0


command_buffer times 64 db 0
filename_buffer times 16 db 0
file_content_buffer times 100 db 0
program_buffer times 128 db 0
char_buffer db 0, 0
backspace_seq db 8, ' ', 8, 0
empty_string db 0

fat12_root_buffer times 7168 db 0

times 16384 - ($-$$) db 0
