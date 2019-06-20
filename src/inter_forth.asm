; vim: syntax=nasm

global _start

%include "src/dict.asm"

%define next_instruction    r15 ; pc
%define current_word        r14 ; w
%define call_stack          r13 ; rstack

section .bss

resq 1023
call_stack_head: resq 1
stack_start_ptr: resq 1

input_buf: resq 1024
dict: resq 32768
mem: resq 32768

section .text

%include "src/words.asm"

section .data

LW: dq _lw
HERE: dq dict
MEM: dq mem

state: dq 0

section .text

global _start

next:
  mov current_word, [next_instruction]
  add next_instruction, 8
  jmp [current_word]

docol:
  sub call_stack, 8
  mov [call_stack], next_instruction
  add current_word, 8
  mov next_instruction, current_word
  jmp next

prog:
  dq exec_token_interpret_initialization

_start:
  mov [stack_start_ptr], rsp
  mov call_stack, call_stack_head
  mov next_instruction, prog
  jmp next
