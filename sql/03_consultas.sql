-- =====================================================================
-- LSM_DB - Catálogo de consultas
-- Ejecutar después de 01_schema.sql y 02_datos_dlsm_cdmx.sql.
--
-- Los valores entre comillas ('Casa', 'B-P 3', 'A.1', ...) son
-- parámetros de ejemplo: cámbialos por lo que quieras buscar.
-- Las palabras se comparan con LOWER() para no depender de mayúsculas.
--
-- Algunas consultas salen vacías con los datos actuales porque la base
-- todavía no tiene esa información (inglés, ASL, glosas, videos o un
-- segundo diccionario). Están marcadas con [VACÍA HOY] y dicen qué falta.
-- Las salidas de todas están en docs/SALIDAS.md.
-- =====================================================================
SET search_path TO lsm;

-- =====================================================================
-- A. PALABRAS, TRADUCCIÓN Y DEFINICIONES
-- La SEÑA es el pivote: palabras y definiciones de cualquier idioma
-- solo se unen a través de ella.
-- =====================================================================

-- A1. Seña(s) de una palabra, con su código y significado en el diccionario
SELECT p.palabra,
       sdc.datos_fonologicos ->> 'codigo'      AS codigo,
       sdc.datos_fonologicos ->> 'significado' AS significado
FROM palabra p
JOIN sena_palabra sp      ON sp.id_palabra = p.id_palabra
JOIN sena_diccionario sdc ON sdc.id_sena = sp.id_sena
WHERE LOWER(p.palabra) = LOWER('Casa');

-- A2. Todas las palabras ligadas a una seña (por código)
SELECT sdc.datos_fonologicos ->> 'codigo' AS codigo, p.palabra, l.nombre_completo AS idioma
FROM sena_diccionario sdc
JOIN sena_palabra sp ON sp.id_sena = sdc.id_sena
JOIN palabra p       ON p.id_palabra = sp.id_palabra
JOIN lengua l        ON l.id_lengua = p.id_lengua
WHERE sdc.datos_fonologicos ->> 'codigo' = '5-G 51';

-- A3. [VACÍA HOY: falta cargar palabras en inglés]
--     Traducir una palabra de español a inglés a través de la seña
SELECT DISTINCT origen.palabra AS espanol, destino.palabra AS ingles
FROM palabra origen
JOIN sena_palabra sp1 ON sp1.id_palabra = origen.id_palabra
JOIN sena_palabra sp2 ON sp2.id_sena    = sp1.id_sena
JOIN palabra destino  ON destino.id_palabra = sp2.id_palabra
WHERE LOWER(origen.palabra) = LOWER('Casa')
  AND origen.id_lengua  = (SELECT id_lengua FROM lengua WHERE nombre_completo = 'Español')
  AND destino.id_lengua = (SELECT id_lengua FROM lengua WHERE nombre_completo = 'Inglés');

-- A4. [VACÍA HOY: falta cargar definiciones en inglés]
--     Definición en inglés de una palabra en español
--     palabra(es) -> sena_palabra -> sena -> sena_definicion -> definicion(en)
SELECT DISTINCT p.palabra, d.definicion
FROM palabra p
JOIN sena_palabra sp    ON sp.id_palabra = p.id_palabra
JOIN sena_definicion sd ON sd.id_sena    = sp.id_sena
JOIN definicion d       ON d.id_definicion = sd.id_definicion
WHERE LOWER(p.palabra) = LOWER('Hola')
  AND p.id_lengua = (SELECT id_lengua FROM lengua WHERE nombre_completo = 'Español')
  AND d.id_lengua = (SELECT id_lengua FROM lengua WHERE nombre_completo = 'Inglés');

-- A5. Definición en español de una palabra (misma ruta que A4)
SELECT p.palabra, sdc.datos_fonologicos ->> 'codigo' AS codigo, d.definicion
FROM palabra p
JOIN sena_palabra sp      ON sp.id_palabra = p.id_palabra
JOIN sena_definicion sd   ON sd.id_sena = sp.id_sena
JOIN definicion d         ON d.id_definicion = sd.id_definicion
JOIN sena_diccionario sdc ON sdc.id_sena = sp.id_sena
WHERE LOWER(p.palabra) = LOWER('Banco')
  AND d.id_lengua = (SELECT id_lengua FROM lengua WHERE nombre_completo = 'Español');

