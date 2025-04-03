; Sobel filter using sequential programming

section .text
    global sobel_sq
    
sobel_sq:
    ; RCX = src, RDX = dst, R8 = width, R9 = height
    push rbp
    mov rbp, rsp
    sub rsp, 32

    ; Save registers
    mov [rsp], rbx
    mov [rsp+8], rsi
    mov [rsp+16], rdi
    mov [rsp+24], r12
    mov [rsp+32], r13
    mov [rsp+40], r14
    mov [rsp+48], r15
    
    ; Setup parameters
    mov rsi, rcx        ; Source pointer
    mov rdi, rdx        ; Destination pointer
    mov r12, r8         ; Width
    mov r13, r9         ; Height
    
    ; Initialize the destination with zeros
    mov rcx, r12        ; copy width to rcx
    imul rcx, r13       ; multiply WxH for dimensions
    xor rax, rax        ; clear rax
    
    xor rbx, rbx        ; Clear rbx, current index
    xor r8, r8          ; Row reference
    xor r9, r9          ; column reference
    
    
    cmp rbx, rcx-1

    cmp r8, 0
    je Setup_next
    cmp r8, r12
    jge Setup_next
    
    cmp r9, 0
    je Setup_next
    cmp r9, r13
    jge Setup_next

    ; Check row and col


sobel_solve:
    ; Solve for Ix of n
    ; use r10 and r11
    
    sub rbx, r13        ; Previous row
    sub rbx, 1          ; Top left | -1
    mov r10b, [rsi+rbx]
    mul r10b, -1        ; Multiply
    add r11b, r10b      ; Add into r11
    add rbx, 2          ; Top right | 1
    mov r10b, [rsi+rbx]
    mul r10b, 1         ; Multiply
    add r11b, r10b      ; Add into r11
    add rbx, r13        ; Middle right | 2
    mov r10b, [rsi+rbx]
    mul r10b, 2         ; Multiply
    add r11b, r10b      ; Add into r11
    sub rbx, 2          ; Middle left | -2
    mov r10b, [rsi+rbx]
    mul r10b, -2         ; Multiply
    add r11b, r10b      ; Add into r11
    add rbx, r13        ; Bottom left | -1
    mov r10b, [rsi+rbx]
    mul r10b, -1         ; Multiply
    add r11b, r10b      ; Add into r11
    add rbx, 2          ; Bottom right | 1
    mov r10b, [rsi+rbx]
    mul r10b, 1         ; Multiply
    add r11b, r10b      ; Add into r11

    div r11b, 6
    mov r14b, r11b      ; Ix
    sub rbx, r13+1      ; Return RBX to original position

    ; Solve for Iy of n
    sub rbx, r13        ; Top Middle | 2
    ; do something
    sub rbx, 1          ; Top left | 1
    ; perform something
    add rbx, 2          ; Top right | 1
    ; do something
    add rbx, r13        ; Middle row (skip since 0)
    add rbx, r13        ; Bottom right | -1
    ; do something
    add rbx, 2          ; Bottom left | -1
    ; do something
    add rbx, 1          ; Bottom right | -2
    ; do something

    ; Get the avg of results
    ; Store somewhere 
    sub rbx, r13+1


    ; Square Ix and Iy
    mul r14b, r14b
    mul r15b, r15b
    ; Add Ix and Iy
    add r15b, r14b
    ; Get the square root of the sum
    fsqrt 
    ; Compare the result with the threshold
    ; If result > thresh, store 255
    ; Else, store 0

Setup_nxt:
    ; Increment count
    
    ; loopback here
L1:
    ; Check if it is first||last row && first||last col
    ;cmp 
        
    ; compute for Ix
    ;mov 
    
    ; Compute for Iy
    
    ; Sqrt(ix^2+iy^2)
    
    ; Check for threshold
    
Col_nxt:
    inc rbx
    inc r9
    jmp Start   ; Update jump to check if end of column

Row_nxt:
    ; Reset row index
    ; Jump back to start

Prog_end:
    ; Store/Update destination / Save results into Destination matrix
    ; Restore pushed registers
    
    mov r15, [rsp+48]
    mov r14, [rsp+40]
    mov r13, [rsp+32]
    mov r12, [rsp+24]
    mov rdi, [rsp+16]
    mov rsi, [rsp+8]
    mov rbx, [rsp]
    
    ret
