# El esquema de LSM_DB, explicado

Este documento describe en texto cada tabla del esquema `lsm`: qué guarda, cómo se conecta y por qué está hecha así. El SQL está en [`sql/01_schema.sql`](../sql/01_schema.sql) y el diagrama en [`img/diagrama_er.png`](img/diagrama_er.png).

## La idea en una frase

**La seña es el pivote.** Todo lo demás (palabras, glosas, definiciones, diccionarios y videos) se conecta a la seña, nunca entre sí.

```
            palabra ─┐
              glosa ─┤
         definicion ─┼── sena ── sena_diccionario ── diccionario
                     │     │            │
          tipo_sena ─┘   lengua     sena_video ── video ── senante
```

## Dos ejes independientes: lengua y diccionario

- **Lengua** dice *en qué idioma* está algo. Una seña es de LSM; una palabra o una definición están en español.
- **Diccionario** dice *qué fuente* lo afirma.

Un diccionario bilingüe tiene textos en dos lenguas, y una lengua tiene muchos diccionarios. Por eso la lengua vive en lo que describe (la seña o el texto) y no en la relación con el diccionario.

## Catálogos

### `lengua`
Las lenguas del sistema, de señas u orales.

| Columna | Tipo | Significado |
|---|---|---|
| `id_lengua` | entero, PK | Identificador |
| `nombre_completo` | texto, obligatorio | «Lengua de Señas Mexicana», «Español» |
| `modalidad` | texto | «viso-gestual» u «oral-auditiva» |

### `tipo_sena`
Catálogo de tipos: **SM** (monomanual), **SB** (bimanual), **SS** (bimanual simétrica) y **SC** (compuesta).

| Columna | Tipo | Significado |
|---|---|---|
| `id_tipo_sena` | entero, PK | Identificador |
| `tipo` | texto, único | Código del tipo |

### `diccionario`
Cada fuente que aporta señas.

| Columna | Tipo | Significado |
|---|---|---|
| `id_diccionario` | entero, PK | Identificador |
| `nombre_completo` | texto, obligatorio | Nombre de la obra, p. ej. «Diccionario de Lengua de Señas Mexicana de la Ciudad de México (DLSM, 2017)» |
| `autor` | texto | Autor o coordinador |

### `senante`
La persona que ejecuta la seña en un video.

| Columna | Tipo | Significado |
|---|---|---|
| `id_senante` | entero, PK | Identificador |
| `edad` | entero ≥ 0 | Edad al grabar |
| `perfil_nativo` | texto | Si es señante nativo, de qué comunidad, etc. |

## El centro: `sena`

Una seña es una unidad de la lengua de señas, independiente de cualquier diccionario.

| Columna | Tipo | Significado |
|---|---|---|
| `id_sena` | entero, PK | Identificador |
| `id_tipo` | FK → `tipo_sena` | Tipo principal de la seña |
| `id_lengua` | FK → `lengua`, obligatoria | Lengua de la seña (LSM). **Es el único lugar donde se guarda la lengua de la seña.** |

## Contenido en texto

Las tres tablas tienen su propia `id_lengua`, porque su lengua es la del *texto* (español), no la de la seña.

### `palabra`
Una palabra de una lengua oral que traduce una o más señas.

| Columna | Tipo | Significado |
|---|---|---|
| `id_palabra` | entero, PK | Identificador |
| `palabra` | texto, obligatorio | La palabra en su forma de cita (lema): «Comer», «Bonito» |
| `id_lengua` | FK → `lengua` | Idioma de la palabra |

### `glosa`
La **ID-glosa**: el nombre único de la seña escrito con palabras del español en MAYÚSCULAS (CASA-A, ABANDONAR-2). No es una traducción: es una etiqueta para identificar la seña sin ambigüedad.

| Columna | Tipo | Significado |
|---|---|---|
| `id_glosa` | entero, PK | Identificador |
| `glosa` | texto, obligatorio | La ID-glosa |
| `autor`, `fecha` | texto, fecha | Quién la propuso y cuándo |
| `id_lengua` | FK → `lengua` | Lengua de la seña que glosa |

### `definicion`
El texto que explica el significado.

| Columna | Tipo | Significado |
|---|---|---|
| `id_definicion` | entero, PK | Identificador |
| `definicion` | texto, obligatorio | Definición completa, con categoría («v. tr.», «sust. f.») |
| `autor`, `fecha` | texto, fecha | Quién la redactó |
| `id_lengua` | FK → `lengua` | Idioma de la definición |

## Tablas intermedias (todas pasan por la seña)

Cada una es una relación N:M con una restricción `UNIQUE` que impide repetir el mismo par.

