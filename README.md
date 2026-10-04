# FDSI · Lab 04 Parte 2 — Reverse Engineering Challenge

Ruta alternativa local del ejercicio Red Team vs. Blue Team: CTF de ingeniería inversa sobre tres crackmes ELF x86-64 entregados por el docente (sin código fuente).

## Resultados

| Nivel | Clave | FLAG |
|---|---|---|
| 🟢 Level 1 – Recon | `REDTEAM-101` | `FLAG{strings_are_evidence}` |
| 🟡 Level 2 – Reverse Engineering | `FDSI-REVERSE-2026` | `FLAG{ghidra_plus_gdb}` |
| 🔴 Boss – Stripped | `FDSI-REVERSE-2026` | `FLAG{ghidra_plus_gdb}` |

## Estructura

```
docs/evidence/reverse/
├── baseline.txt        # file, sha256sum, readelf, nm (integridad y formato)
├── level1.md           # hipótesis → evidencia → resultado (strings / strcmp)
├── level2.md           # Ghidra, pseudocódigo propio, inversión del XOR + Boss stripped
├── gdb.md              # confirmación dinámica (clave falsa vs. válida)
├── gdb-scripts/        # scripts .gdb reproducibles
├── gdb-output.log      # salida completa de GDB
├── runs.log            # ejecuciones de los binarios
└── screenshots/        # capturas (ver screenshots/README.md)
reverse-analysis.md     # resumen + respuestas a las preguntas de análisis
```

## Entorno
- Ubuntu/Kali x86-64 (o WSL2 en Windows)
- `binutils` (file, strings, readelf, objdump, nm), `gdb`, Ghidra

## Integridad de los binarios analizados

| Archivo | SHA-256 | Estado |
|---|---|---|
| crackme_level1 | `61e980febe84b1003b5a3b641468e915b984f7fdd835be9828af54233f88c68c` | ✔ coincide |
| crackme_level2 | `8dc5931dfbf74d7371de9ca9ed8cc57bfe0af4521346202dcd1c701dd8b6f4e5` | ✔ coincide |
| crackme_level2_stripped | `c8e638741272a87ee3b30fe8878898c1aa977e6a879a1ec0b271034b5bb9aed3` | ✔ coincide |

> Los binarios no se suben al repositorio; solo la evidencia del análisis.

## Alcance
Análisis realizado únicamente sobre los crackmes académicos autorizados por el docente.

Tag de entrega: `lab-reverse-v1`
