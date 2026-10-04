set pagination off
set disassembly-flavor intel
break *0x4012d2
run WRONGKEY-12345678
p/x $rax
continue
run FDSI-REVERSE-2026
p/x $rax
continue
