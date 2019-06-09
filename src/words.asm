; vim: syntax=nasm

; Pushes a value immediately following this XT
native "lit", lit
  push qword [next_instruction]
  add next_instruction, 8
  jmp next

native "+", plus
  pop rax
  add [rsp], rax
  jmp next
