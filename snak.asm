
%include "./regs.asm"
%include "./ioSetup.asm"
%include "./colors.asm"


global _start


section .text

exit:
    mov         rax, 60                 ; system call for exit
    xor         rdi, rdi                ; exit code 0
    syscall                           ; invoke operating system to exit
    ret

section .bss
    gameBoard: resq 22*22

section .data
    posX: dq 6
    posY: dq 6

    direction dq 0 ; 0 - down, 1 - right, 2 - up, 3 - left
    prDir dq 0
    startingScore dq 3
    score dq 3

    
section .data
    cursorRestX: dq 26
    cursorRestY: dq 23


section .text
_start:
    ;mov rbp, rsp; for correct debugging
    
    ; initialize termios and set up terminal
    call termios_init

    mov rsi, 0
    call termios_setCanonical

    mov rsi, 0
    call termios_setEcho

    ; set starting score
    hmovq score, startingScore

    ; zfill the game board
    mov rcx, 22*22
    start_init_board:
        mov qword[gameBoard+8*rcx], 0
        loop start_init_board
    
    ; set the pellet to a random position
    call random_pellet_pos




    mov qword[tv_sec], 0
    mov qword[tv_usec], 1000000  * 400;ms

    start_lp:   ; main game loop       
        
        ; sub 1 from block lifetimes
        mov rcx, (22*22)
        start_lp_dec_board:
        push rcx
            dec rcx
            cmp qword[gameBoard+8*rcx], 0
            je start_lp_dec_board_cont 
            dec qword[gameBoard+8*rcx]
            start_lp_dec_board_cont:
        pop rcx
        loop start_lp_dec_board



        ; snake head movement
        mov rdx, qword[direction]
        mov rax, rdx
        and rdx, 01b
        cmp rdx, 0
        jne start_lp__horizontal
            ;vertical movement
            mov r8, posY
            jmp start_lp_end_dir_select
        start_lp__horizontal: 
            ;horizontal movement
            mov r8, posX
        start_lp_end_dir_select:

        and rax, 10b ; get second bit
        cmp rax, 0
        je start_lp_add_dir 
            ; sub dir
            mov rdx, qword[r8]
            sub rdx, 1
            mov qword[r8], rdx
            jmp start_lp_end_dir_adjust
        start_lp_add_dir:
            mov rdx, qword[r8]
            add rdx, 1
            mov qword[r8], rdx
        start_lp_end_dir_adjust:


        ; border kills
        cmp qword[posX], 1
        je start_lp_break

        cmp qword[posY], 1
        je start_lp_break

        cmp qword[posX], 24
        je start_lp_break

        cmp qword[posY], 24
        je start_lp_break
        



        ; pellet and body check
        mov r8, 22
        mov rax, qword[posY]
        sub rax, 2
        mul r8
        add rax, qword[posX]
        sub rax, 2
        cmp rax, qword[pelletPos]
        jne start_lp_no_pellet
            inc qword[score]
            call random_pellet_pos

            sub qword[tv_usec], 1000000  * 10;ms
            

        start_lp_no_pellet:
        cmp qword[gameBoard+8*rax], 0
        jne start_lp_break

        ; leave trail behind head
        
        ; calculate game board position of head into rax
        mov r8, 22 ; constant for mul
        mov rax, qword[posY] 
        sub rax, 2 ; compensate for offset
        mul r8
        add rax, qword[posX]
        sub rax, 2 ; compensate for offset

        mov rdx, qword[score]
        mov qword[gameBoard+8*rax], rdx




        call io_clear_screen ; redraw
        
        ; outer frame
        call colors_set_c
            mov rcx, 24
            mov rdi, 1
            mov rsi, 1
            call buffered_move_cursor
            start_lp_draw_top_loop:
                call colors_fill_c
                loop start_lp_draw_top_loop
            mov rcx, 22
            mov rdi, 1
            mov rsi, 2
            start_lp_draw_side_loop:
                mov rdi,1
                call buffered_move_cursor
                call colors_fill_c
                mov rdi, 24
                call buffered_move_cursor
                call colors_fill_c

                add rsi, 1
                loop start_lp_draw_side_loop
            mov rcx, 24
            mov rdi, 1
            mov rsi, 24
            call buffered_move_cursor
            start_lp_draw_bottom_loop:
                call colors_fill_c
                loop start_lp_draw_bottom_loop
        call colors_unset_c
        

        


        ; draw the snake
        mov rcx, 22
        start_lp_draw_game_y_axis_lp:
        push rcx
            sub rcx, 1
            mov r8, rcx ; move y index to r8
            
            ; move the cursor to line start
            mov rsi, r8
            add rsi, 2
            mov rdi, 2
            call buffered_move_cursor
            mov rax, 22
            mul r8
            mov rcx, 22
            mov r9, rax
            start_lp_draw_game_x_axis_lp:
            push rcx
                sub rcx, 1
                mov rax, r9
                mov rdx, 21
                sub rdx, rcx
                add rax, rdx

                cmp qword[gameBoard+8*rax], 0
                je start_lp_draw_game_x_axis_lp_if_0
                    ; not 0
                    call colors_set_c
                    call colors_fill_c
                    jmp start_lp_draw_game_x_axis_lp_if_end
                start_lp_draw_game_x_axis_lp_if_0:
                    call colors_unset_c
                    call colors_fill_c
                start_lp_draw_game_x_axis_lp_if_end:
            pop rcx    
            loop start_lp_draw_game_x_axis_lp
        pop rcx
        loop start_lp_draw_game_y_axis_lp

        ; draw the head
        mov rdi, qword[posX]
        mov rsi, qword[posY]
        call buffered_move_cursor
        call colors_set_c_red
        call colors_fill_c
        call colors_unset_c

        
        ; draw the pellet
        xor rdx, rdx
        mov rax, qword[pelletPos]
        mov r8, 22
        div r8
        mov rsi, rax
        add rsi, 2
        mov rdi, rdx
        add rdi, 2
        call buffered_move_cursor
        mov rsi, pelletText
        call buffered_push


        ; draw score
        mov rdi, qword[score_posX]
        mov rsi, qword[score_posY]
        call buffered_move_cursor
        mov rsi, score_msg
        call buffered_push
        mov rax, qword[score]
        sub rax, qword[startingScore]
        mov rsi, rax
        call buffered_num_push

        ; move cursor to rest position and flush the buffer
        mov rdi, qword[cursorRestX]
        mov rsi, qword[cursorRestY]
        call buffered_move_cursor
        call buffered_flush


        call sleep ; wait

        ; check for input
        call check_input
        cmp byte[inputStatus], 1
        jne start_lp

        ;input received

        ; loops through all inputted characters
        start_lp_lp_1:
            ;reads one byte
            call read_b
            mov rsi, qword[input_Buffer]
            
            ; quitstate
            cmp rsi, 'q'
            je start_lp_break



            ;direction
            cmp rsi, 's'
            jne start_lp_lp_1_skip_1
                mov qword[direction], 0
                jmp start_lp_lp_1_next_char
            start_lp_lp_1_skip_1:
            cmp rsi, 'd'
            jne start_lp_lp_1_skip_2
                mov qword[direction], 1
                jmp start_lp_lp_1_next_char
            start_lp_lp_1_skip_2:
            cmp rsi, 'w'
            jne start_lp_lp_1_skip_3
                mov qword[direction], 2
                jmp start_lp_lp_1_next_char
            start_lp_lp_1_skip_3:
            cmp rsi, 'a'
            jne start_lp_lp_1_skip_4
                mov qword[direction], 3
                jmp start_lp_lp_1_next_char
            start_lp_lp_1_skip_4:
            
            

            start_lp_lp_1_next_char:

            ; prevent 180 degree direction change
            mov r8, qword[direction]
            mov r9, qword[prDir]
            and r8, 1
            and r9, 1
            cmp r8, r9
            jne start_lp_no_revert_dir
                hmovq direction, prDir
            start_lp_no_revert_dir:

            ;checks if next byte can be read
            call check_input
            cmp byte[inputStatus], 1
            je start_lp_lp_1


        hmovq prDir, direction
            
        jmp start_lp

    start_lp_break:

    call io_clear_screen

    ; draw score
    mov rsi, 1
    mov rdi, 1
    call buffered_move_cursor
    mov rsi, score_msg
    call buffered_push
    mov rax, qword[score]
    sub rax, qword[startingScore]
    mov rsi, rax
    call buffered_num_push
    mov rsi, end_msg
    call buffered_push

    call buffered_flush
    
    call termios_reset
    call exit

section .data
    score_posX dq 27
    score_posY dq 23
    score_msg db 'Your score: ', 0
    end_msg db 10, 0

section .data
timeval:
    tv_sec  dq 0
    tv_usec dq 0

section .text
sleep: ; set timeval to set for how long to sleep
    regs
    mov rax, 35
    mov rdi, timeval
    xor rsi, rsi        
    syscall
    regl
    ret

section .data
    pelletPos: dq 0
    pelletText: dw '+', 0

section .text
random_pellet_pos:
    regs
        rdtsc
        xor     edx, edx             ; Required because there's no division of EAX solely
        mov     ecx, 22*22
        div     ecx                  ; EDX:EAX / ECX --> EAX quotient, EDX remainder
        mov qword[pelletPos], rdx
    regl
    ret



