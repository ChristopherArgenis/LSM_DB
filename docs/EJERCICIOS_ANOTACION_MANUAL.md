# Ejercicios de anotación manual

**Para qué sirven.** Para resolver a mano, con papel y pluma, las preguntas que haría un usuario de LSM_DB. Así se ve paso a paso qué tablas recorre cada consulta y dónde están los límites del modelo.

**Cómo usarlos.**

1. Imprime la **mini-base** (sección A): son filas reales de la base, de 9 señas del DLSM CDMX 2017.
2. Para cada ejercicio, escribe en papel el **recorrido**: tabla por tabla, qué fila tomas y qué columna usas para saltar a la siguiente.
3. Anota la **respuesta** y, si el ejercicio lo pide, qué **limitación** encontraste.
4. Compara con las **soluciones** (sección C). Cada una trae la consulta SQL para comprobarla en DBeaver.

> En esta mini-base los `id` de `sena`, `glosa`, `definicion` y `sena_diccionario` coinciden (107, 108…) porque se cargaron en el mismo orden. **No te fíes de eso:** recorre siempre las tablas intermedias, como lo haría la base.

---

## A. Mini-base (extracto real)

### `lengua`

| id_lengua | nombre_completo | modalidad |
|---:|---|---|
| 1 | Español | oral-auditiva |
| 2 | Lengua de Señas Mexicana | viso-gestual |

### `tipo_sena`

| id_tipo_sena | tipo |
|---:|---|
| 1 | SM (monomanual) |
| 2 | SB (bimanual) |
| 3 | SS (bimanual simétrica) |
| 4 | SC (compuesta) |

### `diccionario`

| id_diccionario | nombre_completo |
|---:|---|
| 1 | Diccionario de Lengua de Señas Mexicana de la Ciudad de México (DLSM, 2017) |

### `palabra`

| id_palabra | palabra | id_lengua |
|---:|---|---:|
| 8 | Abandonar | 1 |
| 33 | Acta | 1 |
| 35 | Acta de nacimiento | 1 |
| 179 | Auto | 1 |
| 180 | Automóvil | 1 |
| 230 | Belleza | 1 |
| 231 | Bello | 1 |
| 260 | Bonito | 1 |
| 344 | Carro | 1 |
| 346 | Casa | 1 |
| 411 | Coche | 1 |
| 527 | Dejar | 1 |
| 751 | Lindo | 1 |
| 825 | Nacer | 1 |
| 826 | Nacimiento | 1 |

### `sena_palabra`

| id_sena_palabra | id_sena | id_palabra |
|---:|---:|---:|
| 134 | 107 | 346 |
| 135 | 108 | 346 |
| 268 | 211 | 825 |
| 269 | 211 | 826 |
| 379 | 294 | 230 |
| 380 | 294 | 231 |
| 381 | 294 | 260 |
| 382 | 294 | 751 |
| 486 | 371 | 33 |
| 488 | 373 | 35 |
| 547 | 425 | 179 |
| 548 | 425 | 180 |
| 549 | 425 | 344 |
| 550 | 425 | 411 |
| 690 | 540 | 8 |
| 691 | 540 | 527 |
| 1148 | 930 | 8 |

### `sena`

| id_sena | id_tipo | id_lengua |
|---:|---:|---:|
| 107 | 3 | 2 |
| 108 | 3 | 2 |
| 211 | 3 | 2 |
| 294 | 1 | 2 |
| 371 | 2 | 2 |
| 373 | 4 | 2 |
| 425 | 2 | 2 |
| 540 | 3 | 2 |
| 930 | 1 | 2 |

### `glosa` y `sena_glosa`

| id_glosa | glosa | id_lengua | | id_sena_glosa | id_sena | id_glosa |
|---:|---|---:|---|---:|---:|---:|
| 107 | CASA-A | 2 | | 107 | 107 | 107 |
| 108 | CASA-B | 2 | | 108 | 108 | 108 |
| 211 | NACER | 2 | | 211 | 211 | 211 |
| 294 | BONITO | 2 | | 294 | 294 | 294 |
| 371 | ACTA | 2 | | 371 | 371 | 371 |
| 373 | ACTA-DE-NACIMIENTO | 2 | | 373 | 373 | 373 |
| 425 | AUTO | 2 | | 425 | 425 | 425 |
| 540 | ABANDONAR-2 | 2 | | 540 | 540 | 540 |
| 930 | ABANDONAR-C | 2 | | 930 | 930 | 930 |

### `definicion` (todas con `id_lengua` = 1) y `sena_definicion`

`sena_definicion` liga cada `id_sena` con la `id_definicion` del mismo número (107→107, 108→108…).

