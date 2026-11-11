# Limitaciones y consultas posibles

Qué se puede y qué no se puede consultar con el esquema actual, cargado con el
Diccionario LSM CDMX 2017 (1,006 señas).

- SQL de cada consulta: [`sql/03_consultas.sql`](../sql/03_consultas.sql) (códigos A1, A2, …).
- Resultados de cada consulta: [`docs/SALIDAS.md`](SALIDAS.md).

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

Por esa ruta funciona la consulta que comprobaste:

> *"Soy americano, sé que en español se dice 'hola' y quiero su definición en inglés."*
> `palabra 'hola' (Español) → sena_palabra → sena → sena_definicion → definicion (Inglés)` (consulta **A4**)

Hoy A4 sale vacía porque solo hay definiciones en español. La misma ruta en español (A5) sí devuelve resultados.
En cuanto se carguen definiciones en inglés ligadas a las mismas señas, A4 funciona sin cambiar nada.

---

## 1. Limitaciones (los "techos")

### 1.1 Todo depende de que exista una seña

| No se puede… | Por qué |
|---|---|
| Obtener la definición o traducción de una palabra que no tiene seña | `palabra` y `definicion` no se relacionan entre sí; solo con `sena` |
| Saber a qué palabra corresponde una definición | La definición se liga a la seña, no a la palabra. La seña 5-G 51 tiene *Bonito, Bello, Lindo, Belleza* y una sola definición |
| Traducir palabras entre idiomas hablados sin pasar por una seña | No hay tabla palabra↔palabra |

### 1.2 Sentidos y ambigüedad

- **Polisemia sin control:** si una palabra tiene varias señas, se obtienen todas sus definiciones mezcladas. *Abandonar* tiene 6 señas (A6).
- **Acepciones juntas:** el diccionario da varias acepciones en un solo texto (`1. adv. … 2. adv. …`) y se guardan en una sola fila. No se puede decir qué acepción corresponde a qué palabra.
- **Variante regional o seña distinta:** *Casa (A)* y *Casa (B)* son dos señas para la misma palabra. La letra de variante solo vive en el texto de `significado`; el esquema no distingue variante de sentido distinto.

### 1.3 Información que no existe en el esquema

| No se puede consultar… | Qué faltaría |
|---|---|
| Variantes por región / estado / comunidad | Campo `region` en `sena`, `senante` o `video` |
| Sinónimos, variantes o componentes **entre señas** | Tabla `sena_relacion (id_sena_a, id_sena_b, tipo)`. Existe el tipo SC (compuesta), pero no se puede decir de qué señas se compone |
| Equivalencia directa LSM ↔ ASL | Hoy solo se deduciría si ambas señas comparten una palabra (B1) |
| Lengua, año o equipo completo de un diccionario | `diccionario` solo tiene `nombre_completo` y `autor` |
| Qué diccionario dio una definición | `definicion` no se liga a `diccionario` (se usa el campo `autor`) |
| Ejemplos de uso u oraciones | No hay tablas ni campos para ello |
| Categoría gramatical | Solo se puede deducir del inicio de la definición (`sust.`, `v.`, … en K5) |
| Nombre, sexo, región o lengua materna del señante | `senante` solo tiene `edad` y `perfil_nativo` (texto libre) |
| Qué persona modeló cada seña en el diccionario | No hay relación seña ↔ señante; solo video ↔ señante |
| En qué segundo de un video aparece cada seña | `sena_video` no tiene tiempo de inicio/fin |
| Historial de cambios / quién capturó qué | Solo `glosa` y `definicion` tienen `autor` y `fecha` |
| Más de un tipo por seña | `sena.id_tipo` es un solo valor (las partes de una compuesta solo están en el JSON) |

### 1.4 Dependencias del diccionario

- Los **datos fonológicos** están en `sena_diccionario`, no en `sena`. Una seña que no está en ningún diccionario no tiene fonología.
- Los **videos** se ligan a `sena_diccionario`, no a `sena`. Una seña que no está en un diccionario no puede tener video.

### 1.5 Lo que el Diccionario CDMX no trae

- **Glosas:** la seña se identifica por `codigo` y `significado` del JSON.
- **Otros idiomas:** solo hay español, así que A3 y A4 salen vacías.
- **Videos y señantes:** el bloque F sale vacío.
- **Un segundo diccionario:** la comparación entre diccionarios (C4) sale vacía.
- **Parámetros fonológicos codificados:** la configuración sí usa códigos cortos (`A.1`, `B-P.2`) y se puede comparar exacta (D1, D2). Ubicación, movimiento y orientación son descripciones libres, así que los pares mínimos (D7) son una aproximación.

### 1.6 Integridad que el esquema no garantiza

Cosas que se pueden capturar mal sin que PostgreSQL lo impida (el bloque **I** las detecta):

