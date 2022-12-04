%ifndef COLORS_ASM
    %define COLORS_ASM

%include "ioSetup.asm"

section .data
    colors_reset_cursor_flag db 1 
    colors_set_pixel_m1 db 33o, '[107m ',33o,'[0m', 0
    colors_set_c_m1 db 33o, '[107m', 0
    colors_set_c_red_m db 33o, '[101m', 0
    colors_set_c_m2 db 33o,'[0m', 0
    colors_filler db ' ', 0



section .text
    colors_set_c:
        push rsi
            mov rsi, colors_set_c_m1
            call buffered_push
        pop rsi
        ret
    colors_set_c_red:
        push rsi
            mov rsi, colors_set_c_red_m
            call buffered_push
        pop rsi
        ret
    colors_unset_c:
        push rsi
            mov rsi, colors_set_c_m2
            call buffered_push
        pop rsi
        ret
    colors_fill_c:
        push rsi
            mov rsi, colors_filler
            call buffered_push
        pop rsi
        ret

    colors_set_pixel: ; paints white block with coordinates (rdi,rsi)
        regs
            call buffered_move_cursor
            mov rsi, colors_set_pixel_m1
            call buffered_push
        regl
        ret

%endif