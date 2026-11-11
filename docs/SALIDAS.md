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

### <a id="a1"></a>A1. Seña(s) de una palabra, con su código y significado en el diccionario

<details><summary>SQL</summary>

```sql
SELECT p.palabra,
       sdc.datos_fonologicos ->> 'codigo'      AS codigo,
       sdc.datos_fonologicos ->> 'significado' AS significado
FROM palabra p
JOIN sena_palabra sp      ON sp.id_palabra = p.id_palabra
JOIN sena_diccionario sdc ON sdc.id_sena = sp.id_sena
WHERE LOWER(p.palabra) = LOWER('Casa');
```

</details>

| palabra | codigo | significado |
|---|---|---|
| Casa | B-P 107 | Casa (A) |
| Casa | B-P 108 | Casa (B) |

*2 filas.*

### <a id="a2"></a>A2. Todas las palabras ligadas a una seña (por código)

<details><summary>SQL</summary>

```sql
SELECT sdc.datos_fonologicos ->> 'codigo' AS codigo, p.palabra, l.nombre_completo AS idioma
FROM sena_diccionario sdc
JOIN sena_palabra sp ON sp.id_sena = sdc.id_sena
JOIN palabra p       ON p.id_palabra = sp.id_palabra
JOIN lengua l        ON l.id_lengua = p.id_lengua
WHERE sdc.datos_fonologicos ->> 'codigo' = '5-G 51';
```

</details>

| codigo | palabra | idioma |
|---|---|---|
| 5-G 51 | Belleza | Español |
| 5-G 51 | Bello | Español |
| 5-G 51 | Bonito | Español |
| 5-G 51 | Lindo | Español |

*4 filas.*

### <a id="a3"></a>A3. [VACÍA HOY: falta cargar palabras en inglés] Traducir una palabra de español a inglés a través de la seña

<details><summary>SQL</summary>

```sql
SELECT DISTINCT origen.palabra AS espanol, destino.palabra AS ingles
FROM palabra origen
JOIN sena_palabra sp1 ON sp1.id_palabra = origen.id_palabra
JOIN sena_palabra sp2 ON sp2.id_sena    = sp1.id_sena
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
SELECT DISTINCT p.palabra, d.definicion
FROM palabra p
JOIN sena_palabra sp    ON sp.id_palabra = p.id_palabra
JOIN sena_definicion sd ON sd.id_sena    = sp.id_sena
JOIN definicion d       ON d.id_definicion = sd.id_definicion
WHERE LOWER(p.palabra) = LOWER('Hola')
  AND p.id_lengua = (SELECT id_lengua FROM lengua WHERE nombre_completo = 'Español')
  AND d.id_lengua = (SELECT id_lengua FROM lengua WHERE nombre_completo = 'Inglés');
```

</details>

**Sin resultados (0 filas).**

### <a id="a5"></a>A5. Definición en español de una palabra (misma ruta que A4)

<details><summary>SQL</summary>

```sql
SELECT p.palabra, sdc.datos_fonologicos ->> 'codigo' AS codigo, d.definicion
FROM palabra p
JOIN sena_palabra sp      ON sp.id_palabra = p.id_palabra
JOIN sena_definicion sd   ON sd.id_sena = sp.id_sena
JOIN definicion d         ON d.id_definicion = sd.id_definicion
JOIN sena_diccionario sdc ON sdc.id_sena = sp.id_sena
WHERE LOWER(p.palabra) = LOWER('Banco')
  AND d.id_lengua = (SELECT id_lengua FROM lengua WHERE nombre_completo = 'Español');
```

</details>

| palabra | codigo | definicion |
|---|---|---|
| Banco | B-P 62 | sust. m. Institución que realiza las múltiples operaciones comerciales a que da lugar el dinero y los títulos que lo representan, como inversiones, créditos, ahorros, pagos, etc. |

*1 fila.*

### <a id="a6"></a>A6. Palabras con varias señas (variantes A/B o sentidos distintos)

<details><summary>SQL</summary>

```sql
SELECT p.palabra, COUNT(*) AS num_senas,
       STRING_AGG(sdc.datos_fonologicos ->> 'codigo', ', ' ORDER BY sdc.datos_fonologicos ->> 'codigo') AS codigos
FROM palabra p
JOIN sena_palabra sp      ON sp.id_palabra = p.id_palabra
JOIN sena_diccionario sdc ON sdc.id_sena = sp.id_sena
GROUP BY p.palabra
HAVING COUNT(*) > 1
ORDER BY num_senas DESC, p.palabra;
```

</details>

