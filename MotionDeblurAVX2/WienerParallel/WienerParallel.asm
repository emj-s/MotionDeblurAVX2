section .text
global wiener_avx2

wiener_avx2:
    push rbp
    mov rbp, rsp
    sub rsp, 32

    ; rdi = input pointer
    ; rsi = output pointer
    ; rdx = width
    ; rcx = height
    ; xmm0 = K (Wiener parameter)

    vbroadcastss ymm0, xmm0   ; Broadcast K to all elements in YMM0
    xor r8, r8                ; y index (row counter)

.loop_y:
    cmp r8, rcx               ; Check if we've reached the last row
    jge .end

    xor r9, r9                ; x index (column counter)

.loop_x:
    cmp r9, rdx               ; If at end of row, move to the next row
    jge .next_row

    ; **Step 1: Load 8 Pixels at Once**
    lea r10, [rdi + r9 + r8 * rdx]  ; Compute address of current pixel block
    vmovdqu ymm1, [r10]             ; Load 8 pixels (8-bit unsigned integers)

    ; **Step 2: Identify Zero Pixels**
    vpxor ymm2, ymm2, ymm2          ; Zero register
    vpcmpeqb ymm3, ymm1, ymm2       ; Mask: 0xFF where input is zero, 0x00 otherwise

    ; **Step 3: Convert Input to Float**
    vpmovzxbd ymm4, xmm1            ; Convert 8-bit to 32-bit integer
    vcvtdq2ps ymm5, ymm4            ; Convert integers to float

    ; **Step 4: Apply Wiener Filter**
    vmulps ymm6, ymm5, ymm0         ; Multiply (pixel * K)
    vsubps ymm7, ymm5, ymm6         ; Compute final result

    ; **Step 5: Convert Back to Integers**
    vcvttps2dq ymm8, ymm7           ; Convert float to integer
    vpackusdw ymm9, ymm8, ymm8      ; Pack into 16-bit
    vpackuswb ymm10, ymm9, ymm9     ; Pack into 8-bit

    ; **Step 6: Preserve Zero Pixels**
    vpblendvb ymm11, ymm10, ymm1, ymm3  ; Preserve original zero pixels

    ; **Step 7: Store Result**
    vmovdqu [rsi + r9 + r8 * rdx], ymm11

    ; Move to the next 8-pixel block
    add r9, 8
    jmp .loop_x

.next_row:
    inc r8
    jmp .loop_y

.end:
    add rsp, 32
    pop rbp
    ret
