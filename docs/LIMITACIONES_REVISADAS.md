# Las 6 limitaciones de la presentación, revisadas

En la presentación anterior mostramos seis «techos» del modelo. Ahora los revisamos con los resultados de las consultas, ya con las glosas cargadas. Para cada uno decimos si **sigue siendo un problema**, si **ya no lo es** o si **nunca fue un problema del esquema** porque cambia la forma de plantearlo.

Las consultas están en [`sql/07_limitaciones_revisadas.sql`](../sql/07_limitaciones_revisadas.sql). Los números de abajo salen de esa ejecución (DLSM CDMX 2017: 1,006 señas, 1,123 palabras, 1,006 glosas).

## Resumen

| # | Limitación | Veredicto | Por qué |
|---|---|---|---|
| 1 | Todo depende de la seña | **No es problema** | Es la regla del modelo: es un diccionario de señas. Hay 0 palabras, 0 glosas y 0 definiciones sueltas. |
| 2 | Sentidos mezclados (ABANDONAR) | **Ya no es problema** | Cada una de las 6 señas tiene su propia glosa y su propia definición, y la base contesta «¿cuál uso?». |
| 3 | Variantes en el texto (Casa A/B) | **Ya no es problema** | La glosa convierte la letra en dato: CASA-A y CASA-B. Son 170 glosas de variante. |
| 4 | Fonología en texto libre | **Sigue vigente** | 526 formas distintas de escribir la ubicación; «pecho» aparece en 623 señas, pero solo 125 coinciden exactamente. |
| 5 | Solo la palabra exacta | **No es del esquema** | La base guarda lemas, como todo diccionario. La búsqueda en español de PostgreSQL lleva «comí» a COMER sin cambiar ninguna tabla. |
| 6 | Compuestas sin sus partes | **Sigue vigente** | Hay 140 compuestas. ACTA-DE-NACIMIENTO = ACTA + NACER se ve a simple vista, pero ninguna fila lo dice. |

## 1. Todo depende de la seña

**Antes:** «Si una palabra no tiene seña, queda aislada y no se llega a su definición».

**Resultado** (consulta 1a):

| palabras_sin_sena | glosas_sin_sena | definiciones_sin_sena |
|---:|---:|---:|
| 0 | 0 | 0 |

**Nuevo planteamiento.** LSM_DB es un diccionario *de señas*. Una palabra en español entra a la base porque traduce una seña; una definición entra porque define una seña. Una palabra sin seña («perro», consulta 1b) no es un dato perdido: simplemente no pertenece a este diccionario. Que todo pase por la seña es justo lo que hace que la base sea coherente: el modelo no puede tener palabras ni definiciones huérfanas.

**Veredicto: no es problema.** Lo dejamos documentado como decisión de diseño (ver [DECISIONES_DE_DISENO.md](DECISIONES_DE_DISENO.md)).

## 2. Sentidos mezclados (caso ABANDONAR)

**Antes:** «Abandonar tiene 6 señas, ¿cuál uso para decir que dejé mi trabajo? La base no lo sabe».

**Resultado** (consulta 2a): cada seña tiene su glosa, su código y su definición.

| glosa | código | significado | definición |
|---|---|---|---|
| ABANDONAR-1 | A-7 | Abandonar | Dejar solo algo o a alguien alejándose de ello o dejando de cuidarlo. |
| ABANDONAR-2 | S-4 | Abandonar 1 – Dejar 2 | 1. Dejar solo algo o a alguien… **2. Suspender una actividad u ocupación.** |
| ABANDONAR-3 | C-1 | Abandonar | Dejar algo o alguien sin cuidado o sin atención. |
| ABANDONAR-A | O-4 | Abandonar (A) | Dejar algo o a alguien sin cuidado o sin atención. |
| ABANDONAR-B | O-5 | Abandonar (B) | Dejar algo o a alguien sin cuidado o sin atención. |
| ABANDONAR-C | O-6 | Abandonar(C) | **Dejar por desdeño una actividad** o persona. |

**La pregunta de la presentación ya tiene respuesta** (consulta 2b): para «dejé mi trabajo» la base devuelve **ABANDONAR-2** (acepción 2, «suspender una actividad u ocupación») y **ABANDONAR-C** («dejar por desdeño una actividad»).

**Por qué cambió:** antes buscábamos por la *palabra* «Abandonar», que es la misma para las seis. Ahora cada seña tiene una **glosa única** y su **definición**, así que el sentido se busca en la definición y la seña se nombra por su glosa.

**Lo que queda (y es otro techo, L1):** dentro de ABANDONAR-2 las dos acepciones están en un mismo texto («1. … 2. …»). La base distingue *señas*, no *acepciones dentro de una seña*.

**Veredicto: ya no es problema.**

### Observación del caso ABANDONAR: -1, -2, -3 y -A, -B, -C

En la reunión se observó que ABANDONAR tiene dos tipos de sufijo. **No es un problema**; cada sufijo dice algo distinto (consulta 2c):

- **-A, -B, -C:** el propio diccionario las marca como variantes, «Abandonar (A)», «(B)», «(C)», en los códigos O-4, O-5 y O-6.
- **-1, -2, -3:** el diccionario repite «Abandonar» *sin letra* en tres códigos distintos (A-7, S-4, C-1). Son señas diferentes: cambian la configuración (A.1→5.1, S.1→5.1, C.7→B-P.2) y la ubicación (plexo, pecho a cintura, frente). Una ID-glosa debe ser **única**, así que se numeran.

