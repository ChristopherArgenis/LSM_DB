# Limitaciones y consultas posibles

Este documento explica qué se puede y qué no se puede consultar con el esquema actual.
El SQL de cada consulta está en [`sql/03_consultas.sql`](../sql/03_consultas.sql), con el mismo código (A1, A2, …).
Los bloques A–J se probaron con los datos inventados de [`sql/datos_prueba.sql`](../sql/datos_prueba.sql) (hola/hello, ASL…).
El bloque K se probó con el diccionario real ([`sql/02_datos_dlsm_cdmx.sql`](../sql/02_datos_dlsm_cdmx.sql)).

## Idea clave: la SEÑA es el pivote

No hay relaciones directas entre `palabra`, `glosa` y `definicion`. Las tres se unen **solo a través de `sena`**:

```
palabra ──┐                       ┌── definicion (cualquier idioma)
          ├── sena_palabra ─ SENA ─ sena_definicion
glosa ────┘   sena_glosa      │
                              └── sena_diccionario ── diccionario
                                        │  (datos_fonologicos)
                                        └── sena_video ── video ── senante
```

Por eso funciona la consulta que comprobaste:

> *"Soy americano, sé que en español se dice 'hola' y quiero su definición en inglés."*
> `palabra 'hola' (Español) → sena_palabra → sena → sena_definicion → definicion (Inglés)`
> Resultado: *"Used as a greeting when meeting someone."* (consulta **A4**)

Y también explica casi todas las limitaciones: si algo no tiene seña, queda aislado.

---

## 1. Limitaciones (los "techos")

### 1.1 Todo depende de que exista una seña

| No se puede… | Por qué | Ejemplo en los datos |
|---|---|---|
| Obtener la definición o traducción de una palabra que no tiene seña | `palabra` y `definicion` no se relacionan entre sí; solo con `sena` | `perro` no tiene seña → no hay traducción ni definición |
| Saber a qué palabra corresponde una definición | La definición se liga a la seña, no a la palabra | En la seña CASA hay *casa* y *vivienda*; la definición es de la seña, no de una palabra |
| Traducir palabras entre idiomas hablados sin pasar por una seña | No hay tabla palabra↔palabra | Útil para un diccionario de señas, pero no es un diccionario bilingüe |

### 1.2 Sentidos y ambigüedad

- **Polisemia sin control:** si una palabra tiene varias señas, A4 devuelve **todas** las definiciones (`banco` → *bank* y *bench*). La única forma de distinguir el sentido es la glosa (`BANCO-DINERO`, `BANCO-ASIENTO`), y eso depende de cómo se escriba.
- **Si una seña tiene varias definiciones en el mismo idioma**, no hay forma de numerar acepciones (1ª, 2ª…) ni de decir cuál traduce a cuál en otro idioma.
- **Variante regional vs. seña distinta:** dos señas LSM con la misma palabra pueden ser variantes regionales o significados diferentes. El esquema no lo distingue.

### 1.3 Información que no existe en el esquema

| No se puede consultar… | Qué faltaría |
|---|---|
| Variantes por región / estado / comunidad | Campo `region` en `sena`, `senante` o `video` |
| Sinónimos, variantes o componentes **entre señas** (p. ej. señas compuestas) | Tabla `sena_relacion (id_sena_a, id_sena_b, tipo)`. Existe el tipo "compuesta", pero no se puede decir de qué señas se compone |
| Equivalencia directa LSM ↔ ASL | Hoy solo se infiere si ambas señas comparten una palabra (B1) |
| Lengua de un diccionario, año, editorial | `diccionario` solo tiene `completo` y `autor` |
| Qué diccionario dio una definición | `definicion` no se liga a `diccionario` |
| Ejemplos de uso, oraciones, categoría gramatical | No hay tablas ni campos para ello |
| Nombre, sexo, región o lengua materna del señante | `senante` solo tiene `edad` y `perfil_nativo` (texto libre) |
| Edad del señante **cuando grabó** | `edad` es fija; haría falta fecha de nacimiento |
| En qué segundo de un video aparece cada seña | `sena_video` no tiene tiempo de inicio/fin (el video de frase solo dice "contiene HOLA y CASA") |
| Duración, resolución o calidad del video | No hay campos |
| Historial de cambios / quién capturó qué | Solo `glosa` y `definicion` tienen `autor` y `fecha` |
| Más de un tipo por seña | `sena.id_tipo` es un solo valor |

