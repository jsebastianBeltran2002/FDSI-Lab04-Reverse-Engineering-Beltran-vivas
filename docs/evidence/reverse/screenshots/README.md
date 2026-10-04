# Capturas

Las capturas de terminal se pueden sacar corriendo `bash reproducir.sh` en la raíz del repo, con los binarios en la misma carpeta.
Las de Ghidra hay que tomarlas a mano (ver pasos en `../level2.md`, sección 2).

| Archivo | Qué mostrar |
|---|---|
| baseline_file_sha256.png | `file` + `sha256sum` de los 3 binarios (hashes = los del docente) |
| l1_run_fail.png | `./crackme_level1 prueba` → Access denied |
| l1_strings.png | `strings -n 5 crackme_level1` con `REDTEAM-101` y `strcmp` visibles |
| l1_objdump_main.png | `main` con `call strcmp` |
| l1_flag.png | `./crackme_level1 REDTEAM-101` → FLAG |
| l2_ghidra_main.png | Decompilador de `main` → llamada a `validate_key` |
| l2_ghidra_validate_renamed.png | `validate_key` con variables renombradas (**obligatoria**) |
| l2_ghidra_data.png | Bytes de `k.1` y `expected.0` |
| l2_flag.png | `./crackme_level2 FDSI-REVERSE-2026` → FLAG |
| l2_python_key.png | Script que reconstruye la clave |
| gdb_fail.png / gdb_success.png / gdb_xor.png | Secciones 1–3 de `gdb.md` |
| boss_ghidra_xref.png | References to "License accepted." → `FUN_00401156` |
| boss_nm_gdb_stripped.png | `nm` → no symbols + GDB `?? ()` con retorno 0 y 1 |