| palabra | num_senas | codigos |
|---|---|---|
| Abandonar | 6 | A-7, C-1, O-4, O-5, O-6, S-4 |
| Convencer | 4 | B-P 130, B-P 131, B-P 132, B-P 133 |
| Copiar | 4 | 5-G 79, 5-G 80, 5-G 81, 5-G 82 |
| Almohada | 3 | 5-G 18, C-6, C-7 |
| Anteriormente | 3 | B-P 35, B-P 36, B-P 37 |
| Antes | 3 | B-P 35, B-P 36, B-P 37 |
| Asar | 3 | 5-G 34, 5-G 35, B-P 45 |
| Aumentar | 3 | B-P 48, L-8, L-9 |
| Descubrir | 3 | L-31, L-32, L-33 |
| Grave | 3 | L-68, L-69, L-70 |
| Libro | 3 | B-P 186, L-106, L-107 |
| Pasado | 3 | B-P 35, B-P 36, B-P 37 |
| Percatarse | 3 | L-31, L-32, L-33 |
| Ya me di cuenta | 3 | L-31, L-32, L-33 |
| Abofetear | 2 | B-P 5, B-P 6 |
| Adiós | 2 | 5-G 8, 5-G 9 |
| Adorar | 2 | A-21, B-P 15 |
| Adán | 2 | A-18, A-19 |
| Ahora | 2 | B-P 20, B-P 21 |
| Alabanza | 2 | A-28, B-P 22 |

*Se muestran 20 de 116 filas.*

### <a id="a7"></a>A7. Sinónimos: palabras que comparten la misma seña

<details><summary>SQL</summary>

```sql
SELECT sdc.datos_fonologicos ->> 'codigo' AS codigo,
       STRING_AGG(p.palabra, ' / ' ORDER BY p.palabra) AS palabras
FROM sena_diccionario sdc
JOIN sena_palabra sp ON sp.id_sena = sdc.id_sena
JOIN palabra p       ON p.id_palabra = sp.id_palabra
GROUP BY sdc.id_sena, codigo
HAVING COUNT(*) > 1
ORDER BY COUNT(*) DESC, codigo;
```

</details>

| codigo | palabras |
|---|---|
| 5-G 51 | Belleza / Bello / Bonito / Lindo |
| A-69 | Auto / Automóvil / Carro / Coche |
| B-P 23 | Alegría / Celebrar / Disfrutar / Divertido |
| 5-G 19 | Alrededor / Ambiente / Contexto |
| 5-G 33 | Aprehender / Arrestar / Detención |
| 5-G 43 | Baloncesto / Basquetbol / Encestar |
| 5-G 82 | Contagiar / Copiar / Imitar |
| 5-G 87 | Arrestado / Arrestar / Detenido |
| A-12 | Acné / Barro / Espinilla |
| A-128 | Alternar / Intercambiar / Relevar |
| A-159 | Casanova / Mujeriego / Promiscuo |
| A-161 | Recarga / Saldo / Tiempo aire |
| B-P 145 | Bloquear / Defender / Proteger |
| B-P 149 | Correr / Despedir / Expulsar |
| B-P 35 | Anteriormente / Antes / Pasado |
| B-P 36 | Anteriormente / Antes / Pasado |
| B-P 37 | Anteriormente / Antes / Pasado |
| B-P 63 | Bandera / Pantitlán / Patriotismo |
| C-17 | Brassier / Corpiño / Top |
| L-26 | Con sueño / Somnoliento / Sueño |

*Se muestran 20 de 219 filas.*

## B. Lenguas

### <a id="b1"></a>B1. [VACÍA HOY: falta cargar una segunda lengua de señas, p. ej. ASL] Equivalente en otra lengua de señas por palabra compartida

<details><summary>SQL</summary>

```sql
SELECT DISTINCT a.datos_fonologicos ->> 'codigo' AS lsm, b.datos_fonologicos ->> 'codigo' AS otra, p.palabra
FROM sena_diccionario a
JOIN sena_palabra sp1 ON sp1.id_sena = a.id_sena
JOIN palabra p        ON p.id_palabra = sp1.id_palabra
JOIN sena_palabra sp2 ON sp2.id_palabra = p.id_palabra AND sp2.id_sena <> sp1.id_sena
JOIN sena s2          ON s2.id_sena = sp2.id_sena
JOIN sena_diccionario b ON b.id_sena = s2.id_sena
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
| Lengua de Señas Mexicana | 0 | 0 | 0 |

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
       sdc.datos_fonologicos ->> 'codigo'        AS codigo,
       sdc.datos_fonologicos ->> 'significado'   AS significado
FROM sena_diccionario sdc
WHERE (sdc.datos_fonologicos ->> 'pagina')::int BETWEEN 1 AND 2
ORDER BY pagina, sdc.id_sena;
```

</details>

| pagina | codigo | significado |
|---|---|---|
| 1 | B-P 1 | ¿Por qué? |
| 1 | B-P 2 | ¿Qué onda? |
| 1 | B-P 3 | ¿Y eso? |
| 2 | B-P 4 | Abajo – Debajo |
| 2 | B-P 5 | Abofetear (A) |
| 2 | B-P 6 | Abofetear (B) |

*6 filas.*

### <a id="c4"></a>C4. [VACÍA HOY: hace falta un segundo diccionario] Misma seña con datos fonológicos distintos entre diccionarios

<details><summary>SQL</summary>