-- A6. Palabras con varias señas (variantes A/B o sentidos distintos)
SELECT p.palabra, COUNT(*) AS num_senas,
       STRING_AGG(sdc.datos_fonologicos ->> 'codigo', ', ' ORDER BY sdc.datos_fonologicos ->> 'codigo') AS codigos
FROM palabra p
JOIN sena_palabra sp      ON sp.id_palabra = p.id_palabra
JOIN sena_diccionario sdc ON sdc.id_sena = sp.id_sena
GROUP BY p.palabra
HAVING COUNT(*) > 1
ORDER BY num_senas DESC, p.palabra;

-- A7. Sinónimos: palabras que comparten la misma seña
SELECT sdc.datos_fonologicos ->> 'codigo' AS codigo,
       STRING_AGG(p.palabra, ' / ' ORDER BY p.palabra) AS palabras
FROM sena_diccionario sdc
JOIN sena_palabra sp ON sp.id_sena = sdc.id_sena
JOIN palabra p       ON p.id_palabra = sp.id_palabra
GROUP BY sdc.id_sena, codigo
HAVING COUNT(*) > 1
ORDER BY COUNT(*) DESC, codigo;

-- =====================================================================
-- B. LENGUAS
-- =====================================================================

-- B1. [VACÍA HOY: falta cargar una segunda lengua de señas, p. ej. ASL]
--     Equivalente en otra lengua de señas por palabra compartida
SELECT DISTINCT a.datos_fonologicos ->> 'codigo' AS lsm, b.datos_fonologicos ->> 'codigo' AS otra, p.palabra
FROM sena_diccionario a
JOIN sena_palabra sp1 ON sp1.id_sena = a.id_sena
JOIN palabra p        ON p.id_palabra = sp1.id_palabra
JOIN sena_palabra sp2 ON sp2.id_palabra = p.id_palabra AND sp2.id_sena <> sp1.id_sena
JOIN sena s2          ON s2.id_sena = sp2.id_sena
JOIN sena_diccionario b ON b.id_sena = s2.id_sena
WHERE s2.id_lengua = (SELECT id_lengua FROM lengua WHERE nombre_completo = 'American Sign Language');

-- B2. Señas por lengua de señas
SELECT l.nombre_completo, COUNT(s.id_sena) AS num_senas
FROM lengua l
LEFT JOIN sena s ON s.id_lengua = l.id_lengua
WHERE l.modalidad = 'viso-gestual'
GROUP BY l.nombre_completo;

-- B3. Palabras, glosas y definiciones por lengua
SELECT l.nombre_completo,
       (SELECT COUNT(*) FROM palabra    p WHERE p.id_lengua = l.id_lengua) AS palabras,
       (SELECT COUNT(*) FROM glosa      g WHERE g.id_lengua = l.id_lengua) AS glosas,
       (SELECT COUNT(*) FROM definicion d WHERE d.id_lengua = l.id_lengua) AS definiciones
FROM lengua l
ORDER BY l.id_lengua;

-- =====================================================================
-- C. DICCIONARIOS
-- =====================================================================

-- C1. Datos del diccionario
SELECT id_diccionario, completo, autor FROM diccionario;

-- C2. Número de señas por diccionario
SELECT dic.completo, COUNT(sdc.id_sena) AS num_senas
FROM diccionario dic
LEFT JOIN sena_diccionario sdc ON sdc.id_diccionario = dic.id_diccionario
GROUP BY dic.completo
ORDER BY num_senas DESC;

-- C3. Contenido del diccionario por página del PDF
SELECT (sdc.datos_fonologicos ->> 'pagina')::int AS pagina,
       sdc.datos_fonologicos ->> 'codigo'        AS codigo,
       sdc.datos_fonologicos ->> 'significado'   AS significado
FROM sena_diccionario sdc
WHERE (sdc.datos_fonologicos ->> 'pagina')::int BETWEEN 1 AND 2
ORDER BY pagina, sdc.id_sena;