| id_definicion | definicion |
|---:|---|
| 107 | sust. f. Edificación destinada para ser habitada. |
| 108 | sust. f. Edificación destinada para ser habitada. |
| 211 | 1. v. intr. Salir un nuevo ser del seno de su madre. 2. sust. m. Acto de nacer. |
| 294 | 1. adj. Que es agradable a los sentidos, particularmente a la vista… 2. sust. f. Cualidad que tiene algo o alguien de producir… placer, admiración y gusto. |
| 371 | sust. f. Documento en que se certifica algo de manera oficial. |
| 373 | sust. f. Documento en que se certifica el nacimiento de una persona. |
| 425 | sust. m. Vehículo con motor de combustión interna que se desplaza sobre ruedas… auto, coche, carro. |
| 540 | 1. v. tr. Dejar solo algo o a alguien alejándose de ello o dejando de cuidarlo. 2. v. tr. Suspender una actividad u ocupación. |
| 930 | v. tr. Dejar por desdeño una actividad o persona. |

### `sena_diccionario` (todas con `id_diccionario` = 1; extracto de `datos_fonologicos`)

| id | id_sena | codigo | tipo_sena | configuracion | ubicacion | movimiento |
|---:|---:|---|---|---|---|---|
| 107 | 107 | B-P 107 | SS | B-P.12 | A la altura del pecho. | Las puntas de los dedos se encuentran y chocan repetidamente. |
| 108 | 108 | B-P 108 | SS | Seña que cambia de B-P.2 a B-P.12 | A la altura del pecho. | Las muñecas se mueven formando un círculo y después las puntas de los dedos… chocan repetidamente. |
| 211 | 211 | B-P 211 | SS | B-P.8 | A la altura del pecho de los lados al centro. | Las manos cruzan hacia el centro y llegan a un punto cercano. |
| 294 | 294 | 5-G 51 | SM | Seña que pasa de 5.2 a O.9 | A la altura de la cara. | La MD se mueve formando un círculo y mientras el pulgar toca los dedos. |
| 371 | 371 | A-13 | SB | MD A.1, MB B-P.2 | A la altura del pecho. MD sobre MB. | La MD se mueve formando un círculo y después golpea a la MB en línea recta. |
| 373 | 373 | A-15 | SC: I. SB; II. SS | I. MD A.1, MB B-P.2; II. B-P.7 | I. A la altura del pecho. MD sobre MB; II. A la altura del pecho de los lados al centro. | I. MD se mueve formando un círculo y después golpea a la MB en línea recta; II. Las manos se cruzan hacia el centro… |
| 425 | 425 | A-69 | SB | MD A.1, MB S.1 | A la altura del pecho. MD sobre MB. | MD recto hacia la izquierda repetidamente. |
| 540 | 540 | S-4 | SS | Seña que pasa de S.1 a 5.1 | Del pecho a la cintura, del lado derecho al izquierdo. | Recto mientras los dedos se extienden. |
| 930 | 930 | O-6 | SM | I. O.9 y II. 5.4 | De la nariz a la mejilla. | Los dedos se extienden. |

---

## B. Ejercicios

Para cada uno: **(1)** escribe el recorrido de tablas, **(2)** la respuesta y **(3)** si hay limitación, cuál es.

### Nivel 1: recorridos básicos

**E1. «¿Cómo digo *Coche* en LSM?»**
Encuentra la glosa y el código de la seña.
*Pista:* palabra → sena_palabra → sena_glosa → glosa.

**E2. «¿Qué otras palabras se dicen con la misma seña que *Coche*?»**
*Pista:* cuando llegues a la seña, regresa por `sena_palabra` hacia `palabra`.

**E3. «¿Qué significa la seña ACTA?»**
*Pista:* entra por `glosa`, no por `palabra`.

### Nivel 2: varias señas para una palabra

**E4. «¿Cuántas señas hay para *Casa* y en qué se diferencian?»**
Compara las filas de `sena_diccionario`. ¿Qué parámetro cambia y cuál se queda igual?

**E5. «Quiero decir *dejé mi trabajo*. ¿Qué seña uso?»**
Parte de la palabra «Abandonar». Lee las definiciones de cada seña que encuentres y decide.
*(En la base completa son 6 señas; en esta mini-base solo están 2.)*

**E6. «¿En qué lengua está la seña CASA-A y en qué idioma está su definición?»**
*Pista:* son dos `id_lengua` distintos. ¿De qué tabla sale cada uno?

### Nivel 3: encontrar los límites

**E7. Un usuario escribe «bonita». ¿Qué le responde la base?**
Primero busca la palabra exacta. Luego piensa qué tendría que hacer la búsqueda para encontrar algo.

**E8. «¿Qué señas se hacen a la altura del pecho?»**
Cuéntalas de dos formas: (a) ubicación *exactamente igual* a «A la altura del pecho.»; (b) ubicación que *contenga* la palabra «pecho». ¿Por qué cambia el número?

