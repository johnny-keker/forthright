; vim: syntax=nasm
; last word
%define _lw 0
%macro native 3
  section .data
  word_header_ %+ %2 : dq _lw
  db 0
  db %1, 0
  db %3
; update the reference to the last word
%define _lw word_header_%+ %2
exec_token_ %+ %2 : dq impl_ %+ %2
; implementation starts here
  section .text
  impl_ %+ %2:
%endmacro
%macro native 2
  native %1, %2, 0
%endmacro

%macro colon 3
section .data 
    word_header_ %+ %2 : dq _lw
    %define _lw word_header_ %+ %2 
    db 0
    str_ %+ %2:
    db %1, 0
    db %3
    
    exec_token_ %+ %2 : dq impl_docol
%endmacro

%macro colon 2
colon %1, %2, 0
%endmacro

%macro zero_branch 1 
dq exec_token_zero_branch
dq %1 
%endmacro

%macro branch 1 
dq exec_token_branch
dq %1
%endmacro

%macro const 2
%defstr %%__cnst_str %1
native %%__cnst_str, %1 
    push qword %2
    jmp next
%endmacro

%macro rpop 1
    mov %1, qword [call_stack]
    add call_stack, 8
%endmacro

%macro rpush 1
    sub call_stack, 8
    mov qword [call_stack], %1
%endmacro
