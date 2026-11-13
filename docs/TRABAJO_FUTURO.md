# Trabajo futuro

Lo que el esquema actual no modela y que conviene agregar después. Ninguno de estos puntos exige rehacer lo que ya existe: son tablas o campos nuevos alrededor de `sena`.

## 1. Verbos

**Situación actual.** Un verbo es una seña más: tiene glosa (COMER, ABANDONAR-2), palabra («Comer») y definición («v. tr. …»). La categoría «verbo» solo aparece dentro del texto de la definición.

**Lo que falta.** En las lenguas de señas los verbos cambian de forma según la oración, y nada de eso se puede guardar hoy:

| Fenómeno | Ejemplo | Qué tendría que guardar la base |
|---|---|---|
| **Concordancia o dirección** | DAR que va de mí hacia ti vs. de ti hacia mí | Tipo de verbo (plano, de concordancia, espacial) y puntos de inicio y fin del movimiento |
| **Aspecto** | TRABAJAR repetido = «trabajar mucho, sin parar» | Las modulaciones del movimiento (repetición, duración, intensidad) |
| **Formas de una misma seña** | Una seña base y sus versiones modificadas | Una relación forma → seña base, con qué cambió |
| **Argumentos** | Quién hace la acción y sobre qué | Valencia (intransitivo, transitivo, ditransitivo), que hoy solo está como «v. tr.» en el texto |

**Propuesta para cuando se aborde:**

- un catálogo `tipo_verbo` (plano, de concordancia, espacial) y una columna opcional en `sena`;
- una tabla `forma_sena (id_forma, id_sena_base, rasgo, valor)` para las modulaciones;
- grabaciones de cada forma en `sena_video`, que ya existe.

**Por qué no ahora:** el DLSM CDMX 2017 registra cada verbo en su forma de cita, sin sus formas flexionadas. No hay datos con qué llenar estas tablas, y diseñarlas sin datos produciría columnas vacías.

## 2. Señas compuestas y sus partes

Hay 140 señas compuestas cuyas partes solo están descritas en texto («I. …; II. …»). Por ejemplo, ACTA-DE-NACIMIENTO se forma de ACTA + NACER. La propuesta es una tabla:

```sql
CREATE TABLE sena_componente (
    id_sena_compuesta  INTEGER REFERENCES sena (id_sena),
    id_sena_parte      INTEGER REFERENCES sena (id_sena),
    orden              SMALLINT NOT NULL,
    PRIMARY KEY (id_sena_compuesta, orden)
);
```

Ver [LIMITACIONES_REVISADAS.md § 6](LIMITACIONES_REVISADAS.md#6-compuestas-sin-sus-partes-caso-acta-de-nacimiento).

## 3. Metadata fonológica discretizada

Ubicación, movimiento y orientación son texto libre (526 formas distintas de escribir la ubicación). Se agregarán valores cerrados por parámetro siguiendo el JSON que compartirá el asesor. **Pendiente de recibir ese JSON.** Ver [LIMITACIONES_REVISADAS.md § 4](LIMITACIONES_REVISADAS.md#4-fonología-en-texto-libre).

## 4. Otros límites de diseño

Los 13 límites de [`sql/05_consultas_limitaciones.sql`](../sql/05_consultas_limitaciones.sql) siguen como referencia. Entre ellos están las acepciones separadas (L1), el origen de cada palabra por diccionario (L2), las relaciones entre señas (L3) y la variación regional (L6).
