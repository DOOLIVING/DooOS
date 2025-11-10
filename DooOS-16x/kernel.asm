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
    
    mov si, welcome_msg
    mov ah, 0x02        
    int 0x21
    
    call init_filesystem

shell_loop:
    mov si, prompt
    mov ah, 0x02
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
    jc .cmd_create
    
    mov di, cmd_files
    call compare_string
    jc .cmd_files
    
    mov di, cmd_open
    call compare_string
    jc .cmd_open
    
    mov di, cmd_run
    call compare_string
    jc .cmd_run
    
    mov di, cmd_reboot
    call compare_string
    jc .cmd_reboot
    
    mov si, unknown_cmd
    mov ah, 0x04
    int 0x21
    ret

.empty_cmd:
    ret

.cmd_help:
    call show_help
    ret

.cmd_create:
    call create_file
    ret

.cmd_files:
    call list_files
    ret

.cmd_open:
    call open_file
    ret

.cmd_run:
    call run_program
    ret

.cmd_reboot:
    mov si, rebooting_msg
    mov ah, 0x01 
    int 0x21
    mov cx, 0xFFFF
.delay:
    loop .delay
    int 0x19


show_help:
    mov si, help_header
    mov ah, 0x03 
    int 0x21
    
    mov si, help_help
    mov ah, 0x01     
    int 0x21
    
    mov si, help_create
    mov ah, 0x01
    int 0x21
    
    mov si, help_files
    mov ah, 0x01
    int 0x21
    
    mov si, help_open
    mov ah, 0x01
    int 0x21
    
    mov si, help_run
    mov ah, 0x01
    int 0x21
    
    mov si, help_reboot
    mov ah, 0x01
    int 0x21
    
    ret


run_program:
    mov si, enter_filename
    mov ah, 0x02       
    int 0x21
    mov di, filename_buffer
    call read_string
    
    cmp byte [filename_buffer], 0
    je .no_name
    
    ; Найти файл
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
    mov ah, 0x04    
    int 0x21
    ret

.file_found:
    mov si, bx
    call get_file_extension
    mov di, doo_extension
    call compare_string
    jc .valid_extension
    
    mov si, not_program_msg
    mov ah, 0x04        
    int 0x21
    ret

.valid_extension:

    mov si, bx
    add si, 16  
    mov di, program_buffer
    call copy_string
    

    mov si, running_program_msg
    mov ah, 0x02     
    int 0x21
    
    mov si, program_buffer
    call execute_program
    
    ret

.no_name:
    mov si, no_name_msg
    mov ah, 0x04   
    int 0x21
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
    mov ah, 0x04      
    int 0x21
    mov si, di
    mov ah, 0x01     
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
    mov ah, 0x01        
    int 0x21
    mov ah, 0x05      
    int 0x21
    inc di
    jmp .program_loop

.invalid_print:
    mov si, invalid_print_msg
    mov ah, 0x04       
    int 0x21
    ret

.next_char:
    inc di
    jmp .program_loop

.program_done:
    mov si, program_end_msg
    mov ah, 0x02        
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

file_system_start equ 0x9000
max_files equ 5
file_entry_size equ 80

init_filesystem:
    mov di, file_system_start
    mov cx, max_files * file_entry_size
    xor al, al
    rep stosb
    
    mov word [file_count], 0
    ret

create_file:
    mov si, enter_filename
    mov ah, 0x02     
    int 0x21
    mov di, filename_buffer
    call read_string
    
    cmp byte [filename_buffer], 0
    je .no_name
    
    mov bx, file_system_start
    mov cx, max_files
.find_slot:
    cmp byte [bx], 0
    je .found_slot
    add bx, file_entry_size
    loop .find_slot
    
    mov si, no_space_msg
    mov ah, 0x04     
    int 0x21
    ret

.found_slot:
    mov si, filename_buffer
    mov di, bx
    call copy_string
    
    mov si, enter_content
    mov ah, 0x02        
    int 0x21
    mov di, file_content_buffer
    call read_string
    
    mov di, bx
    add di, 16
    mov si, file_content_buffer
    call copy_string
    
    inc word [file_count]
    
    mov si, file_created
    mov ah, 0x02        
    int 0x21
    ret
    
.no_name:
    mov si, no_name_msg
    mov ah, 0x04        
    int 0x21
    ret

list_files:
    mov si, files_header
    mov ah, 0x03       
    int 0x21
    
    mov cx, [file_count]
    test cx, cx
    jnz .show_files
    
    mov si, no_files_msg
    mov ah, 0x04        
    int 0x21
    ret

.show_files:
    mov bx, file_system_start
    mov cx, max_files
    
.show_loop:
    cmp byte [bx], 0
    je .next_file
    
    mov si, file_prefix
    mov ah, 0x01       
    int 0x21
    mov si, bx
    mov ah, 0x01
    int 0x21
    

    mov si, bx
    call get_file_extension
    mov di, doo_extension
    call compare_string
    jnc .not_program
    mov si, program_indicator
    mov ah, 0x03       
    int 0x21
.not_program:
    
    mov ah, 0x05        
    int 0x21
    
.next_file:
    add bx, file_entry_size
    loop .show_loop
    ret

open_file:
    mov si, enter_filename
    mov ah, 0x02        ; исправить
    int 0x21
    mov di, filename_buffer
    call read_string
    
    cmp byte [filename_buffer], 0
    je .no_name
    
    ; Найти файл
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
    mov ah, 0x04        
    int 0x21
    ret