```sql
SELECT a.id_sena, k AS parametro,
       a.datos_fonologicos ->> k AS valor_a, b.datos_fonologicos ->> k AS valor_b
FROM sena_diccionario a
JOIN sena_diccionario b ON b.id_sena = a.id_sena AND b.id_diccionario > a.id_diccionario
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

### <a id="c6"></a>C6. Buscar una seña por su código

<details><summary>SQL</summary>

```sql
SELECT jsonb_pretty(sdc.datos_fonologicos) AS datos_fonologicos
FROM sena_diccionario sdc
WHERE sdc.datos_fonologicos ->> 'codigo' = 'B-P 3';
```

</details>

| datos_fonologicos |
|---|
| { "codigo": "B-P 3", "pagina": 1, "tipo_sena": "SC: I. SM; II. SB", "ubicacion": "I. La mano inicia sobre el pecho y se desliza hacia enfrente; II. Del pecho al rostro.", "definic… |

*1 fila.*

## D. Fonología (datos_fonologicos)

### <a id="d1"></a>D1. Señas con una configuración exacta

<details><summary>SQL</summary>

```sql
SELECT sdc.datos_fonologicos ->> 'codigo'      AS codigo,
       sdc.datos_fonologicos ->> 'significado' AS significado,
       sdc.datos_fonologicos ->> 'ubicacion'   AS ubicacion
FROM sena_diccionario sdc
WHERE sdc.datos_fonologicos @> '{"configuracion": "B-P.2"}'
ORDER BY codigo;
```

</details>

| codigo | significado | ubicacion |
|---|---|---|
| 5-G 7 | Acusar (vas a ver) | A la altura del hombro. |
| B-P 10 | Abrir mente (mente abierta) | A Ia altura de la frente. |
| B-P 103 | Calma | Del pecho a la cintura. |
| B-P 104 | Camote | Sobre el cuello y se desliza hacia el pecho. |
| B-P 110 | Ceder el paso | A la altura del pecho del centro al lado izquierdo. |
| B-P 114 | Clavado | A la altura del pecho. |
| B-P 115 | Clóset (A) | A la altura de los hombros. |
| B-P 124 | Confesar 1 / Confesión 2 (B) | Sobre el pecho. |
| B-P 125 | Confiar 1 / Confianza 2 | Sobre el pecho. |
| B-P 13 | Activo, -a | Sobre la frente. |
| B-P 130 | Convencer (A) | Del pecho al cuello. |
| B-P 131 | Convencer (B) | MD y MB a la altura del cuello. |
| B-P 143 | Dadivoso, sa | A la altura del plexo, MD sobre MB. |
| B-P 145 | Defender – Proteger 1 (B) / Bloquear 2 | A la altura de los hombros. MD delante de MB. |
| B-P 147 | Delfín | A la altura del pecho. del lado derecho al izquierdo. |
| B-P 148 | Despedir 1 - Correr 2 (A) | Del hombro al rostro. |
| B-P 15 | Adorar | Del rostro a la cintura. |
| B-P 151 | Dieta | Del pecho a la cadera. |
| B-P 152 | Distraído, da 1 / Distraer 2 | A la altura del cuello. |
| B-P 154 | Doble cara – Hipócrita | De la barbilla a la nuca. |

*Se muestran 20 de 58 filas.*

### <a id="d2"></a>D2. Varias condiciones a la vez (usa el índice GIN)

<details><summary>SQL</summary>

```sql
SELECT sdc.datos_fonologicos ->> 'codigo'      AS codigo,
       sdc.datos_fonologicos ->> 'significado' AS significado
FROM sena_diccionario sdc
WHERE sdc.datos_fonologicos @> '{"configuracion": "A.1", "ubicacion": "A la altura del pecho."}';
```

</details>

| codigo | significado |
|---|---|
| A-5 | A salvo |
| A-2 | ¡Excelente! |
| A-30 | Alcohólicos Anónimos |
| A-43 | Antiguo, gua 1 / Antiguamente 2 |
| A-55 | Arroba |
| A-62 | Asociación |
| A-88 | Canadá (B) (SSI) |
| A-103 | Con |
| A-110 | Contigo (B) |
| A-117 | Eludir |
| A-149 | Pan |
| A-163 | Relación sexual 1 / Apareamiento 2 |
| A-169 | Separar – Terminar (relación de novios) |

*13 filas.*

### <a id="d3"></a>D3. Búsqueda de texto dentro de un parámetro (configuraciones que usan B-P.2)

<details><summary>SQL</summary>

```sql
SELECT sdc.datos_fonologicos ->> 'codigo'        AS codigo,
       sdc.datos_fonologicos ->> 'significado'   AS significado,
       sdc.datos_fonologicos ->> 'configuracion' AS configuracion
