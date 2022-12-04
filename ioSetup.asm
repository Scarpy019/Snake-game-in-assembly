
%ifndef IO_SETUP_ASM
    %define IO_SETUP_ASM


%include "regs.asm"

; ------------------------------------------io settings------------------------------------------------

section .bss

TERMIOS_DEFAULT: ; constant block containing original io settings - used for resetting console to initial state
    c_iflag_D resd 1   ; input mode flags
    c_oflag_D resd 1   ; output mode flags
    c_cflag_D resd 1   ; control mode flags
    c_lflag_D resd 1   ; local mode flags
    c_line_D  resb 1   ; line discipline
    c_cc_D    resb 19  ; control characters

termios: ; mutable block containing io settings - used by echo and canonical settings
    c_iflag resd 1   ; input mode flags
    c_oflag resd 1   ; output mode flags
    c_cflag resd 1   ; control mode flags
    c_lflag resd 1   ; local mode flags
    c_line  resb 1   ; line discipline
    c_cc    resb 19  ; control characters

section .text

; acquires initial io settings
termios_init:
    regs


    mov  rax, 16             ; syscall number: SYS_ioctl
    mov  rdi, 0              ; fd:      STDIN_FILENO
    mov  rsi, 0x5401         ; request: TCGETS
    mov  rdx, termios ; request data
    syscall

    mov  rax, 16             ; syscall number: SYS_ioctl
    mov  rdi, 0              ; fd:      STDIN_FILENO
    mov  rsi, 0x5401         ; request: TCGETS
    mov  rdx, TERMIOS_DEFAULT ; request data
    syscall

    regl
    ret

termios_reset:
    regs
    ; Write the original termios structure back
    mov  rax, 16             ; syscall number: SYS_ioctl
    mov  rdi, 0              ; fd:      STDIN_FILENO
    mov  rsi, 0x5402         ; request: TCSETS
    mov  rdx, TERMIOS_DEFAULT        ; request data
    syscall
    regl
    ret

termios_update:
    regs
    ; Write modified termios structure
    mov  rax, 16             ; syscall number: SYS_ioctl
    mov  rdi, 0              ; fd:      STDIN_FILENO
    mov  rsi, 0x5402         ; request: TCSETS
    mov  rdx, termios        ; request data
    syscall
    regl
    ret

termios_setCanonical:; rsi - canonical mode flag
    regs
    ; shift rsi to be the correct flag
    and rsi, 1
    shl rsi, 1


    and dword [c_lflag], 0xFD ; Clear ICANON flag to disable canonical mode
    or dword[c_lflag], esi ; set ICANON if rsi was set
    
    ; Write modified termios structure back
    mov  rax, 16             ; syscall number: SYS_ioctl
    mov  rdi, 0              ; fd:      STDIN_FILENO
    mov  rsi, 0x5402         ; request: TCSETS
    mov  rdx, termios        ; request data
    syscall
    regl
    ret


termios_setEcho: ; rsi - echo mode flag
    regs
    and rsi, 1
    shl rsi, 3
    ; Modify flags
    and dword [c_lflag], 0xF7 ; Clear ECHO
    or dword[c_lflag], esi
    
    ; Write termios structure back
    mov  eax, 16             ; syscall number: SYS_ioctl
    mov  edi, 0              ; fd:      STDIN_FILENO
    mov  esi, 0x5402         ; request: TCSETS
    mov  rdx, termios        ; request data
    syscall
    regl
    ret
; ---------------------------------------------------------------------------------------------


section .data

	struc pollfd
		fd: resd 1
		events: resd 1
		revents: resq 1
	endstruc

	readstdin istruc pollfd
	at fd , dd 0
	at events , dd 1
	at revents , dq 0
	iend

inputStatus: dw 0

section .text
check_input:
    regs
    mov dword [readstdin+fd],  0
    mov byte [readstdin+events],  1 
    mov byte [readstdin+revents],  0
    mov rdx, 1 ; timeout
    mov	rsi, 2		; events to listen to
    mov	rdi, readstdin		; file descriptor
    mov	rax, 7		; system call number
    syscall  
    mov [inputStatus], ax
    regl
    ret




print:      ; rsi - address of string, rdx - amount of bytes
    regs
        mov         rax, 1                    ; system call for write
        mov         rdi, 1                    ; file handle 1 is stdout
        syscall                             ; invoke operating system to do the write
    regl
    ret                                 ;return


printNum:
    regs
        mov rax, rsi
        mov rcx,0
        lp:
            xor rdx, rdx
            mov r8, 10
            div r8
            add rdx, '0'
            inc rcx
            push rdx
            cmp rax, 0
            jg lp
        prl:
            mov rsi, rsp
            mov rdx, 1
            call print
            pop rdx
            loop prl
    regl
    ret


section .data
    io_setup_debug_message_1: db 0x1B, '[s', 0x1B, '[25;1H Waiting.   ', 0x1B, '[u', 0
    io_setup_debug_message_2: db 0x1B, '[s', 0x1B, '[25;1H Waiting..  ', 0x1B, '[u', 0
    io_setup_debug_message_3: db 0x1B, '[s', 0x1B, '[25;1H Waiting... ', 0x1B, '[u', 0
    io_setup_debug_addresses: dq io_setup_debug_message_1, io_setup_debug_message_2, io_setup_debug_message_3
    io_setup_debug_id db 0

