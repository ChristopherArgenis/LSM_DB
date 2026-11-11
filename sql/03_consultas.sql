-- =====================================================================
-- LSM_DB - Catálogo de consultas
-- Ejecutar después de 01_schema.sql, 02_datos_dlsm_cdmx.sql y
-- 02b_glosas_dlsm_cdmx.sql.
--
-- Cada seña se identifica por su GLOSA (CASA-A, ABAJO, ADORAR-1).
-- El código del diccionario (B-P 4) se muestra solo cuando aporta algo.
--
-- Los valores entre comillas ('Casa', 'ABAJO', 'A.1', ...) son
-- parámetros de ejemplo: cámbialos por lo que quieras buscar.
-- Las palabras se comparan con LOWER() para no depender de mayúsculas.
--
-- Algunas consultas salen vacías con los datos actuales porque la base
-- todavía no tiene esa información (inglés, ASL, videos o un segundo
-- diccionario). Están marcadas con [VACÍA HOY] y dicen qué falta.
-- Las salidas de todas están en docs/SALIDAS.md.
-- =====================================================================
SET search_path TO lsm;

-- =====================================================================
-- A. PALABRAS, TRADUCCIÓN Y DEFINICIONES
-- La SEÑA es el pivote: palabras, glosas y definiciones de cualquier
-- idioma solo se unen a través de ella.
-- =====================================================================

-- A1. Seña(s) de una palabra: su glosa y su código en el diccionario
SELECT p.palabra, g.glosa,
       sdc.datos_fonologicos ->> 'codigo' AS codigo
FROM palabra p
JOIN sena_palabra sp      ON sp.id_palabra = p.id_palabra
JOIN sena_glosa sg        ON sg.id_sena = sp.id_sena
JOIN glosa g              ON g.id_glosa = sg.id_glosa
JOIN sena_diccionario sdc ON sdc.id_sena = sp.id_sena
WHERE LOWER(p.palabra) = LOWER('Casa')
ORDER BY g.glosa;

-- A2. Todas las palabras de una glosa, con su idioma
SELECT g.glosa, p.palabra, l.nombre_completo AS idioma
FROM glosa g
JOIN sena_glosa sg   ON sg.id_glosa = g.id_glosa
JOIN sena_palabra sp ON sp.id_sena = sg.id_sena
JOIN palabra p       ON p.id_palabra = sp.id_palabra
JOIN lengua l        ON l.id_lengua = p.id_lengua
WHERE g.glosa = 'BONITO'
ORDER BY p.palabra;

-- A3. [VACÍA HOY: falta cargar palabras en inglés]
--     Traducir una palabra de español a inglés a través de la seña
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

-- A4. [VACÍA HOY: falta cargar definiciones en inglés]
--     Definición en inglés de una palabra en español
--     palabra(es) -> sena_palabra -> sena -> sena_definicion -> definicion(en)
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

-- A5. Definición en español de una palabra (misma ruta que A4)
SELECT p.palabra, g.glosa, d.definicion
FROM palabra p
JOIN sena_palabra sp    ON sp.id_palabra = p.id_palabra
JOIN sena_glosa sg      ON sg.id_sena = sp.id_sena
JOIN glosa g            ON g.id_glosa = sg.id_glosa
JOIN sena_definicion sd ON sd.id_sena = sp.id_sena
JOIN definicion d       ON d.id_definicion = sd.id_definicion
WHERE LOWER(p.palabra) = LOWER('Banco')
  AND d.id_lengua = (SELECT id_lengua FROM lengua WHERE nombre_completo = 'Español');

-- A6. Palabras con varias señas (variantes A/B o sentidos distintos)
SELECT p.palabra, COUNT(*) AS num_senas,
       STRING_AGG(g.glosa, ', ' ORDER BY g.glosa) AS glosas
FROM palabra p
JOIN sena_palabra sp ON sp.id_palabra = p.id_palabra
JOIN sena_glosa sg   ON sg.id_sena = sp.id_sena
JOIN glosa g         ON g.id_glosa = sg.id_glosa
GROUP BY p.palabra
HAVING COUNT(*) > 1
ORDER BY num_senas DESC, p.palabra;

-- A7. Sinónimos: palabras que comparten la misma seña
SELECT g.glosa,
       STRING_AGG(p.palabra, ' / ' ORDER BY p.palabra) AS palabras
