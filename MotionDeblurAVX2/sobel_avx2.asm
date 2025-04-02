section .text
    global sobel_avx2

sobel_avx2:
    push rbp
    mov rbp, rsp
    sub rsp, 32

    mov [rsp], rbx
    mov [rsp+8], r12
    mov [rsp+16], r13
    mov [rsp+24], r14

    mov r10, rcx        ; Source pointer
    mov r11, rdx        ; Destination pointer
    mov r12, r8         ; Width
    mov r13, r9         ; Height

    cmp r13, 2
    jle .end_function
    cmp r12, 2
    jle .end_function

    mov r14, 1  
.row_loop:
    cmp r14, r13
    je .end_function
    dec r13
    cmp r14, r13
    jge .end_function
    inc r13

    mov rcx, 1  
.col_loop:
    cmp rcx, r12
    je .next_row
    dec r12
    cmp rcx, r12
    jge .next_col
    inc r12

    mov rax, r14
    imul rax, r12
    add rax, rcx

    mov rbx, rax
    sub rbx, r12  

    movzx r8d, byte [r10+rbx-1]  
    movzx r9d, byte [r10+rbx]    
    movzx r10d, byte [r10+rbx+1] 

    movzx r11d, byte [r10+rax-1]  
    movzx r15d, byte [r10+rax+1]  

    add rbx, r12
    add rbx, r12

    movzx r12d, byte [r10+rbx-1]  
    movzx r13d, byte [r10+rbx]    
    movzx r14d, byte [r10+rbx+1]  

    mov edx, r10d
    add edx, r15d
    add edx, r15d
    add edx, r14d
    sub edx, r8d
    sub edx, r11d
    sub edx, r11d
    sub edx, r12d
    
    test edx, edx
    jns .skip_abs_h
    neg edx
.skip_abs_h:

    mov ebx, r12d
    add ebx, r13d
    add ebx, r13d
    add ebx, r14d
    sub ebx, r8d
    sub ebx, r9d
    sub ebx, r9d
    sub ebx, r10d
    
    test ebx, ebx
    jns .skip_abs_v
    neg ebx
.skip_abs_v:

    add edx, ebx
    shr edx, 3
    cmp edx, 255
    jle .no_clamp
    mov edx, 255
.no_clamp:

    mov byte [r11+rax], dl

.next_col:
    inc rcx
    jmp .col_loop

.next_row:
    inc r14
    jmp .row_loop

.end_function:
    mov rbx, [rsp]
    mov r12, [rsp+8]
    mov r13, [rsp+16]
    mov r14, [rsp+24]
    add rsp, 32
    pop rbp
    ret