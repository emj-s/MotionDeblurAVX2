section .text
global wiener_sequential

wiener_sequential:
    push rbp
    mov rbp, rsp
    sub rsp, 32

    ; rdi = input pointer
    ; rsi = output pointer
    ; rdx = width
    ; rcx = height
    ; xmm0 = K (Wiener parameter)

    mov r8, 0                 ; y index (row counter)

.loop_y:
    cmp r8, rcx               ; Check if we've reached the end of rows
    jge .end                   ; If yes, exit

    mov r9, 0                 ; x index (column counter)

.loop_x:
    cmp r9, rdx               ; Check if we've reached the end of columns
    jge .next_row              ; If yes, move to the next row

    mov r10, rdx              ; Compute pixel offset (y * width + x)
    imul r10, r8
    add r10, r9

    ; Load pixel value
    movzx r11, byte [rdi + r10]

    ; **Step 1: Identify Zero Pixels**
    cmp r11, 0
    je .store_zero             ; If the pixel is zero, store zero

    ; **Step 2: Convert to Float**
    cvtsi2ss xmm1, r11         ; Convert input to float

    ; **Step 3: Apply Wiener Filter**
    mulss xmm1, xmm0           ; Multiply (pixel * K)

    ; **Step 4: Convert Back to Integer**
    cvttss2si r12, xmm1        ; Convert float back to integer
    ; Clip result to 0-255 range
    cmp r12, 0
    jl .store_zero
    cmp r12, 255
    jg .store_max

.store:
    mov byte [rsi + r10], r12  ; Store the result

    jmp .next_pixel

.store_zero:
    xor r12, r12               ; Store zero if pixel is zero
    jmp .store

.store_max:
    mov r12, 255               ; Store max value if clipped

.next_pixel:
    inc r9                     ; Increment column index
    jmp .loop_x

.next_row:
    inc r8                     ; Increment row index
    jmp .loop_y

.end:
    add rsp, 32
    pop rbp
    ret
