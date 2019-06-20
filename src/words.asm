; vim: syntax=nasm
section .rodata
msg_no_such_word: db "error: word not found", 10, 0
in_fd: dq 0
section .text

%include "src/lib.inc"
; Pushes a value immediately following this XT
native "lit", lit
  push qword [next_instruction]
  add next_instruction, 8
  jmp next

native "+", plus
  pop rax
  add [rsp], rax
  jmp next

native "-", minus
  pop rax
  sub [rsp], rax
  jmp next

native "=", equals
  pop rax
  pop rdx
  cmp rax, rdx
  sete al
  movzx rax, al
  push rax
  jmp next

native "dup", dup
  push qword [rsp]
  jmp next

native "swap", swap
  pop rax
  pop rdx
  push rax
  push rdx
  jmp next

native "drop", drop
  add rsp, 8
  jmp next

native "exit", exit
  rpop next_instruction
  jmp next

native "try_parse_num", try_parse_num
  pop rdi
  call parse_int
  push rax
  push rdx
  jmp next

native "emit", emit
  pop rdi
  call print_char
  jmp next

native "word", word
  pop rdi
  mov rsi, 1024
  call read_word
  push rdx
  jmp next

native ">r", to_r
  pop rax
  rpush rax
  jmp next

native "r>", from_r
  rpop rax
  push rax
  jmp next

native "r@", r_fetch
  push qword [call_stack]
  jmp next

section .data
  stack_base: dq 0

native "interpret_initialization", interpret_initialization
  mov qword [state], 0
  mov call_stack, call_stack_head
  mov next_instruction, interpreter_stub
  cmp qword [stack_base], 0
  je  .first
  mov rsp, [stack_base]
  jmp next
.first:
  mov [stack_base], rsp
  jmp next


native "docol", docol
  rpush next_instruction
  add current_word, 8
  mov next_instruction, current_word
  jmp next

native ".", dot
  pop rdi
  call print_int
  jmp next

native "!", write
  pop rax
  pop rdx
  mov [rax], rdx
  jmp next

native "@", fetch
  pop rax
  push qword[rax]
  jmp next

native "c@", fetch_char
  pop rax
  movzx rax, byte [rax]
  push rax
  jmp next

native "not", not
  pop rax
  test rax, rax
  setz al
  movzx rax, al
  push rax
  jmp next

native ",", comma
  mov rax, [HERE]
  pop qword [rax]
  add qword [HERE], 8
  jmp next

native "create", create
  mov rcx, [LW]
  mov rsi, [HERE]
  mov [rsi], rcx
  mov [LW], rsi
  add rsi, 8
  mov byte [rsi], 0
  inc rsi

  pop rdi
  push rsi
  call string_copy
  pop rsi
  push rsi
  mov rdi, rsi
  call string_length
  pop rsi
  add rsi, rax
  inc rsi
  pop rax
  mov [rsi], al
  inc rsi

  mov [HERE], rsi
  jmp next

colon "count", count
  dq exec_token_dup
.count_loop:
  dq exec_token_dup
  dq exec_token_fetch_char
  zero_branch .count_exit
  dq exec_token_lit, 1
  dq exec_token_plus
  branch .count_loop
.count_exit:
  dq exec_token_swap
  dq exec_token_minus
  dq exec_token_exit

colon "printc", printc
  dq exec_token_to_r
.printc_loop:
  dq exec_token_r_fetch
  zero_branch .printc_exit
  dq exec_token_dup
  dq exec_token_fetch_char
  dq exec_token_emit
  dq exec_token_lit, 1
  dq exec_token_plus
  dq exec_token_from_r
  dq exec_token_lit, 1
  dq exec_token_minus
  dq exec_token_to_r
  branch .printc_loop
.printc_exit:
  dq exec_token_from_r
  dq exec_token_drop
  dq exec_token_drop
  dq exec_token_exit

colon "prints", prints
  dq exec_token_dup
  dq exec_token_count
  dq exec_token_printc
  dq exec_token_exit

native "syscall", syscall
  pop r9
  pop r8
  pop r10
  pop rdx
  pop rsi
  pop rdi
  pop rax
  syscall
  push rax
  push rdx
  jmp next



colon ":", colon
  .restart:
  dq exec_token_inbuf
  dq exec_token_word
  zero_branch .restart
  dq exec_token_lit, 0
  dq exec_token_inbuf
  dq exec_token_create
  dq exec_token_lit, 1
  dq exec_token_state
  dq exec_token_write
  dq exec_token_lit, impl_docol
  dq exec_token_comma
  dq exec_token_exit

