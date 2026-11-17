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

Ubicación, movimiento y orientación son texto libre (526 formas distintas de escribir la ubicación). Para buscar y comparar se definió **METADATOS**: un JSON aparte, que **no** vive en la base, con valores de lista cerrada.

- Esquema: [`metadatos/esquema_metadatos.txt`](../metadatos/esquema_metadatos.txt) (y su versión en notación SQL, [`esquema_metadatos.sql`](../metadatos/esquema_metadatos.sql)).
- Generación: [`metadatos/generar_metadatos.sql`](../metadatos/generar_metadatos.sql) lo construye a partir de `datos_fonologicos`.
- **Versión 1:** configuración (solo familia) y ubicación, por mano y por momento. Orientación y movimiento son claves opcionales del esquema que todavía no se generan.
- Con la versión 1, de los 136 pares de señas que comparten palabra, 10 quedan iguales (GRAVE, por ejemplo, tiene el mismo texto en el DLSM). No es un problema: METADATOS sirve para buscar, y a cada seña la identifican su código y su glosa.

## 4. Otros diccionarios

Hasta ahora todo se probó con un solo diccionario (DLSM CDMX 2017). Antes de cargar otro hay que revisar tres cosas.

**a) La discretización depende de la notación de cada diccionario.** «B-P.2» o «A la altura del pecho» son la forma de escribir del DLSM. Otro diccionario puede usar otros nombres de configuración, otras zonas del cuerpo o solo texto libre. Se necesita:

- un **catálogo común** (familias de configuración y zonas) que no dependa del DLSM;
- una **tabla de traducción por diccionario**, de su notación a ese catálogo;
- adaptar `generar_metadatos.sql` (sus patrones y catálogos) o tener una versión por diccionario.

**b) Las coincidencias se leen distinto dentro y entre diccionarios.**

| Dónde | Dos señas con METADATOS igual significa | ¿Es bueno? |
|---|---|---|
| Dentro de un diccionario | No se distinguen con los parámetros elegidos | Se revisa (hoy, 10 pares de 136) |
| Entre diccionarios | Posiblemente es la misma seña descrita por dos fuentes | Sí: sirve para enlazarlas |

Por eso la prueba de colisiones debe medirse **dentro de cada diccionario**, no sobre todos juntos.

**c) El origen de la seña.** Algunos diccionarios lo marcan y otros no. En el DLSM: CANADÁ (A) dice «(LSM)» y CANADÁ (B) dice «(SSI)»; ADORAR-1 y ADORAR-2 se distinguen por la comunidad que las usa. Hoy esto queda en la glosa y en el campo `nota`. Con varios diccionarios habría que decidir si se vuelve un dato propio (por ejemplo, un catálogo de origen o comunidad).

**Por qué no ahora:** no hay un segundo diccionario cargado con qué probar la traducción ni el catálogo común.

## 5. Otros límites de diseño

Los 13 límites de [`sql/05_consultas_limitaciones.sql`](../sql/05_consultas_limitaciones.sql) siguen como referencia. Entre ellos están las acepciones separadas (L1), el origen de cada palabra por diccionario (L2), las relaciones entre señas (L3) y la variación regional (L6).