FROM sena_diccionario sdc
WHERE sdc.datos_fonologicos ->> 'configuracion' ILIKE '%B-P.2%'
ORDER BY codigo;
```

</details>

| codigo | significado | configuracion |
|---|---|---|
| 5-G 105 | Reunión (Isla de Francia) (SSI) | MD seña que pasa de 5.1 a S.1, MB B-P.2, S.1 |
| 5-G 34 | Asar (A) | MD 5.1, MB B-P.2 |
| 5-G 48 | Bloqueador solar | I. 5.1; II. MD B-P.2, MB B-P.1; 5.10III. MD y MB B-P.1 |
| 5-G 53 | Bosque 1 / Popotla 2 (STC Metro) | MD 5.1, MB B-P.2 |
| 5-G 59 | Calculadora | MD 5.13, MB B-P.2 |
| 5-G 7 | Acusar (vas a ver) | B-P.2 |
| 5-G 85 | De contado | I. MD 5.25, MB B-P.2; II. MD 5.12, MB B-P.2 |
| 5-G 87 | Detenido, -a – Arrestado, -a 1 / Arrestar 2 | I. Seña que pasa de 5.16 a S.1; II. MD S.1, MB B-P.2; III. MD y MB 5.1 |
| 5-G 96 | Palacio de los Deportes | I. MD 5.16, MB B-P.2; II. MD y MB D.2 |
| 5-G 97 | Pantera | I. 5.18; II. MD U.3, MB B-P.2 |
| A-100 | Ciudad de México | I. MD A.1, MB B-P.2; II. 2.1 |
| A-125 | Huella | MD A.1, MB B-P.2 |
| A-129 | Irán (SSI) | MD A.1, MB B-P.2 |
| A-13 | Acta | MD A.1, MB B-P.2 |
| A-137 | Marca | MD A.1, MB B-P.2 |
| A-14 | Acta de demanda 1 2 | I. MD A.1, MB B-P.2; II. MD y MB B-P.2 |
| A-141 | Mensualidad 1 / Mensual 2 | MD A.1, MB B-P.2 |
| A-142 | Mes | MD A.1, MB B-P.2 |
| A-143 | Mesa (B) | MD A.1, MB B-P.2 |
| A-15 | Acta de nacimiento | I. MD A.1, MB B-P.2; II. B-P.7 |

*Se muestran 20 de 247 filas.*

### <a id="d4"></a>D4. Rasgos no manuales que mencionan las cejas

<details><summary>SQL</summary>

```sql
SELECT sdc.datos_fonologicos ->> 'significado'        AS significado,
       sdc.datos_fonologicos ->> 'rasgos_no_manuales' AS rasgos
FROM sena_diccionario sdc
WHERE sdc.datos_fonologicos ->> 'rasgos_no_manuales' ILIKE '%ceja%'
ORDER BY significado;
```

</details>

| significado | rasgos |
|---|---|
| Abarrotado, da | Cejas hacia arriba, mejillas infladas. |
| Aprovecharse de | Cejas hacia arriba, ojos abiertos, boca abierta mostrando los dientes. |
| Asalto (A) | Cabeza hacia atrás, cejas hacia arriba, boca abierta y mostrando los dientes. |
| Ceder el paso | Cejas hacia arriba, cabeza ladeada hacia la derecha. |
| Confirmación | Cejas hacia arriba, se esboza una sonrisa. |
| Descubrir 1 / Ya me di cuenta – Percatarse 2 (A) | Cejas hacia arriba, boca abierta. |
| Difundir | Cabeza atrás, cejas arriba. |
| No gustar | Cejas hacia arriba, ceño fruncido. |
| Patrulla | Cejas hacia arriba, ojos inusualmente abiertos, mejillas infladas. |
| Prender – Encender | Cejas hacia arriba. |
| ¡Qué padre! – ¡Qué chido! | Cabeza inclinada, cejas hacia arriba, boca semiabierta. |
| ¿Cuántos? (A) | Cabeza hacia atrás, ceño fruncido, cejas arriba. |
| ¿Cuántos? (B) | Cabeza hacia atrás, ceño fruncido, cejas arriba. |
| ¿Y eso? | Cejas hacia arriba, comisuras de los labios ligeramente hacia abajo. |

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
    SELECT sdc.id_sena,
           sdc.datos_fonologicos ->> 'codigo'      AS codigo,
           sdc.datos_fonologicos ->> 'significado' AS significado,
           COALESCE(sdc.datos_fonologicos ->> 'configuracion', '') AS c,
           COALESCE(sdc.datos_fonologicos ->> 'ubicacion', '')     AS u,
           COALESCE(sdc.datos_fonologicos ->> 'movimiento', '')    AS m,
           COALESCE(sdc.datos_fonologicos ->> 'orientacion', '')   AS o
    FROM sena_diccionario sdc
)
SELECT a.significado AS sena_a, b.significado AS sena_b,
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
| A salvo | Asociación | movimiento: Recto hacia el frente. / Las manos se mueven formando un círculo hacia enfrente. |
| A salvo | Contigo (B) | orientacion: Palmas hacia afuera. / Las palmas se encuentran frente a frente. |
| A salvo | Lujo1 / Lujoso, sa2 | configuracion: A.1 / L.1 |
| Abrazar | Alegría 1 / Disfrutar 2 / Celebrar 3 / Divertido, da 4 | movimiento: Las manos golpean los hombros repetidamente. / De atrás hacia adelante flexionando sólo las muñecas alternadamente. |
| Abrazar | Confesar 1 / Confesión 2 (B) | movimiento: Las manos golpean los hombros repetidamente. / Las manos se mueven formando círculos hacia enfrente repetidamente. |
| Abrazar | Confiar 1 / Confianza 2 | movimiento: Las manos golpean los hombros repetidamente. / Las manos se mueven formando un arco hacia el frente. |
| Acta | Centro | movimiento: La MD se mueve formando un círculo y después golpea a la MB en línea recta. / La MD se mueve formando un círculo y golpea a la MB. |
| Acta | Huella | movimiento: La MD se mueve formando un círculo y después golpea a la MB en línea recta. / El dedo pulgar de la MD presiona la palma de la MB. |
| Acta | Suspender | movimiento: La MD se mueve formando un círculo y después golpea a la MB en línea recta. / MD recto hacia el frente. |
| Acta | África (LSM) | movimiento: La MD se mueve formando un círculo y después golpea a la MB en línea recta. / La MD simula un salto de los dedos a la muñeca de MB. |
| Adiós (A) | Sal (A) | configuracion: 5.1 / S.1 |
| Alcohólicos Anónimos | Arroba | movimiento: La mano simula un salto de izquierda a derecha. / La mano se mueve formando un círculo. |
| Alegría 1 / Disfrutar 2 / Celebrar 3 / Divertido, da 4 | Confesar 1 / Confesión 2 (B) | movimiento: De atrás hacia adelante flexionando sólo las muñecas alternadamente. / Las manos se mueven formando círculos hacia enfrente repetidamente. |
| Alegría 1 / Disfrutar 2 / Celebrar 3 / Divertido, da 4 | Confiar 1 / Confianza 2 | movimiento: De atrás hacia adelante flexionando sólo las muñecas alternadamente. / Las manos se mueven formando un arco hacia el frente. |
| Alma | Descubrir 1 / Ya me di cuenta – Percatarse 2 (B) | ubicacion: A la altura de la boca. / A la altura de la frente. |
| Alma | Feo, a | ubicacion: A la altura de la boca. / A la altura de la cara. |
| Alma | Lengua | movimiento: Recto hacia el frente. / La mano se mueve formando círculos. |
| Alto | Empujar | orientacion: Palma hacia afuera. / Palmas hacia afuera. |
| Alumno, na | Apóstoles (A) | ubicacion: A la altura de la boca. / A la altura de la frente. |
| Analfabeto, ta | Ayer | ubicacion: Inicia sobre la barbilla y termina sobre la frente. / Inicia sobre la barbilla y termina sobre la mejilla. |

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
SELECT sdc.datos_fonologicos ->> 'codigo'      AS codigo,
       sdc.datos_fonologicos ->> 'significado' AS significado,
       sdc.datos_fonologicos ->> 'tipo_sena'   AS partes
FROM sena s
JOIN tipo_sena t          ON t.id_tipo_sena = s.id_tipo
JOIN sena_diccionario sdc ON sdc.id_sena = s.id_sena
WHERE t.tipo = 'SC'
ORDER BY codigo;
```

