section .text
    global wiener_avx2

section .data
    max_val dd 255.0        ; Constant for clamping to 255

wiener_avx2:
    ; RCX = src, RDX = dst, R8 = width, R9 = height, XMM0 = K
    push rbp
    mov rbp, rsp
    sub rsp, 32

    mov rsi, rcx            ; Source pointer
    mov rdi, rdx            ; Destination pointer
    mov r10, r8             ; width
    mov r11, r9             ; height

    ; Prepare constants
    vbroadcastss ymm5, xmm0  ; Broadcast K to all elements in ymm5
    vbroadcastss ymm7, dword [max_val]  ; Broadcast 255.0 to ymm7

.row_loop:
    xor rcx, rcx            ; Reset col
.col_loop:
    cmp rcx, r10
    jge .next_row

    ; Load 8 pixels (unsigned 8-bit)
    vpmovzxbd ymm0, [rsi]   ; Zero-extend 8-bit to 32-bit integers
    vcvtdq2ps ymm1, ymm0    ; Convert to single-precision float

    vaddps ymm2, ymm1, ymm5 ; Wiener filter operation: x / (x + K)
    vdivps ymm3, ymm1, ymm2 ; Compute Wiener deconvolution

    vminps ymm3, ymm3, ymm7 ; Clamp to 255

    ; Convert back to 8-bit and store
    vcvtps2dq ymm4, ymm3    ; Convert float back to int32
    vpackusdw ymm4, ymm4, ymm4  ; Pack 32-bit to 16-bit
    vpackuswb ymm4, ymm4, ymm4  ; Pack 16-bit to 8-bit
    vmovdqu [rdi], xmm4     ; Store result (lower 128 bits)

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