### 1.4 Dependencias del diccionario

- Los **datos fonológicos** están en `sena_diccionario`, no en `sena`. Una seña que no está en ningún diccionario **no tiene fonología** (en los datos: HOUSE y HELLO de ASL).
- Los **videos** se ligan a `sena_diccionario`, no a `sena`. Una seña que no está en un diccionario **no puede tener video**. Un video de corpus libre (sin diccionario) solo puede quedar sin etiquetar.

### 1.5 Con el diccionario real (LSM CDMX 2017)

- **No hay glosas.** El diccionario no las trae, así que las consultas A–J que usan `glosa` salen vacías. La seña se identifica por `codigo` y `significado` del JSON (bloque K).
- **Solo hay español.** Para que funcione A4 (definición en inglés) hace falta cargar palabras y definiciones en inglés y ligarlas a las mismas señas.
- **Los parámetros fonológicos son texto libre** (`"La MD se mueve formando un arco."`). Se puede buscar por texto (`ILIKE '%arco%'`), pero no comparar parámetro por parámetro como en D1 y D5. Para eso habría que codificarlos (p. ej. `"configuracion": "B-P.6"`).
- **Las acepciones van juntas** en una sola definición (`1. adv. … 2. adv. …`). No se puede saber qué acepción corresponde a qué palabra del significado.
- **Variantes `(A)`/`(B)`**: la palabra queda ligada a varias señas, pero la letra de variante solo está en el texto de `significado`.

### 1.6 Integridad que el esquema no garantiza

Son cosas que se pueden capturar mal sin que PostgreSQL lo impida (las consultas del bloque **I** las detectan):

- `sena_diccionario.id_lengua` puede ser distinta de `sena.id_lengua` (dato redundante) → **I1**
- Una glosa de ASL se puede ligar a una seña LSM → **I2**
- La misma palabra se puede capturar dos veces en la misma lengua → **I3**
- ~~`datos_fonologicos` no tiene estructura fija~~ → **resuelto**: ahora PostgreSQL valida el JSON (ver [DATOS_FONOLOGICOS.md](DATOS_FONOLOGICOS.md))
- `modalidad`, `perfil_nativo`, `mano_dominante`, `tipo_de_toma` son texto libre ("derecha", "Derecha", "der")

---

## 2. Consultas posibles

### A. Palabras, traducción y definiciones
| Código | Pregunta | Ruta |
|---|---|---|
| A1 | ¿Qué seña(s) tiene la palabra *hola*? | palabra → seña → glosa |
| A2 | ¿Qué palabras (en todos los idiomas) corresponden a la glosa CASA? | glosa → seña → palabra |
| A3 | ¿Cómo se dice *banco* en inglés? | palabra es → seña → palabra en |
| **A4** | **Definición en inglés de la palabra en español *hola*** | palabra es → seña → definición en |
| A5 | Todas las definiciones de una seña, por idioma | glosa → seña → definición |
| A6 | Palabras polisémicas (una palabra, varias señas) | palabra → seña (conteo) |
| A7 | Sinónimos: palabras del mismo idioma que comparten seña (*casa / vivienda*) | seña → palabra (agrupado) |

### B. Entre lenguas de señas
| Código | Pregunta |
|---|---|
| B1 | Equivalente ASL de una seña LSM (por palabra compartida) |
| B2 | Número de señas por lengua de señas |
| B3 | Palabras, glosas y definiciones por lengua |