-- C4. [VACÍA HOY: hace falta un segundo diccionario]
--     Misma seña con datos fonológicos distintos entre diccionarios
SELECT a.id_sena, k AS parametro,
       a.datos_fonologicos ->> k AS valor_a, b.datos_fonologicos ->> k AS valor_b
FROM sena_diccionario a
JOIN sena_diccionario b ON b.id_sena = a.id_sena AND b.id_diccionario > a.id_diccionario
CROSS JOIN LATERAL (SELECT jsonb_object_keys(a.datos_fonologicos || b.datos_fonologicos) AS k) keys
WHERE a.datos_fonologicos -> k IS DISTINCT FROM b.datos_fonologicos -> k;

-- C5. Señas por grupo de configuración (prefijo del código: B-P, 5-G, A, L, S, C, O)
SELECT REGEXP_REPLACE(sdc.datos_fonologicos ->> 'codigo', '[- ]?\d+$', '') AS grupo,
       COUNT(*) AS num_senas
FROM sena_diccionario sdc
GROUP BY 1
ORDER BY 2 DESC;

-- C6. Buscar una seña por su código
SELECT jsonb_pretty(sdc.datos_fonologicos) AS datos_fonologicos
FROM sena_diccionario sdc
WHERE sdc.datos_fonologicos ->> 'codigo' = 'B-P 3';

-- =====================================================================
-- D. FONOLOGÍA (datos_fonologicos)
-- =====================================================================

-- D1. Señas con una configuración exacta
SELECT sdc.datos_fonologicos ->> 'codigo'      AS codigo,
       sdc.datos_fonologicos ->> 'significado' AS significado,
       sdc.datos_fonologicos ->> 'ubicacion'   AS ubicacion
FROM sena_diccionario sdc
WHERE sdc.datos_fonologicos @> '{"configuracion": "B-P.2"}'
ORDER BY codigo;

-- D2. Varias condiciones a la vez (usa el índice GIN)
SELECT sdc.datos_fonologicos ->> 'codigo'      AS codigo,
       sdc.datos_fonologicos ->> 'significado' AS significado
FROM sena_diccionario sdc
WHERE sdc.datos_fonologicos @> '{"configuracion": "A.1", "ubicacion": "A la altura del pecho."}';

-- D3. Búsqueda de texto dentro de un parámetro (configuraciones que usan B-P.2)
SELECT sdc.datos_fonologicos ->> 'codigo'        AS codigo,
       sdc.datos_fonologicos ->> 'significado'   AS significado,
       sdc.datos_fonologicos ->> 'configuracion' AS configuracion
FROM sena_diccionario sdc
WHERE sdc.datos_fonologicos ->> 'configuracion' ILIKE '%B-P.2%'
ORDER BY codigo;

-- D4. Rasgos no manuales que mencionan las cejas
SELECT sdc.datos_fonologicos ->> 'significado'        AS significado,
       sdc.datos_fonologicos ->> 'rasgos_no_manuales' AS rasgos
FROM sena_diccionario sdc
WHERE sdc.datos_fonologicos ->> 'rasgos_no_manuales' ILIKE '%ceja%'
ORDER BY significado;

-- D5. Frecuencia de cada configuración
SELECT sdc.datos_fonologicos ->> 'configuracion' AS configuracion, COUNT(*) AS num_senas
FROM sena_diccionario sdc
GROUP BY 1
ORDER BY 2 DESC, 1;

-- D6. Frecuencia de cada ubicación
SELECT sdc.datos_fonologicos ->> 'ubicacion' AS ubicacion, COUNT(*) AS num_senas
FROM sena_diccionario sdc
GROUP BY 1
ORDER BY 2 DESC, 1;

-- D7. Pares mínimos: señas iguales en todo salvo un parámetro
--     Compara el texto exacto de configuración, ubicación, movimiento y orientación;
--     como son descripciones libres, es una aproximación.
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

-- D8. Cobertura de cada campo del JSON
SELECT k AS campo,
       COUNT(*) FILTER (WHERE sdc.datos_fonologicos ? k) AS con_dato,
       COUNT(*) AS total
