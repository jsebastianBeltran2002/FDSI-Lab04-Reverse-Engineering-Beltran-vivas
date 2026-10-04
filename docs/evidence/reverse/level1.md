# Nivel 1 — "Strings are evidence"

**Binario:** `crackme_level1` · SHA-256 `61e980fe…f88c68c` (verificado en `baseline.txt`)
**Resultado:** contraseña `REDTEAM-101` → `FLAG{strings_are_evidence}`

---

## 1. Observación inicial (caja negra)

```text
$ ./crackme_level1
=== FDSI CrackMe Level 1 ===
Uso: ./crackme_level1 <password>        (exit code 1)

$ ./crackme_level1 prueba
=== FDSI CrackMe Level 1 ===
Access denied.                           (exit code 2)
```

- El programa recibe **un argumento** (`argc == 2`) y responde `Access granted.` / `Access denied.`
- `file` indica: ELF 64-bit, x86-64, enlazado dinámicamente, **not stripped, with debug_info**. Es decir, conserva nombres de funciones y variables.

## 2. Hipótesis

Si el programa compara el argumento contra una contraseña fija, esa contraseña tiene que estar guardada **dentro del binario**, probablemente en `.rodata`, y `strings` debería poder verla.

## 3. Evidencia estática

### `strings -n 5 crackme_level1`

```text
printf
strcmp            <- importa strcmp de libc: compara dos cadenas
REDTEAM-101       <- cadena "rara" justo antes de los mensajes del programa
=== FDSI CrackMe Level 1 ===
Uso: %s <password>
Access granted.
Access denied.
print_flag        <- símbolo de una función que imprime la flag
```

La aparición de `strcmp` en las importaciones y de `REDTEAM-101` junto a los mensajes de acceso refuerza la hipótesis.

### `objdump -d -M intel crackme_level1` (función `main`)

```asm
40122c: mov  rax,QWORD PTR [rbp-0x20]   ; argv
401230: add  rax,0x8                    ; argv[1]  (lo que escribe el usuario)
401237: mov  rdx,QWORD PTR [rbp-0x8]    ; password = 0x402004
40123b: mov  rsi,rdx                    ; 2º arg -> la contraseña embebida
40123e: mov  rdi,rax                    ; 1º arg -> argv[1]
401241: call strcmp@plt
401246: test eax,eax
401248: jne  401265                     ; si son distintas -> "Access denied."
40124a: ... puts("Access granted.")
401259: call print_flag
```

### `objdump -s -j .rodata` confirma qué hay en `0x402004`

```text
402000 01000200 52454454 45414d2d 31303100  ....REDTEAM-101.
```

**Conclusión:** `main` hace `strcmp(argv[1], "REDTEAM-101")`. Si devuelve 0, llama a `print_flag()`.

## 4. Confirmación (ejecución)

```text
$ ./crackme_level1 REDTEAM-101
=== FDSI CrackMe Level 1 ===
Access granted.
FLAG{strings_are_evidence}               (exit code 0)
```

## 5. Detalle extra: ¿por qué la FLAG no aparece en `strings`?

`print_flag` no guarda la flag en texto plano. La arma en el stack con constantes de 64 bits (`movabs`) y la decodifica con **XOR 0x5A**, imprimiendo un byte a la vez con `putchar` (26 bytes, `cmp ...,0x19`). Por eso la pista dice *"no busques la FLAG, busca qué compara"*: la flag está ofuscada, pero la contraseña no lo está.

## 6. ¿Por qué `strings` revela secretos embebidos?

Toda constante de texto que el programa usa (como el literal `"REDTEAM-101"`) el compilador la copia tal cual en la sección `.rodata` del ejecutable. Quien tenga el binario puede leerla sin ejecutarlo y sin conocimientos de ensamblador. Compilar no oculta nada.

**Lección de desarrollo seguro:** nunca se deben poner secretos en el código (*hardcoded credentials*, CWE-798). La verificación de credenciales tiene que hacerse en el servidor, contra un hash con sal (bcrypt/argon2), y los secretos se cargan desde un gestor de secretos o desde variables de entorno.

## Capturas sugeridas (`screenshots/`)
- `l1_run_fail.png`: ejecución con `prueba`
- `l1_strings.png`: salida de `strings` resaltando `REDTEAM-101` y `strcmp`
- `l1_objdump_main.png`: `call strcmp` en `main`
- `l1_flag.png`: ejecución exitosa con la FLAG
