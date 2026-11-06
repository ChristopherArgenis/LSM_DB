# Importación del Diccionario LSM CDMX (2017)

Fuente: `data/LSM_diccionario_Scraper.xlsx` (scrapeo del PDF, 1,006 señas).
Script: `scripts/importar_dlsm_cdmx.py` → genera `sql/02_datos_dlsm_cdmx.sql`.

```bash
pip install openpyxl
python3 scripts/importar_dlsm_cdmx.py
```

## Qué se llenó

| Tabla | Filas | De dónde sale |
|---|---|---|
| `lengua` | 2 | "Lengua de Señas Mexicana" y "Español" |
| `diccionario` | 1 | "Diccionario de Lengua de Señas Mexicana de la Ciudad de México (2017)". `autor` queda vacío (el Excel no lo trae) |
| `tipo_sena` | 4 | `SM`, `SB`, `SS`, `SC` (columna *Tipo de Seña*) |
| `sena` | 1,006 | Una por fila del Excel. `id_tipo` = tipo principal (`SC` si es compuesta) |
| `sena_diccionario` | 1,006 | Una por seña, con todo el detalle en `datos_fonologicos` |
| `definicion` | 1,006 | Columna *Definición*, en español. `autor` = nombre del diccionario, `fecha` vacía |
| `sena_definicion` | 1,006 | Una por seña |
| `palabra` | 1,123 | Palabras en español sacadas de *Significado* (sin repetir) |
| `sena_palabra` | 1,258 | Una seña puede tener varias palabras (sinónimos, acepciones) |

## Qué NO se llenó

`glosa`, `sena_glosa`, `senante`, `video`, `sena_video`: el diccionario no trae esa información.
La seña se identifica por `codigo` y `significado` dentro de `datos_fonologicos`.

## Correspondencia de columnas

| Columna del Excel | Destino |
|---|---|
| Pagina_PDF | `datos_fonologicos.pagina` |
| Codigo | `datos_fonologicos.codigo` |
| Significado | `datos_fonologicos.significado` + tabla `palabra` |
| Tipo de Seña | `datos_fonologicos.tipo_sena` + `sena.id_tipo` |
| Configuración | `datos_fonologicos.configuracion` |
| Orientación | `datos_fonologicos.orientacion` |
| Ubicación | `datos_fonologicos.ubicacion` |
| Movimiento | `datos_fonologicos.movimiento` |
| Rasgos no manuales | `datos_fonologicos.rasgos_no_manuales` |
| Representación | `datos_fonologicos.representacion` |
| Definición | `datos_fonologicos.definicion` + tabla `definicion` |
| Nota cultural | `datos_fonologicos.nota_cultural` |

## Cómo se sacan las palabras del *Significado*

| Significado | Palabras |
|---|---|
| `Abajo – Debajo` | Abajo, Debajo (`–` = sinónimos) |
| `Abrir 1 / Abierto, ta 2 (A)` | Abrir, Abierto (`/` = acepciones; se quitan número, terminación femenina y variante) |
| `Ir (A)` y `Ir (B)` | Ir → la misma palabra queda ligada a 2 señas (variantes) |
| `Cuba 1 (LSM) / Cuba 2 (bebida)` | Cuba (se quitan las aclaraciones entre paréntesis) |
| `Guadalajara, Jalisco` | Guadalajara, Jalisco (la coma con mayúscula no es terminación femenina) |

El texto original completo siempre queda en `datos_fonologicos.significado`.

## Limpieza y correcciones aplicadas

- Espacios repetidos eliminados.
- Palabras cortadas con guion por el PDF unidas en todos los campos: `alimen- to` → `alimento` (51 casos).

Correcciones de errores del scraper:

| Código | Problema | Corrección |
|---|---|---|
| B-P 111 | Tipo `SB Centro` | Tipo `SB`; significado `Centro Paralímpico Mexicano (CEPAMEX)` |
| 5-G 25 | Tipo `SB \|` | Tipo `SB` |
| 5-G 51 | Tipo `SM Bonito,`; significado `ta – Bello, lla – …` | Tipo `SM`; significado `Bonito, ta – Bello, lla – Lindo, da 1 / Belleza 2` |
| A-159 | Tipo `SB Promiscuo,`; significado `cua – Mujeriego, …` | Tipo `SB`; significado `Promiscuo, cua – Mujeriego, ga – Casanova` |
| A-26 | La orientación quedó dentro de la configuración | Separadas |
| `120`, `121` | Código sin prefijo (están entre S-119 y S-122) | `S-120`, `S-121` |

## Pendientes (no se corrigieron, hay que revisarlos en el PDF)

| Código | Problema |
|---|---|
| C-84 | Aparece dos veces: *Cuba* (pág. 308) y *Enfermera (A)* (pág. 309). Una de las dos probablemente es otro código |
| O-80 | Tipo `MB` (no existe ese tipo). `sena.id_tipo` quedó vacío; el texto original se conserva en el JSON |
| L-119 | Configuración `Seña que pasa de L.1 a S.1 a Configuración M.1` y sin orientación: posible error del scraper |
| Varios | Errores de OCR dentro del texto (`A Ia altura`, `c ontacto`) que no se pueden corregir de forma automática |

## Notas sobre el diseño

- **Tipo de seña.** `SM` y `SB` parecen ser monomanual y bimanual. `SS` en los datos son señas con las dos manos y una sola configuración (posiblemente "simétrica"). `SC` son las compuestas, con sus partes I, II, III. Conviene confirmar los nombres oficiales en la introducción del diccionario.
- **Definiciones con varias acepciones** (`1. adv. … 2. adv. …`) se guardan en **una sola** fila de `definicion`, tal como vienen.
- **La definición se guarda dos veces**: en el JSON (como en tu ejemplo) y en la tabla `definicion`, que es la que permite la consulta entre idiomas (A4). Se puede quitar del JSON si se prefiere no duplicarla.
