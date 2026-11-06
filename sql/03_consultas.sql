-- =====================================================================
-- LSM_DB - Catálogo de consultas posibles
-- Ejecutar después de 01_schema.sql y 02_seed.sql.
-- Los valores fijos ('hola', 'Inglés', 'B', ...) son parámetros de
-- ejemplo; cámbialos por lo que quieras buscar.
-- Explicación de cada bloque y de las limitaciones: docs/CONSULTAS.md
-- =====================================================================
SET search_path TO lsm;

-- =====================================================================
-- A. PALABRAS, TRADUCCIÓN Y DEFINICIONES
-- La SEÑA es el "pivote": una seña puede ligarse a palabras y
-- definiciones de cualquier idioma. Toda traducción pasa por ella.
-- =====================================================================

-- A1. Seña(s) de una palabra (con su glosa y su lengua de señas)
SELECT p.palabra, ls.nombre_completo AS lengua_senas, g.glosa, s.id_sena
FROM palabra p
JOIN sena_palabra sp ON sp.id_palabra = p.id_palabra
JOIN sena s          ON s.id_sena     = sp.id_sena
JOIN lengua ls       ON ls.id_lengua  = s.id_lengua
LEFT JOIN sena_glosa sg ON sg.id_sena = s.id_sena
LEFT JOIN glosa g       ON g.id_glosa = sg.id_glosa
WHERE p.palabra = 'hola';

-- A2. Palabra(s) de una glosa, en todos los idiomas
SELECT g.glosa, p.palabra, lp.nombre_completo AS idioma
FROM glosa g
JOIN sena_glosa sg   ON sg.id_glosa  = g.id_glosa
JOIN sena_palabra sp ON sp.id_sena   = sg.id_sena
JOIN palabra p       ON p.id_palabra = sp.id_palabra
JOIN lengua lp       ON lp.id_lengua = p.id_lengua
WHERE g.glosa = 'CASA';

-- A3. Traducir una palabra de un idioma a otro (es -> en) vía la seña
SELECT DISTINCT origen.palabra AS espanol, destino.palabra AS ingles
FROM palabra origen
JOIN sena_palabra sp1 ON sp1.id_palabra = origen.id_palabra
JOIN sena_palabra sp2 ON sp2.id_sena    = sp1.id_sena
JOIN palabra destino  ON destino.id_palabra = sp2.id_palabra
WHERE origen.palabra = 'banco'
  AND origen.id_lengua  = (SELECT id_lengua FROM lengua WHERE nombre_completo = 'Español')
  AND destino.id_lengua = (SELECT id_lengua FROM lengua WHERE nombre_completo = 'Inglés');

-- A4. *** Definición en inglés de una palabra en español ***
--     palabra(es) -> sena_palabra -> sena -> sena_definicion -> definicion(en)
--     Se muestra la glosa para distinguir sentidos (p. ej. 'banco').
SELECT DISTINCT p.palabra, g.glosa, d.definicion, d.autor
FROM palabra p
JOIN sena_palabra sp    ON sp.id_palabra = p.id_palabra
JOIN sena_definicion sd ON sd.id_sena    = sp.id_sena
JOIN definicion d       ON d.id_definicion = sd.id_definicion
LEFT JOIN sena_glosa sg ON sg.id_sena = sp.id_sena
LEFT JOIN glosa g       ON g.id_glosa = sg.id_glosa
WHERE p.palabra = 'hola'
  AND p.id_lengua = (SELECT id_lengua FROM lengua WHERE nombre_completo = 'Español')
  AND d.id_lengua = (SELECT id_lengua FROM lengua WHERE nombre_completo = 'Inglés');

-- A5. Todas las definiciones de una seña, agrupadas por idioma
SELECT g.glosa, ld.nombre_completo AS idioma, d.definicion
FROM glosa g
JOIN sena_glosa sg      ON sg.id_glosa = g.id_glosa
JOIN sena_definicion sd ON sd.id_sena  = sg.id_sena
JOIN definicion d       ON d.id_definicion = sd.id_definicion
JOIN lengua ld          ON ld.id_lengua = d.id_lengua
WHERE g.glosa = 'BANCO-ASIENTO'
ORDER BY idioma;

