set pagination off
set disassembly-flavor intel
break validate_key
break *0x4011e7
run FDSI-REVERSE-2026
x/s $rdi
p/x *(unsigned long*)($rbp-0x18)
x/4xb 0x40208b
x/17xb 0x402090
continue
p/x *(int*)($rbp-0x4)
finish
p/x $rax
continue