section .bss
    io_setup_print_buffer: resb 256
    io_setup_num_print_buffer: resb 64
section .data
    io_setup_print_buffer_pos: db 0
    io_setup_debug_print_buffer_flush_calls: dq 0
section .text

buffered_num_push:
    regs
        mov rax, 1
        mov r8, 10 ; holds 10 for the whole subroutine
        mov r9, 1 ; the previous value
        buffered_num_push_b10_loop: ; finds the smallest power of 10 larger than the number (rax), and uses the previous one stored in r9. No divisions this way
            mov r9, rax
            mul r8
            cmp rax, rsi
            jle buffered_num_push_b10_loop
        
        mov rax, rsi
        mov cl, byte[io_setup_print_buffer_pos]
        ;mov r10b, byte[io_setup_print_buffer_pos]
        buffered_num_push_lp:
            xor rdx, rdx ; clears rdx for dividing
            div r9 ; leaves only the first number
            add rax, '0' ; convert digit to correct char
            mov byte[io_setup_print_buffer+rcx], al ; set char 
            ;push rax
            ;call printNum
            ;pop rax
            inc rcx
            cmp rcx, 255 ; check if flushing is needed
            jne buffered_num_push_lp_skip_flush

                ;flush needed
                mov [io_setup_print_buffer_pos], cl
                call buffered_flush ;resets the buffer
                mov cl, 0 ; resets buffer position

            buffered_num_push_lp_skip_flush:
            mov rsi,rdx ; move the remainder away for dividing

                xor rdx,rdx ; divides power of 10 by 10
                mov rax, r9
                div r8
                mov r9, rax

            mov rax,rsi ; set the previous remainder for next loop
            
            cmp r9, 0
            jg buffered_num_push_lp
        mov byte[io_setup_print_buffer+rcx], 0
        
        mov byte[io_setup_print_buffer_pos], cl

    regl
    ret

; pushes to a buffer, requires flush to guarantee send
buffered_push: ; rsi - address of string
    regs
        mov rcx, 0 ; rcx - input string index
        mov dl, byte[io_setup_print_buffer_pos] ; rdx - buffer position
        buffered_push_lp_1:
            cmp byte[rsi+rcx], 0
            je buffered_push_lp_1_break ; breaks loop if null terminator found
            mov al, byte[rsi+rcx]
            ;mov cl, byte[io_setup_print_buffer_pos]
            mov byte[io_setup_print_buffer+rdx], al

            inc cl
            inc dl
            cmp dl, 255

            jne buffered_push_lp_1 ; repeat if buffer not full
            ; flush buffer
            mov byte[io_setup_print_buffer_pos], dl
            call buffered_flush
            mov dl, 0
            jmp buffered_push_lp_1
        buffered_push_lp_1_break:
        
        ; add a terminator at the end
        mov byte[io_setup_print_buffer+rdx], 0
        mov byte[io_setup_print_buffer_pos], dl
    regl
    ret

buffered_flush:
    regs
    mov al, byte[io_setup_print_buffer_pos]
    mov byte[io_setup_print_buffer+rax], 0 ; ensures last byte in buffer is terminator
    mov rsi, io_setup_print_buffer
    call terminated_print
    mov byte[io_setup_print_buffer_pos], 0 ; resets buffer position
    mov rax, qword[io_setup_debug_print_buffer_flush_calls]
    inc rax
    mov qword[io_setup_debug_print_buffer_flush_calls], rax
    regl
    ret
terminated_print:    ; rsi - address of string
    regs
        mov rcx, 0
        terminated_print_counter:; increments string until finds \0
            cmp byte [rsi+rcx],0
            je terminated_print_counter_break
            inc rcx
            jmp terminated_print_counter
        terminated_print_counter_break:
        
        ; sends the syscall
                                                ; target is already in rsi 
        mov rdx, rcx                            ; set amount of bytes 
        mov         rax, 1                      ; system call for write
        mov         rdi, 1                      ; file handle 1 is stdout
        syscall                                 ; invoke operating system to do the write
    
    regl
    ret
section .data
    io_clear_screen_msg: db 33o,'[2J', 33o,'[3J', 33o,'[1;1H', 0 ; clears the current screen, then clears the scrolled buffer and resets the cursor to start
section .text
io_clear_screen:
    push rsi
        mov rsi, io_clear_screen_msg
        call buffered_push
        call buffered_flush
        
    pop rsi
    ret



section .data
    io_set_cursor_command_1 db 33o, '[', 0
    io_set_cursor_command_2 db ';', 0
    io_set_cursor_command_3 db 'H', 0
section .text
    buffered_move_cursor: ;  rdi - x, rsi - y
        regs
            mov rdx, rsi
            mov rsi, io_set_cursor_command_1
            call buffered_push

            mov rsi, rdx
            call buffered_num_push 

            mov rsi, io_set_cursor_command_2
            call buffered_push

            mov rsi, rdi
            call buffered_num_push

            mov rsi, io_set_cursor_command_3
            call buffered_push
        regl
        ret
section .bss
input_Buffer: resq 1
section .text

read_b:      ; Reads 1 byte from stdin and puts into rax
    regs
            mov         rax, 0
            mov         rdi, 0
            mov         rsi, input_Buffer
            mov         rdx, 1
            syscall
            mov         rax, [input_Buffer]
    regl
    ret
%endif