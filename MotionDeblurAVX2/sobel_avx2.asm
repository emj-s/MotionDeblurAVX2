section .text
    global sobel_avx2

sobel_avx2:
    ; RCX = src, RDX = dst, R8 = width, R9 = height
    push rbp
    mov rbp, rsp
    and rsp, -16

    mov rsi, rcx
    mov rdi, rdx
    mov r10, r8
    mov r11, r9

    sub r10, 2
    sub r11, 2

.row_loop:
    xor rcx, rcx
.col_loop:
    cmp rcx, r10
    jge .next_row

    vmovdqu ymm0, [rsi] 
    vmovdqu ymm1, [rsi + r10]
    vmovdqu ymm2, [rsi + 2*r10]

    vpabsw ymm3, ymm0
    vpabsw ymm4, ymm1
    vpabsw ymm5, ymm2
    vpaddw ymm6, ymm3, ymm4
    vpaddw ymm6, ymm6, ymm5

    vpxor ymm7, ymm7, ymm7
    vpcmpeqw ymm8, ymm8, ymm8
    vpsrlw ymm8, ymm8, 8
    vpminsw ymm6, ymm6, ymm8

    vmovdqu [rdi], ymm6

    add rsi, 8
    add rdi, 8
    add rcx, 8
    cmp rcx, r10
    jl .col_loop

.next_row:
    add rsi, r10
    add rdi, r10
    sub r11, 1
    jnz .row_loop

.end_function:
    mov rsp, rbp
    pop rbp
    ret