FROM glosa g
JOIN sena_glosa sg   ON sg.id_glosa = g.id_glosa
JOIN sena_palabra sp ON sp.id_sena = sg.id_sena
JOIN palabra p       ON p.id_palabra = sp.id_palabra
GROUP BY g.glosa
HAVING COUNT(*) > 1
ORDER BY COUNT(*) DESC, g.glosa;

-- =====================================================================
-- B. LENGUAS
-- =====================================================================

-- B1. [VACÍA HOY: falta cargar una segunda lengua de señas, p. ej. ASL]
--     Equivalente en otra lengua de señas por palabra compartida
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
SELECT id_diccionario, nombre_completo, autor FROM diccionario;

-- C2. Número de señas por diccionario
SELECT dic.nombre_completo, COUNT(sdc.id_sena) AS num_senas
FROM diccionario dic
LEFT JOIN sena_diccionario sdc ON sdc.id_diccionario = dic.id_diccionario
GROUP BY dic.nombre_completo
ORDER BY num_senas DESC;

-- C3. Contenido del diccionario por página del PDF
SELECT (sdc.datos_fonologicos ->> 'pagina')::int AS pagina,
       g.glosa,
       sdc.datos_fonologicos ->> 'significado'   AS significado
FROM sena_diccionario sdc
JOIN sena_glosa sg ON sg.id_sena = sdc.id_sena
JOIN glosa g       ON g.id_glosa = sg.id_glosa
WHERE (sdc.datos_fonologicos ->> 'pagina')::int BETWEEN 1 AND 2
ORDER BY pagina, sdc.id_sena;

-- C4. [VACÍA HOY: hace falta un segundo diccionario]
--     Misma seña con datos fonológicos distintos entre diccionarios
SELECT g.glosa, k AS parametro,
       a.datos_fonologicos ->> k AS valor_a, b.datos_fonologicos ->> k AS valor_b
FROM sena_diccionario a
JOIN sena_diccionario b ON b.id_sena = a.id_sena AND b.id_diccionario > a.id_diccionario
JOIN sena_glosa sg      ON sg.id_sena = a.id_sena
JOIN glosa g            ON g.id_glosa = sg.id_glosa
CROSS JOIN LATERAL (SELECT jsonb_object_keys(a.datos_fonologicos || b.datos_fonologicos) AS k) keys
WHERE a.datos_fonologicos -> k IS DISTINCT FROM b.datos_fonologicos -> k;

-- C5. Señas por grupo de configuración (prefijo del código: B-P, 5-G, A, L, S, C, O)
SELECT REGEXP_REPLACE(sdc.datos_fonologicos ->> 'codigo', '[- ]?\d+$', '') AS grupo,
       COUNT(*) AS num_senas
FROM sena_diccionario sdc
GROUP BY 1
ORDER BY 2 DESC;

-- C6. Ver el JSON completo de una seña por su glosa
SELECT g.glosa, jsonb_pretty(sdc.datos_fonologicos) AS datos_fonologicos
FROM glosa g
JOIN sena_glosa sg        ON sg.id_glosa = g.id_glosa
JOIN sena_diccionario sdc ON sdc.id_sena = sg.id_sena
WHERE g.glosa = 'Y-ESO';

-- =====================================================================
-- D. FONOLOGÍA (datos_fonologicos)
-- =====================================================================

-- D1. Señas con una configuración exacta
SELECT g.glosa, sdc.datos_fonologicos ->> 'ubicacion' AS ubicacion
FROM sena_diccionario sdc
JOIN sena_glosa sg ON sg.id_sena = sdc.id_sena
JOIN glosa g       ON g.id_glosa = sg.id_glosa
WHERE sdc.datos_fonologicos @> '{"configuracion": "B-P.2"}'
ORDER BY g.glosa;

-- D2. Varias condiciones a la vez (usa el índice GIN)
SELECT g.glosa
FROM sena_diccionario sdc
JOIN sena_glosa sg ON sg.id_sena = sdc.id_sena
JOIN glosa g       ON g.id_glosa = sg.id_glosa
WHERE sdc.datos_fonologicos @> '{"configuracion": "A.1", "ubicacion": "A la altura del pecho."}'
ORDER BY g.glosa;

