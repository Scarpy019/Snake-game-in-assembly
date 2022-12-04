%include "./ioSetup.asm"

global _start

section .data
    textins: db 'zapte',  0
    textins2: db 'h', 0

section .text
_start:
    mov rcx, 2
    textins_loop:
    mov rsi, textins2
    call buffered_push 
    loop textins_loop

    ;mov rsi, textins
    ;call buffered_push

    ;call buffered_flush
    mov rsi, [io_setup_debug_print_buffer_flush_calls]
    call buffered_num_push
    call buffered_flush

    call io_clear_screen

    mov rsi, 14
    call buffered_move_cursor

    mov rsi, textins
    call buffered_push
    call buffered_flush


    call exit 
    ret
 

section .text

exit:
    mov         rax, 60                 ; system call for exit
    xor         rdi, rdi                ; exit code 0
    syscall                           ; invoke operating system to exit
    ret