</details>

| codigo | significado | partes |
|---|---|---|
| 5-G 10 | Adulterio | SC: I. SS; II. SM |
| 5-G 100 | Portero, ra | SC: I. SB; II. SS |
| 5-G 21 | Amante | SC: I. SM; II. SB |
| 5-G 30 | Arena de mar | SC: I. SB; II. SS |
| 5-G 42 | Balón 1 / Pelota 2 | SC: I. SS; II. SM |
| 5-G 43 | Baloncesto – Basquetbol 1 / Encestar 2 | SC: I. y II. SM |
| 5-G 48 | Bloqueador solar | SC: I. SM; II. y III. SB |
| 5-G 50 | Boliche | SC: I. SS; II. SM |
| 5-G 55 | Buceo | SC: I. SM; II. SB |
| 5-G 75 | Cómplice | SC: I. y II. SB |
| 5-G 84 | Cosechar 1 / Recolectar 2 | SC: I. y II. SB |
| 5-G 85 | De contado | SC: I. y II. SB |
| 5-G 87 | Detenido, -a – Arrestado, -a 1 / Arrestar 2 | SC: I. SM; II. SB; III. SB |
| 5-G 96 | Palacio de los Deportes | SC: I. y II. SB |
| 5-G 97 | Pantera | SC: I. SM; II. SB |
| A-10 | Abuela 1 2 | SC: I. SB; II. SM |
| A-100 | Ciudad de México | SC: I. SB; II. SM |
| A-104 | Concuño 1 2 | SC: I. y II. SS |
| A-105 | Conmigo (A) | SC: I. y II. SS |
| A-106 | Conmigo (B) | SC: I. SS; II. SM |

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
| I. SB y II. SB | 1 |
| SC: I. SM y II. SM | 1 |
| I. y II. SM | 1 |
| SC: I. SM; II. SB; III. SB | 1 |
| SC: I.SB; II. SS | 1 |
| I. y II.SM | 1 |
| SC: I. y II.SB | 1 |

*Se muestran 20 de 32 filas.*

## F. Videos y señantes

### <a id="f1"></a>F1. [VACÍA HOY: no hay videos] Videos de una seña, con su señante

<details><summary>SQL</summary>