FROM sena_diccionario sdc
CROSS JOIN UNNEST(ARRAY['codigo', 'significado', 'tipo_sena', 'configuracion', 'ubicacion',
                        'orientacion', 'movimiento', 'rasgos_no_manuales', 'representacion',
                        'definicion', 'nota_cultural', 'pagina']) k
GROUP BY k
ORDER BY con_dato DESC, k;

-- =====================================================================
-- E. TIPO DE SEÑA
-- =====================================================================

-- E1. Señas por tipo (SM, SB, SS, SC)
SELECT COALESCE(t.tipo, '(sin tipo)') AS tipo, COUNT(*) AS num_senas
FROM sena s
LEFT JOIN tipo_sena t ON t.id_tipo_sena = s.id_tipo
GROUP BY 1
ORDER BY 2 DESC;

-- E2. Señas compuestas (SC) con el tipo de cada parte
SELECT sdc.datos_fonologicos ->> 'codigo'      AS codigo,
       sdc.datos_fonologicos ->> 'significado' AS significado,
       sdc.datos_fonologicos ->> 'tipo_sena'   AS partes
FROM sena s
JOIN tipo_sena t          ON t.id_tipo_sena = s.id_tipo
JOIN sena_diccionario sdc ON sdc.id_sena = s.id_sena
WHERE t.tipo = 'SC'
ORDER BY codigo;

-- E3. Combinaciones de partes en las señas compuestas
SELECT sdc.datos_fonologicos ->> 'tipo_sena' AS partes, COUNT(*) AS num_senas
FROM sena s
JOIN tipo_sena t          ON t.id_tipo_sena = s.id_tipo
JOIN sena_diccionario sdc ON sdc.id_sena = s.id_sena
WHERE t.tipo = 'SC'
GROUP BY 1
ORDER BY 2 DESC;

-- =====================================================================
-- F. VIDEOS Y SEÑANTES
-- El diccionario no trae videos ni datos de señantes.
-- =====================================================================

-- F1. [VACÍA HOY: no hay videos]
--     Videos de una seña, con su señante
SELECT sdc.datos_fonologicos ->> 'codigo' AS codigo, v.path, v.tipo_de_toma, v.mano_dominante,
       st.id_senante, st.perfil_nativo
FROM sena_diccionario sdc
JOIN sena_video sv ON sv.id_sena_diccionario = sdc.id_sena_diccionario
JOIN video v       ON v.id_video = sv.id_video
JOIN senante st    ON st.id_senante = v.id_senante
WHERE sdc.datos_fonologicos ->> 'codigo' = 'B-P 3';

-- F2. [VACÍA HOY: no hay videos]
--     Video de una palabra (palabra -> seña -> video)
SELECT DISTINCT p.palabra, v.path
FROM palabra p
JOIN sena_palabra sp      ON sp.id_palabra = p.id_palabra
JOIN sena_diccionario sdc ON sdc.id_sena = sp.id_sena
JOIN sena_video sv        ON sv.id_sena_diccionario = sdc.id_sena_diccionario
JOIN video v              ON v.id_video = sv.id_video
WHERE LOWER(p.palabra) = LOWER('Casa');

-- F3. [VACÍA HOY: no hay señantes]
--     Videos y señas distintas grabadas por cada señante
SELECT st.id_senante, st.edad, st.perfil_nativo,
       COUNT(DISTINCT v.id_video)  AS videos,
       COUNT(DISTINCT sdc.id_sena) AS senas_distintas
FROM senante st
LEFT JOIN video v              ON v.id_senante = st.id_senante
LEFT JOIN sena_video sv        ON sv.id_video = v.id_video
LEFT JOIN sena_diccionario sdc ON sdc.id_sena_diccionario = sv.id_sena_diccionario
GROUP BY st.id_senante, st.edad, st.perfil_nativo
ORDER BY st.id_senante;

-- F4. [VACÍA HOY: no hay videos]
--     Señas grabadas por 2 o más señantes (para estudiar variación)
SELECT sdc.datos_fonologicos ->> 'codigo' AS codigo, COUNT(DISTINCT v.id_senante) AS num_senantes
FROM sena_diccionario sdc
JOIN sena_video sv ON sv.id_sena_diccionario = sdc.id_sena_diccionario
JOIN video v       ON v.id_video = sv.id_video
GROUP BY 1
HAVING COUNT(DISTINCT v.id_senante) > 1;

