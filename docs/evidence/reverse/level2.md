# Nivel 2 — Reconstruir la validación con Ghidra

**Binario:** `crackme_level2` · SHA-256 `8dc5931d…b6f4e5`
**Resultado:** licencia `FDSI-REVERSE-2026` → `FLAG{ghidra_plus_gdb}`

---

## 1. Observación inicial

```text
$ ./crackme_level2 AAAA
=== FDSI CrackMe Level 2 ===
Hint: static + dynamic analysis.
Invalid license.                         (exit code 3)
```

En `strings` no aparece nada que parezca una clave. Sí aparecen los símbolos `validate_key`, `reveal_flag`, `expected`, `transformed`, `score` y `candidate`, porque el binario se compiló con `-g` y no está stripped. También sale basura como `q{vpLP_^H`, que son los bytes de la flag ofuscada. A diferencia del nivel 1, **ya no hay `strcmp`**: solo se importan `strlen`, `puts`, `printf` y `putchar`. Eso quiere decir que la comparación está implementada a mano.

## 2. Procedimiento en Ghidra

1. `File → New Project → Non-Shared Project` → `fdsi-reverse`
2. `File → Import File` → `crackme_level2` (formato ELF, x86:LE:64)
3. Doble clic → *Analyze?* **Yes** → opciones por defecto → *Analyze*
4. En *Symbol Tree → Functions* → `main`
5. En el decompilador de `main` se ve:
   ```c
   if (validate_key(argv[1]) == 0) { puts("Invalid license."); return 3; }
   puts("License accepted."); reveal_flag(); return 0;
   ```
6. Doble clic en `validate_key` y renombrar variables (tecla **L**):
   `local_20 → len_esperada`, `local_c → diff`, `local_18 → i`, `local_21 → transformado`
7. Doble clic en `k.1` y `expected.0` para ver sus bytes en el *Listing*

## 3. Lo que muestra el desensamblado de `validate_key` (0x401156)

```asm
401162: mov  QWORD PTR [rbp-0x18],0x11      ; len_esperada = 17
401171: call strlen                          ; strlen(candidate)
401176: cmp  [rbp-0x18],rax
40117a: je   ...                             ; si la longitud no es 17 -> return 0
...                                          ; --- bucle i = 0..16 ---
40119f: movzx eax,BYTE PTR [candidate+i]     ; c = candidate[i]
4011a8: and  eax,0x3                         ; i & 3  -> índice cíclico 0,1,2,3,0,1...
4011ae: lea  rax,[k.1]                       ; k = {0x23,0x51,0x17,0x6a}
4011b9: xor  eax,ecx                         ; t = c ^ k[i & 3]
4011cf: xor  al,BYTE PTR [expected.0+i]      ; t ^ expected[i]  (0 si son iguales)
4011d5: or   DWORD PTR [rbp-0x4],eax         ; diff |= (t ^ expected[i])
...
4011e7: cmp  DWORD PTR [rbp-0x4],0x0
4011eb: sete al                              ; return diff == 0
```

### Datos en `.rodata`

| Símbolo | Dirección | Bytes |
|---|---|---|
| `k.1` (clave XOR, 4 bytes) | `0x40208b` | `23 51 17 6a` |
| `expected.0` (17 bytes) | `0x402090` | `65 15 44 23 0e 03 52 3c 66 03 44 2f 0e 63 27 58 15` |

## 4. Pseudocódigo propio

```text
función validar_licencia(candidata):
    K        ← [0x23, 0x51, 0x17, 0x6A]          # clave corta que se repite
    ESPERADO ← [0x65,0x15,0x44,0x23,0x0E,0x03,0x52,0x3C,
                0x66,0x03,0x44,0x2F,0x0E,0x63,0x27,0x58,0x15]

    si longitud(candidata) ≠ 17: retornar FALSO

    diferencias ← 0
    para i desde 0 hasta 16:
        transformado ← candidata[i] XOR K[i mod 4]
        diferencias  ← diferencias OR (transformado XOR ESPERADO[i])
    retornar (diferencias = 0)
```

Notas:
- `i & 3` equivale a `i mod 4`, así que la clave de 4 bytes se reutiliza cíclicamente (pista 1).
- Se acumula con `OR` en vez de cortar en el primer error. Así el tiempo de ejecución no depende de cuántos caracteres estén bien (comparación en tiempo constante, que evita ataques de *timing*).

## 5. Invertir el algoritmo

El XOR es reversible: si `c ^ k = e`, entonces `c = e ^ k` (pista 2). Por tanto:

```
clave[i] = ESPERADO[i] XOR K[i mod 4]
```