```sql
SELECT sdc.datos_fonologicos ->> 'codigo' AS codigo, v.path, v.tipo_de_toma, v.mano_dominante,
       st.id_senante, st.perfil_nativo
FROM sena_diccionario sdc
JOIN sena_video sv ON sv.id_sena_diccionario = sdc.id_sena_diccionario
JOIN video v       ON v.id_video = sv.id_video
JOIN senante st    ON st.id_senante = v.id_senante
WHERE sdc.datos_fonologicos ->> 'codigo' = 'B-P 3';
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
SELECT sdc.datos_fonologicos ->> 'codigo' AS codigo, COUNT(DISTINCT v.id_senante) AS num_senantes
FROM sena_diccionario sdc
JOIN sena_video sv ON sv.id_sena_diccionario = sdc.id_sena_diccionario
JOIN video v       ON v.id_video = sv.id_video
GROUP BY 1
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

*1 fila.*

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
| 1006 | 1006 | 1006 | 0 | 1006 | 0 | 1005 |

*1 fila.*

### <a id="h2"></a>H2. Señas sin tipo

<details><summary>SQL</summary>

```sql
SELECT s.id_sena, sdc.datos_fonologicos ->> 'codigo' AS codigo, sdc.datos_fonologicos ->> 'tipo_sena' AS tipo_original
FROM sena s
JOIN sena_diccionario sdc ON sdc.id_sena = s.id_sena
WHERE s.id_tipo IS NULL;
```

</details>

| id_sena | codigo | tipo_original |
|---|---|---|
| 1003 | O-80 | MB |

*1 fila.*

### <a id="h3"></a>H3. Señas sin movimiento u orientación en el diccionario

<details><summary>SQL</summary>

```sql
SELECT sdc.datos_fonologicos ->> 'codigo'      AS codigo,
       sdc.datos_fonologicos ->> 'significado' AS significado,
       NOT sdc.datos_fonologicos ? 'movimiento'  AS sin_movimiento,
       NOT sdc.datos_fonologicos ? 'orientacion' AS sin_orientacion
FROM sena_diccionario sdc
WHERE NOT sdc.datos_fonologicos ?& ARRAY['movimiento', 'orientacion']
ORDER BY codigo;
```

</details>

| codigo | significado | sin_movimiento | sin_orientacion |
|---|---|---|---|
| 5-G 22 | Amar 1 / Amor 2 | t | f |
| 5-G 39 | Audífonos | t | f |
| 5-G 63 | Capitán | t | f |
| 5-G 65 | Cargar | t | f |
| A-136 | Mamila 1 / Chupón 2 | t | f |
| A-51 | Ardilla | t | f |
| A-90 | Centroamérica (SSI) | t | f |
| B-P 123 | Confesar 1 / Confesión 2 (A) | t | f |
| B-P 229 | Pingüino | t | f |
| B-P 232 | Prometer 1 / Promesa 2 | t | f |
| C-78 | CPU (Gabinete) | t | f |
| C-88 | Escuchar | t | f |
| L-119 | LSM | t | t |
| L-160 | Vagina | t | f |
| L-54 | Gel | t | f |
| L-85 | Inglés | t | f |
| L-86 | Inglaterra | t | f |
| O-61 | Oro (A) | t | f |
| S-127 | Tepito (STC Metro) | t | f |
| S-50 | Estornudar | t | f |

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
       STRING_AGG(sdc.datos_fonologicos ->> 'significado', ' | ') AS significados
FROM sena_diccionario sdc
GROUP BY 1
HAVING COUNT(*) > 1;
```

</details>

| codigo | veces | significados |
|---|---|---|
| C-84 | 2 | Cuba 1 (LSM) / Cuba 2 (bebida) \| Enfermera (A) |

*1 fila.*

### <a id="i2"></a>I2. [CONTROL: vacía = sin problemas] Significados repetidos (posibles variantes o duplicados)

<details><summary>SQL</summary>

```sql
SELECT sdc.datos_fonologicos ->> 'significado' AS significado, COUNT(*) AS veces,
       STRING_AGG(sdc.datos_fonologicos ->> 'codigo', ', ') AS codigos
FROM sena_diccionario sdc
GROUP BY 1
HAVING COUNT(*) > 1
ORDER BY significado;
```

</details>

| significado | veces | codigos |
|---|---|---|
| Abandonar | 2 | A-7, C-1 |
| Adorar | 2 | B-P 15, A-21 |
| Constitución | 2 | S-35, C-72 |
| Separar – Terminar (relación de novios) | 2 | A-168, A-169 |
| Vagina | 2 | A-180, L-160 |

*5 filas.*

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

### <a id="i4"></a>I4. [CONTROL: vacía = sin problemas] Palabras duplicadas (misma palabra y lengua dos veces)

<details><summary>SQL</summary>

```sql
SELECT LOWER(palabra) AS palabra, id_lengua, COUNT(*)
FROM palabra
GROUP BY LOWER(palabra), id_lengua
HAVING COUNT(*) > 1;
```

</details>

**Sin resultados (0 filas).**

### <a id="i5"></a>I5. [CONTROL: vacía = sin problemas] Tipo de sena.id_tipo que no coincide con el tipo del JSON

<details><summary>SQL</summary>

```sql
SELECT sdc.datos_fonologicos ->> 'codigo' AS codigo, t.tipo, sdc.datos_fonologicos ->> 'tipo_sena' AS tipo_json
FROM sena s
JOIN tipo_sena t          ON t.id_tipo_sena = s.id_tipo
JOIN sena_diccionario sdc ON sdc.id_sena = s.id_sena
WHERE t.tipo <> 'SC' AND t.tipo <> sdc.datos_fonologicos ->> 'tipo_sena';
```

</details>

**Sin resultados (0 filas).**

## J. Ficha completa de una seña

### <a id="j1"></a>J1. Todo lo que se sabe de una seña en una sola fila

<details><summary>SQL</summary>