-- F5. [VACÍA HOY: no hay videos]
--     Videos por mano dominante y tipo de toma
SELECT mano_dominante, tipo_de_toma, COUNT(*) AS videos
FROM video
GROUP BY mano_dominante, tipo_de_toma
ORDER BY mano_dominante, tipo_de_toma;

-- =====================================================================
-- G. AUTORÍA
-- =====================================================================

-- G1. Definiciones y glosas por autor
SELECT autor, 'definicion' AS tipo, COUNT(*) AS total FROM definicion GROUP BY autor
UNION ALL
SELECT autor, 'glosa', COUNT(*) FROM glosa GROUP BY autor
ORDER BY autor, tipo;

-- =====================================================================
-- H. COBERTURA (qué falta por capturar)
-- =====================================================================

-- H1. Resumen: cuántas señas tienen cada cosa
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

-- H2. Señas sin tipo
SELECT s.id_sena, sdc.datos_fonologicos ->> 'codigo' AS codigo, sdc.datos_fonologicos ->> 'tipo_sena' AS tipo_original
FROM sena s
JOIN sena_diccionario sdc ON sdc.id_sena = s.id_sena
WHERE s.id_tipo IS NULL;

-- H3. Señas sin movimiento u orientación en el diccionario
SELECT sdc.datos_fonologicos ->> 'codigo'      AS codigo,
       sdc.datos_fonologicos ->> 'significado' AS significado,
       NOT sdc.datos_fonologicos ? 'movimiento'  AS sin_movimiento,
       NOT sdc.datos_fonologicos ? 'orientacion' AS sin_orientacion
FROM sena_diccionario sdc
WHERE NOT sdc.datos_fonologicos ?& ARRAY['movimiento', 'orientacion']
ORDER BY codigo;

-- H4. [CONTROL: vacía = sin problemas]
--     Palabras sin seña (todas salen del diccionario)
SELECT p.palabra
FROM palabra p
WHERE NOT EXISTS (SELECT 1 FROM sena_palabra sp WHERE sp.id_palabra = p.id_palabra);

-- =====================================================================
-- I. CONTROL DE CONSISTENCIA
-- =====================================================================

-- I1. [CONTROL: vacía = sin problemas]
--     Códigos repetidos en el diccionario
SELECT sdc.datos_fonologicos ->> 'codigo' AS codigo, COUNT(*) AS veces,
       STRING_AGG(sdc.datos_fonologicos ->> 'significado', ' | ') AS significados
FROM sena_diccionario sdc
GROUP BY 1
HAVING COUNT(*) > 1;

-- I2. [CONTROL: vacía = sin problemas]
--     Significados repetidos (posibles variantes o duplicados)
SELECT sdc.datos_fonologicos ->> 'significado' AS significado, COUNT(*) AS veces,
       STRING_AGG(sdc.datos_fonologicos ->> 'codigo', ', ') AS codigos
FROM sena_diccionario sdc
GROUP BY 1
HAVING COUNT(*) > 1
ORDER BY significado;

-- I3. [CONTROL: vacía = sin problemas]
--     Lengua de la entrada distinta de la lengua de la seña
SELECT sdc.id_sena_diccionario, s.id_lengua AS lengua_sena, sdc.id_lengua AS lengua_entrada
FROM sena_diccionario sdc
JOIN sena s ON s.id_sena = sdc.id_sena
WHERE s.id_lengua <> sdc.id_lengua;

-- I4. [CONTROL: vacía = sin problemas]
--     Palabras duplicadas (misma palabra y lengua dos veces)
SELECT LOWER(palabra) AS palabra, id_lengua, COUNT(*)
FROM palabra
GROUP BY LOWER(palabra), id_lengua
HAVING COUNT(*) > 1;

