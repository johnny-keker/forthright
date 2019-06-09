; vim: syntax=nasm

section .text

string_length:
    xor rax, rax
string_length_loop:
    cmp byte [rdi+rax], 0
    je string_length_ret
    inc rax
    jmp string_length_loop
string_length_ret:
    ret

print_string:
    push rdx
    xor rax, rax
    call string_length
    mov rsi, rdi
    mov rdx, rax
    mov rax, 1
    mov rdi, 1
    syscall
    pop rdx
    ret


print_char:
    mov rax, 1
    push rdi
    mov rdi, 1
    mov rsi, rsp
    mov rdx, 1
    syscall
    add rsp, 8
    ret


print_newline:
    xor rax, rax
    ret

print_uint:
    push r12
    push r13
    mov r12, rsp
    mov rax, rdi
    mov r13, 10     ; radix, dont forget to restore r13
    dec rsp         ; dynamic bufer generation
    mov byte [rsp], 0
uint_loop:
    xor rdx, rdx    ; clear rdx, because div uses rdx:rax
    div r13
    add rdx, 0x30   ; because of ascii
    dec rsp         ; dynamic bufer generation
    mov [rsp], dl
    cmp rax, 0         ; when chastnoe is 0, then it`s time to bye-bye from loop
    je uint_ret
    jmp uint_loop
uint_ret:
    mov rdi, rsp
    call print_string
    mov rsp, r12
    pop r13
    pop r12
    ret

print_int:
    xor rax, rax
    test rdi, rdi
    js negative
    call print_uint
    jmp int_ret
negative:
    push rdi
    mov rdi, '-'
    call print_char
    pop rdi
    neg rdi
    call print_uint
int_ret:
    ret

string_equals: 
    xor rcx, rcx      ; loop iterator
    mov r10, rdi
    mov r9, rsi
srt_eq_loop:
    mov r11b, byte [r10+rcx] ; r11 = first string's character
    mov r8b, byte [r9+rcx]  ; r8 = second string's character
    cmp r8b, r11b
    jne str_eq_false   ; terminate if characters aren't equal
    inc rcx
    cmp r11b, 0x0
    je str_eq_true
    jmp srt_eq_loop    ; loop until we've reached the end of the strings
str_eq_true:
    mov rax, 1         ; 1 = strings are equal
    ret
str_eq_false:
    mov rax, 0         ; 0 = strings aren't equal
    ret


read_char:
    xor rax, rax
    mov rax, 0
    mov rdi, 0
    mov rdx, 1
    dec rsp
    mov rsi, rsp
    syscall
    test rax, rax     ; rax = number of characters read, if rax = 0, it's the end of input
    je print_char_ret
    xor rax, rax
    mov al, [rsp]
print_char_ret:
    inc rsp
    ret

read_word:
    push r13
    push r14
    xor r14, r14
    mov r10, rsi
    mov r13, rdi
first_loop:
    call read_char
    cmp al, 0x20
    jne write_char
    jmp first_loop
cont_read:
    call read_char
    cmp r14, r10
    je read_out
    cmp al, 0x20 ; space
    je read_ret
write_char:
    cmp al, 0x9 ; tab
    je read_ret
    cmp al, 0x0 ; end of input
    je read_ret
    mov byte [r13+r14], al
    inc r14
    jmp cont_read
read_ret:
    mov rax, r13
    mov byte [r13+r14], 0
    mov rdx, r14 ; string length
    pop r14
    pop r13
    ret
read_out:
    mov rax, 0
    xor rdx, rdx ; string length = 0
    pop r14
    pop r13
    ret

; rdi -- null-terminated input string pointer
; out rax -- parsed uint
; out rdx -- number of characters parsed
parse_uint:
    xor rax, rax
    xor rsi, rsi
    mov r8, 10
    xor rcx, rcx
    xor rdx, rdx
parse_uint_loop:
    mov sil, [rdi+rcx]
    cmp sil, 0x30
    jl parse_uint_exit
    cmp sil, 0x39
    jg parse_uint_exit
    inc rcx
    sub sil, 0x30
    mul r8
    add rax, rsi
    jmp parse_uint_loop
parse_uint_exit:
    mov rdx, rcx
    ret

; rdi points to a string
; returns rax: number, rdx : length
parse_int:
    xor rax, rax
    cmp byte [rdi], 0x2d
    je parse_int_negative
    call parse_uint
    ret
parse_int_negative:
    inc rdi
    call parse_uint
    cmp rdx, 0      ; if we haven't read any digits, we shouldn't count the '-'
    je parse_int_ret
    neg rax
    inc rdx
parse_int_ret:
    ret 


string_copy:
    xor rcx, rcx
string_copy_loop:
    cmp rcx, rdx
    je string_copy_ret_too_long
    mov rax, [rdi+rcx]
    mov [rsi+rcx], rax
    cmp byte [rdi+rcx], 0x0
    je string_copy_ret
    inc rcx
    jmp string_copy_loop
string_copy_ret:
    mov rax, rsi
    ret
string_copy_ret_too_long:
    mov rax, 0
    ret