```sql
SELECT sdc.datos_fonologicos ->> 'codigo' AS codigo,
       l.nombre_completo AS lengua,
       t.tipo,
       (SELECT STRING_AGG(p.palabra, ', ') FROM sena_palabra x JOIN palabra p USING (id_palabra) WHERE x.id_sena = s.id_sena) AS palabras,
       (SELECT STRING_AGG(d.definicion, ' | ') FROM sena_definicion x JOIN definicion d USING (id_definicion) WHERE x.id_sena = s.id_sena) AS definiciones,
       dic.nombre_completo AS diccionario,
       sdc.datos_fonologicos ->> 'configuracion' AS configuracion,
       sdc.datos_fonologicos ->> 'ubicacion'     AS ubicacion,
       sdc.datos_fonologicos ->> 'movimiento'    AS movimiento
FROM sena s
JOIN lengua l             ON l.id_lengua = s.id_lengua
LEFT JOIN tipo_sena t     ON t.id_tipo_sena = s.id_tipo
JOIN sena_diccionario sdc ON sdc.id_sena = s.id_sena
JOIN diccionario dic      ON dic.id_diccionario = sdc.id_diccionario
WHERE sdc.datos_fonologicos ->> 'codigo' = 'B-P 4';
```

</details>

| codigo | lengua | tipo | palabras | definiciones | diccionario | configuracion | ubicacion | movimiento |
|---|---|---|---|---|---|---|---|---|
| B-P 4 | Lengua de Señas Mexicana | SB | Abajo, Debajo | 1. adv. En el lugar o parte inferior. 2. adv. En la parte inferior o interna de algo y cubierto por ello. | Diccionario de Lengua de Señas Mexicana de la Ciudad de México (DLSM, 2017) | MD y MB B-P.6 | MD inicia sobre MB y termina a la altura de la cintura, MB a la altura del pecho. | La MD se mueve formando un arco. |

*1 fila.*

## K. Temas del diccionario

### <a id="k1"></a>K1. Señas con nota cultural

<details><summary>SQL</summary>

```sql
SELECT sdc.datos_fonologicos ->> 'significado'   AS significado,
       sdc.datos_fonologicos ->> 'nota_cultural' AS nota_cultural
FROM sena_diccionario sdc
WHERE sdc.datos_fonologicos ? 'nota_cultural'
ORDER BY significado;
```

</details>

| significado | nota_cultural |
|---|---|
| Abandonar(C) | Esta seña connota una actitud despectiva |
| Activo, -a | La seña se usa para la comunidad sorda LGBTTTI. |
| Adorar | La seña se usa en la comunidad sorda de los Testigos de Jehová. |
| Adorar | La seña se usa en la comunidad sorda cristiana y mormona. |
| Adventista 1 – Iglesia Adventista del Séptimo Día 2 | La seña se usa en la comunidad sorda adventista. |
| Adán (A) | La seña se usa en la comunidad sorda católica, cristiana y de los Testigos de Jehová. |
| Adán (B) | La seña se usa en la comunidad sorda mormona. |
| Alabanza 1 /Alabar 2 | La seña se usa en la comunidad sorda católica. |
| Alabar 1 / Alabanza 2 | La seña se usa en la comunidad sorda Amistad Cristiana e Iglesia de Cristo. |
| Aleluya | La seña se usa en la comunidad sorda Amistad Cristiana e Iglesia de Cristo. |
| Altar | La seña se usa en la comunidad sorda mormona. |
| Alumno, na | El género femenino se articula con ALUMNO + MUJER. |
| Amén (A) | La seña se usa en la comunidad sorda católica. |
| Amén (B) | la seña se usa en la comunidad sorda cristiana. |
| Anciano | La seña se usa en la comunidad sorda del Testigo de Je hová. |
| Antropología | La seña se usa en la comunidad sorda catolica. |
| Apocalipsis (B) | la seña se usa en la comunidad sorda mormona. |
| Aprovechar | Generalmente se acompaña de la emisión de un clic bilabial o lengua vibratoria dependiendo de su contexto.. |
| Apóstol | la seña se usa en la comunidad sorda de los Testigos de Jehová. |
| Apóstoles (A) | La seña se usa en la comunidad sorda católica. |

*Se muestran 20 de 42 filas.*

### <a id="k2"></a>K2. Señas con representación (qué imitan)

<details><summary>SQL</summary>

```sql
SELECT sdc.datos_fonologicos ->> 'significado'    AS significado,
       sdc.datos_fonologicos ->> 'representacion' AS representacion
FROM sena_diccionario sdc
WHERE sdc.datos_fonologicos ? 'representacion'
ORDER BY significado;
```

</details>

