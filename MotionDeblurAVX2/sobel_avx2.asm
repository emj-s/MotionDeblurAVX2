section .text
    global sobel_avx2

sobel_avx2:
    ; RCX = src, RDX = dst, R8 = width, R9 = height
    push rbp
    mov rbp, rsp
    sub rsp, 32

    mov rsi, rcx 
    mov rdi, rdx            ; Destination pointer
    mov r10, r8             ; width
    mov r11, r9             ; height

    sub r10, 2              ; width- 2 (to avoid boundary issues)
    sub r11, 2              ; height- 2

    ; Compute buffer end addresses for safety
    mov rax, r8
    mul r9
    add rcx, rax            ; rsi_end =src + width* height
    add rdx, rax            ; rdi_end= dst + width * height

.row_loop:
    xor rcx, rcx            ; Reset col
.col_loop:
    cmp rcx, r10
    jge .next_row

    ; Ensure we don't read out of bounds
    cmp rsi, rcx
    jge .end_function

    ; Load pixels safely
    vmovdqu ymm0, [rsi]     

    ; Compute row offsets
    mov rdx, rsi
    add rdx, r8              ; Move to next row
    cmp rdx, rcx
    jge .end_function
    vmovdqu ymm1, [rdx]      ; Load second row

    mov rdx, rsi
    add rdx, r8
    add rdx, r8
    cmp rdx, rcx
    jge .end_function
    vmovdqu ymm2, [rdx]      ; Load third row

    ; Sobel approximation (sum of absolute differences)
    vpabsw ymm3, ymm0
    vpabsw ymm4, ymm1
    vpabsw ymm5, ymm2
    vpaddw ymm6, ymm3, ymm4
    vpaddw ymm6, ymm6, ymm5

    ; Clamp values to 255
    vpxor ymm7, ymm7, ymm7
    vpcmpeqw ymm8, ymm8, ymm8
    vpsrlw ymm8, ymm8, 8
    vpminsw ymm6, ymm6, ymm8

    ; Prevent writing out of bounds
    cmp rdi, rdx
    jge .end_function

    ; Store result
    vmovdqu [rdi], ymm6

    ; Move to next column
    add rsi, 8
    add rdi, 8
    add rcx, 8
    cmp rcx, r10
    jl .col_loop

.next_row:
    add rsi, r8
    add rdi, r8
    sub r11, 1
    jnz .row_loop

.end_function:
    add rsp, 32
    pop rbp
    ret