.file_found:
  
    mov [current_file], bx
    
    mov si, file_content_header
    mov ah, 0x03       
    int 0x21
    mov si, bx
    add si, 16
    mov ah, 0x01     
    int 0x21
    mov ah, 0x05     
    int 0x21
    
    mov si, editing_instructions
    mov ah, 0x02        
    int 0x21

    mov di, bx
    add di, 16  
    mov cx, 64  
    
.edit_loop:
    mov ah, 0x00
    int 0x16
    
    cmp al, 0x1B 
    je .save_and_exit
    
    cmp al, 0x0D 
    je .handle_enter
    
    cmp al, 0x08  
    je .handle_backspace
    
    ;
    cmp cx, 1
    jbe .edit_loop
    
 
    mov [di], al
    inc di
    dec cx

    push si
    push ax
    mov si, char_buffer
    mov [si], al
    mov ah, 0x01        
    int 0x21
    pop ax
    pop si
    
    jmp .edit_loop

.handle_enter:
    mov al, 0x0D
    mov [di], al
    inc di
    dec cx
    mov ah, 0x05        
    int 0x21
    jmp .edit_loop

.handle_backspace:

    mov ax, di
    sub ax, bx
    cmp ax, 16
    jbe .edit_loop
    
    dec di
    inc cx
    mov byte [di], 0
    

    push si
    mov si, backspace_seq
    mov ah, 0x01       
    int 0x21
    pop si
    jmp .edit_loop

.save_and_exit:

    mov byte [di], 0
    
    mov si, file_saved
    mov ah, 0x02       
    int 0x21
    ret

.no_name:
    mov si, no_name_msg
    mov ah, 0x04       
    int 0x21
    ret
print_string:
    mov ah, 0x01        
    int 0x21
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
    mov ah, 0x02        
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
    mov ah, 0x02       
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
    ; Set up INT 0x21 in IVT
    xor ax, ax
    mov es, ax
    mov word [es:0x21*4], int21_handler ; Offset
    mov word [es:0x21*4+2], cs          ; Segment
    mov ax, 0x0003                      ; 80x25 text mode
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
    jmp .done

.init:
    mov ax, 0x0003      
    int 0x10
    jmp .done

.print_string:
    mov ah, 0x0E
    mov bl, 0x0F          
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

.print_string_green:
    mov ah, 0x0E
    mov bl, 0x0A        
.print_green_char:
    lodsb
    cmp al, 0
    je .done
    int 0x10
    jmp .print_green_char

.print_string_cyan:
    mov ah, 0x0E
    mov bl, 0x0B          
.print_cyan_char:
    lodsb
    cmp al, 0
    je .done
    int 0x10
    jmp .print_cyan_char

.print_string_red:
    mov ah, 0x0E
    mov bl, 0x0C         
.print_red_char:
    lodsb
    cmp al, 0
    je .done
    int 0x10
    jmp .print_red_char

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


welcome_msg db 'DooOS> ', 0
prompt db 'DooOS> ', 0
newline db 0x0D, 0x0A, 0
rebooting_msg db 'Rebooting...', 0

; Команды
cmd_help db 'help', 0
cmd_create db 'create', 0
cmd_files db 'files', 0
cmd_open db 'open', 0
cmd_run db 'run', 0
cmd_reboot db 'reboot', 0

; Команды программ
cmd_print db 'print', 0

; Расширения
doo_extension db '.doo', 0

; Тексты
unknown_cmd db 'Error: Unknown command!', 0

; Файловая система
enter_filename db 'Enter filename: ', 0
enter_content db 'Enter content: ', 0
file_created db 'Success: File created!', 0
no_space_msg db 'Error: No space for new file!', 0
no_name_msg db 'Error: Empty filename!', 0
files_header db 'Files list:', 0
no_files_msg db 'No files found', 0
file_prefix db '- ', 0
file_not_found db 'Error: File not found!', 0
file_content_header db 'File content:', 0
editing_instructions db 'Editing mode - type text, ESC to save and exit', 0
file_saved db 'Success: File saved!', 0
program_indicator db ' [PROGRAM]', 0

; Программы
running_program_msg db 'Running program...', 0
not_program_msg db 'Error: File is not a .doo program!', 0
unknown_program_cmd db 'Error: Unknown program command: ', 0
invalid_print_msg db 'Error: Invalid print command syntax!', 0
program_end_msg db 'Program finished successfully', 0

help_header db 'Available commands:', 0x0D, 0x0A, 0
help_help db '  help    - Show this help message', 0x0D, 0x0A, 0
help_create db '  create  - Create a new file', 0x0D, 0x0A, 0
help_files db '  files   - List all files', 0x0D, 0x0A, 0
help_open db '  open    - Open and edit a file', 0x0D, 0x0A, 0
help_run db '  run     - Run a .doo program', 0x0D, 0x0A, 0
help_reboot db '  reboot  - Reboot the system', 0x0D, 0x0A, 0

; Буферы
command_buffer times 64 db 0
filename_buffer times 16 db 0
file_content_buffer times 64 db 0
program_buffer times 128 db 0
char_buffer db 0, 0
backspace_seq db 8, ' ', 8, 0 


file_count dw 0
current_file dw 0
empty_string db 0


times 4096 - ($-$$) db 0