- Códigos repetidos en el JSON (`C-84` aparece dos veces) → **I1**
- `sena_diccionario.id_lengua` distinta de `sena.id_lengua` → **I3**
- La misma palabra capturada dos veces → **I4**
- `modalidad`, `perfil_nativo`, `mano_dominante`, `tipo_de_toma` son texto libre ("derecha", "Derecha", "der")
- ~~`datos_fonologicos` sin estructura fija~~ → resuelto: PostgreSQL valida el JSON ([DATOS_FONOLOGICOS.md](DATOS_FONOLOGICOS.md))

---

## 2. Consultas

`[VACÍA HOY]` = la base todavía no tiene esa información. `[CONTROL]` = revisión de calidad; vacía significa sin problemas.

### A. Palabras, traducción y definiciones
| Código | Pregunta |
|---|---|
| A1 | ¿Qué seña(s) tiene la palabra *Casa*? |
| A2 | ¿Qué palabras tiene la seña 5-G 51? |
| A3 | `[VACÍA HOY]` ¿Cómo se dice *Casa* en inglés? |
| **A4** | `[VACÍA HOY]` **Definición en inglés de una palabra en español** |
| A5 | Definición en español de *Banco* |
| A6 | Palabras con varias señas (variantes o sentidos distintos) |
| A7 | Sinónimos: palabras que comparten seña (*Auto / Automóvil / Carro / Coche*) |

### B. Lenguas
| Código | Pregunta |
|---|---|
| B1 | `[VACÍA HOY]` Equivalente en otra lengua de señas |
| B2 | Señas por lengua de señas |
| B3 | Palabras, glosas y definiciones por lengua |

### C. Diccionarios
| Código | Pregunta |
|---|---|
| C1 | Datos del diccionario |
| C2 | Señas por diccionario |
| C3 | Contenido por página del PDF |
| C4 | `[VACÍA HOY]` Diferencias de una seña entre diccionarios |
| C5 | Señas por grupo de configuración (B-P, 5-G, A, L, S, C, O) |
| C6 | Buscar una seña por código (JSON completo) |

### D. Fonología
| Código | Pregunta |
|---|---|
| D1 | Señas con configuración exacta `B-P.2` |
| D2 | Configuración `A.1` **y** ubicación "A la altura del pecho." |
| D3 | Configuraciones que contienen `B-P.2` (incluye compuestas y bimanuales) |
| D4 | Rasgos no manuales que mencionan las cejas |
| D5 | Frecuencia de cada configuración |
| D6 | Frecuencia de cada ubicación |
| D7 | Pares mínimos (aproximación) |
| D8 | Cobertura de cada campo del JSON |

### E. Tipo de seña
| Código | Pregunta |
|---|---|
| E1 | Señas por tipo (SM, SB, SS, SC) |
| E2 | Señas compuestas y sus partes |
| E3 | Combinaciones de partes en las compuestas |

### F. Videos y señantes (todas `[VACÍA HOY]`)
| Código | Pregunta |
|---|---|
| F1 | Videos de una seña y su señante |
| F2 | Video de una palabra |
| F3 | Videos y señas por señante |
| F4 | Señas grabadas por varios señantes |
| F5 | Videos por mano dominante y tipo de toma |

### G. Autoría
| Código | Pregunta |
|---|---|
| G1 | Definiciones y glosas por autor |

### H. Cobertura
| Código | Pregunta |
|---|---|
| H1 | Resumen: cuántas señas tienen palabra, definición, glosa, diccionario, video, tipo |
| H2 | Señas sin tipo |
| H3 | Señas sin movimiento u orientación |
| H4 | `[CONTROL]` Palabras sin seña |

### I. Consistencia (todas `[CONTROL]`)
| Código | Pregunta |
|---|---|
| I1 | Códigos repetidos |
| I2 | Significados repetidos |
| I3 | Lengua de la entrada distinta de la de la seña |
| I4 | Palabras duplicadas |
| I5 | Tipo en `sena` distinto del tipo en el JSON |

### J. Ficha completa
| Código | Pregunta |
|---|---|
| J1 | Todo sobre una seña en una fila: palabras, definición, tipo, configuración, ubicación, movimiento |

### K. Temas del diccionario
| Código | Pregunta |
|---|---|
| K1 | Señas con nota cultural |
| K2 | Señas con representación (qué imitan) |
| K3 | Estaciones del Metro |
| K4 | Señas de lugares internacionales |
| K5 | Señas por categoría gramatical |
| K6 | Búsqueda libre en las definiciones |

---

## 3. Cómo ejecutarlas

Todas, con sus resultados en `docs/SALIDAS.md`:

```bash
python3 scripts/generar_salidas.py
```

Solo algunas, en pantalla:

```bash
python3 scripts/generar_salidas.py A1 D7
```

Directo en PostgreSQL:

```bash
psql -d lsm_db -f sql/03_consultas.sql
```