**E9. «¿De qué señas se forma ACTA-DE-NACIMIENTO?»**
Usa `tipo_sena` y compara a mano la parte I y la parte II con las demás señas de la mini-base. ¿La base lo puede decir sola?

### Nivel 4: anotar

**E10. Escribe a mano el `datos_fonologicos` de ABANDONAR-2 agregando una `nota`** que explique cuándo se usa en lugar de ABANDONAR-C. Revisa las reglas: claves obligatorias, sin textos vacíos, sin claves inventadas.

**E11. Llega un segundo diccionario que también describe CASA-A**, con el código «C-12» y la ubicación «Frente al pecho.». Escribe las filas nuevas que habría que agregar. ¿Hace falta una fila nueva en `sena`? ¿Y en `glosa`?

---

## C. Soluciones

### E1. Coche → AUTO

1. `palabra`: «Coche» → `id_palabra` 411.
2. `sena_palabra`: `id_palabra` 411 → `id_sena` **425**.
3. `sena_glosa`: `id_sena` 425 → `id_glosa` 425.
4. `glosa`: 425 → **AUTO**.
5. `sena_diccionario`: `id_sena` 425 → código **A-69**.

```sql
SELECT g.glosa, sdc.datos_fonologicos ->> 'codigo' AS codigo
FROM lsm.palabra p
JOIN lsm.sena_palabra sp      ON sp.id_palabra = p.id_palabra
JOIN lsm.sena_glosa sg        ON sg.id_sena = sp.id_sena
JOIN lsm.glosa g              ON g.id_glosa = sg.id_glosa
JOIN lsm.sena_diccionario sdc ON sdc.id_sena = sp.id_sena
WHERE p.palabra = 'Coche';
```

### E2. Sinónimos de Coche → Auto, Automóvil, Carro

1. Como en E1, se llega a `id_sena` 425.
2. `sena_palabra` con `id_sena` 425 → `id_palabra` 179, 180, 344, 411.
3. `palabra` → Auto, Automóvil, Carro (y Coche).

**Idea clave:** las palabras no se conectan entre sí; son sinónimos **porque comparten seña**.

```sql
SELECT p2.palabra
FROM lsm.palabra p
JOIN lsm.sena_palabra sp  ON sp.id_palabra = p.id_palabra
JOIN lsm.sena_palabra sp2 ON sp2.id_sena = sp.id_sena
JOIN lsm.palabra p2       ON p2.id_palabra = sp2.id_palabra
WHERE p.palabra = 'Coche' AND p2.palabra <> 'Coche';
```

### E3. Significado de ACTA

`glosa` ACTA (371) → `sena_glosa` → `id_sena` 371 → `sena_definicion` → `definicion` 371: «Documento en que se certifica algo de manera oficial».

```sql
SELECT d.definicion
FROM lsm.glosa g
JOIN lsm.sena_glosa sg      ON sg.id_glosa = g.id_glosa
JOIN lsm.sena_definicion sd ON sd.id_sena = sg.id_sena
JOIN lsm.definicion d       ON d.id_definicion = sd.id_definicion
WHERE g.glosa = 'ACTA';
```

### E4. Casa → 2 señas: CASA-A y CASA-B

1. `palabra` «Casa» (346) → `sena_palabra` → `id_sena` **107** y **108**.
2. Glosas: CASA-A y CASA-B.
3. Comparación en `sena_diccionario`:
   - **Igual:** tipo SS y ubicación «A la altura del pecho.». La definición también es la misma.
   - **Cambia:** la configuración (CASA-A: B-P.12 fija; CASA-B: cambia de B-P.2 a B-P.12) y el movimiento (CASA-B agrega un círculo de las muñecas).

Son **variantes**: mismo significado, distinta forma. La glosa (-A, -B) las distingue.

### E5. «Dejé mi trabajo» → ABANDONAR-2

1. `palabra` «Abandonar» (8) → `sena_palabra` → `id_sena` 540 y 930.
2. Definiciones:
   - 540 (ABANDONAR-2): «… **2. Suspender una actividad u ocupación.**»
   - 930 (ABANDONAR-C): «Dejar por desdeño una actividad o persona.»
3. Para «dejé mi trabajo» (suspender una ocupación), la mejor es **ABANDONAR-2**. ABANDONAR-C sirve si se quiere decir que se dejó *por desdeño*.

**Límite que queda (L1):** las dos acepciones de ABANDONAR-2 están en un solo texto. La base distingue señas, no acepciones dentro de una seña.

```sql
SELECT g.glosa, d.definicion
FROM lsm.palabra p
JOIN lsm.sena_palabra sp    ON sp.id_palabra = p.id_palabra
JOIN lsm.sena_glosa sg      ON sg.id_sena = sp.id_sena
JOIN lsm.glosa g            ON g.id_glosa = sg.id_glosa
JOIN lsm.sena_definicion sd ON sd.id_sena = sp.id_sena
JOIN lsm.definicion d       ON d.id_definicion = sd.id_definicion
WHERE p.palabra = 'Abandonar' AND d.definicion ILIKE '%ocupación%';
```