-- A6. Palabras polisémicas: una palabra ligada a 2+ señas de la misma lengua
SELECT p.palabra, l.nombre_completo AS lengua_senas,
       COUNT(*) AS num_senas, STRING_AGG(g.glosa, ', ') AS glosas
FROM palabra p
JOIN sena_palabra sp ON sp.id_palabra = p.id_palabra
JOIN sena s          ON s.id_sena = sp.id_sena
JOIN lengua l        ON l.id_lengua = s.id_lengua
LEFT JOIN sena_glosa sg ON sg.id_sena = s.id_sena
LEFT JOIN glosa g       ON g.id_glosa = sg.id_glosa
GROUP BY p.palabra, l.nombre_completo
HAVING COUNT(DISTINCT s.id_sena) > 1;

-- A7. Sinónimos en un idioma: palabras distintas que comparten seña
SELECT s.id_sena, STRING_AGG(p.palabra, ' / ' ORDER BY p.palabra) AS palabras
FROM sena s
JOIN sena_palabra sp ON sp.id_sena = s.id_sena
JOIN palabra p       ON p.id_palabra = sp.id_palabra
WHERE p.id_lengua = (SELECT id_lengua FROM lengua WHERE nombre_completo = 'Español')
GROUP BY s.id_sena
HAVING COUNT(*) > 1;

-- =====================================================================
-- B. ENTRE LENGUAS DE SEÑAS (LSM <-> ASL)
-- No hay relación directa seña-seña; se usa una palabra compartida.
-- =====================================================================

-- B1. Equivalente ASL de una seña LSM (por palabras en común)
SELECT DISTINCT g_lsm.glosa AS lsm, g_asl.glosa AS asl, p.palabra AS palabra_comun
FROM glosa g_lsm
JOIN sena_glosa sg1   ON sg1.id_glosa = g_lsm.id_glosa
JOIN sena_palabra sp1 ON sp1.id_sena  = sg1.id_sena
JOIN palabra p        ON p.id_palabra = sp1.id_palabra
JOIN sena_palabra sp2 ON sp2.id_palabra = p.id_palabra AND sp2.id_sena <> sp1.id_sena
JOIN sena s2          ON s2.id_sena = sp2.id_sena
JOIN sena_glosa sg2   ON sg2.id_sena = s2.id_sena
JOIN glosa g_asl      ON g_asl.id_glosa = sg2.id_glosa
WHERE g_lsm.glosa = 'HOLA'
  AND s2.id_lengua = (SELECT id_lengua FROM lengua WHERE nombre_completo = 'American Sign Language');

-- B2. Conteo de señas por lengua de señas
SELECT l.nombre_completo, COUNT(s.id_sena) AS num_senas
FROM lengua l
LEFT JOIN sena s ON s.id_lengua = l.id_lengua
WHERE l.modalidad = 'viso-gestual'
GROUP BY l.nombre_completo;

-- B3. Conteo de palabras, glosas y definiciones por lengua
SELECT l.nombre_completo,
       (SELECT COUNT(*) FROM palabra    p WHERE p.id_lengua = l.id_lengua) AS palabras,
       (SELECT COUNT(*) FROM glosa      g WHERE g.id_lengua = l.id_lengua) AS glosas,
       (SELECT COUNT(*) FROM definicion d WHERE d.id_lengua = l.id_lengua) AS definiciones
FROM lengua l
ORDER BY l.id_lengua;

-- =====================================================================
-- C. DICCIONARIOS
-- =====================================================================

-- C1. Contenido de un diccionario (glosa + palabra en español)
SELECT dic.completo, g.glosa,
       STRING_AGG(DISTINCT p.palabra, ', ') FILTER (WHERE p.id_lengua = 2) AS palabras_es  -- 2 = Español
