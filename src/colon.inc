%ifndef colon_inc
%define colon_inc

%define lw 0

%macro colon 2
%%la: dq lw
dq 0
db %1, 0
%2:
%define lw %%la
%endmacro

colon "colo", colo
db 'colon rulez', 0

colon "reasons_to_live", reasons_to_live
db '0', 0

colon "third", third
db 'trird', 0

colon "four", four
db 'four', 0

%endif