| significado | representacion |
|---|---|
| Abajo – Debajo | Simula la acción de poner algo debajo de otra cosa. |
| Abofetear (A) | Simula la acción de abofetear a alguien. |
| Abofetear (B) | Simula la acción de abofetear a alguien. |
| Abrazar | Simula la acción de abrazar a alguien. |
| Acceso 1 / Accesibilidad 2 | Simula la acción de entrar a un lugar. |
| Accidente | Simula la acción de herirse. |
| Acné – Barro– Espinilla | Simula la acción de exprimir un barro o una espinilla. |
| Acta | Simula la acción de sellar un documento |
| Acta de demanda 1 2 | Simula la acción de sellar un documento. |
| Acta de nacimiento | Simula la acción de sellar un documento y cargar a un bebé. |
| Almeja | Simula el abrir de una almeja. |
| Almohada (B) | Simula la acción de apretar una almohada. |
| Almohada (C) | Simula la acción de apretar una almohada detrás de la cabeza. |
| Altar | Simula la forma de un altar. |
| Alto, ta | Simula la altura de una persona. |
| Amanecer | Simula el sol saliendo por el horizonte. |
| Ametralladora – Metralleta | Simula la acción de disparar con una ametralladora o metralleta. |
| Amén (A) | Simula la imagen de la cruz. |
| América (SSI) | Simula la forma del continente americano. |
| Andar – Caminar | Simula la acción de caminar. |

*Se muestran 20 de 160 filas.*

### <a id="k3"></a>K3. Estaciones del Metro (STC Metro)

<details><summary>SQL</summary>

```sql
SELECT sdc.datos_fonologicos ->> 'codigo'      AS codigo,
       sdc.datos_fonologicos ->> 'significado' AS significado
FROM sena_diccionario sdc
WHERE sdc.datos_fonologicos ->> 'significado' LIKE '%(STC Metro)%'
ORDER BY codigo;
```

</details>

| codigo | significado |
|---|---|
| 5-G 41 | Azteca 1 / Cuauhtémoc 2 3 (STC Metro) |
| 5-G 53 | Bosque 1 / Popotla 2 (STC Metro) |
| B-P 63 | Bandera 1 (A) / Pantitlán 2 (STC Metro) / Patriotismo 3 (STC Metro) |
| B-P 99 | Buenavista(STC Metro) |
| C-46 | Chabacano (A) (STC Metro) |
| C-47 | Chabacano 1 (B) (STC Metro) / Lázaro Cárdenas 2 3 (STC Metro) |
| C-58 | Ciudad Deportiva (STC Metro) |
| L-122 | Luna1 / Taxqueña2 (STC Metro) |
| S-127 | Tepito (STC Metro) |
| S-78 | Nativitas (STC Metro) |

*10 filas.*

### <a id="k4"></a>K4. Señas de lugares internacionales (SSI)

<details><summary>SQL</summary>

```sql
SELECT sdc.datos_fonologicos ->> 'codigo'      AS codigo,
       sdc.datos_fonologicos ->> 'significado' AS significado
FROM sena_diccionario sdc
WHERE sdc.datos_fonologicos ->> 'significado' LIKE '%(SSI)%'
ORDER BY codigo;
```

</details>

| codigo | significado |
|---|---|
| 5-G 105 | Reunión (Isla de Francia) (SSI) |
| 5-G 12 | África (SSI) |
| 5-G 14 | Albania (SSI) |
| 5-G 31 | Argentina (SSI) |
| 5-G 44 | Bangladesh (SSI) |
| 5-G 61 | Camboya (SSI) |
| A-121 | Estonia (SSI) |
| A-123 | Etiopía (SSI) |
| A-127 | India (SSI) |
| A-129 | Irán (SSI) |
| A-130 | Islandia (SSI) |
| A-173 | Sudán (SSI) |
| A-61 | Asia (SSI) (B) |
| A-88 | Canadá (B) (SSI) |
| A-90 | Centroamérica (SSI) |
| B-P 134 | Corea del Norte (SSI) |
| B-P 135 | Corea del Sur (SSI) |
| B-P 142 | Cuba (SSI) |
| B-P 156 | Egipcio 1 / Egipto 2 (SSI) |
| B-P 182 | Jamaica (SSI) |

*Se muestran 20 de 48 filas.*

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
SELECT sdc.datos_fonologicos ->> 'significado' AS significado, d.definicion
FROM definicion d
JOIN sena_definicion x    ON x.id_definicion = d.id_definicion
JOIN sena_diccionario sdc ON sdc.id_sena = x.id_sena
WHERE d.definicion ILIKE '%comida%'
ORDER BY significado;
```

</details>

| significado | definicion |
|---|---|
| Carl´s Jr. ® | sust. Cadena de restaurantes de hamburguesas y comida rápida cuya sede central se localiza en Estados Unidos. |
| Cenar 1 / Cena 2 | 1. v. intr. Comer por la noche. 2. sust. f. Última comida del día que se toma al atardecer o por la noche. |
| Chimenea | sust. f. Construcción doméstica terminada en un conducto vertical que lleva al exterior el humo producido por la leña que se puso en su base para cuecer la comida o calentar la ca… |
| Cocinar 1 / Cocina 2 | 1. v. tr. Preparar los alimentos cociéndolos en el fuego. 2. sust. f. Pieza o sitio de la casa en el cual se guisa la comida. |
| Desayunar 1 / Desayuno 2 | 1. v. tr. Tomar la primera comida del día que generalmente es ligera y se hace por la mañana. 2. sust. Primera comida del día generalmente ligera que se toma por la mañana. |
| Mancha | sust. f. Porción de alguna cosa, como una gota de líquido, un fragmento de comida, etc. que ensucia o echa a perder una cosa por ser de apariencia o color distinto del que domina … |

*6 filas.*