FROM diccionario dic
JOIN sena_diccionario sdc ON sdc.id_diccionario = dic.id_diccionario
LEFT JOIN sena_glosa sg   ON sg.id_sena = sdc.id_sena
LEFT JOIN glosa g         ON g.id_glosa = sg.id_glosa
LEFT JOIN sena_palabra sp ON sp.id_sena = sdc.id_sena
LEFT JOIN palabra p       ON p.id_palabra = sp.id_palabra
WHERE dic.completo LIKE '%DIELSEME%'
GROUP BY dic.completo, g.glosa;

-- C2. Número de señas por diccionario
SELECT dic.completo, COUNT(sdc.id_sena) AS num_senas
FROM diccionario dic
LEFT JOIN sena_diccionario sdc ON sdc.id_diccionario = dic.id_diccionario
GROUP BY dic.completo
ORDER BY num_senas DESC;

-- C3. En qué diccionarios aparece una seña
SELECT g.glosa, dic.completo
FROM glosa g
JOIN sena_glosa sg        ON sg.id_glosa = g.id_glosa
JOIN sena_diccionario sdc ON sdc.id_sena = sg.id_sena
JOIN diccionario dic      ON dic.id_diccionario = sdc.id_diccionario
WHERE g.glosa = 'HOLA';

-- C4. Señas que están en un diccionario pero no en otro
SELECT g.glosa
FROM sena_diccionario a
JOIN sena_glosa sg ON sg.id_sena = a.id_sena
JOIN glosa g       ON g.id_glosa = sg.id_glosa
WHERE a.id_diccionario = 1
  AND NOT EXISTS (SELECT 1 FROM sena_diccionario b
                  WHERE b.id_sena = a.id_sena AND b.id_diccionario = 2);

-- C5. Señas presentes en 2+ diccionarios
SELECT g.glosa, COUNT(*) AS num_diccionarios
FROM sena_diccionario sdc
JOIN sena_glosa sg ON sg.id_sena = sdc.id_sena
JOIN glosa g       ON g.id_glosa = sg.id_glosa
GROUP BY g.glosa
HAVING COUNT(*) > 1;

-- C6. Misma seña, datos fonológicos distintos entre diccionarios
SELECT g.glosa, d1.completo AS dic_a, d2.completo AS dic_b,
       a.datos_fonologicos AS fono_a, b.datos_fonologicos AS fono_b
FROM sena_diccionario a
JOIN sena_diccionario b ON b.id_sena = a.id_sena AND b.id_diccionario > a.id_diccionario
JOIN diccionario d1     ON d1.id_diccionario = a.id_diccionario
JOIN diccionario d2     ON d2.id_diccionario = b.id_diccionario
JOIN sena_glosa sg      ON sg.id_sena = a.id_sena
JOIN glosa g            ON g.id_glosa = sg.id_glosa
WHERE a.datos_fonologicos IS DISTINCT FROM b.datos_fonologicos;

-- C7. Qué parámetro exacto cambia entre diccionarios
SELECT g.glosa, k AS parametro,
       a.datos_fonologicos ->> k AS valor_a, b.datos_fonologicos ->> k AS valor_b
FROM sena_diccionario a
JOIN sena_diccionario b ON b.id_sena = a.id_sena AND b.id_diccionario > a.id_diccionario
JOIN sena_glosa sg      ON sg.id_sena = a.id_sena
JOIN glosa g            ON g.id_glosa = sg.id_glosa
CROSS JOIN LATERAL (SELECT jsonb_object_keys(a.datos_fonologicos || b.datos_fonologicos) AS k) keys
WHERE a.datos_fonologicos -> k IS DISTINCT FROM b.datos_fonologicos -> k;

-- =====================================================================
-- D. FONOLOGÍA (datos_fonologicos JSONB)
-- =====================================================================

