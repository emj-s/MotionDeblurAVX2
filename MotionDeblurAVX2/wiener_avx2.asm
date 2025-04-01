section .text
    global wiener_avx2

section .data
    align 32
    max_val dd 255.0, 255.0, 255.0, 255.0, 255.0, 255.0, 255.0, 255.0
    one_val dd 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0

wiener_avx2:
    ; RCX = src, RDX = dst, R8 = width, R9 = height, XMM0 = K
    push rbp
    mov rbp, rsp
    sub rsp, 32
    
    ; Save registers
    mov [rsp], rbx
    mov [rsp+8], r12
    mov [rsp+16], r13
    mov [rsp+24], r14
    
    ; Setup parameters
    mov r10, rcx        ; Source pointer
    mov r11, rdx        ; Destination pointer
    mov r12, r8         ; Width
    mov r13, r9         ; Height
    
    ; Prepare constants
    vbroadcastss ymm5, xmm0  ; Broadcast K to all elements in ymm5
    vmovaps ymm7, [max_val]  ; Load 255.0 to ymm7
    vmovaps ymm6, [one_val]  ; Load 1.0 to ymm6
    
    ; For each pixel
    mov rcx, 0          ; Total pixel counter
    imul r9, r8         ; Total number of pixels
    
.pixel_loop:
    cmp rcx, r9
    jge .end_function
    
    ; Process 8 pixels at a time if possible
    mov rax, r9
    sub rax, rcx
    cmp rax, 8
    jl .process_remaining
    
    ; Load 8 pixels
    vmovq xmm0, qword [r10+rcx]      ; Load 8 bytes
    
    ; Convert to float (0-255)
    vpmovzxbd ymm0, xmm0             ; Zero-extend 8-bit to 32-bit
    vcvtdq2ps ymm1, ymm0             ; Convert to float
    
    ; Apply Wiener filter: output = input * (input / (input + K))
    ; For denoising: output = input * (input / (input + K))
    ; For deblurring: output = input / (input * K + 1)
    
    ; Deblurring formula (more likely to show visible effect)
    vmulps ymm2, ymm1, ymm5          ; input * K
    vaddps ymm2, ymm2, ymm6          ; input * K + 1
    vdivps ymm3, ymm1, ymm2          ; input / (input * K + 1)
    vmulps ymm3, ymm3, ymm7          ; Scale to 0-255
    
    ; Convert back to 8-bit
    vcvtps2dq ymm4, ymm3             ; Convert to int
    vpackusdw ymm4, ymm4, ymm4       ; Pack to 16-bit
    vpackuswb xmm4, xmm4, xmm4       ; Pack to 8-bit
    
    ; Store result
    vmovq qword [r11+rcx], xmm4
    
    ; Move to next 8 pixels
    add rcx, 8
    jmp .pixel_loop
    
.process_remaining:
    ; Process remaining pixels one by one
    cmp rcx, r9
    jge .end_function
    
    ; Load pixel
    movzx ebx, byte [r10+rcx]
    
    ; Convert to float
    cvtsi2ss xmm0, ebx
    
    ; Apply Wiener filter (deblurring)
    mulss xmm0, xmm5            ; input * K
    addss xmm0, dword [one_val] ; input * K + 1
    movss xmm1, dword [r10+rcx] ; Load input again
    cvtsi2ss xmm1, ebx
    divss xmm1, xmm0            ; input / (input * K + 1)
    mulss xmm1, dword [max_val] ; Scale to 0-255
    
    ; Convert back and store
    cvtss2si ebx, xmm1
    
    ; Clamp to 0-255
    cmp ebx, 255
    jle .no_clamp_single
    mov ebx, 255
.no_clamp_single:
    cmp ebx, 0
    jge .no_clamp_single_low
    xor ebx, ebx
.no_clamp_single_low:
    
    ; Store result
    mov byte [r11+rcx], bl
    
    ; Next pixel
    inc rcx
    jmp .process_remaining

.end_function:
    ; Restore registers
    mov rbx, [rsp]
    mov r12, [rsp+8]
    mov r13, [rsp+16]
    mov r14, [rsp+24]
    
    add rsp, 32
    pop rbp
    ret