Numerar las glosas homónimas es la práctica normal en los corpus de lenguas de señas. Lo importante es que la glosa **identifica** a la seña sin ambigüedad, y eso se cumple.

*Nota de datos:* en el Excel de origen, la entrada C-1 (ABANDONAR-3) trae cortado un ejemplo de uso: la definición termina en «Él desea» y el movimiento termina en «pro-ÉL DESEAR». Ese tipo de aviso es justo lo que irá en la nueva clave `nota` de `datos_fonologicos` (ver [ESQUEMA_EXPLICADO.md](ESQUEMA_EXPLICADO.md)).

## 3. Variantes en el texto (caso CASA)

**Antes:** «Casa (A) y Casa (B) son variantes, pero esa letra solo vive en el texto».

**Resultado** (consulta 3a):

| glosa | código | configuración | ubicación |
|---|---|---|---|
| CASA-A | B-P 107 | B-P.12 | A la altura del pecho. |
| CASA-B | B-P 108 | Seña que cambia de B-P.2 a B-P.12 | A la altura del pecho. |

Hay **170 glosas de variante** (consulta 3b), y se pueden agrupar por su base. Por ejemplo, CONVENCER y COPIAR tienen 4 variantes cada una (consulta 3c).

**Por qué cambió:** la glosa convierte la letra en dato consultable. Además, la tabla muestra *en qué* se diferencian: la misma ubicación, pero CASA-B cambia de configuración durante la seña.

**Lo que queda:** no hay una relación explícita «X es variante de Y» (techo L3). Se deduce de la glosa base, lo cual basta para consultar.

**Veredicto: ya no es problema.**

## 4. Fonología en texto libre

**Antes:** «Los códigos se comparan; las frases no».

**Resultado** (consultas 4a a 4c):

| configuraciones distintas | ubicaciones distintas | movimientos distintos |
|---:|---:|---:|
| 417 | 526 | 649 |

«Pecho» se escribe de muchas formas: «A la altura del pecho.» (125), «A la altura del pecho. MD sobre MB.» (65), «MD y MB a la altura del pecho.» (59), «Sobre el pecho.» (21)… Buscando igualdad exacta salen **125** señas; buscando el texto «pecho» salen **623**.

**Por qué sigue:** guardar el texto tal como lo escribe el diccionario es correcto (fidelidad a la fuente), pero no permite comparar señas por parámetros. Hoy se compensa con búsqueda de texto (`ILIKE`), que es aproximada.

**Cómo se resolverá:** con la **metadata discretizada**, es decir, valores cerrados por parámetro (ubicación: pecho, frente, mejilla…). Está pendiente del JSON que compartirá el asesor. El texto original se conservará y la categoría discreta se agregará al lado.

**Veredicto: sigue vigente** (en curso, nota 4 de la reunión).

## 5. Solo la palabra exacta

**Antes:** «Buscar "bonita" o "comí" da 0 resultados, aunque Bonito y Comer sí están».

**Resultado:** la igualdad exacta sigue dando 0 (consulta 5a). Pero con la búsqueda de texto en español de PostgreSQL (consulta 5b):

| buscado | glosa encontrada |
|---|---|
| comí | COMER |
| comiendo | COMER |
| bonita | BONITO |
| abandoné | ABANDONAR-1 … ABANDONAR-C |

Funciona porque las formas se reducen a la misma raíz: `comí`, `comiendo` y `comer` → `com` (consulta 5c).

**Nuevo planteamiento.** Un diccionario guarda **lemas** (la forma de cita: el verbo en infinitivo, el adjetivo en masculino). Esta base hace lo mismo, y eso es correcto. Pasar de «comí» a «comer» le toca a la **capa de búsqueda** (la consulta o la API), no al esquema. No hay que cambiar ninguna tabla.

**Matiz honesto:** el recorte a la raíz es aproximado. «comí» también trae COMIDA-CADUCADA porque comparte la raíz. La aplicación debe ordenar los resultados (primero la coincidencia más parecida).

**Veredicto: no es una limitación del diseño de la base.**

## 6. Compuestas sin sus partes (caso ACTA-DE-NACIMIENTO)

**Antes:** «Hay 140 señas compuestas, pero la base no sabe de qué señas se forman».

**Resultado** (consulta 6b):

| glosa | configuración | ubicación | movimiento |
|---|---|---|---|
| ACTA | MD A.1, MB B-P.2 | A la altura del pecho. MD sobre MB. | La MD se mueve formando un círculo y después golpea a la MB… |
| NACER | B-P.8 | A la altura del pecho de los lados al centro. | Las manos cruzan hacia el centro… |
| ACTA-DE-NACIMIENTO | **I.** MD A.1, MB B-P.2; **II.** B-P.7 | **I.** A la altura del pecho…; **II.** …de los lados al centro. | **I.** …círculo y golpea…; **II.** …se cruzan hacia el centro… |

Una persona ve que la parte I es igual a ACTA y que la parte II es casi igual a NACER. Pero en la base no existe ninguna tabla que lo diga (consulta 6c: 0 filas).

**Por qué sigue:** el esquema no tiene una relación «la seña X se compone de las señas Y y Z, en este orden».

**Cómo se resolvería:** una tabla `sena_componente (id_sena_compuesta, id_sena_parte, orden)`. Queda en [TRABAJO_FUTURO.md](TRABAJO_FUTURO.md).

**Veredicto: sigue vigente** (trabajo futuro).