-- D3. Búsqueda de texto dentro de un parámetro (configuraciones que usan B-P.2)
SELECT g.glosa, sdc.datos_fonologicos ->> 'configuracion' AS configuracion
FROM sena_diccionario sdc
JOIN sena_glosa sg ON sg.id_sena = sdc.id_sena
JOIN glosa g       ON g.id_glosa = sg.id_glosa
WHERE sdc.datos_fonologicos ->> 'configuracion' ILIKE '%B-P.2%'
ORDER BY g.glosa;

-- D4. Rasgos no manuales que mencionan las cejas
SELECT g.glosa, sdc.datos_fonologicos ->> 'rasgos_no_manuales' AS rasgos
FROM sena_diccionario sdc
JOIN sena_glosa sg ON sg.id_sena = sdc.id_sena
JOIN glosa g       ON g.id_glosa = sg.id_glosa
WHERE sdc.datos_fonologicos ->> 'rasgos_no_manuales' ILIKE '%ceja%'
ORDER BY g.glosa;

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
SELECT g.glosa, sdc.datos_fonologicos ->> 'tipo_sena' AS partes
FROM sena s
JOIN tipo_sena t          ON t.id_tipo_sena = s.id_tipo
JOIN sena_diccionario sdc ON sdc.id_sena = s.id_sena
JOIN sena_glosa sg        ON sg.id_sena = s.id_sena
JOIN glosa g              ON g.id_glosa = sg.id_glosa
WHERE t.tipo = 'SC'
ORDER BY g.glosa;

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
SELECT g.glosa, v.path, v.tipo_de_toma, v.mano_dominante, st.id_senante, st.perfil_nativo
FROM glosa g
JOIN sena_glosa sg        ON sg.id_glosa = g.id_glosa
JOIN sena_diccionario sdc ON sdc.id_sena = sg.id_sena
JOIN sena_video sv        ON sv.id_sena_diccionario = sdc.id_sena_diccionario
JOIN video v              ON v.id_video = sv.id_video
JOIN senante st           ON st.id_senante = v.id_senante
WHERE g.glosa = 'CASA-A';

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
SELECT g.glosa, COUNT(DISTINCT v.id_senante) AS num_senantes
FROM sena_diccionario sdc
JOIN sena_video sv ON sv.id_sena_diccionario = sdc.id_sena_diccionario
JOIN video v       ON v.id_video = sv.id_video
JOIN sena_glosa sg ON sg.id_sena = sdc.id_sena
JOIN glosa g       ON g.id_glosa = sg.id_glosa
GROUP BY g.glosa
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
SELECT g.glosa, sdc.datos_fonologicos ->> 'codigo' AS codigo,
       sdc.datos_fonologicos ->> 'tipo_sena' AS tipo_original
FROM sena s
JOIN sena_diccionario sdc ON sdc.id_sena = s.id_sena
JOIN sena_glosa sg        ON sg.id_sena = s.id_sena
JOIN glosa g              ON g.id_glosa = sg.id_glosa
WHERE s.id_tipo IS NULL;

-- H3. Señas sin movimiento u orientación en el diccionario
SELECT g.glosa,
       NOT sdc.datos_fonologicos ? 'movimiento'  AS sin_movimiento,
       NOT sdc.datos_fonologicos ? 'orientacion' AS sin_orientacion
FROM sena_diccionario sdc
JOIN sena_glosa sg ON sg.id_sena = sdc.id_sena
JOIN glosa g       ON g.id_glosa = sg.id_glosa
WHERE NOT sdc.datos_fonologicos ?& ARRAY['movimiento', 'orientacion']
ORDER BY g.glosa;

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
       STRING_AGG(g.glosa, ', ' ORDER BY g.glosa) AS glosas
FROM sena_diccionario sdc
JOIN sena_glosa sg ON sg.id_sena = sdc.id_sena
JOIN glosa g       ON g.id_glosa = sg.id_glosa
GROUP BY 1
HAVING COUNT(*) > 1;

-- I2. [CONTROL: vacía = sin problemas]
--     Glosas numeradas: el diccionario no da nada que distinga esas señas
SELECT g.glosa, sdc.datos_fonologicos ->> 'codigo' AS codigo,
       sdc.datos_fonologicos ->> 'significado' AS significado
FROM glosa g
JOIN sena_glosa sg        ON sg.id_glosa = g.id_glosa
JOIN sena_diccionario sdc ON sdc.id_sena = sg.id_sena
WHERE g.glosa ~ '-[0-9]+$'
ORDER BY g.glosa;