colon ";", semicolon, 1
  dq exec_token_lit, 0
  dq exec_token_state
  dq exec_token_write
  dq exec_token_lit
  dq exec_token_exit
  dq exec_token_comma
  dq exec_token_exit


native "zero_branch", zero_branch
  pop rax
  test rax, rax
  jnz .skip_instruction
  mov next_instruction, [next_instruction]
  jmp next
.skip_instruction:
  add next_instruction, 8
  jmp next

native "branch", branch
  mov next_instruction, [next_instruction]
  jmp next

native "get_exec_token_by_word_header", get_exec_token_by_word_header
  pop rsi
  add rsi, 9       ; cmd name offset
.loop:
  mov al, [rsi]
  test al, al
  jz .end
  inc rsi
  jmp .loop
.end:
  add rsi, 2
  push rsi
  jmp next

; Address of the input buffer (is used by interpreter/compiler)
const inbuf, input_buf

; Address of user memory.
const mem, mem

; Last word address
const last_word, LW

; State cell address.
; The state cell stores either 1 (compilation mode) or 0 (interpretation mode)
const state, state

const here, [HERE]
const in_fd, in_fd
const dp, MEM

native "execute", execute
  pop rax
  mov current_word, rax
  jmp [rax]

native "find_word", find_word
  mov rsi, LW
  mov rax, [state]
  test rax, rax
  jz .loop
  mov rsi, [rsi]
.loop:
  mov rdi, [rsp]
  push rsi
  add rsi, 9          ; cmd name offset
  call string_equals
  pop rsi
  test rax, rax
  jnz .found_word
  mov rsi, [rsi]
  test rsi, rsi
  jnz .loop
  mov qword [rsp], 0
  jmp next
.found_word:
  mov [rsp], rsi
  jmp next

colon "terminate", terminate
   dq exec_token_lit, 60
   dq exec_token_lit, 0
   dq exec_token_lit, 0
   dq exec_token_lit, 0
   dq exec_token_lit, 0
   dq exec_token_lit, 0
   dq exec_token_lit, 0
   dq exec_token_syscall

section .rodata
interpreter_stub:
  dq exec_token_interpret
  dq exec_token_terminate

colon "interpret", interpret
.loop:
  dq exec_token_inbuf
  dq exec_token_word
  zero_branch .end_of_input

  dq exec_token_inbuf
  dq exec_token_main_loop

  branch .loop

.end_of_input:
  dq exec_token_exit

colon "main_loop", main_loop
.start:
  dq exec_token_dup
  dq exec_token_find_word
  dq exec_token_dup
  zero_branch .try_parse_as_number
  dq exec_token_get_exec_token_by_word_header
  
  dq exec_token_state
  dq exec_token_fetch
  zero_branch .inter

  dq exec_token_dup
  dq exec_token_lit, 1
  dq exec_token_minus
  dq exec_token_fetch_char
  dq exec_token_not
  zero_branch .inter

  dq exec_token_swap
  dq exec_token_drop
  dq exec_token_comma
  dq exec_token_exit

.inter:
  dq exec_token_swap
  dq exec_token_drop
  dq exec_token_execute
  dq exec_token_exit

.try_parse_as_number:
  dq exec_token_drop
  dq exec_token_dup
  dq exec_token_try_parse_num
  zero_branch .word_not_found
  dq exec_token_swap
  dq exec_token_drop
  dq exec_token_state
  dq exec_token_fetch
  zero_branch .exit

  dq exec_token_here
  dq exec_token_lit, 8
  dq exec_token_minus
  dq exec_token_fetch

  dq exec_token_dup
  dq exec_token_lit
  dq exec_token_zero_branch
  dq exec_token_equals
  dq exec_token_not
  zero_branch .is_branch

  dq exec_token_dup
  dq exec_token_lit
  dq exec_token_branch
  dq exec_token_equals
  dq exec_token_not
  zero_branch .is_branch

  dq exec_token_lit, exec_token_lit, exec_token_comma

.is_branch:
  dq exec_token_drop
  dq exec_token_comma
  dq exec_token_exit

.word_not_found:
  dq exec_token_drop
  dq exec_token_lit
  dq msg_no_such_word
  dq exec_token_prints
.exit:
  dq exec_token_exit