-- D1. Señas con una configuración de mano dada
SELECT DISTINCT g.glosa, sdc.datos_fonologicos ->> 'ubicacion' AS ubicacion
FROM sena_diccionario sdc
JOIN sena_glosa sg ON sg.id_sena = sdc.id_sena
JOIN glosa g       ON g.id_glosa = sg.id_glosa
WHERE sdc.datos_fonologicos @> '{"configuracion": "B"}';

-- D2. Búsqueda por varios parámetros a la vez (usa el índice GIN)
SELECT DISTINCT g.glosa
FROM sena_diccionario sdc
JOIN sena_glosa sg ON sg.id_sena = sdc.id_sena
JOIN glosa g       ON g.id_glosa = sg.id_glosa
WHERE sdc.datos_fonologicos @> '{"ubicacion": "barbilla", "movimiento": "toque repetido"}';

-- D3. Señas con un rasgo no manual
SELECT DISTINCT g.glosa
FROM sena_diccionario sdc
JOIN sena_glosa sg ON sg.id_sena = sdc.id_sena
JOIN glosa g       ON g.id_glosa = sg.id_glosa
WHERE sdc.datos_fonologicos -> 'rasgos_no_manuales' ? 'sonrisa';

-- D4. Frecuencia de cada configuración (o cualquier parámetro)
SELECT datos_fonologicos ->> 'configuracion' AS configuracion, COUNT(DISTINCT id_sena) AS num_senas
FROM sena_diccionario
GROUP BY 1
ORDER BY 2 DESC;

-- D5. Pares mínimos: señas que difieren en exactamente un parámetro
WITH f AS (
    SELECT DISTINCT ON (sdc.id_sena) sdc.id_sena, g.glosa,
           sdc.datos_fonologicos ->> 'configuracion' AS c,
           sdc.datos_fonologicos ->> 'ubicacion'     AS u,
           sdc.datos_fonologicos ->> 'movimiento'    AS m,
           sdc.datos_fonologicos ->> 'orientacion'   AS o
    FROM sena_diccionario sdc
    JOIN sena_glosa sg ON sg.id_sena = sdc.id_sena
    JOIN glosa g       ON g.id_glosa = sg.id_glosa
    ORDER BY sdc.id_sena, sdc.id_diccionario
)
SELECT a.glosa, b.glosa,
       CASE WHEN a.c <> b.c THEN 'configuracion'
            WHEN a.u <> b.u THEN 'ubicacion'
            WHEN a.m <> b.m THEN 'movimiento'
            ELSE 'orientacion' END AS parametro_distinto
FROM f a JOIN f b ON a.id_sena < b.id_sena
WHERE (a.c <> b.c)::int + (a.u <> b.u)::int + (a.m <> b.m)::int + (a.o <> b.o)::int = 1;

-- D6. Qué claves se usan en datos_fonologicos (control de consistencia)
SELECT k AS clave, COUNT(*) AS veces
FROM sena_diccionario, jsonb_object_keys(datos_fonologicos) k
GROUP BY k
ORDER BY veces DESC;

-- =====================================================================
-- E. TIPO DE SEÑA
-- =====================================================================

-- E1. Señas por tipo
SELECT t.tipo, COUNT(s.id_sena) AS num_senas
FROM tipo_sena t
LEFT JOIN sena s ON s.id_tipo = t.id_tipo_sena
GROUP BY t.tipo
ORDER BY num_senas DESC;

-- E2. Señas de un tipo, con su glosa y lengua
SELECT t.tipo, g.glosa, l.nombre_completo
FROM sena s
JOIN tipo_sena t ON t.id_tipo_sena = s.id_tipo
JOIN lengua l    ON l.id_lengua = s.id_lengua
LEFT JOIN sena_glosa sg ON sg.id_sena = s.id_sena
LEFT JOIN glosa g       ON g.id_glosa = sg.id_glosa
WHERE t.tipo = 'icónica';