### E6. CASA-A: seña en LSM, definición en español

- Lengua de la **seña:** `glosa` → `sena_glosa` → `sena` 107 → `id_lengua` **2** → Lengua de Señas Mexicana.
- Idioma de la **definición:** `sena_definicion` → `definicion` 107 → `id_lengua` **1** → Español.

**Idea clave:** la lengua se guarda en lo que describe. La seña es de LSM y el texto que la explica está en español. El diccionario no tiene lengua propia, por eso se quitó `id_lengua` de `sena_diccionario`.

### E7. «bonita» → 0 resultados exactos; BONITO con búsqueda por raíz

1. En `palabra` no hay «bonita»: la búsqueda exacta da **0 filas**.
2. El diccionario guarda el **lema** «Bonito». Una búsqueda que recorte a la raíz (`bonit-`) llega a 260 → `id_sena` 294 → **BONITO**. De paso trae sus sinónimos: Bello, Lindo y Belleza.

**Conclusión:** no es una limitación del esquema sino de la búsqueda. PostgreSQL lo resuelve con su búsqueda de texto en español:

```sql
SELECT g.glosa
FROM lsm.palabra p
JOIN lsm.sena_palabra sp ON sp.id_palabra = p.id_palabra
JOIN lsm.sena_glosa sg   ON sg.id_sena = sp.id_sena
JOIN lsm.glosa g         ON g.id_glosa = sg.id_glosa
WHERE to_tsvector('spanish', p.palabra) @@ plainto_tsquery('spanish', 'bonita');
```

### E8. Señas a la altura del pecho: 2 exactas, 7 que mencionan «pecho»

- (a) Exactamente «A la altura del pecho.»: **107 y 108** → 2 señas.
- (b) Contienen «pecho»: 107, 108, 211, 371, 373, 425 y 540 → **7 señas**.

Cambia porque la ubicación es **texto libre**: la misma idea se escribe como «A la altura del pecho. MD sobre MB.», «Del pecho a la cintura…», etc. En la base completa son 125 frente a 623.

**Limitación vigente (4):** se resolverá con la metadata discretizada.

### E9. ACTA-DE-NACIMIENTO = ACTA + NACER (la base no lo sabe)

1. `sena` 373 → `id_tipo` 4 → **SC (compuesta)**; `tipo_sena` del JSON: «SC: I. SB; II. SS».
2. Comparación a mano:
   - **Parte I:** MD A.1, MB B-P.2, pecho con MD sobre MB, círculo y golpe → **igual a ACTA** (371).
   - **Parte II:** B-P.7, pecho de los lados al centro, manos que se cruzan → **casi igual a NACER** (211, que usa B-P.8).
3. La base **no puede decirlo sola**: no hay tabla que ligue una compuesta con sus partes.

**Limitación vigente (6):** trabajo futuro (`sena_componente`).

### E10. Nota para ABANDONAR-2 (una respuesta posible)

```json
{
  "codigo": "S-4",
  "significado": "Abandonar 1 – Dejar 2",
  "tipo_sena": "SS",
  "configuracion": "Seña que pasa de S.1 a 5.1",
  "ubicacion": "Del pecho a la cintura, del lado derecho al izquierdo.",
  "movimiento": "Recto mientras los dedos se extienden.",
  "nota": "Es la seña de ABANDONAR para dejar un trabajo o una actividad (acepción 2). Para dejar algo por desdeño se usa ABANDONAR-C."
}
```

Revisión: están las 5 obligatorias (`codigo`, `significado`, `tipo_sena`, `configuracion`, `ubicacion`); `nota` es una clave permitida; ningún valor está vacío. **Es válido.** Si escribiste `"observacion"` o `"nota": ""`, la base lo rechazaría.

### E11. Segundo diccionario para CASA-A

- `diccionario`: **1 fila nueva** (el nuevo diccionario, `id_diccionario` 2).
- `sena_diccionario`: **1 fila nueva** → `id_sena` 107, `id_diccionario` 2, `datos_fonologicos` `{"codigo": "C-12", "significado": "Casa", "tipo_sena": "SS", "configuracion": "B-P.12", "ubicacion": "Frente al pecho."}`.
- `sena`: **no**, la seña ya existe (107).
- `glosa`: **no**, la seña ya tiene su ID-glosa (CASA-A).

**Idea clave:** el esquema no cambió y la misma seña queda con **dos descripciones**, una por diccionario. Por eso se diseñó desde el modelo y no desde un diccionario (ver [DECISIONES_DE_DISENO.md](DECISIONES_DE_DISENO.md)).
