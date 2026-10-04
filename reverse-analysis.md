# Análisis de ingeniería inversa — FDSI Lab 04 Parte 2

## Resumen de resultados

| Nivel | Binario | Técnica clave | Clave | FLAG |
|---|---|---|---|---|
| 1 · Recon | `crackme_level1` | `strings` + `objdump` (`strcmp`) | `REDTEAM-101` | `FLAG{strings_are_evidence}` |
| 2 · Decompile | `crackme_level2` | Ghidra + inversión de XOR + GDB | `FDSI-REVERSE-2026` | `FLAG{ghidra_plus_gdb}` |
| Boss · Stripped | `crackme_level2_stripped` | `_start`→`main`, xrefs de strings, breakpoints por dirección | `FDSI-REVERSE-2026` | `FLAG{ghidra_plus_gdb}` |

Detalle: [`baseline.txt`](docs/evidence/reverse/baseline.txt) · [`level1.md`](docs/evidence/reverse/level1.md) · [`level2.md`](docs/evidence/reverse/level2.md) · [`gdb.md`](docs/evidence/reverse/gdb.md)

---

## Preguntas de análisis

### 1. ¿Qué información pudiste obtener sin ejecutar el binario?
Bastante:
- Con `file` y `readelf -h`: formato ELF64, arquitectura x86-64, enlazado dinámico, punto de entrada `0x401070`, y si tiene o no símbolos y debug info.
- Con `sha256sum`: la integridad del archivo.
- Con `strings`: los mensajes, la contraseña completa del nivel 1, las funciones importadas (`strcmp`, `strlen`) y los nombres de funciones y variables.
- Con `objdump` y Ghidra: el algoritmo completo de validación, la longitud esperada (17), la clave XOR y el arreglo `expected`.

Con eso se puede deducir la clave del nivel 2 **sin ejecutarlo**. La ejecución solo se usó para confirmar.

### 2. ¿Por qué una contraseña compilada como string es un diseño inseguro?
Porque el compilador guarda el literal tal cual en `.rodata`. Cualquiera con el ejecutable la lee con `strings` en segundos, sin saber ensamblador. Además es igual en todas las copias del programa, no se puede rotar sin recompilar y redistribuir, y queda en el historial de Git. Es la debilidad CWE-798 (*Use of Hard-coded Credentials*).

### 3. ¿Qué cambió entre `crackme_level2` y `crackme_level2_stripped`?
Se eliminaron `.symtab`, `.strtab` y todas las secciones `.debug_*` (DWARF). El archivo pasó de 18 200 B a 14 424 B, `nm` dice `no symbols`, Ghidra muestra `FUN_00401156` en lugar de `validate_key` y GDB muestra `?? ()`. **No cambió** el código máquina ni `.rodata`: verificamos con `objcopy` + `cmp` que `.text` y `.rodata` son byte a byte idénticos. El strip solo hace más lento el análisis; no protege la lógica.

### 4. ¿Qué ventaja tuvo Ghidra sobre objdump?
`objdump` entrega un listado lineal de instrucciones. Ghidra agrega:
- un **decompilador** a pseudo-C, donde los bucles, los `if` y los índices se leen directamente;
- **referencias cruzadas** (quién usa una cadena o quién llama una función), que fueron clave en el boss;
- **renombrado** de funciones y variables que se propaga en todo el proyecto;
- vista de datos tipados (arreglos `k` y `expected`) y grafo de flujo.

Con objdump hay que reconstruir todo eso a mano.

### 5. ¿Qué confirmó GDB que el análisis estático por sí solo no demostraba?
Que la hipótesis es correcta **en ejecución real**:
- el argumento llega en `rdi`;
- los bytes de `k` y `expected` en memoria son los que leímos;
- el XOR produce exactamente `expected[i]` (por ejemplo `'F' ^ 0x23 = 0x65`);
- `validate_key` retorna 0 con una clave falsa y 1 con la reconstruida.

El análisis estático puede equivocarse (decompilación imprecisa, datos modificados en tiempo de ejecución). GDB lo demuestra.

### 6. ¿Por qué Burp Suite no es una herramienta de ingeniería inversa de binarios?
Burp es un **proxy HTTP**: se ubica entre el navegador y el servidor para interceptar, modificar y repetir peticiones y respuestas. Analiza el **tráfico** de una aplicación web, o sea, su comportamiento observable en la red. No abre ejecutables, no desensambla, no decompila ni pone breakpoints. Ghidra y GDB analizan el **programa en sí** (código máquina, memoria, registros). Son niveles distintos: la comunicación frente a la implementación.

### 7. ¿Qué controles de desarrollo evitarían embebidos inseguros de secretos en software real?
- **No validar secretos en el cliente.** La verificación se hace en el servidor y el cliente nunca tiene la respuesta correcta.
- Guardar solo **hashes con sal y lentos** (bcrypt, scrypt, argon2), nunca la contraseña ni un XOR reversible. El XOR del nivel 2 es ofuscación, no cifrado.
- Para licencias, usar **firmas asimétricas** (el cliente solo tiene la llave pública y no puede generar licencias válidas).
- Usar **gestores de secretos** (Vault, AWS/Azure Secrets Manager) o variables de entorno, en lugar de literales en el código.
- **Escaneo de secretos** en CI y pre-commit (gitleaks, trufflehog, GitHub secret scanning), y SAST (Semgrep, SonarQube).
- Revisión de código y **rotación** de credenciales cuando se filtran.
- Asumir que **todo binario distribuido será analizado**: strip y ofuscación solo retrasan al atacante.

---

## Enseñanza principal
> Todo lo que se distribuye al cliente puede ser leído por el cliente. El nivel 1 cayó con `strings`, el nivel 2 con Ghidra y el XOR invertido, y el `strip` no cambió nada de la lógica. La seguridad tiene que estar en el diseño (servidor, hashes, firmas), no en esconder datos dentro del ejecutable.

Un detalle positivo del nivel 2: compara con `OR` acumulado (tiempo constante) en lugar de cortar en el primer carácter incorrecto. Así evita ataques de *timing*, que sería la siguiente vía para atacarlo.
