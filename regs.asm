%ifndef REGS_ASM
    %define REGS_ASM

    ; ------------------------------------------Helpers ------------------------------------------------------

    %macro hmovq 2 ; Moves values between addresses ex. hmovw dest, src 
        push rax
        mov rax, qword [%2]
        mov qword [%1], rax
        pop rax
    %endmacro

    %macro hmovd 2 ; Moves values between addresses ex. hmovd dest, src 
        push rax
        mov eax, dword [%2]
        mov dword [%1], eax
        pop rax
    %endmacro

    %macro hmovw 2 ; Moves values between addresses ex. hmovw dest, src 
        push rax
        mov ax, word [%2]
        mov word [%1], ax
        pop rax
    %endmacro

    %macro hmovb 2 ; Moves values between addresses ex. hmovb dest, src 
        push rax
        mov al, byte [%2]
        mov byte [%1], al
        pop rax
    %endmacro

    ; --------------------------------------------------------------------------------------------------------


    ; ----------------------------------------- register saving/loading ----------------------------------------
    ; pushes all registers to stack
    %macro  regs 0
        push rax 
        push rcx 
        push rdx 
        push rsi 
        push rdi 
        push r8  
        push r9  
        push r10 
        push r11

    %endmacro

    ; pops all registers from stack
    %macro  regl 0
        pop r11  
        pop r10  
        pop r9   
        pop r8   
        pop rdi  
        pop rsi  
        pop rdx  
        pop rcx  
        pop rax

    %endmacro
    ; ------------------------------------------------------------------------------------------------------------

%endif