-- =====================================================================
-- F. VIDEOS Y SEÑANTES (corpus)
-- =====================================================================

-- F1. Videos de una seña (con señante y diccionario de la entrada)
SELECT g.glosa, v.path, v.tipo_de_toma, v.mano_dominante,
       st.id_senante, st.perfil_nativo, dic.completo AS diccionario
FROM glosa g
JOIN sena_glosa sg        ON sg.id_glosa = g.id_glosa
JOIN sena_diccionario sdc ON sdc.id_sena = sg.id_sena
JOIN diccionario dic      ON dic.id_diccionario = sdc.id_diccionario
JOIN sena_video sv        ON sv.id_sena_diccionario = sdc.id_sena_diccionario
JOIN video v              ON v.id_video = sv.id_video
JOIN senante st           ON st.id_senante = v.id_senante
WHERE g.glosa = 'HOLA';

-- F2. Video de una palabra en español (palabra -> seña -> video)
SELECT DISTINCT p.palabra, g.glosa, v.path
FROM palabra p
JOIN sena_palabra sp      ON sp.id_palabra = p.id_palabra
JOIN sena_diccionario sdc ON sdc.id_sena = sp.id_sena
JOIN sena_video sv        ON sv.id_sena_diccionario = sdc.id_sena_diccionario
JOIN video v              ON v.id_video = sv.id_video
LEFT JOIN sena_glosa sg   ON sg.id_sena = sp.id_sena
LEFT JOIN glosa g         ON g.id_glosa = sg.id_glosa
WHERE p.palabra = 'casa';

-- F3. Señas contenidas en un video
SELECT v.path, g.glosa
FROM video v
JOIN sena_video sv        ON sv.id_video = v.id_video
JOIN sena_diccionario sdc ON sdc.id_sena_diccionario = sv.id_sena_diccionario
JOIN sena_glosa sg        ON sg.id_sena = sdc.id_sena
JOIN glosa g              ON g.id_glosa = sg.id_glosa
WHERE v.path LIKE '%frase%';

-- F4. Videos y señas distintas grabadas por cada señante
SELECT st.id_senante, st.edad, st.perfil_nativo,
       COUNT(DISTINCT v.id_video)  AS videos,
       COUNT(DISTINCT sdc.id_sena) AS senas_distintas
FROM senante st
LEFT JOIN video v              ON v.id_senante = st.id_senante
LEFT JOIN sena_video sv        ON sv.id_video = v.id_video
LEFT JOIN sena_diccionario sdc ON sdc.id_sena_diccionario = sv.id_sena_diccionario
GROUP BY st.id_senante, st.edad, st.perfil_nativo
ORDER BY st.id_senante;

-- F5. Señas grabadas por 2+ señantes (útil para estudiar variación)
SELECT g.glosa, COUNT(DISTINCT v.id_senante) AS num_senantes
FROM sena_diccionario sdc
JOIN sena_video sv ON sv.id_sena_diccionario = sdc.id_sena_diccionario
JOIN video v       ON v.id_video = sv.id_video
JOIN sena_glosa sg ON sg.id_sena = sdc.id_sena
JOIN glosa g       ON g.id_glosa = sg.id_glosa
GROUP BY g.glosa
HAVING COUNT(DISTINCT v.id_senante) > 1;

-- F6. Distribución de videos por mano dominante y tipo de toma
SELECT mano_dominante, tipo_de_toma, COUNT(*) AS videos
FROM video
GROUP BY ROLLUP (mano_dominante, tipo_de_toma)
ORDER BY mano_dominante NULLS LAST, tipo_de_toma NULLS LAST;

-- F7. Videos por perfil de señante y rango de edad
SELECT st.perfil_nativo,
       CASE WHEN st.edad < 30 THEN '<30' WHEN st.edad < 50 THEN '30-49' ELSE '50+' END AS rango_edad,
       COUNT(v.id_video) AS videos
FROM senante st
LEFT JOIN video v ON v.id_senante = st.id_senante
GROUP BY 1, 2
ORDER BY 1, 2;