### C. Diccionarios
| Código | Pregunta |
|---|---|
| C1 | Contenido de un diccionario (glosa + palabras) |
| C2 | Número de señas por diccionario |
| C3 | ¿En qué diccionarios aparece la seña HOLA? |
| C4 | Señas que están en el diccionario A pero no en el B |
| C5 | Señas presentes en 2 o más diccionarios |
| C6 | Misma seña con datos fonológicos distintos según el diccionario |
| C7 | Qué parámetro exacto cambia entre diccionarios (CASA: orientación) |

### D. Fonología (`datos_fonologicos`)
| Código | Pregunta |
|---|---|
| D1 | Señas con configuración de mano "B" |
| D2 | Búsqueda combinada (ubicación = barbilla **y** movimiento = toque repetido) |
| D3 | Señas con un rasgo no manual (texto que contiene "sonrisa") |
| D4 | Frecuencia de cada configuración |
| D5 | Pares mínimos: señas que difieren en un solo parámetro (AGUA / MAMÁ) |
| D6 | Qué claves se usan en el JSON (control de calidad) |

### E. Tipo de seña
| Código | Pregunta |
|---|---|
| E1 | Número de señas por tipo |
| E2 | Señas de un tipo dado |

### F. Videos y señantes
| Código | Pregunta |
|---|---|
| F1 | Videos de una seña, con señante y diccionario |
| F2 | Video de una palabra en español (palabra → seña → video) |
| F3 | Señas contenidas en un video |
| F4 | Videos y señas distintas por señante |
| F5 | Señas grabadas por 2+ señantes (para estudiar variación) |
| F6 | Videos por mano dominante y tipo de toma (con subtotales) |
| F7 | Videos por perfil de señante y rango de edad |
| F8 | Videos en un rango de fechas |

### G. Autoría y fechas
| Código | Pregunta |
|---|---|
| G1 | Glosas y definiciones por autor |
| G2 | Lo capturado en un periodo |

### H. Cobertura (qué falta)
| Código | Pregunta |
|---|---|
| H1 | Palabras sin seña |
| H2 | Señas a las que les falta glosa, palabra, definición, diccionario o tipo |
| H3 | Señas sin definición en un idioma dado |
| H4 | Entradas de diccionario sin video |
| H5 | Videos sin seña y señantes sin videos |
| H6 | Definiciones y glosas no ligadas a ninguna seña |

### I. Consistencia
| Código | Pregunta |
|---|---|
| I1 | Lengua de la entrada de diccionario ≠ lengua de la seña |
| I2 | Glosa de otra lengua ligada a una seña |
| I3 | Palabras duplicadas |
| I4 | Señas con más de una glosa |

### J. Ficha completa
| Código | Pregunta |
|---|---|
| J1 | Todo lo que se sabe de una seña en una fila: lengua, tipo, glosas, palabras, definiciones por idioma, diccionarios y número de videos |

### K. Diccionario LSM CDMX 2017 (datos reales)
| Código | Pregunta |
|---|---|
| K1 | Buscar una palabra y ver su seña: código, tipo, configuración, ubicación, movimiento |
| K2 | Buscar por código del diccionario (`B-P 3`) |
| K3 | Palabras con varias señas (variantes A/B o sentidos distintos) |
| K4 | Sinónimos: palabras que comparten seña |
| K5 | Señas por tipo (SM, SB, SS, SC) |
| K6 | Señas compuestas con el detalle de cada parte |
| K7 | Señas por grupo de configuración (prefijo del código) |
| K8 | Búsqueda de texto en un parámetro (configuración `B-P.2`) |
| K9 | Rasgos no manuales que mencionan las cejas |
| K10 | Señas con nota cultural o representación |
| K11 | Señas de lugares (STC Metro, señas internacionales) |
| K12 | Definición en español de una palabra |
| K13 | Cobertura de cada campo opcional del JSON |

---

## 3. Cómo ejecutarlas

```bash
psql -d lsm_db -f sql/03_consultas.sql
```

O copia una consulta suelta y cambia el valor de ejemplo (`'hola'`, `'Inglés'`, `'B'`, …).
