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
