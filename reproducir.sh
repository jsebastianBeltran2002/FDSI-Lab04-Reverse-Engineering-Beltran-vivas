#!/usr/bin/env bash
# Reproduce todo el análisis. Uso: copiar los 3 crackme_* junto a este script y correr: bash reproducir.sh
set -u
chmod +x crackme_level1 crackme_level2 crackme_level2_stripped
G=docs/evidence/reverse/gdb-scripts
p(){ echo; echo -e "\e[1;36m\$ $*\e[0m"; "$@"; echo "(exit $?)"; read -rp "[Enter para seguir]" _; }

p file crackme_level1 crackme_level2 crackme_level2_stripped
p sha256sum crackme_level1 crackme_level2 crackme_level2_stripped
# ---- Nivel 1
p ./crackme_level1 prueba
p bash -c "strings -n 5 crackme_level1 | grep -nE 'strcmp|REDTEAM|Access|print_flag'"
p bash -c "objdump -d -M intel --no-show-raw-insn crackme_level1 | awk '/<main>:/,/^\$/'"
p ./crackme_level1 REDTEAM-101
# ---- Nivel 2
p ./crackme_level2 AAAA
p bash -c "objdump -d -M intel --no-show-raw-insn crackme_level2 | awk '/<validate_key>:/,/^\$/'"
p objdump -s -j .rodata crackme_level2
p python3 -c "k=bytes.fromhex('2351176a');e=bytes.fromhex('651544230e03523c6603442f0e63275815');print(bytes(e[i]^k[i%4] for i in range(17)).decode())"
p ./crackme_level2 FDSI-REVERSE-2026
# ---- GDB
p gdb -q -batch -x $G/g1.gdb ./crackme_level2
p gdb -q -batch -x $G/g2.gdb ./crackme_level2
p gdb -q -batch -x $G/g3.gdb ./crackme_level2
# ---- Boss
p nm crackme_level2_stripped
p bash -c "objdump -d -M intel --no-show-raw-insn crackme_level2_stripped | sed -n '/^0000000000401070/,/hlt/p'"
p gdb -q -batch -x $G/g4.gdb ./crackme_level2_stripped
p ./crackme_level2_stripped FDSI-REVERSE-2026
