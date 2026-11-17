# Decisiones de diseño

Decisiones que se discutieron con el asesor, con la pregunta, la respuesta y su justificación.

## 1. Partimos del esquema de la base de datos, no del diccionario

**Pregunta.** El esquema se diseñó a partir del modelo entidad-relación y después se cargó el DLSM CDMX 2017. ¿Es un problema no haber partido de la estructura del diccionario?

**Respuesta: no, y tampoco es necesario partir del diccionario.**

**Por qué.**

1. **El objetivo es una base de *diccionarios*, en plural.** Si el esquema copiara la estructura de un diccionario, el segundo diccionario no cabría: cada obra organiza sus entradas a su manera (códigos, campos, orden).
2. **El esquema modela lo que es común a cualquier diccionario de señas:** una seña, su lengua, las palabras que la traducen, su glosa, su definición y cómo se articula. Lo que es propio de cada obra se guarda en `sena_diccionario.datos_fonologicos`, que es un JSON por entrada y por diccionario.
3. **La prueba es que el DLSM entró sin cambiar el esquema.** El importador ([`scripts/importar_dlsm_cdmx.py`](../scripts/importar_dlsm_cdmx.py)) solo traduce el Excel a filas: 1,006 señas, 1,123 palabras y 1,006 entradas de diccionario. No hubo que agregar ninguna tabla para el DLSM.
4. **Separar el modelo de la fuente es la práctica normal:** el diccionario es un *dato* que se carga, no la *forma* de la base.

**Ejemplo: así entraría un segundo diccionario.** Supongamos un diccionario de LSM de otra ciudad que también tiene la seña de CASA:

```sql
-- 1. El diccionario es una fila nueva, no una tabla nueva
INSERT INTO lsm.diccionario (nombre_completo, autor)
VALUES ('Diccionario de LSM de [ciudad] ([año])', '[autor]');

-- 2. Si la seña ya existe (CASA-A), solo se agrega cómo la describe esta fuente
INSERT INTO lsm.sena_diccionario (id_sena, id_diccionario, datos_fonologicos)
SELECT sg.id_sena, d.id_diccionario,
       '{"codigo": "C-12", "significado": "Casa", "tipo_sena": "SS",
         "configuracion": "B-P.12", "ubicacion": "Frente al pecho.",
         "nota": "En esta región la seña se hace más arriba."}'::jsonb
FROM lsm.glosa g
JOIN lsm.sena_glosa sg ON sg.id_glosa = g.id_glosa
CROSS JOIN lsm.diccionario d
WHERE g.glosa = 'CASA-A' AND d.nombre_completo LIKE 'Diccionario de LSM de [ciudad]%';

-- 3. Si la seña es nueva, se crea en sena y se liga igual que en el DLSM
```

El resultado es que la misma seña tiene **dos descripciones**, una por diccionario, y se pueden comparar.

## 2. La lengua se guarda una sola vez por seña

**Pregunta.** `sena_diccionario` tenía `id_lengua` (relación «identifica» con LENGUA). ¿Hace falta?

**Respuesta: no; se quitó el 2026-11-11.**

**Por qué.** La lengua de una entrada de diccionario es, por definición, la lengua de la seña que describe, y esa ya está en `sena.id_lengua`. Guardarla dos veces es una dependencia transitiva (va contra la Tercera Forma Normal) y ninguna regla obligaba a que ambas coincidieran, así que podían contradecirse al cargar más lenguas.

**Cómo se hizo.** El script [`sql/migraciones/2026-11-11_quitar_lengua_sena_diccionario.sql`](../sql/migraciones/2026-11-11_quitar_lengua_sena_diccionario.sql) primero comprueba que las 1,006 entradas coinciden con su seña y solo entonces borra la columna, su llave foránea y su índice. Si alguna no coincide, se detiene sin tocar nada. `01_schema.sql` ya crea la tabla sin esa columna, y el diagrama se actualizó ([`img/diagrama_er.png`](img/diagrama_er.png)).

**Cómo se consulta ahora la lengua de una entrada:**

```sql
SELECT l.nombre_completo
FROM lsm.sena_diccionario sdc
JOIN lsm.sena s   ON s.id_sena = sdc.id_sena
JOIN lsm.lengua l ON l.id_lengua = s.id_lengua;
```

## 3. Las glosas homónimas se numeran (caso ABANDONAR)

**Observación.** ABANDONAR aparece como ABANDONAR-1, -2, -3 y como ABANDONAR-A, -B, -C.

**Respuesta: no es un problema.**

- **-A, -B, -C** son las variantes que el propio diccionario marca con «(A)», «(B)», «(C)».
- **-1, -2, -3** son señas distintas (códigos A-7, S-4 y C-1, con otra configuración y otra ubicación) que el diccionario titula igual, «Abandonar», sin letra.

Una ID-glosa tiene que ser **única** para identificar la seña, así que las homónimas se numeran, como se hace en los corpus de lenguas de señas. Gracias a eso la base contesta qué seña usar para «dejar el trabajo»: ABANDONAR-2. Detalle en [LIMITACIONES_REVISADAS.md § 2](LIMITACIONES_REVISADAS.md#2-sentidos-mezclados-caso-abandonar).

## 4. Las excepciones van en `nota`, dentro del JSON

**Pregunta.** ¿Dónde se anotan las excepciones de una seña?

**Respuesta:** en una clave opcional `nota` dentro de `datos_fonologicos`.

**Por qué ahí:** la excepción es de la seña *según un diccionario* (otra fuente puede no tenerla), así que va en `sena_diccionario` y no en `sena`. Además, al ir dentro del JSON, no hace falta cambiar la estructura de la tabla y la regla de validación sigue impidiendo textos vacíos o claves parecidas. Ver [DATOS_FONOLOGICOS.md](DATOS_FONOLOGICOS.md).
