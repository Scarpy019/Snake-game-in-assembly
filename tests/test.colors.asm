%include "./colors.asm"

global _start

section .data
    textins: db ' zapte ',  0
    textins2: db 'h', 0

section .text
_start:
    call io_clear_screen
    call colors_set_c
    mov rcx, 23
    loopy_1:
        push rcx
        mov rsi, rcx
            mov rcx, 23
            loopy_2:
                mov rdi, rcx
                mov rax, rsi
                and rax, 1
                add rax, rdi
                and rax, 1
                cmp rax, 0
                jne loopy_1_skip
                call buffered_move_cursor
                call colors_fill_c
                loopy_1_skip:
            loop loopy_2
        pop rcx 
    loop loopy_1
    call colors_unset_c

    mov rsi, 24
    mov rdi, 0
    call buffered_move_cursor
    
    call buffered_flush


    call exit 
    ret
 

section .text

exit:
    mov         rax, 60                 ; system call for exit
    xor         rdi, rdi                ; exit code 0
    syscall                           ; invoke operating system to exit
    ret

