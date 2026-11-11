# Salidas de las consultas

Generado por `scripts/generar_salidas.py` sobre el Diccionario LSM CDMX 2017 (`sql/02_datos_dlsm_cdmx.sql`). No editar a mano: vuelve a ejecutar el script.

Cada consulta muestra hasta 20 filas; las celdas largas se recortan. El SQL completo está en `sql/03_consultas.sql`.

**49 consultas.**

- Vacías porque falta información (inglés, ASL, videos, otro diccionario): A3, A4, B1, C4, F1, F2, F3, F4, F5.
- Controles de calidad sin problemas encontrados: H4, I3, I4, I5.

## Índice

- **A. Palabras, traducción y definiciones**: [A1](#a1), [A2](#a2), [A3](#a3), [A4](#a4), [A5](#a5), [A6](#a6), [A7](#a7)
- **B. Lenguas**: [B1](#b1), [B2](#b2), [B3](#b3)
- **C. Diccionarios**: [C1](#c1), [C2](#c2), [C3](#c3), [C4](#c4), [C5](#c5), [C6](#c6)
- **D. Fonología (datos_fonologicos)**: [D1](#d1), [D2](#d2), [D3](#d3), [D4](#d4), [D5](#d5), [D6](#d6), [D7](#d7), [D8](#d8)
- **E. Tipo de seña**: [E1](#e1), [E2](#e2), [E3](#e3)
- **F. Videos y señantes**: [F1](#f1), [F2](#f2), [F3](#f3), [F4](#f4), [F5](#f5)
- **G. Autoría**: [G1](#g1)
- **H. Cobertura (qué falta por capturar)**: [H1](#h1), [H2](#h2), [H3](#h3), [H4](#h4)
- **I. Control de consistencia**: [I1](#i1), [I2](#i2), [I3](#i3), [I4](#i4), [I5](#i5)
- **J. Ficha completa de una seña**: [J1](#j1)
- **K. Temas del diccionario**: [K1](#k1), [K2](#k2), [K3](#k3), [K4](#k4), [K5](#k5), [K6](#k6)

## A. Palabras, traducción y definiciones

### <a id="a1"></a>A1. Seña(s) de una palabra: su glosa y su código en el diccionario

<details><summary>SQL</summary>

```sql
SELECT p.palabra, g.glosa,
       sdc.datos_fonologicos ->> 'codigo' AS codigo
FROM palabra p
JOIN sena_palabra sp      ON sp.id_palabra = p.id_palabra
JOIN sena_glosa sg        ON sg.id_sena = sp.id_sena
JOIN glosa g              ON g.id_glosa = sg.id_glosa
JOIN sena_diccionario sdc ON sdc.id_sena = sp.id_sena
WHERE LOWER(p.palabra) = LOWER('Casa')
ORDER BY g.glosa;
```

</details>

| palabra | glosa | codigo |
|---|---|---|
| Casa | CASA-A | B-P 107 |
| Casa | CASA-B | B-P 108 |

*2 filas.*

### <a id="a2"></a>A2. Todas las palabras de una glosa, con su idioma

<details><summary>SQL</summary>

```sql
SELECT g.glosa, p.palabra, l.nombre_completo AS idioma
FROM glosa g
JOIN sena_glosa sg   ON sg.id_glosa = g.id_glosa
JOIN sena_palabra sp ON sp.id_sena = sg.id_sena
JOIN palabra p       ON p.id_palabra = sp.id_palabra
JOIN lengua l        ON l.id_lengua = p.id_lengua
WHERE g.glosa = 'BONITO'
ORDER BY p.palabra;
```

</details>

| glosa | palabra | idioma |
|---|---|---|
| BONITO | Belleza | Español |
| BONITO | Bello | Español |
| BONITO | Bonito | Español |
| BONITO | Lindo | Español |

*4 filas.*

### <a id="a3"></a>A3. [VACÍA HOY: falta cargar palabras en inglés] Traducir una palabra de español a inglés a través de la seña

<details><summary>SQL</summary>

```sql
SELECT DISTINCT origen.palabra AS espanol, g.glosa, destino.palabra AS ingles
FROM palabra origen
JOIN sena_palabra sp1 ON sp1.id_palabra = origen.id_palabra
JOIN sena_glosa sg    ON sg.id_sena = sp1.id_sena
JOIN glosa g          ON g.id_glosa = sg.id_glosa
JOIN sena_palabra sp2 ON sp2.id_sena = sp1.id_sena
JOIN palabra destino  ON destino.id_palabra = sp2.id_palabra
WHERE LOWER(origen.palabra) = LOWER('Casa')
  AND origen.id_lengua  = (SELECT id_lengua FROM lengua WHERE nombre_completo = 'Español')
  AND destino.id_lengua = (SELECT id_lengua FROM lengua WHERE nombre_completo = 'Inglés');
```

</details>

**Sin resultados (0 filas).**

### <a id="a4"></a>A4. [VACÍA HOY: falta cargar definiciones en inglés] Definición en inglés de una palabra en español palabra(es) -> sena_palabra -> sena -> sena_definicion -> definicion(en)

<details><summary>SQL</summary>

```sql
SELECT DISTINCT p.palabra, g.glosa, d.definicion
FROM palabra p
JOIN sena_palabra sp    ON sp.id_palabra = p.id_palabra
JOIN sena_glosa sg      ON sg.id_sena = sp.id_sena
JOIN glosa g            ON g.id_glosa = sg.id_glosa
JOIN sena_definicion sd ON sd.id_sena = sp.id_sena
JOIN definicion d       ON d.id_definicion = sd.id_definicion
WHERE LOWER(p.palabra) = LOWER('Banco')
  AND p.id_lengua = (SELECT id_lengua FROM lengua WHERE nombre_completo = 'Español')
  AND d.id_lengua = (SELECT id_lengua FROM lengua WHERE nombre_completo = 'Inglés');
```

</details>

**Sin resultados (0 filas).**

### <a id="a5"></a>A5. Definición en español de una palabra (misma ruta que A4)

<details><summary>SQL</summary>

```sql
SELECT p.palabra, g.glosa, d.definicion
FROM palabra p
JOIN sena_palabra sp    ON sp.id_palabra = p.id_palabra
JOIN sena_glosa sg      ON sg.id_sena = sp.id_sena
JOIN glosa g            ON g.id_glosa = sg.id_glosa
JOIN sena_definicion sd ON sd.id_sena = sp.id_sena
JOIN definicion d       ON d.id_definicion = sd.id_definicion
WHERE LOWER(p.palabra) = LOWER('Banco')
  AND d.id_lengua = (SELECT id_lengua FROM lengua WHERE nombre_completo = 'Español');
```

</details>

| palabra | glosa | definicion |
|---|---|---|
| Banco | BANCO | sust. m. Institución que realiza las múltiples operaciones comerciales a que da lugar el dinero y los títulos que lo representan, como inversiones, créditos, ahorros, pagos, etc. |

*1 fila.*

### <a id="a6"></a>A6. Palabras con varias señas (variantes A/B o sentidos distintos)

<details><summary>SQL</summary>

```sql
SELECT p.palabra, COUNT(*) AS num_senas,
       STRING_AGG(g.glosa, ', ' ORDER BY g.glosa) AS glosas
FROM palabra p
JOIN sena_palabra sp ON sp.id_palabra = p.id_palabra
JOIN sena_glosa sg   ON sg.id_sena = sp.id_sena
JOIN glosa g         ON g.id_glosa = sg.id_glosa
GROUP BY p.palabra
HAVING COUNT(*) > 1
ORDER BY num_senas DESC, p.palabra;
```

</details>

| palabra | num_senas | glosas |
|---|---|---|
| Abandonar | 6 | ABANDONAR-1, ABANDONAR-2, ABANDONAR-3, ABANDONAR-A, ABANDONAR-B, ABANDONAR-C |
| Convencer | 4 | CONVENCER-A, CONVENCER-B, CONVENCER-C, CONVENCER-D |
| Copiar | 4 | COPIAR-A, COPIAR-B, COPIAR-C, COPIAR-D |
| Almohada | 3 | ALMOHADA-A, ALMOHADA-B, ALMOHADA-C |
| Anteriormente | 3 | ANTES-A, ANTES-B, ANTES-C |
| Antes | 3 | ANTES-A, ANTES-B, ANTES-C |
| Asar | 3 | ASAR, ASAR-A, ASAR-B |
| Aumentar | 3 | AUMENTAR, AUMENTAR-ELEVAR-ECONOMÍA, AUMENTAR-GANANCIA |
| Descubrir | 3 | DESCUBRIR-A, DESCUBRIR-B, DESCUBRIR-C |
| Grave | 3 | GRAVE-A, GRAVE-B, GRAVE-C |
| Libro | 3 | LIBRO-A, LIBRO-B, LIBRO-C |
| Pasado | 3 | ANTES-A, ANTES-B, ANTES-C |
| Percatarse | 3 | DESCUBRIR-A, DESCUBRIR-B, DESCUBRIR-C |
| Ya me di cuenta | 3 | DESCUBRIR-A, DESCUBRIR-B, DESCUBRIR-C |
| Abofetear | 2 | ABOFETEAR-A, ABOFETEAR-B |
| Adiós | 2 | ADIÓS-A, ADIÓS-B |
| Adorar | 2 | ADORAR-1, ADORAR-2 |
| Adán | 2 | ADÁN-A, ADÁN-B |
| Ahora | 2 | AHORA-A, AHORA-B |
| Alabanza | 2 | ALABANZA, ALABAR |

*Se muestran 20 de 116 filas.*

### <a id="a7"></a>A7. Sinónimos: palabras que comparten la misma seña

<details><summary>SQL</summary>

```sql
SELECT g.glosa,
       STRING_AGG(p.palabra, ' / ' ORDER BY p.palabra) AS palabras
FROM glosa g
JOIN sena_glosa sg   ON sg.id_glosa = g.id_glosa
JOIN sena_palabra sp ON sp.id_sena = sg.id_sena
JOIN palabra p       ON p.id_palabra = sp.id_palabra
GROUP BY g.glosa
HAVING COUNT(*) > 1
ORDER BY COUNT(*) DESC, g.glosa;
```

</details>

| glosa | palabras |
|---|---|
| ALEGRÍA | Alegría / Celebrar / Disfrutar / Divertido |
| AUTO | Auto / Automóvil / Carro / Coche |
| BONITO | Belleza / Bello / Bonito / Lindo |
| ACNÉ | Acné / Barro / Espinilla |
| ALREDEDOR | Alrededor / Ambiente / Contexto |
| ANTES-A | Anteriormente / Antes / Pasado |
| ANTES-B | Anteriormente / Antes / Pasado |
| ANTES-C | Anteriormente / Antes / Pasado |
| ARGUMENTAR | Argumentar / Debate / Discusión |
| ARRESTAR | Aprehender / Arrestar / Detención |
| BALONCESTO | Baloncesto / Basquetbol / Encestar |
| BANDERA-A | Bandera / Pantitlán / Patriotismo |
| BRASSIER | Brassier / Corpiño / Top |
| CON-SUEÑO | Con sueño / Somnoliento / Sueño |
| COPIAR-D | Contagiar / Copiar / Imitar |
| DE-TODOS-MODOS | De todas formas / De todas maneras / De todos modos |
| DEFENDER-B | Bloquear / Defender / Proteger |
| DESCUBRIR-A | Descubrir / Percatarse / Ya me di cuenta |
| DESCUBRIR-B | Descubrir / Percatarse / Ya me di cuenta |
| DESCUBRIR-C | Descubrir / Percatarse / Ya me di cuenta |

*Se muestran 20 de 219 filas.*

## B. Lenguas

### <a id="b1"></a>B1. [VACÍA HOY: falta cargar una segunda lengua de señas, p. ej. ASL] Equivalente en otra lengua de señas por palabra compartida

<details><summary>SQL</summary>

```sql
SELECT DISTINCT g1.glosa AS lsm, g2.glosa AS otra, p.palabra
FROM sena_glosa sg1
JOIN glosa g1         ON g1.id_glosa = sg1.id_glosa
JOIN sena_palabra sp1 ON sp1.id_sena = sg1.id_sena
JOIN palabra p        ON p.id_palabra = sp1.id_palabra
JOIN sena_palabra sp2 ON sp2.id_palabra = p.id_palabra AND sp2.id_sena <> sp1.id_sena
JOIN sena s2          ON s2.id_sena = sp2.id_sena
JOIN sena_glosa sg2   ON sg2.id_sena = s2.id_sena
JOIN glosa g2         ON g2.id_glosa = sg2.id_glosa
WHERE s2.id_lengua = (SELECT id_lengua FROM lengua WHERE nombre_completo = 'American Sign Language');
```

</details>

**Sin resultados (0 filas).**

### <a id="b2"></a>B2. Señas por lengua de señas

<details><summary>SQL</summary>

```sql
SELECT l.nombre_completo, COUNT(s.id_sena) AS num_senas
FROM lengua l
LEFT JOIN sena s ON s.id_lengua = l.id_lengua
WHERE l.modalidad = 'viso-gestual'
GROUP BY l.nombre_completo;
```

</details>

| nombre_completo | num_senas |
|---|---|
| Lengua de Señas Mexicana | 1006 |

*1 fila.*

### <a id="b3"></a>B3. Palabras, glosas y definiciones por lengua

<details><summary>SQL</summary>

```sql
SELECT l.nombre_completo,
       (SELECT COUNT(*) FROM palabra    p WHERE p.id_lengua = l.id_lengua) AS palabras,
       (SELECT COUNT(*) FROM glosa      g WHERE g.id_lengua = l.id_lengua) AS glosas,
       (SELECT COUNT(*) FROM definicion d WHERE d.id_lengua = l.id_lengua) AS definiciones
FROM lengua l
ORDER BY l.id_lengua;
```

</details>

| nombre_completo | palabras | glosas | definiciones |
|---|---|---|---|
| Español | 1123 | 0 | 1006 |
| Lengua de Señas Mexicana | 0 | 1006 | 0 |

*2 filas.*

## C. Diccionarios

### <a id="c1"></a>C1. Datos del diccionario

<details><summary>SQL</summary>

```sql
SELECT id_diccionario, nombre_completo, autor FROM diccionario;
```

</details>

| id_diccionario | nombre_completo | autor |
|---|---|---|
| 1 | Diccionario de Lengua de Señas Mexicana de la Ciudad de México (DLSM, 2017) | Lic. César Ernesto Escobedo Delgado (coordinador y editor) |

*1 fila.*

### <a id="c2"></a>C2. Número de señas por diccionario

<details><summary>SQL</summary>

```sql
SELECT dic.nombre_completo, COUNT(sdc.id_sena) AS num_senas
FROM diccionario dic
LEFT JOIN sena_diccionario sdc ON sdc.id_diccionario = dic.id_diccionario
GROUP BY dic.nombre_completo
ORDER BY num_senas DESC;
```

</details>

| nombre_completo | num_senas |
|---|---|
| Diccionario de Lengua de Señas Mexicana de la Ciudad de México (DLSM, 2017) | 1006 |

*1 fila.*

### <a id="c3"></a>C3. Contenido del diccionario por página del PDF

<details><summary>SQL</summary>

```sql
SELECT (sdc.datos_fonologicos ->> 'pagina')::int AS pagina,
       g.glosa,
       sdc.datos_fonologicos ->> 'significado'   AS significado
FROM sena_diccionario sdc
JOIN sena_glosa sg ON sg.id_sena = sdc.id_sena
JOIN glosa g       ON g.id_glosa = sg.id_glosa
WHERE (sdc.datos_fonologicos ->> 'pagina')::int BETWEEN 1 AND 2
ORDER BY pagina, sdc.id_sena;
```

</details>

| pagina | glosa | significado |
|---|---|---|
| 1 | POR-QUÉ | ¿Por qué? |
| 1 | QUÉ-ONDA | ¿Qué onda? |
| 1 | Y-ESO | ¿Y eso? |
| 2 | ABAJO | Abajo – Debajo |
| 2 | ABOFETEAR-A | Abofetear (A) |
| 2 | ABOFETEAR-B | Abofetear (B) |

*6 filas.*

### <a id="c4"></a>C4. [VACÍA HOY: hace falta un segundo diccionario] Misma seña con datos fonológicos distintos entre diccionarios

<details><summary>SQL</summary>

```sql
SELECT g.glosa, k AS parametro,
       a.datos_fonologicos ->> k AS valor_a, b.datos_fonologicos ->> k AS valor_b
FROM sena_diccionario a
JOIN sena_diccionario b ON b.id_sena = a.id_sena AND b.id_diccionario > a.id_diccionario
JOIN sena_glosa sg      ON sg.id_sena = a.id_sena
JOIN glosa g            ON g.id_glosa = sg.id_glosa
CROSS JOIN LATERAL (SELECT jsonb_object_keys(a.datos_fonologicos || b.datos_fonologicos) AS k) keys
WHERE a.datos_fonologicos -> k IS DISTINCT FROM b.datos_fonologicos -> k;
```

</details>

**Sin resultados (0 filas).**

### <a id="c5"></a>C5. Señas por grupo de configuración (prefijo del código: B-P, 5-G, A, L, S, C, O)

<details><summary>SQL</summary>

```sql
SELECT REGEXP_REPLACE(sdc.datos_fonologicos ->> 'codigo', '[- ]?\d+$', '') AS grupo,
       COUNT(*) AS num_senas
FROM sena_diccionario sdc
GROUP BY 1
ORDER BY 2 DESC;
```

</details>

| grupo | num_senas |
|---|---|
| B-P | 243 |
| A | 178 |
| L | 161 |
| S | 136 |
| 5-G | 115 |
| C | 91 |
| O | 82 |

*7 filas.*

### <a id="c6"></a>C6. Ver el JSON completo de una seña por su glosa

<details><summary>SQL</summary>

```sql
SELECT g.glosa, jsonb_pretty(sdc.datos_fonologicos) AS datos_fonologicos
FROM glosa g
JOIN sena_glosa sg        ON sg.id_glosa = g.id_glosa
JOIN sena_diccionario sdc ON sdc.id_sena = sg.id_sena
WHERE g.glosa = 'Y-ESO';
```

</details>

| glosa | datos_fonologicos |
|---|---|
| Y-ESO | { "codigo": "B-P 3", "pagina": 1, "tipo_sena": "SC: I. SM; II. SB", "ubicacion": "I. La mano inicia sobre el pecho y se desliza hacia enfrente; II. Del pecho al rostro.", "definic… |

*1 fila.*

## D. Fonología (datos_fonologicos)

### <a id="d1"></a>D1. Señas con una configuración exacta

<details><summary>SQL</summary>

```sql
SELECT g.glosa, sdc.datos_fonologicos ->> 'ubicacion' AS ubicacion
FROM sena_diccionario sdc
JOIN sena_glosa sg ON sg.id_sena = sdc.id_sena
JOIN glosa g       ON g.id_glosa = sg.id_glosa
WHERE sdc.datos_fonologicos @> '{"configuracion": "B-P.2"}'
ORDER BY g.glosa;
```

</details>

| glosa | ubicacion |
|---|---|
| ABOFETEAR-B | A la altura de la mejilla. |
| ABRAZAR | Sobre el pecho. |
| ABRIR-A | Del centro del cuello a los hombros. |
| ABRIR-MENTE | A Ia altura de la frente. |
| ACTIVO | Sobre la frente. |
| ACUSAR | A la altura del hombro. |
| ADORAR-1 | Del rostro a la cintura. |
| AEROPUERTO | De los hombros a la cabeza, del centro a los lados. |
| AHORA-A | A la altura del pecho. |
| ALABAR | A la altura del rostro. |
| ALEGRÍA | Sobre el pecho. |
| ALTO-1 | A la altura del pecho. |
| ANDAR | A la altura del pecho. |
| ANIMAR | A la altura del pecho. |
| APLAZAR | A la altura del pecho. |
| AYUNAR | A la altura de la boca del lado derecho al izquierdo. |
| BARCO | A la altura del pecho; las puntas de los dedos se tocan. |
| BAÑO | Sobre el pecho y se desliza hacia el abdomen. |
| BIEN | Sobre la barbilla. |
| BOSTEZAR | A la altura de la boca. |

*Se muestran 20 de 58 filas.*

### <a id="d2"></a>D2. Varias condiciones a la vez (usa el índice GIN)

<details><summary>SQL</summary>

```sql
SELECT g.glosa
FROM sena_diccionario sdc
JOIN sena_glosa sg ON sg.id_sena = sdc.id_sena
JOIN glosa g       ON g.id_glosa = sg.id_glosa
WHERE sdc.datos_fonologicos @> '{"configuracion": "A.1", "ubicacion": "A la altura del pecho."}'
ORDER BY g.glosa;
```

</details>

| glosa |
|---|
| A-SALVO |
| ALCOHÓLICOS-ANÓNIMOS |
| ANTIGUO |
| ARROBA |
| ASOCIACIÓN |
| CANADÁ-B |
| CON |
| CONTIGO-B |
| ELUDIR |
| EXCELENTE |
| PAN |
| RELACIÓN-SEXUAL |
| SEPARAR-2 |

*13 filas.*

### <a id="d3"></a>D3. Búsqueda de texto dentro de un parámetro (configuraciones que usan B-P.2)

<details><summary>SQL</summary>

```sql
SELECT g.glosa, sdc.datos_fonologicos ->> 'configuracion' AS configuracion
FROM sena_diccionario sdc
JOIN sena_glosa sg ON sg.id_sena = sdc.id_sena
JOIN glosa g       ON g.id_glosa = sg.id_glosa
WHERE sdc.datos_fonologicos ->> 'configuracion' ILIKE '%B-P.2%'
ORDER BY g.glosa;
```

</details>

| glosa | configuracion |
|---|---|
| ABANDONAR-3 | MD y MB seña que pasa de C.7 a B-P.2 |
| ABOFETEAR-A | MD B-P.2, MB 1.1 |
| ABOFETEAR-B | B-P.2 |
| ABONO | MD y MB B-P.2 |
| ABRAZAR | B-P.2 |
| ABRIR-A | B-P.2 |
| ABRIR-MENTE | B-P.2 |
| ACCESO | MD y MB B-P.2 |
| ACTA | MD A.1, MB B-P.2 |
| ACTA-DE-DEMANDA | I. MD A.1, MB B-P.2; II. MD y MB B-P.2 |
| ACTA-DE-NACIMIENTO | I. MD A.1, MB B-P.2; II. B-P.7 |
| ACTIVO | B-P.2 |
| ACUSAR | B-P.2 |
| ADORAR-1 | B-P.2 |
| AEROPUERTO | B-P.2 |
| AFUERA | Seña que pasa de B-P.2 a B-P.8 y a B-P.2 |
| AGENDA-B | I. B-P. 2; II. MD O.4, MB B-P.2; III. 5.1 |
| AHORA-A | B-P.2 |
| AHORA-B | MD y MB B-P.2 |
| ALABANZA | I. A.1; II. B-P.2 |

*Se muestran 20 de 247 filas.*

### <a id="d4"></a>D4. Rasgos no manuales que mencionan las cejas

<details><summary>SQL</summary>

```sql
SELECT g.glosa, sdc.datos_fonologicos ->> 'rasgos_no_manuales' AS rasgos
FROM sena_diccionario sdc
JOIN sena_glosa sg ON sg.id_sena = sdc.id_sena
JOIN glosa g       ON g.id_glosa = sg.id_glosa
WHERE sdc.datos_fonologicos ->> 'rasgos_no_manuales' ILIKE '%ceja%'
ORDER BY g.glosa;
```

</details>

| glosa | rasgos |
|---|---|
| ABARROTADO | Cejas hacia arriba, mejillas infladas. |
| APROVECHARSE-DE | Cejas hacia arriba, ojos abiertos, boca abierta mostrando los dientes. |
| ASALTO-A | Cabeza hacia atrás, cejas hacia arriba, boca abierta y mostrando los dientes. |
| CEDER-EL-PASO | Cejas hacia arriba, cabeza ladeada hacia la derecha. |
| CONFIRMACIÓN | Cejas hacia arriba, se esboza una sonrisa. |
| CUÁNTOS-A | Cabeza hacia atrás, ceño fruncido, cejas arriba. |
| CUÁNTOS-B | Cabeza hacia atrás, ceño fruncido, cejas arriba. |
| DESCUBRIR-A | Cejas hacia arriba, boca abierta. |
| DIFUNDIR | Cabeza atrás, cejas arriba. |
| NO-GUSTAR | Cejas hacia arriba, ceño fruncido. |
| PATRULLA | Cejas hacia arriba, ojos inusualmente abiertos, mejillas infladas. |
| PRENDER | Cejas hacia arriba. |
| QUÉ-PADRE | Cabeza inclinada, cejas hacia arriba, boca semiabierta. |
| Y-ESO | Cejas hacia arriba, comisuras de los labios ligeramente hacia abajo. |

*14 filas.*

### <a id="d5"></a>D5. Frecuencia de cada configuración

<details><summary>SQL</summary>

```sql
SELECT sdc.datos_fonologicos ->> 'configuracion' AS configuracion, COUNT(*) AS num_senas
FROM sena_diccionario sdc
GROUP BY 1
ORDER BY 2 DESC, 1;
```

</details>

| configuracion | num_senas |
|---|---|
| A.1 | 63 |
| S.1 | 61 |
| B-P.2 | 58 |
| L.1 | 42 |
| MD y MB B-P.2 | 33 |
| C.1 | 29 |
| 5.1 | 23 |
| MD A.1, MB B-P.2 | 22 |
| B-P.1 | 20 |
| MD y MB S.1 | 18 |
| O.5 | 16 |
| MD L.1, MB B-P.2 | 15 |
| L.10 | 14 |
| MD y MB A.1 | 12 |
| O.1 | 12 |
| A.5 | 9 |
| MD C.1, MB B-P.2 | 9 |
| MD y MB L.1 | 9 |
| 5.16 | 7 |
| 5.2 | 7 |

*Se muestran 20 de 417 filas.*

### <a id="d6"></a>D6. Frecuencia de cada ubicación

<details><summary>SQL</summary>

```sql
SELECT sdc.datos_fonologicos ->> 'ubicacion' AS ubicacion, COUNT(*) AS num_senas
FROM sena_diccionario sdc
GROUP BY 1
ORDER BY 2 DESC, 1;
```

</details>

| ubicacion | num_senas |
|---|---|
| A la altura del pecho. | 125 |
| A la altura del pecho. MD sobre MB. | 65 |
| MD y MB a la altura del pecho. | 59 |
| Sobre el pecho. | 21 |
| A la altura de la boca. | 15 |
| A la altura del hombro. | 15 |
| A la altura del cuello. | 12 |
| A la altura del abdomen. | 10 |
| A la altura de la frente. | 9 |
| Sobre la frente. | 9 |
| Sobre la mejilla. | 8 |
| A la altura de la barbilla. | 7 |
| I. y II. A la altura del pecho. | 7 |
| A la altura de la cara. | 6 |
| A la altura de los hombros. | 6 |
| A la altura del pecho. MD detrás de MB. | 6 |
| Sobre el cuello. | 6 |
| Sobre la barbilla. | 6 |
| A la altura de la cabeza. | 5 |
| A la altura del pecho, MD sobre MB. | 5 |

*Se muestran 20 de 526 filas.*

### <a id="d7"></a>D7. Pares mínimos: señas iguales en todo salvo un parámetro Compara el texto exacto de configuración, ubicación, movimiento y orientación; como son descripciones libres, es una aproximación.

<details><summary>SQL</summary>

```sql
WITH f AS (
    SELECT sdc.id_sena, g.glosa,
           COALESCE(sdc.datos_fonologicos ->> 'configuracion', '') AS c,
           COALESCE(sdc.datos_fonologicos ->> 'ubicacion', '')     AS u,
           COALESCE(sdc.datos_fonologicos ->> 'movimiento', '')    AS m,
           COALESCE(sdc.datos_fonologicos ->> 'orientacion', '')   AS o
    FROM sena_diccionario sdc
    JOIN sena_glosa sg ON sg.id_sena = sdc.id_sena
    JOIN glosa g       ON g.id_glosa = sg.id_glosa
)
SELECT a.glosa AS sena_a, b.glosa AS sena_b,
       CASE WHEN a.c <> b.c THEN 'configuracion: ' || a.c || ' / ' || b.c
            WHEN a.u <> b.u THEN 'ubicacion: '     || a.u || ' / ' || b.u
            WHEN a.m <> b.m THEN 'movimiento: '    || a.m || ' / ' || b.m
            ELSE                 'orientacion: '   || a.o || ' / ' || b.o END AS diferencia
FROM f a
JOIN f b ON a.id_sena < b.id_sena
WHERE (a.c <> b.c)::int + (a.u <> b.u)::int + (a.m <> b.m)::int + (a.o <> b.o)::int = 1
ORDER BY sena_a, sena_b;
```

</details>

| sena_a | sena_b | diferencia |
|---|---|---|
| A-SALVO | ASOCIACIÓN | movimiento: Recto hacia el frente. / Las manos se mueven formando un círculo hacia enfrente. |
| A-SALVO | CONTIGO-B | orientacion: Palmas hacia afuera. / Las palmas se encuentran frente a frente. |
| A-SALVO | LUJO | configuracion: A.1 / L.1 |
| ABRAZAR | ALEGRÍA | movimiento: Las manos golpean los hombros repetidamente. / De atrás hacia adelante flexionando sólo las muñecas alternadamente. |
| ABRAZAR | CONFESAR-B | movimiento: Las manos golpean los hombros repetidamente. / Las manos se mueven formando círculos hacia enfrente repetidamente. |
| ABRAZAR | CONFIAR | movimiento: Las manos golpean los hombros repetidamente. / Las manos se mueven formando un arco hacia el frente. |
| ACTA | CENTRO | movimiento: La MD se mueve formando un círculo y después golpea a la MB en línea recta. / La MD se mueve formando un círculo y golpea a la MB. |
| ACTA | HUELLA | movimiento: La MD se mueve formando un círculo y después golpea a la MB en línea recta. / El dedo pulgar de la MD presiona la palma de la MB. |
| ACTA | SUSPENDER | movimiento: La MD se mueve formando un círculo y después golpea a la MB en línea recta. / MD recto hacia el frente. |
| ACTA | ÁFRICA-LSM | movimiento: La MD se mueve formando un círculo y después golpea a la MB en línea recta. / La MD simula un salto de los dedos a la muñeca de MB. |
| ADIÓS-A | SAL-A | configuracion: 5.1 / S.1 |
| ALCOHÓLICOS-ANÓNIMOS | ARROBA | movimiento: La mano simula un salto de izquierda a derecha. / La mano se mueve formando un círculo. |
| ALEGRÍA | CONFESAR-B | movimiento: De atrás hacia adelante flexionando sólo las muñecas alternadamente. / Las manos se mueven formando círculos hacia enfrente repetidamente. |
| ALEGRÍA | CONFIAR | movimiento: De atrás hacia adelante flexionando sólo las muñecas alternadamente. / Las manos se mueven formando un arco hacia el frente. |
| ALMA | DESCUBRIR-B | ubicacion: A la altura de la boca. / A la altura de la frente. |
| ALMA | FEO | ubicacion: A la altura de la boca. / A la altura de la cara. |
| ALMA | LENGUA | movimiento: Recto hacia el frente. / La mano se mueve formando círculos. |
| ALTO-1 | EMPUJAR | orientacion: Palma hacia afuera. / Palmas hacia afuera. |
| ALUMNO | APÓSTOLES-A | ubicacion: A la altura de la boca. / A la altura de la frente. |
| ANALFABETO | AYER | ubicacion: Inicia sobre la barbilla y termina sobre la frente. / Inicia sobre la barbilla y termina sobre la mejilla. |

*Se muestran 20 de 107 filas.*

### <a id="d8"></a>D8. Cobertura de cada campo del JSON

<details><summary>SQL</summary>

```sql
SELECT k AS campo,
       COUNT(*) FILTER (WHERE sdc.datos_fonologicos ? k) AS con_dato,
       COUNT(*) AS total
FROM sena_diccionario sdc
CROSS JOIN UNNEST(ARRAY['codigo', 'significado', 'tipo_sena', 'configuracion', 'ubicacion',
                        'orientacion', 'movimiento', 'rasgos_no_manuales', 'representacion',
                        'definicion', 'nota_cultural', 'pagina']) k
GROUP BY k
ORDER BY con_dato DESC, k;
```

</details>

| campo | con_dato | total |
|---|---|---|
| codigo | 1006 | 1006 |
| configuracion | 1006 | 1006 |
| definicion | 1006 | 1006 |
| pagina | 1006 | 1006 |
| significado | 1006 | 1006 |
| tipo_sena | 1006 | 1006 |
| ubicacion | 1006 | 1006 |
| orientacion | 1005 | 1006 |
| movimiento | 985 | 1006 |
| rasgos_no_manuales | 253 | 1006 |
| representacion | 160 | 1006 |
| nota_cultural | 42 | 1006 |

*12 filas.*

## E. Tipo de seña

### <a id="e1"></a>E1. Señas por tipo (SM, SB, SS, SC)

<details><summary>SQL</summary>

```sql
SELECT COALESCE(t.tipo, '(sin tipo)') AS tipo, COUNT(*) AS num_senas
FROM sena s
LEFT JOIN tipo_sena t ON t.id_tipo_sena = s.id_tipo
GROUP BY 1
ORDER BY 2 DESC;
```

</details>

| tipo | num_senas |
|---|---|
| SM | 328 |
| SB | 319 |
| SS | 218 |
| SC | 140 |
| (sin tipo) | 1 |

*5 filas.*

### <a id="e2"></a>E2. Señas compuestas (SC) con el tipo de cada parte

<details><summary>SQL</summary>

```sql
SELECT g.glosa, sdc.datos_fonologicos ->> 'tipo_sena' AS partes
FROM sena s
JOIN tipo_sena t          ON t.id_tipo_sena = s.id_tipo
JOIN sena_diccionario sdc ON sdc.id_sena = s.id_sena
JOIN sena_glosa sg        ON sg.id_sena = s.id_sena
JOIN glosa g              ON g.id_glosa = sg.id_glosa
WHERE t.tipo = 'SC'
ORDER BY g.glosa;
```

</details>

| glosa | partes |
|---|---|
| ABRIGO | I. SS; II. SM |
| ABUELA | SC: I. SB; II. SM |
| ACOMPAÑAR-A | SC: I. SB; II. SS |
| ACTA-DE-DEMANDA | SC: I. y II. SB |
| ACTA-DE-NACIMIENTO | SC: I. SB; II. SS |
| ACTOR | I. SB y II. SB |
| ADULTERIO | SC: I. SS; II. SM |
| AGENDA-B | SC: I. SS; II. SB; III. SS |
| AIRE-ACONDICIONADO | SC: I.; II y III. SM |
| ALABANZA | SC: I. y II. SS |
| ALELUYA | SC: I. y II. SS |
| ALTAR | I. y II. SS |
| AMANTE | SC: I. SM; II. SB |
| AMÉN-A | I. y II. SM |
| APROBAR | SC: I. y II. SB |
| ARCHIVO | SC: I. SS; II. SB |
| ARENA-DE-MAR | SC: I. SB; II. SS |
| ASUNTO | SC: I. SM; II. SS |
| AUMENTAR-ELEVAR-ECONOMÍA | SC: I. SM; II. SB |
| AUMENTAR-GANANCIA | SC: I. SM; II. SS |

*Se muestran 20 de 140 filas.*

### <a id="e3"></a>E3. Combinaciones de partes en las señas compuestas

<details><summary>SQL</summary>

```sql
SELECT sdc.datos_fonologicos ->> 'tipo_sena' AS partes, COUNT(*) AS num_senas
FROM sena s
JOIN tipo_sena t          ON t.id_tipo_sena = s.id_tipo
JOIN sena_diccionario sdc ON sdc.id_sena = s.id_sena
WHERE t.tipo = 'SC'
GROUP BY 1
ORDER BY 2 DESC;
```

</details>

| partes | num_senas |
|---|---|
| SC: I. SM; II. SB | 19 |
| SC: I. y II. SB | 16 |
| SC: I. SS; II. SB | 15 |
| SC: I. y II. SM | 14 |
| SC: I. y II. SS | 12 |
| SC: I. SS; II. SM | 11 |
| SC: I. SM; II. SS | 11 |
| SC: I. SB; II. SS | 8 |
| SC: I. SB; II. SM | 7 |
| SC | 3 |
| SC: I., II. y III. SB | 2 |
| I. y II. SS | 2 |
| SC: I. SS; II. SB; III. SS. | 1 |
| SC: I. SS; II. y III. SB | 1 |
| SC: I. y II. SS; III. SM | 1 |
| SC: I. y II.SB | 1 |
| SC: I.; II y III. SM | 1 |
| SC: I.SB; II. SS | 1 |
| SC: I: SS; II. SS | 1 |
| I. SB y II. SB | 1 |

*Se muestran 20 de 32 filas.*

## F. Videos y señantes

### <a id="f1"></a>F1. [VACÍA HOY: no hay videos] Videos de una seña, con su señante

<details><summary>SQL</summary>

```sql
SELECT g.glosa, v.path, v.tipo_de_toma, v.mano_dominante, st.id_senante, st.perfil_nativo
FROM glosa g
JOIN sena_glosa sg        ON sg.id_glosa = g.id_glosa
JOIN sena_diccionario sdc ON sdc.id_sena = sg.id_sena
JOIN sena_video sv        ON sv.id_sena_diccionario = sdc.id_sena_diccionario
JOIN video v              ON v.id_video = sv.id_video
JOIN senante st           ON st.id_senante = v.id_senante
WHERE g.glosa = 'CASA-A';
```

</details>

**Sin resultados (0 filas).**

### <a id="f2"></a>F2. [VACÍA HOY: no hay videos] Video de una palabra (palabra -> seña -> video)

<details><summary>SQL</summary>

```sql
SELECT DISTINCT p.palabra, v.path
FROM palabra p
JOIN sena_palabra sp      ON sp.id_palabra = p.id_palabra
JOIN sena_diccionario sdc ON sdc.id_sena = sp.id_sena
JOIN sena_video sv        ON sv.id_sena_diccionario = sdc.id_sena_diccionario
JOIN video v              ON v.id_video = sv.id_video
WHERE LOWER(p.palabra) = LOWER('Casa');
```

</details>

**Sin resultados (0 filas).**

### <a id="f3"></a>F3. [VACÍA HOY: no hay señantes] Videos y señas distintas grabadas por cada señante

<details><summary>SQL</summary>

```sql
SELECT st.id_senante, st.edad, st.perfil_nativo,
       COUNT(DISTINCT v.id_video)  AS videos,
       COUNT(DISTINCT sdc.id_sena) AS senas_distintas
FROM senante st
LEFT JOIN video v              ON v.id_senante = st.id_senante
LEFT JOIN sena_video sv        ON sv.id_video = v.id_video
LEFT JOIN sena_diccionario sdc ON sdc.id_sena_diccionario = sv.id_sena_diccionario
GROUP BY st.id_senante, st.edad, st.perfil_nativo
ORDER BY st.id_senante;
```

</details>

**Sin resultados (0 filas).**

### <a id="f4"></a>F4. [VACÍA HOY: no hay videos] Señas grabadas por 2 o más señantes (para estudiar variación)

<details><summary>SQL</summary>

```sql
SELECT g.glosa, COUNT(DISTINCT v.id_senante) AS num_senantes
FROM sena_diccionario sdc
JOIN sena_video sv ON sv.id_sena_diccionario = sdc.id_sena_diccionario
JOIN video v       ON v.id_video = sv.id_video
JOIN sena_glosa sg ON sg.id_sena = sdc.id_sena
JOIN glosa g       ON g.id_glosa = sg.id_glosa
GROUP BY g.glosa
HAVING COUNT(DISTINCT v.id_senante) > 1;
```

</details>

**Sin resultados (0 filas).**

### <a id="f5"></a>F5. [VACÍA HOY: no hay videos] Videos por mano dominante y tipo de toma

<details><summary>SQL</summary>

```sql
SELECT mano_dominante, tipo_de_toma, COUNT(*) AS videos
FROM video
GROUP BY mano_dominante, tipo_de_toma
ORDER BY mano_dominante, tipo_de_toma;
```

</details>

**Sin resultados (0 filas).**

## G. Autoría

### <a id="g1"></a>G1. Definiciones y glosas por autor

<details><summary>SQL</summary>

```sql
SELECT autor, 'definicion' AS tipo, COUNT(*) AS total FROM definicion GROUP BY autor
UNION ALL
SELECT autor, 'glosa', COUNT(*) FROM glosa GROUP BY autor
ORDER BY autor, tipo;
```

</details>

| autor | tipo | total |
|---|---|---|
| Equipo de Lexicografía, DLSM CDMX 2017 | definicion | 1006 |
| LSM_DB (generadas a partir del DLSM CDMX 2017) | glosa | 1006 |

*2 filas.*

## H. Cobertura (qué falta por capturar)

### <a id="h1"></a>H1. Resumen: cuántas señas tienen cada cosa

<details><summary>SQL</summary>

```sql
SELECT COUNT(*) AS senas,
       COUNT(*) FILTER (WHERE EXISTS (SELECT 1 FROM sena_palabra     x WHERE x.id_sena = s.id_sena)) AS con_palabra,
       COUNT(*) FILTER (WHERE EXISTS (SELECT 1 FROM sena_definicion  x WHERE x.id_sena = s.id_sena)) AS con_definicion,
       COUNT(*) FILTER (WHERE EXISTS (SELECT 1 FROM sena_glosa       x WHERE x.id_sena = s.id_sena)) AS con_glosa,
       COUNT(*) FILTER (WHERE EXISTS (SELECT 1 FROM sena_diccionario x WHERE x.id_sena = s.id_sena)) AS en_diccionario,
       COUNT(*) FILTER (WHERE EXISTS (SELECT 1 FROM sena_diccionario x
                                      JOIN sena_video v USING (id_sena_diccionario)
                                      WHERE x.id_sena = s.id_sena))                              AS con_video,
       COUNT(*) FILTER (WHERE s.id_tipo IS NOT NULL)                                             AS con_tipo
FROM sena s;
```

</details>

| senas | con_palabra | con_definicion | con_glosa | en_diccionario | con_video | con_tipo |
|---|---|---|---|---|---|---|
| 1006 | 1006 | 1006 | 1006 | 1006 | 0 | 1005 |

*1 fila.*

### <a id="h2"></a>H2. Señas sin tipo

<details><summary>SQL</summary>

```sql
SELECT g.glosa, sdc.datos_fonologicos ->> 'codigo' AS codigo,
       sdc.datos_fonologicos ->> 'tipo_sena' AS tipo_original
FROM sena s
JOIN sena_diccionario sdc ON sdc.id_sena = s.id_sena
JOIN sena_glosa sg        ON sg.id_sena = s.id_sena
JOIN glosa g              ON g.id_glosa = sg.id_glosa
WHERE s.id_tipo IS NULL;
```

</details>

| glosa | codigo | tipo_original |
|---|---|---|
| TODAVÍA | O-80 | MB |

*1 fila.*

### <a id="h3"></a>H3. Señas sin movimiento u orientación en el diccionario

<details><summary>SQL</summary>

```sql
SELECT g.glosa,
       NOT sdc.datos_fonologicos ? 'movimiento'  AS sin_movimiento,
       NOT sdc.datos_fonologicos ? 'orientacion' AS sin_orientacion
FROM sena_diccionario sdc
JOIN sena_glosa sg ON sg.id_sena = sdc.id_sena
JOIN glosa g       ON g.id_glosa = sg.id_glosa
WHERE NOT sdc.datos_fonologicos ?& ARRAY['movimiento', 'orientacion']
ORDER BY g.glosa;
```

</details>

| glosa | sin_movimiento | sin_orientacion |
|---|---|---|
| AMAR | t | f |
| ARDILLA | t | f |
| AUDÍFONOS | t | f |
| CAPITÁN | t | f |
| CARGAR | t | f |
| CENTROAMÉRICA | t | f |
| CONFESAR-A | t | f |
| CPU | t | f |
| ESCUCHAR | t | f |
| ESTORNUDAR | t | f |
| GEL | t | f |
| INGLATERRA | t | f |
| INGLÉS | t | f |
| LSM | t | t |
| MAMILA | t | f |
| ORO-A | t | f |
| PINGÜINO | t | f |
| PROMETER | t | f |
| SAL-B | t | f |
| TEPITO | t | f |

*Se muestran 20 de 21 filas.*

### <a id="h4"></a>H4. [CONTROL: vacía = sin problemas] Palabras sin seña (todas salen del diccionario)

<details><summary>SQL</summary>

```sql
SELECT p.palabra
FROM palabra p
WHERE NOT EXISTS (SELECT 1 FROM sena_palabra sp WHERE sp.id_palabra = p.id_palabra);
```

</details>

**Sin resultados (0 filas).**

## I. Control de consistencia

### <a id="i1"></a>I1. [CONTROL: vacía = sin problemas] Códigos repetidos en el diccionario

<details><summary>SQL</summary>

```sql
SELECT sdc.datos_fonologicos ->> 'codigo' AS codigo, COUNT(*) AS veces,
       STRING_AGG(g.glosa, ', ' ORDER BY g.glosa) AS glosas
FROM sena_diccionario sdc
JOIN sena_glosa sg ON sg.id_sena = sdc.id_sena
JOIN glosa g       ON g.id_glosa = sg.id_glosa
GROUP BY 1
HAVING COUNT(*) > 1;
```

</details>

| codigo | veces | glosas |
|---|---|---|
| C-84 | 2 | CUBA-LSM, ENFERMERA-A |

*1 fila.*

### <a id="i2"></a>I2. [CONTROL: vacía = sin problemas] Glosas numeradas: el diccionario no da nada que distinga esas señas

<details><summary>SQL</summary>

```sql
SELECT g.glosa, sdc.datos_fonologicos ->> 'codigo' AS codigo,
       sdc.datos_fonologicos ->> 'significado' AS significado
FROM glosa g
JOIN sena_glosa sg        ON sg.id_glosa = g.id_glosa
JOIN sena_diccionario sdc ON sdc.id_sena = sg.id_sena
WHERE g.glosa ~ '-[0-9]+$'
ORDER BY g.glosa;
```

</details>

| glosa | codigo | significado |
|---|---|---|
| ABANDONAR-1 | A-7 | Abandonar |
| ABANDONAR-2 | S-4 | Abandonar 1 – Dejar 2 |
| ABANDONAR-3 | C-1 | Abandonar |
| ADORAR-1 | B-P 15 | Adorar |
| ADORAR-2 | A-21 | Adorar |
| ALTO-1 | B-P 28 | Alto |
| ALTO-2 | A-33 | Alto, ta |
| CONSTITUCIÓN-1 | S-35 | Constitución |
| CONSTITUCIÓN-2 | C-72 | Constitución |
| NACIONAL-1 | B-P 212 | Nacional |
| NACIONAL-2 | L-129 | Nacional 1 / República Mexicana 2 |
| SEPARAR-1 | A-168 | Separar – Terminar (relación de novios) |
| SEPARAR-2 | A-169 | Separar – Terminar (relación de novios) |
| VAGINA-1 | A-180 | Vagina |
| VAGINA-2 | L-160 | Vagina |

*15 filas.*

### <a id="i3"></a>I3. [CONTROL: vacía = sin problemas] Lengua de la entrada distinta de la lengua de la seña

<details><summary>SQL</summary>

```sql
SELECT sdc.id_sena_diccionario, s.id_lengua AS lengua_sena, sdc.id_lengua AS lengua_entrada
FROM sena_diccionario sdc
JOIN sena s ON s.id_sena = sdc.id_sena
WHERE s.id_lengua <> sdc.id_lengua;
```

</details>

**Sin resultados (0 filas).**

### <a id="i4"></a>I4. [CONTROL: vacía = sin problemas] Glosas repetidas o señas con más de una glosa

<details><summary>SQL</summary>

```sql
SELECT g.glosa, COUNT(*) AS veces
FROM glosa g
JOIN sena_glosa sg ON sg.id_glosa = g.id_glosa
GROUP BY g.glosa
HAVING COUNT(*) > 1
UNION ALL
SELECT 'seña ' || sg.id_sena, COUNT(*)
FROM sena_glosa sg
GROUP BY sg.id_sena
HAVING COUNT(*) > 1;
```

</details>

**Sin resultados (0 filas).**

### <a id="i5"></a>I5. [CONTROL: vacía = sin problemas] Tipo de sena.id_tipo que no coincide con el tipo del JSON

<details><summary>SQL</summary>

```sql
SELECT g.glosa, t.tipo, sdc.datos_fonologicos ->> 'tipo_sena' AS tipo_json
FROM sena s
JOIN tipo_sena t          ON t.id_tipo_sena = s.id_tipo
JOIN sena_diccionario sdc ON sdc.id_sena = s.id_sena
JOIN sena_glosa sg        ON sg.id_sena = s.id_sena
JOIN glosa g              ON g.id_glosa = sg.id_glosa
WHERE t.tipo <> 'SC' AND t.tipo <> sdc.datos_fonologicos ->> 'tipo_sena';
```

</details>

**Sin resultados (0 filas).**

## J. Ficha completa de una seña

### <a id="j1"></a>J1. Todo lo que se sabe de una seña en una sola fila

<details><summary>SQL</summary>

```sql
SELECT g.glosa,
       sdc.datos_fonologicos ->> 'codigo' AS codigo,
       l.nombre_completo AS lengua,
       t.tipo,
       (SELECT STRING_AGG(p.palabra, ', ') FROM sena_palabra x JOIN palabra p USING (id_palabra) WHERE x.id_sena = s.id_sena) AS palabras,
       (SELECT STRING_AGG(d.definicion, ' | ') FROM sena_definicion x JOIN definicion d USING (id_definicion) WHERE x.id_sena = s.id_sena) AS definiciones,
       dic.nombre_completo AS diccionario,
       sdc.datos_fonologicos ->> 'configuracion' AS configuracion,
       sdc.datos_fonologicos ->> 'ubicacion'     AS ubicacion,
       sdc.datos_fonologicos ->> 'movimiento'    AS movimiento
FROM glosa g
JOIN sena_glosa sg        ON sg.id_glosa = g.id_glosa
JOIN sena s               ON s.id_sena = sg.id_sena
JOIN lengua l             ON l.id_lengua = s.id_lengua
LEFT JOIN tipo_sena t     ON t.id_tipo_sena = s.id_tipo
JOIN sena_diccionario sdc ON sdc.id_sena = s.id_sena
JOIN diccionario dic      ON dic.id_diccionario = sdc.id_diccionario
WHERE g.glosa = 'ABAJO';
```

</details>

| glosa | codigo | lengua | tipo | palabras | definiciones | diccionario | configuracion | ubicacion | movimiento |
|---|---|---|---|---|---|---|---|---|---|
| ABAJO | B-P 4 | Lengua de Señas Mexicana | SB | Abajo, Debajo | 1. adv. En el lugar o parte inferior. 2. adv. En la parte inferior o interna de algo y cubierto por ello. | Diccionario de Lengua de Señas Mexicana de la Ciudad de México (DLSM, 2017) | MD y MB B-P.6 | MD inicia sobre MB y termina a la altura de la cintura, MB a la altura del pecho. | La MD se mueve formando un arco. |

*1 fila.*

## K. Temas del diccionario

### <a id="k1"></a>K1. Señas con nota cultural

<details><summary>SQL</summary>

```sql
SELECT g.glosa, sdc.datos_fonologicos ->> 'nota_cultural' AS nota_cultural
FROM sena_diccionario sdc
JOIN sena_glosa sg ON sg.id_sena = sdc.id_sena
JOIN glosa g       ON g.id_glosa = sg.id_glosa
WHERE sdc.datos_fonologicos ? 'nota_cultural'
ORDER BY g.glosa;
```

</details>

| glosa | nota_cultural |
|---|---|
| ABANDONAR-C | Esta seña connota una actitud despectiva |
| ACTIVO | La seña se usa para la comunidad sorda LGBTTTI. |
| ADORAR-1 | La seña se usa en la comunidad sorda de los Testigos de Jehová. |
| ADORAR-2 | La seña se usa en la comunidad sorda cristiana y mormona. |
| ADVENTISTA | La seña se usa en la comunidad sorda adventista. |
| ADÁN-A | La seña se usa en la comunidad sorda católica, cristiana y de los Testigos de Jehová. |
| ADÁN-B | La seña se usa en la comunidad sorda mormona. |
| ALABANZA | La seña se usa en la comunidad sorda católica. |
| ALABAR | La seña se usa en la comunidad sorda Amistad Cristiana e Iglesia de Cristo. |
| ALELUYA | La seña se usa en la comunidad sorda Amistad Cristiana e Iglesia de Cristo. |
| ALTAR | La seña se usa en la comunidad sorda mormona. |
| ALUMNO | El género femenino se articula con ALUMNO + MUJER. |
| AMÉN-A | La seña se usa en la comunidad sorda católica. |
| AMÉN-B | la seña se usa en la comunidad sorda cristiana. |
| ANCIANO | La seña se usa en la comunidad sorda del Testigo de Je hová. |
| ANTROPOLOGÍA | La seña se usa en la comunidad sorda catolica. |
| APOCALIPSIS-B | la seña se usa en la comunidad sorda mormona. |
| APROVECHAR | Generalmente se acompaña de la emisión de un clic bilabial o lengua vibratoria dependiendo de su contexto.. |
| APÓSTOL | la seña se usa en la comunidad sorda de los Testigos de Jehová. |
| APÓSTOLES-A | La seña se usa en la comunidad sorda católica. |

*Se muestran 20 de 42 filas.*

### <a id="k2"></a>K2. Señas con representación (qué imitan)

<details><summary>SQL</summary>

```sql
SELECT g.glosa, sdc.datos_fonologicos ->> 'representacion' AS representacion
FROM sena_diccionario sdc
JOIN sena_glosa sg ON sg.id_sena = sdc.id_sena
JOIN glosa g       ON g.id_glosa = sg.id_glosa
WHERE sdc.datos_fonologicos ? 'representacion'
ORDER BY g.glosa;
```

</details>

| glosa | representacion |
|---|---|
| ABAJO | Simula la acción de poner algo debajo de otra cosa. |
| ABOFETEAR-A | Simula la acción de abofetear a alguien. |
| ABOFETEAR-B | Simula la acción de abofetear a alguien. |
| ABRAZAR | Simula la acción de abrazar a alguien. |
| ACCESO | Simula la acción de entrar a un lugar. |
| ACCIDENTE | Simula la acción de herirse. |
| ACNÉ | Simula la acción de exprimir un barro o una espinilla. |
| ACTA | Simula la acción de sellar un documento |
| ACTA-DE-DEMANDA | Simula la acción de sellar un documento. |
| ACTA-DE-NACIMIENTO | Simula la acción de sellar un documento y cargar a un bebé. |
| ALMEJA | Simula el abrir de una almeja. |
| ALMOHADA-B | Simula la acción de apretar una almohada. |
| ALMOHADA-C | Simula la acción de apretar una almohada detrás de la cabeza. |
| ALTAR | Simula la forma de un altar. |
| ALTO-2 | Simula la altura de una persona. |
| AMANECER | Simula el sol saliendo por el horizonte. |
| AMETRALLADORA | Simula la acción de disparar con una ametralladora o metralleta. |
| AMÉN-A | Simula la imagen de la cruz. |
| AMÉRICA | Simula la forma del continente americano. |
| ANDAR | Simula la acción de caminar. |

*Se muestran 20 de 160 filas.*

### <a id="k3"></a>K3. Estaciones del Metro (STC Metro)

<details><summary>SQL</summary>

```sql
SELECT g.glosa, sdc.datos_fonologicos ->> 'significado' AS significado
FROM sena_diccionario sdc
JOIN sena_glosa sg ON sg.id_sena = sdc.id_sena
JOIN glosa g       ON g.id_glosa = sg.id_glosa
WHERE sdc.datos_fonologicos ->> 'significado' LIKE '%(STC Metro)%'
ORDER BY g.glosa;
```

</details>

| glosa | significado |
|---|---|
| AZTECA | Azteca 1 / Cuauhtémoc 2 3 (STC Metro) |
| BANDERA-A | Bandera 1 (A) / Pantitlán 2 (STC Metro) / Patriotismo 3 (STC Metro) |
| BOSQUE | Bosque 1 / Popotla 2 (STC Metro) |
| BUENAVISTA | Buenavista(STC Metro) |
| CHABACANO-A | Chabacano (A) (STC Metro) |
| CHABACANO-B | Chabacano 1 (B) (STC Metro) / Lázaro Cárdenas 2 3 (STC Metro) |
| CIUDAD-DEPORTIVA | Ciudad Deportiva (STC Metro) |
| LUNA | Luna1 / Taxqueña2 (STC Metro) |
| NATIVITAS | Nativitas (STC Metro) |
| TEPITO | Tepito (STC Metro) |

*10 filas.*

### <a id="k4"></a>K4. Señas de lugares internacionales (SSI)

<details><summary>SQL</summary>

```sql
SELECT g.glosa, sdc.datos_fonologicos ->> 'significado' AS significado
FROM sena_diccionario sdc
JOIN sena_glosa sg ON sg.id_sena = sdc.id_sena
JOIN glosa g       ON g.id_glosa = sg.id_glosa
WHERE sdc.datos_fonologicos ->> 'significado' ~ '\(SS[Il]\)'
ORDER BY g.glosa;
```

</details>

| glosa | significado |
|---|---|
| ALBANIA | Albania (SSI) |
| AMÉRICA | América (SSI) |
| ARGENTINA-SSI | Argentina (SSI) |
| ASIA-B | Asia (SSI) (B) |
| BANGLADESH | Bangladesh (SSI) |
| BELICE | Belice (SSI) |
| BENIN | Benin (SSI) |
| BERLÍN-ALEMANIA | Berlín, Alemania (SSI) |
| BOGOTÁ-COLOMBIA | Bogotá, Colombia (SSI) |
| BOSNIA-Y-HERZEGOVINA | Bosnia y Herzegovina (SSI) |
| BOTSUANA | Botsuana (SSI) |
| BRASIL-SSI | Brasil (SSI) |
| BULGARIA | Bulgaria (SSI) |
| BÉLGICA-SSI | Bélgica (SSI) |
| CAMBOYA | Camboya (SSI) |
| CANADÁ-B | Canadá (B) (SSI) |
| CENTROAMÉRICA | Centroamérica (SSI) |
| COLOMBIA-SSI | Colombia (SSl) |
| COREA-DEL-NORTE | Corea del Norte (SSI) |
| COREA-DEL-SUR | Corea del Sur (SSI) |

*Se muestran 20 de 49 filas.*

### <a id="k5"></a>K5. Señas por categoría gramatical (inicio de la definición: sust., v., adj., adv., ...)

<details><summary>SQL</summary>

```sql
SELECT COALESCE(LOWER(SUBSTRING(d.definicion FROM '^\d?\.?\s*([a-zA-Z]+\.)')), '(otro)') AS categoria,
       COUNT(*) AS num_senas
FROM definicion d
GROUP BY 1
ORDER BY 2 DESC;
```

</details>

| categoria | num_senas |
|---|---|
| sust. | 483 |
| v. | 210 |
| (otro) | 133 |
| adj. | 105 |
| adv. | 28 |
| loc. | 22 |
| interj. | 13 |
| pron. | 6 |
| prep. | 3 |
| intej. | 2 |
| pref. | 1 |

*11 filas.*

### <a id="k6"></a>K6. Búsqueda libre en las definiciones

<details><summary>SQL</summary>

```sql
SELECT g.glosa, d.definicion
FROM definicion d
JOIN sena_definicion x ON x.id_definicion = d.id_definicion
JOIN sena_glosa sg     ON sg.id_sena = x.id_sena
JOIN glosa g           ON g.id_glosa = sg.id_glosa
WHERE d.definicion ILIKE '%comida%'
ORDER BY g.glosa;
```

</details>

| glosa | definicion |
|---|---|
| CARLS-JR | sust. Cadena de restaurantes de hamburguesas y comida rápida cuya sede central se localiza en Estados Unidos. |
| CENAR | 1. v. intr. Comer por la noche. 2. sust. f. Última comida del día que se toma al atardecer o por la noche. |
| CHIMENEA | sust. f. Construcción doméstica terminada en un conducto vertical que lleva al exterior el humo producido por la leña que se puso en su base para cuecer la comida o calentar la ca… |
| COCINAR | 1. v. tr. Preparar los alimentos cociéndolos en el fuego. 2. sust. f. Pieza o sitio de la casa en el cual se guisa la comida. |
| DESAYUNAR | 1. v. tr. Tomar la primera comida del día que generalmente es ligera y se hace por la mañana. 2. sust. Primera comida del día generalmente ligera que se toma por la mañana. |
| MANCHA | sust. f. Porción de alguna cosa, como una gota de líquido, un fragmento de comida, etc. que ensucia o echa a perder una cosa por ser de apariencia o color distinto del que domina … |

*6 filas.*