-- F8. Videos grabados en un rango de fechas
SELECT v.fecha, v.path, v.id_senante
FROM video v
WHERE v.fecha BETWEEN '2026-03-01' AND '2026-03-04'
ORDER BY v.fecha;

-- =====================================================================
-- G. AUTORÍA Y FECHAS (glosa, definicion)
-- =====================================================================

-- G1. Aportaciones por autor
SELECT autor, 'glosa' AS tipo, COUNT(*) FROM glosa GROUP BY autor
UNION ALL
SELECT autor, 'definicion', COUNT(*) FROM definicion GROUP BY autor
ORDER BY autor, tipo;

-- G2. Glosas y definiciones creadas en un periodo
SELECT 'glosa' AS tipo, glosa AS texto, autor, fecha FROM glosa
WHERE fecha BETWEEN '2026-01-01' AND '2026-01-31'
UNION ALL
SELECT 'definicion', definicion, autor, fecha FROM definicion
WHERE fecha BETWEEN '2026-01-01' AND '2026-01-31'
ORDER BY fecha;

-- =====================================================================
-- H. COBERTURA (qué falta por capturar)
-- =====================================================================

-- H1. Palabras sin seña
SELECT p.palabra, l.nombre_completo
FROM palabra p
JOIN lengua l ON l.id_lengua = p.id_lengua
WHERE NOT EXISTS (SELECT 1 FROM sena_palabra sp WHERE sp.id_palabra = p.id_palabra);

-- H2. Señas a las que les falta algo
SELECT s.id_sena,
       (SELECT STRING_AGG(g.glosa, ', ') FROM sena_glosa sg JOIN glosa g USING (id_glosa) WHERE sg.id_sena = s.id_sena) AS glosa,
       NOT EXISTS (SELECT 1 FROM sena_glosa       x WHERE x.id_sena = s.id_sena) AS sin_glosa,
       NOT EXISTS (SELECT 1 FROM sena_palabra     x WHERE x.id_sena = s.id_sena) AS sin_palabra,
       NOT EXISTS (SELECT 1 FROM sena_definicion  x WHERE x.id_sena = s.id_sena) AS sin_definicion,
       NOT EXISTS (SELECT 1 FROM sena_diccionario x WHERE x.id_sena = s.id_sena) AS sin_diccionario,
       s.id_tipo IS NULL AS sin_tipo
FROM sena s
ORDER BY s.id_sena;

-- H3. Señas sin definición en un idioma dado (p. ej. inglés)
SELECT s.id_sena, g.glosa
FROM sena s
LEFT JOIN sena_glosa sg ON sg.id_sena = s.id_sena
LEFT JOIN glosa g       ON g.id_glosa = sg.id_glosa
WHERE NOT EXISTS (
    SELECT 1 FROM sena_definicion sd
    JOIN definicion d ON d.id_definicion = sd.id_definicion
    WHERE sd.id_sena = s.id_sena
      AND d.id_lengua = (SELECT id_lengua FROM lengua WHERE nombre_completo = 'Inglés'));

-- H4. Entradas de diccionario sin video
SELECT dic.completo, g.glosa
FROM sena_diccionario sdc
JOIN diccionario dic    ON dic.id_diccionario = sdc.id_diccionario
LEFT JOIN sena_glosa sg ON sg.id_sena = sdc.id_sena
LEFT JOIN glosa g       ON g.id_glosa = sg.id_glosa
WHERE NOT EXISTS (SELECT 1 FROM sena_video sv WHERE sv.id_sena_diccionario = sdc.id_sena_diccionario);

-- H5. Videos sin seña y señantes sin videos
SELECT 'video sin seña' AS problema, v.path AS detalle
FROM video v
WHERE NOT EXISTS (SELECT 1 FROM sena_video sv WHERE sv.id_video = v.id_video)
UNION ALL
SELECT 'señante sin videos', 'id_senante = ' || st.id_senante
FROM senante st
WHERE NOT EXISTS (SELECT 1 FROM video v WHERE v.id_senante = st.id_senante);

