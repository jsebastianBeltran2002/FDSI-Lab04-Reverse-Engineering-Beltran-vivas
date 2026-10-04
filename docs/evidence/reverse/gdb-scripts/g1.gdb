set pagination off
set disassembly-flavor intel
break validate_key
run AAAA
info registers rdi
x/s $rdi
finish
p/x $rax
continue