| Tabla | Une | Ejemplo |
|---|---|---|
| `sena_palabra` | seña ↔ palabra | La seña A-69 ↔ Auto, Automóvil, Carro, Coche (sinónimos) |
| `sena_glosa` | seña ↔ glosa | La seña S-4 ↔ ABANDONAR-2 |
| `sena_definicion` | seña ↔ definición | La seña S-4 ↔ «1. Dejar solo algo… 2. Suspender una actividad…» |

## `sena_diccionario`: la seña según un diccionario

Una fila es **una seña descrita por un diccionario**. Si dos diccionarios describen la misma seña, hay dos filas, cada una con su descripción.

| Columna | Tipo | Significado |
|---|---|---|
| `id_sena_diccionario` | entero, PK | Identificador de la entrada |
| `id_sena` | FK → `sena` | La seña descrita |
| `id_diccionario` | FK → `diccionario` | La fuente |
| `datos_fonologicos` | JSONB validado | Cómo se hace la seña según esa fuente |

`UNIQUE (id_sena, id_diccionario)`: un diccionario describe una seña una sola vez.

**Cambio del 2026-11-11:** se quitó `id_lengua` de esta tabla. La lengua de una entrada es siempre la de su seña (`sena.id_lengua`); tenerla dos veces era redundante y podía contradecirse. Ver [DECISIONES_DE_DISENO.md](DECISIONES_DE_DISENO.md).

### `datos_fonologicos` y el nuevo campo `nota`

Un objeto JSON que PostgreSQL valida antes de guardarlo (función `valida_datos_fonologicos`):

| Clave | ¿Obligatoria? | Contenido |
|---|---|---|
| `codigo` | sí | Código en el diccionario: «S-4» |
| `significado` | sí | Significado tal como aparece: «Abandonar 1 – Dejar 2» |
| `tipo_sena` | sí | Tipo como lo escribe la fuente: «SC: I. SB; II. SS» |
| `configuracion` | sí | Forma de la mano: «Seña que pasa de S.1 a 5.1» |
| `ubicacion` | sí | Dónde se hace: «Del pecho a la cintura…» |
| `orientacion` | no | Hacia dónde mira la palma |
| `movimiento` | no | Cómo se mueve la mano |
| `rasgos_no_manuales` | no | Cara, cabeza, cuerpo |
| `representacion` | no | Qué imita la seña |
| `definicion` | no | Definición de la fuente |
| `nota_cultural` | no | Uso en la comunidad |
| **`nota`** | no | **Excepciones de la entrada** (nueva) |
| `pagina` | no | Página del PDF (entero ≥ 1) |

**`nota`** guarda las excepciones: lo que hay que advertir de esa seña en ese diccionario y no cabe en otra clave. Por ejemplo, el uso restringido de una variante, la diferencia con otra seña del mismo significado o un error de la fuente. Es texto no vacío y, como las demás opcionales, se omite si no hay nada que decir. Detalles y ejemplos en [DATOS_FONOLOGICOS.md](DATOS_FONOLOGICOS.md).

## Videos

### `video`
Una grabación.

| Columna | Tipo | Significado |
|---|---|---|
| `id_video` | entero, PK | Identificador |
| `mano_dominante` | texto | Derecha o izquierda |
| `tipo_de_toma` | texto | Frontal, lateral… |
| `path` | texto, obligatorio | Ruta del archivo |
| `fecha` | fecha | Fecha de grabación |
| `id_senante` | FK → `senante`, obligatoria | Quién señó |

### `sena_video`
Liga un video con una entrada de diccionario («este video muestra la seña S-4 del DLSM»).

| Columna | Tipo | Significado |
|---|---|---|
| `id_sena_video` | entero, PK | Identificador |
| `id_video` | FK → `video` | La grabación |
| `id_sena_diccionario` | FK → `sena_diccionario` | La entrada que documenta |

## Reglas que protege la base

1. **Llaves foráneas:** no se puede ligar una seña a una palabra, glosa, diccionario o lengua que no exista.
2. **`UNIQUE` en las intermedias:** no se repite un mismo par.
3. **`ON DELETE CASCADE`** en las intermedias: si se borra una seña, se borran sus vínculos.
4. **Validación del JSON:** claves permitidas, obligatorias presentes, sin textos vacíos.
5. **Índices** en todas las FK, en `LOWER(palabra)` (búsqueda sin mayúsculas), un índice GIN en `datos_fonologicos` (búsqueda por contenido) y otro en el `codigo`.

## Recorrido típico de una consulta

«¿Qué seña uso para *Coche* y qué significa?»

```
palabra (Coche, id 411)
  → sena_palabra (id_sena 425)
    → sena (425, tipo SB)
      → sena_glosa → glosa AUTO
      → sena_definicion → definicion «Vehículo con motor…»
      → sena_diccionario → datos_fonologicos (código A-69, MD A.1, MB S.1…)
```

Este recorrido a mano es el que practican los [ejercicios de anotación manual](EJERCICIOS_ANOTACION_MANUAL.md).
