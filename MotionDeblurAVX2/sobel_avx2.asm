section .text
    global sobel_avx2

sobel_avx2:
    ; RCX = src, RDX = dst, R8 = width, R9 = height
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
    
    ; Initialize the destination with zeros
    mov rcx, r12
    imul rcx, r13
    xor rax, rax
    mov rdi, r11
    rep stosb
    
    ; Skip first and last row, first and last column
    cmp r13, 2
    jle .end_function   ; Not enough rows to process
    cmp r12, 2
    jle .end_function   ; Not enough columns to process
    
    ; Process rows 1 to height-2
    mov r14, 1          ; Start from row 1
.row_loop:
    cmp r14, r13
    je .end_function    ; Finished processing all rows
    dec r13             ; Compare with height-1
    cmp r14, r13
    jge .end_function   ; Skip last row
    inc r13             ; Restore height
    
    ; Process columns 1 to width-2
    mov rcx, 1          ; Start from column 1
.col_loop:
    cmp rcx, r12
    je .next_row        ; Finished processing this row
    dec r12             ; Compare with width-1
    cmp rcx, r12
    jge .next_col       ; Skip last column
    inc r12             ; Restore width
    
    ; Calculate current pixel position (row * width + col)
    mov rax, r14
    imul rax, r12
    add rax, rcx
    
    ; Load 3x3 neighborhood
    ; Top row (y-1)
    mov rbx, rax
    sub rbx, r12        ; Move to previous row
    
    movzx esi, byte [r10+rbx-1]   ; top-left
    movzx edi, byte [r10+rbx]     ; top-center
    movzx r8d, byte [r10+rbx+1]   ; top-right
    
    ; Middle row (y)
    movzx r9d, byte [r10+rax-1]   ; middle-left
    ; Skip center pixel
    movzx r15d, byte [r10+rax+1]  ; middle-right
    
    ; Bottom row (y+1)
    add rbx, r12
    add rbx, r12        ; Move to next row
    
    movzx esi, byte [r10+rbx-1]   ; bottom-left
    movzx edi, byte [r10+rbx]     ; bottom-center
    movzx r8d, byte [r10+rbx+1]   ; bottom-right
    
    ; Compute Sobel gradient
    ; Horizontal gradient: (top-right + 2*middle-right + bottom-right) - (top-left + 2*middle-left + bottom-left)
    mov edx, r8d        ; top-right
    add edx, r15d       ; + middle-right
    add edx, r15d       ; + middle-right (x2)
    add edx, r8d        ; + bottom-right
    
    mov ebx, esi        ; top-left
    add ebx, r9d        ; + middle-left
    add ebx, r9d        ; + middle-left (x2)
    add ebx, esi        ; + bottom-left
    
    sub edx, ebx        ; horizontal gradient
    
    ; Take absolute value
    cmp edx, 0
    jge .skip_abs_h
    neg edx
.skip_abs_h:
    
    ; Vertical gradient: (bottom-left + 2*bottom-center + bottom-right) - (top-left + 2*top-center + top-right)
    mov ebx, esi        ; bottom-left
    add ebx, edi        ; + bottom-center
    add ebx, edi        ; + bottom-center (x2)
    add ebx, r8d        ; + bottom-right
    
    mov esi, esi        ; top-left
    add esi, edi        ; + top-center
    add esi, edi        ; + top-center (x2)
    add esi, r8d        ; + top-right
    
    sub ebx, esi        ; vertical gradient
    
    ; Take absolute value
    cmp ebx, 0
    jge .skip_abs_v
    neg ebx
.skip_abs_v:
    
    ; Combine gradients (approximation of sqrt(gx² + gy²))
    add edx, ebx
    shr edx, 3          ; Scale down to avoid overflow (divide by 8)
    
    ; Clamp to 255
    cmp edx, 255
    jle .no_clamp
    mov edx, 255
.no_clamp:
    
    ; Store result
    mov byte [r11+rax], dl
    
.next_col:
    inc rcx
    jmp .col_loop
    
.next_row:
    inc r14
    jmp .row_loop

.end_function:
    ; Restore registers
    mov rbx, [rsp]
    mov r12, [rsp+8]
    mov r13, [rsp+16]
    mov r14, [rsp+24]
    
    add rsp, 32
    pop rbp
    ret