set pagination off
set disassembly-flavor intel
break *0x4011b9
run FDSI-REVERSE-2026
p/c $ecx
p/x $ecx
p/x $eax
stepi
p/x $al
continue
p/c $ecx
p/x $eax
delete
break *0x4012d2
continue
p/x $rax
continue