-- I3. [CONTROL: vacía = sin problemas]
--     Entradas cuyo diccionario y seña no existen (integridad del pivote).
--     Antes comparaba sena_diccionario.id_lengua con sena.id_lengua; esa
--     columna se quitó porque la lengua de la entrada es la de su seña.
SELECT sdc.id_sena_diccionario
FROM sena_diccionario sdc
LEFT JOIN sena s        ON s.id_sena = sdc.id_sena
LEFT JOIN diccionario d ON d.id_diccionario = sdc.id_diccionario
WHERE s.id_sena IS NULL OR d.id_diccionario IS NULL;

-- I4. [CONTROL: vacía = sin problemas]
--     Glosas repetidas o señas con más de una glosa
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

-- I5. [CONTROL: vacía = sin problemas]
--     Tipo de sena.id_tipo que no coincide con el tipo del JSON
SELECT g.glosa, t.tipo, sdc.datos_fonologicos ->> 'tipo_sena' AS tipo_json
FROM sena s
JOIN tipo_sena t          ON t.id_tipo_sena = s.id_tipo
JOIN sena_diccionario sdc ON sdc.id_sena = s.id_sena
JOIN sena_glosa sg        ON sg.id_sena = s.id_sena
JOIN glosa g              ON g.id_glosa = sg.id_glosa
WHERE t.tipo <> 'SC' AND t.tipo <> sdc.datos_fonologicos ->> 'tipo_sena';

-- =====================================================================
-- J. FICHA COMPLETA DE UNA SEÑA
-- =====================================================================

-- J1. Todo lo que se sabe de una seña en una sola fila
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

-- =====================================================================
-- K. TEMAS DEL DICCIONARIO
-- =====================================================================

-- K1. Señas con nota cultural
SELECT g.glosa, sdc.datos_fonologicos ->> 'nota_cultural' AS nota_cultural
FROM sena_diccionario sdc
JOIN sena_glosa sg ON sg.id_sena = sdc.id_sena
JOIN glosa g       ON g.id_glosa = sg.id_glosa
WHERE sdc.datos_fonologicos ? 'nota_cultural'
ORDER BY g.glosa;

-- K2. Señas con representación (qué imitan)
SELECT g.glosa, sdc.datos_fonologicos ->> 'representacion' AS representacion
FROM sena_diccionario sdc
JOIN sena_glosa sg ON sg.id_sena = sdc.id_sena
JOIN glosa g       ON g.id_glosa = sg.id_glosa
WHERE sdc.datos_fonologicos ? 'representacion'
ORDER BY g.glosa;

-- K3. Estaciones del Metro (STC Metro)
SELECT g.glosa, sdc.datos_fonologicos ->> 'significado' AS significado
FROM sena_diccionario sdc
JOIN sena_glosa sg ON sg.id_sena = sdc.id_sena
JOIN glosa g       ON g.id_glosa = sg.id_glosa
WHERE sdc.datos_fonologicos ->> 'significado' LIKE '%(STC Metro)%'
ORDER BY g.glosa;

-- K4. Señas de lugares internacionales (SSI)
SELECT g.glosa, sdc.datos_fonologicos ->> 'significado' AS significado
FROM sena_diccionario sdc
JOIN sena_glosa sg ON sg.id_sena = sdc.id_sena
JOIN glosa g       ON g.id_glosa = sg.id_glosa
WHERE sdc.datos_fonologicos ->> 'significado' ~ '\(SS[Il]\)'
ORDER BY g.glosa;

-- K5. Señas por categoría gramatical (inicio de la definición: sust., v., adj., adv., ...)
SELECT COALESCE(LOWER(SUBSTRING(d.definicion FROM '^\d?\.?\s*([a-zA-Z]+\.)')), '(otro)') AS categoria,
       COUNT(*) AS num_senas
FROM definicion d
GROUP BY 1
ORDER BY 2 DESC;

-- K6. Búsqueda libre en las definiciones
SELECT g.glosa, d.definicion
FROM definicion d
JOIN sena_definicion x ON x.id_definicion = d.id_definicion
JOIN sena_glosa sg     ON sg.id_sena = x.id_sena
JOIN glosa g           ON g.id_glosa = sg.id_glosa
WHERE d.definicion ILIKE '%comida%'
ORDER BY g.glosa;