-- I5. [CONTROL: vacía = sin problemas]
--     Tipo de sena.id_tipo que no coincide con el tipo del JSON
SELECT sdc.datos_fonologicos ->> 'codigo' AS codigo, t.tipo, sdc.datos_fonologicos ->> 'tipo_sena' AS tipo_json
FROM sena s
JOIN tipo_sena t          ON t.id_tipo_sena = s.id_tipo
JOIN sena_diccionario sdc ON sdc.id_sena = s.id_sena
WHERE t.tipo <> 'SC' AND t.tipo <> sdc.datos_fonologicos ->> 'tipo_sena';

-- =====================================================================
-- J. FICHA COMPLETA DE UNA SEÑA
-- =====================================================================

-- J1. Todo lo que se sabe de una seña en una sola fila
SELECT sdc.datos_fonologicos ->> 'codigo' AS codigo,
       l.nombre_completo AS lengua,
       t.tipo,
       (SELECT STRING_AGG(p.palabra, ', ') FROM sena_palabra x JOIN palabra p USING (id_palabra) WHERE x.id_sena = s.id_sena) AS palabras,
       (SELECT STRING_AGG(d.definicion, ' | ') FROM sena_definicion x JOIN definicion d USING (id_definicion) WHERE x.id_sena = s.id_sena) AS definiciones,
       dic.completo AS diccionario,
       sdc.datos_fonologicos ->> 'configuracion' AS configuracion,
       sdc.datos_fonologicos ->> 'ubicacion'     AS ubicacion,
       sdc.datos_fonologicos ->> 'movimiento'    AS movimiento
FROM sena s
JOIN lengua l             ON l.id_lengua = s.id_lengua
LEFT JOIN tipo_sena t     ON t.id_tipo_sena = s.id_tipo
JOIN sena_diccionario sdc ON sdc.id_sena = s.id_sena
JOIN diccionario dic      ON dic.id_diccionario = sdc.id_diccionario
WHERE sdc.datos_fonologicos ->> 'codigo' = 'B-P 4';

-- =====================================================================
-- K. TEMAS DEL DICCIONARIO
-- =====================================================================

-- K1. Señas con nota cultural
SELECT sdc.datos_fonologicos ->> 'significado'   AS significado,
       sdc.datos_fonologicos ->> 'nota_cultural' AS nota_cultural
FROM sena_diccionario sdc
WHERE sdc.datos_fonologicos ? 'nota_cultural'
ORDER BY significado;

-- K2. Señas con representación (qué imitan)
SELECT sdc.datos_fonologicos ->> 'significado'    AS significado,
       sdc.datos_fonologicos ->> 'representacion' AS representacion
FROM sena_diccionario sdc
WHERE sdc.datos_fonologicos ? 'representacion'
ORDER BY significado;

-- K3. Estaciones del Metro (STC Metro)
SELECT sdc.datos_fonologicos ->> 'codigo'      AS codigo,
       sdc.datos_fonologicos ->> 'significado' AS significado
FROM sena_diccionario sdc
WHERE sdc.datos_fonologicos ->> 'significado' LIKE '%(STC Metro)%'
ORDER BY codigo;

-- K4. Señas de lugares internacionales (SSI)
SELECT sdc.datos_fonologicos ->> 'codigo'      AS codigo,
       sdc.datos_fonologicos ->> 'significado' AS significado
FROM sena_diccionario sdc
WHERE sdc.datos_fonologicos ->> 'significado' LIKE '%(SSI)%'
ORDER BY codigo;

-- K5. Señas por categoría gramatical (inicio de la definición: sust., v., adj., adv., ...)
SELECT COALESCE(LOWER(SUBSTRING(d.definicion FROM '^\d?\.?\s*([a-zA-Z]+\.)')), '(otro)') AS categoria,
       COUNT(*) AS num_senas
FROM definicion d
GROUP BY 1
ORDER BY 2 DESC;

-- K6. Búsqueda libre en las definiciones
SELECT sdc.datos_fonologicos ->> 'significado' AS significado, d.definicion
FROM definicion d
JOIN sena_definicion x    ON x.id_definicion = d.id_definicion
JOIN sena_diccionario sdc ON sdc.id_sena = x.id_sena
WHERE d.definicion ILIKE '%comida%'
ORDER BY significado;
