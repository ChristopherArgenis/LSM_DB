# Esquema de `datos_fonologicos` (JSONB)

Columna `sena_diccionario.datos_fonologicos`: describe **una seña según un diccionario**.
Si la misma seña está en dos diccionarios, cada uno tiene su propio JSON.

La regla está definida en tres lugares que deben coincidir:

| Dónde | Para qué |
|---|---|
| `sql/01_schema.sql` → función `lsm.valida_datos_fonologicos` | PostgreSQL **rechaza** cualquier `INSERT`/`UPDATE` que no cumpla (restricción `datos_fonologicos_validos`) |
| `schemas/datos_fonologicos.schema.json` | JSON Schema estándar, para validar desde Python, JS, etc. antes de insertar |
| Este documento | Referencia para personas |

## Campos

```
datos_fonologicos: {
  "codigo":             "str",  # Obligatorio. Código de la seña en el diccionario. Ej. "B-P 3"
  "significado":        "str",  # Obligatorio. El significado de la seña según el diccionario, tal como aparece
  "tipo_sena":          "str",  # Obligatorio. Tipo como lo escribe el diccionario. Ej. "SB", "SC: I. SM; II. SB"
  "configuracion":      "str",  # Obligatorio. Configuración manual (forma de la mano). Ej. "MD y MB B-P.6"
  "ubicacion":          "str",  # Obligatorio. Dónde se articula la seña
  "orientacion":        "str",  # Opcional.    Orientación de la(s) palma(s)
  "movimiento":         "str",  # Opcional.    Movimiento de la(s) mano(s)
  "rasgos_no_manuales": "str",  # Opcional.    Expresión facial, cabeza, cuerpo
  "representacion":     "str",  # Opcional.    Qué representa o imita la seña
  "definicion":         "str",  # Opcional.    Definición del diccionario (también va en la tabla definicion)
  "nota_cultural":      "str",  # Opcional.    Nota sobre el uso cultural
  "pagina":             "int"   # Opcional.    Página del PDF del diccionario (>= 1)
}
```

### Reglas

1. Las 5 claves obligatorias deben existir.
2. Todos los valores son texto **no vacío**, salvo `pagina`, que es un entero ≥ 1.
3. Si un dato no existe, **se omite la clave**. No se usan `null` ni `""`.
4. **No se aceptan otras claves.** Así se evitan variantes como `configuracion_manual` / `configuracion` / `config`, que harían que una búsqueda no encuentre la seña.

### ¿Por qué estos campos son obligatorios?

`configuracion` y `ubicacion` están en las 1,006 señas del diccionario CDMX.
`orientacion` falta en 1 seña y `movimiento` en 21, así que quedaron opcionales.
`definicion` está en todas, pero es opcional para poder cargar diccionarios que no traigan definiciones.

## Ejemplos válidos

```json
{
  "codigo": "B-P 3",
  "significado": "¿Y eso?",
  "tipo_sena": "SC: I. SM; II. SB",
  "configuracion": "I. B-P.2; II. MD y MB 1.1",
  "orientacion": "I. y II. Palmas hacia adentro.",
  "ubicacion": "I. La mano inicia sobre el pecho y se desliza hacia enfrente; II. Del pecho al rostro.",
  "movimiento": "I. La mano se mueve formando un arco; II. MD y MB recto alternadamente.",
  "rasgos_no_manuales": "Cejas hacia arriba, comisuras de los labios ligeramente hacia abajo.",
  "definicion": "loc. adv. Frase coloquial para preguntar a nuestro interlocutor por qué razón ocurre alguna situación.",
  "nota_cultural": "La seña se emplea después de una ofensa como respuesta.",
  "pagina": 1
}
```

```json
{
  "codigo": "B-P 4",
  "significado": "Abajo – Debajo",
  "tipo_sena": "SB",
  "configuracion": "MD y MB B-P.6",
  "orientacion": "MD y MB palmas hacia abajo.",
  "ubicacion": "MD inicia sobre MB y termina a la altura de la cintura, MB a la altura del pecho.",
  "movimiento": "La MD se mueve formando un arco.",
  "representacion": "Simula la acción de poner algo debajo de otra cosa.",
  "definicion": "1. adv. En el lugar o parte inferior. 2. adv. En la parte inferior o interna de algo y cubierto por ello.",
  "pagina": 1
}
```

## Ejemplos rechazados

| JSON | Motivo |
|---|---|
| `{"codigo": "X", "significado": "x", "tipo_sena": "SM", "configuracion_manual": "B", "ubicacion": "x"}` | Clave no permitida (`configuracion_manual`) y falta `configuracion` |
| `{..., "significado": ""}` | Texto vacío |
| `{..., "pagina": "3"}` | `pagina` debe ser número, no texto |
| `{..., "orientacion": null}` | Se omite la clave en lugar de poner `null` |

## Cómo cambiar el esquema

Para agregar un campo, por ejemplo `region`:
1. Agrégalo a la lista de claves permitidas en `valida_datos_fonologicos` (`sql/01_schema.sql`).
2. Agrégalo a `properties` en `schemas/datos_fonologicos.schema.json`.
3. Agrégalo a la tabla de este documento.