-- H6. Definiciones, glosas y palabras huérfanas (no ligadas a ninguna seña)
SELECT 'definicion' AS tabla, d.definicion AS texto FROM definicion d
WHERE NOT EXISTS (SELECT 1 FROM sena_definicion x WHERE x.id_definicion = d.id_definicion)
UNION ALL
SELECT 'glosa', g.glosa FROM glosa g
WHERE NOT EXISTS (SELECT 1 FROM sena_glosa x WHERE x.id_glosa = g.id_glosa);

-- =====================================================================
-- I. CONTROL DE CONSISTENCIA
-- El esquema permite estas incoherencias; estas consultas las detectan.
-- =====================================================================

-- I1. sena_diccionario.id_lengua distinto de sena.id_lengua
SELECT sdc.id_sena_diccionario, s.id_lengua AS lengua_sena, sdc.id_lengua AS lengua_entrada
FROM sena_diccionario sdc
JOIN sena s ON s.id_sena = sdc.id_sena
WHERE s.id_lengua <> sdc.id_lengua;

-- I2. Glosa de otra lengua ligada a una seña (p. ej. glosa ASL en seña LSM)
SELECT s.id_sena, g.glosa, s.id_lengua AS lengua_sena, g.id_lengua AS lengua_glosa
FROM sena_glosa sg
JOIN sena s  ON s.id_sena = sg.id_sena
JOIN glosa g ON g.id_glosa = sg.id_glosa
WHERE s.id_lengua <> g.id_lengua;

-- I3. Palabras duplicadas (misma palabra y lengua capturada dos veces)
SELECT LOWER(palabra) AS palabra, id_lengua, COUNT(*)
FROM palabra
GROUP BY LOWER(palabra), id_lengua
HAVING COUNT(*) > 1;

-- I4. Señas con más de una glosa
SELECT sg.id_sena, STRING_AGG(g.glosa, ', ') AS glosas
FROM sena_glosa sg
JOIN glosa g ON g.id_glosa = sg.id_glosa
GROUP BY sg.id_sena
HAVING COUNT(*) > 1;

-- =====================================================================
-- J. VISTA "FICHA COMPLETA" DE UNA SEÑA
-- =====================================================================

-- J1. Todo lo que se sabe de una seña en una sola fila
SELECT s.id_sena,
       l.nombre_completo AS lengua,
       t.tipo,
       (SELECT STRING_AGG(g.glosa, ', ') FROM sena_glosa x JOIN glosa g USING (id_glosa) WHERE x.id_sena = s.id_sena) AS glosas,
       (SELECT STRING_AGG(p.palabra || ' (' || lp.nombre_completo || ')', ', ')
          FROM sena_palabra x JOIN palabra p USING (id_palabra) JOIN lengua lp ON lp.id_lengua = p.id_lengua
         WHERE x.id_sena = s.id_sena) AS palabras,
       (SELECT JSONB_OBJECT_AGG(ld.nombre_completo, d.definicion)
          FROM sena_definicion x JOIN definicion d USING (id_definicion) JOIN lengua ld ON ld.id_lengua = d.id_lengua
         WHERE x.id_sena = s.id_sena) AS definiciones,
       (SELECT STRING_AGG(dic.completo, ', ') FROM sena_diccionario x JOIN diccionario dic USING (id_diccionario) WHERE x.id_sena = s.id_sena) AS diccionarios,
       (SELECT COUNT(*) FROM sena_diccionario x JOIN sena_video sv USING (id_sena_diccionario) WHERE x.id_sena = s.id_sena) AS videos
FROM sena s
JOIN lengua l         ON l.id_lengua = s.id_lengua
LEFT JOIN tipo_sena t ON t.id_tipo_sena = s.id_tipo
WHERE s.id_sena = 6;