| i | expected | k[i%4] | resultado | char |
|--:|--:|--:|--:|:--:|
| 0 | 0x65 | 0x23 | 0x46 | F |
| 1 | 0x15 | 0x51 | 0x44 | D |
| 2 | 0x44 | 0x17 | 0x53 | S |
| 3 | 0x23 | 0x6a | 0x49 | I |
| 4 | 0x0e | 0x23 | 0x2d | - |
| 5 | 0x03 | 0x51 | 0x52 | R |
| 6 | 0x52 | 0x17 | 0x45 | E |
| 7 | 0x3c | 0x6a | 0x56 | V |
| 8 | 0x66 | 0x23 | 0x45 | E |
| 9 | 0x03 | 0x51 | 0x52 | R |
| 10 | 0x44 | 0x17 | 0x53 | S |
| 11 | 0x2f | 0x6a | 0x45 | E |
| 12 | 0x0e | 0x23 | 0x2d | - |
| 13 | 0x63 | 0x51 | 0x32 | 2 |
| 14 | 0x27 | 0x17 | 0x30 | 0 |
| 15 | 0x58 | 0x6a | 0x32 | 2 |
| 16 | 0x15 | 0x23 | 0x36 | 6 |

Script de comprobación:

```python
k = bytes.fromhex("2351176a")
e = bytes.fromhex("651544230e03523c6603442f0e63275815")
print(bytes(e[i] ^ k[i % 4] for i in range(len(e))).decode())   # FDSI-REVERSE-2026
```

## 6. Confirmación

```text
$ ./crackme_level2 FDSI-REVERSE-2026
=== FDSI CrackMe Level 2 ===
Hint: static + dynamic analysis.
License accepted.
FLAG{ghidra_plus_gdb}                    (exit code 0)
```

La confirmación dinámica con GDB está en [`gdb.md`](gdb.md).

`reveal_flag` usa el mismo truco que en el nivel 1: 21 bytes armados en el stack y decodificados con **XOR 0x37**.

---

# Boss Level — `crackme_level2_stripped`

## ¿Qué desapareció con `strip`?

| | `crackme_level2` | `crackme_level2_stripped` |
|---|---|---|
| `nm` | `main`, `validate_key`, `reveal_flag`, `k.1`, `expected.0`… | `no symbols` |
| `.symtab` / `.strtab` | sí | **no** |
| `.debug_*` (DWARF: nombres de variables, tipos, líneas del .c) | sí | **no** |
| Tamaño | 18 200 B | 14 424 B |
| Código máquina y `.rodata` | — | **idénticos** (mismas direcciones) |

`strip` elimina los **nombres**, no la **lógica**. Las cadenas, las constantes y las instrucciones siguen ahí.

## Cómo se encontró la validación sin nombres

1. **Desde `_start` hasta `main`.** El punto de entrada (`readelf -h` → `0x401070`) hace `mov rdi,0x401267` justo antes de llamar a `__libc_start_main`. El primer argumento de esa función siempre es `main`, así que `main` está en **0x401267**. En Ghidra aparece como `FUN_00401267` y se renombra a `main`.
2. **Desde las cadenas.** En Ghidra: *Search → For Strings* → `License accepted.` → clic derecho → *References → Show References to Address*. La referencia está en `0x4012d6`, dentro de `main`.
3. **Flujo de control.** Justo antes de esa referencia está:
   ```asm
   4012cd: call 0x401156        ; FUN_00401156  <- la validación
   4012d2: test eax,eax
   4012d4: je   -> "Invalid license."
   ```
   La función cuyo resultado decide entre "accepted" e "invalid" es la validadora, así que `FUN_00401156` se renombra a `validate_key`.
4. **Comportamiento.** Dentro de `FUN_00401156` aparecen el mismo patrón `strlen` + `cmp 0x11`, `and eax,0x3` y dos `xor` contra `DAT_0040208b` y `DAT_00402090`, y la función termina en `sete`. Es el mismo algoritmo. `FUN_004011f3` (llamada después de "accepted") hace XOR con 0x37 y `putchar`, así que es `reveal_flag`.
5. **Confirmación con GDB**, poniendo el breakpoint por dirección porque ya no hay nombres (`break *0x4012d2`). Ver `gdb.md`, sección 4.

```text
$ ./crackme_level2_stripped FDSI-REVERSE-2026
License accepted.
FLAG{ghidra_plus_gdb}
```

## Capturas sugeridas (`screenshots/`)
- `l2_ghidra_main.png`: decompilador de `main` mostrando la llamada a `validate_key`
- `l2_ghidra_validate_renamed.png`: `validate_key` con variables renombradas (**obligatoria**)
- `l2_ghidra_data.png`: bytes de `k.1` y `expected.0` en el Listing
- `l2_python_key.png`: script que reconstruye la clave
- `l2_flag.png`: ejecución exitosa
- `boss_nm.png`: `nm` mostrando `no symbols`
- `boss_ghidra_xref.png`: referencias a `License accepted.` → `FUN_00401156`
