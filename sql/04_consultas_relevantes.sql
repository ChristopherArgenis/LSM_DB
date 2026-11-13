-- =====================================================================
-- LSM_DB - Consultas interesantes y relevantes
-- Requiere: 01_schema.sql, 02_datos_dlsm_cdmx.sql, 02b_glosas_dlsm_cdmx.sql
-- En DBeaver: ejecutar primero el SET y luego cada consulta con Ctrl+Enter.
-- Los valores entre comillas son ejemplos: cámbialos para explorar.
-- =====================================================================
SET search_path TO lsm;

-- R1. Panorama general de la base
SELECT (SELECT COUNT(*) FROM sena)        AS senas,
       (SELECT COUNT(*) FROM glosa)       AS glosas,
       (SELECT COUNT(*) FROM palabra)     AS palabras,
       (SELECT COUNT(*) FROM definicion)  AS definiciones,
       (SELECT COUNT(*) FROM sena_palabra) AS vinculos_sena_palabra,
       (SELECT COUNT(*) FROM diccionario) AS diccionarios;

-- R2. De una palabra en español a su seña: glosa, tipo y definición
SELECT p.palabra, g.glosa, t.tipo, d.definicion
FROM palabra p
JOIN sena_palabra sp    ON sp.id_palabra = p.id_palabra
JOIN sena s             ON s.id_sena = sp.id_sena
LEFT JOIN tipo_sena t   ON t.id_tipo_sena = s.id_tipo
JOIN sena_glosa sg      ON sg.id_sena = s.id_sena
JOIN glosa g            ON g.id_glosa = sg.id_glosa
JOIN sena_definicion sd ON sd.id_sena = s.id_sena
JOIN definicion d       ON d.id_definicion = sd.id_definicion
WHERE LOWER(p.palabra) = LOWER('Casa')
ORDER BY g.glosa;

-- R3. De una glosa a todas sus palabras (sinónimos)
SELECT g.glosa, STRING_AGG(p.palabra, ' / ' ORDER BY p.palabra) AS palabras
FROM glosa g
JOIN sena_glosa sg   ON sg.id_glosa = g.id_glosa
JOIN sena_palabra sp ON sp.id_sena = sg.id_sena
JOIN palabra p       ON p.id_palabra = sp.id_palabra
WHERE g.glosa = 'AUTO'
GROUP BY g.glosa;

-- R4. Las señas con más sinónimos
SELECT g.glosa, COUNT(*) AS num_palabras,
       STRING_AGG(p.palabra, ' / ' ORDER BY p.palabra) AS palabras
FROM glosa g
JOIN sena_glosa sg   ON sg.id_glosa = g.id_glosa
JOIN sena_palabra sp ON sp.id_sena = sg.id_sena
JOIN palabra p       ON p.id_palabra = sp.id_palabra
GROUP BY g.glosa
HAVING COUNT(*) >= 3
ORDER BY num_palabras DESC, g.glosa;

-- R5. Las palabras con más señas (variantes o sentidos)
SELECT p.palabra, COUNT(*) AS num_senas,
       STRING_AGG(g.glosa, ', ' ORDER BY g.glosa) AS glosas
FROM palabra p
JOIN sena_palabra sp ON sp.id_palabra = p.id_palabra
JOIN sena_glosa sg   ON sg.id_sena = sp.id_sena
JOIN glosa g         ON g.id_glosa = sg.id_glosa
GROUP BY p.palabra
HAVING COUNT(*) > 1
ORDER BY num_senas DESC, p.palabra;

-- R6. Ficha completa de una seña
SELECT g.glosa,
       sdc.datos_fonologicos ->> 'codigo'         AS codigo,
       t.tipo,
       (SELECT STRING_AGG(p.palabra, ', ') FROM sena_palabra x JOIN palabra p USING (id_palabra)
         WHERE x.id_sena = s.id_sena)             AS palabras,
       d.definicion,
       sdc.datos_fonologicos ->> 'configuracion'  AS configuracion,
       sdc.datos_fonologicos ->> 'orientacion'    AS orientacion,
       sdc.datos_fonologicos ->> 'ubicacion'      AS ubicacion,
       sdc.datos_fonologicos ->> 'movimiento'     AS movimiento,
       sdc.datos_fonologicos ->> 'representacion' AS representacion
FROM glosa g
JOIN sena_glosa sg        ON sg.id_glosa = g.id_glosa
JOIN sena s               ON s.id_sena = sg.id_sena
LEFT JOIN tipo_sena t     ON t.id_tipo_sena = s.id_tipo
JOIN sena_definicion sd   ON sd.id_sena = s.id_sena
JOIN definicion d         ON d.id_definicion = sd.id_definicion
JOIN sena_diccionario sdc ON sdc.id_sena = s.id_sena
WHERE g.glosa = 'ABAJO';

-- R7. Señas por tipo (SM monomanual, SB bimanual, SS dos manos iguales, SC compuesta)
SELECT COALESCE(t.tipo, '(sin tipo)') AS tipo, COUNT(*) AS num_senas,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS porcentaje
FROM sena s
LEFT JOIN tipo_sena t ON t.id_tipo_sena = s.id_tipo
GROUP BY 1
ORDER BY 2 DESC;

-- R8. Cómo se combinan las partes de las señas compuestas
SELECT sdc.datos_fonologicos ->> 'tipo_sena' AS partes, COUNT(*) AS num_senas,
       STRING_AGG(g.glosa, ', ' ORDER BY g.glosa) AS glosas
FROM sena s
JOIN tipo_sena t          ON t.id_tipo_sena = s.id_tipo
JOIN sena_diccionario sdc ON sdc.id_sena = s.id_sena
JOIN sena_glosa sg        ON sg.id_sena = s.id_sena
JOIN glosa g              ON g.id_glosa = sg.id_glosa
WHERE t.tipo = 'SC'
GROUP BY 1
ORDER BY 2 DESC;

-- R9. Las 10 configuraciones de mano más usadas
SELECT sdc.datos_fonologicos ->> 'configuracion' AS configuracion, COUNT(*) AS num_senas
FROM sena_diccionario sdc
GROUP BY 1
ORDER BY 2 DESC, 1
LIMIT 10;

-- R10. Las 10 ubicaciones más frecuentes
SELECT sdc.datos_fonologicos ->> 'ubicacion' AS ubicacion, COUNT(*) AS num_senas
FROM sena_diccionario sdc
GROUP BY 1
ORDER BY 2 DESC, 1
LIMIT 10;

-- R11. Búsqueda fonológica combinada: configuración y ubicación exactas
SELECT g.glosa
FROM sena_diccionario sdc
JOIN sena_glosa sg ON sg.id_sena = sdc.id_sena
JOIN glosa g       ON g.id_glosa = sg.id_glosa
WHERE sdc.datos_fonologicos @> '{"configuracion": "A.1", "ubicacion": "A la altura del pecho."}'
ORDER BY g.glosa;

-- R12. Señas que se hacen en una parte del cuerpo (búsqueda de texto)
SELECT g.glosa, sdc.datos_fonologicos ->> 'ubicacion' AS ubicacion
FROM sena_diccionario sdc
JOIN sena_glosa sg ON sg.id_sena = sdc.id_sena
JOIN glosa g       ON g.id_glosa = sg.id_glosa
WHERE sdc.datos_fonologicos ->> 'ubicacion' ILIKE '%frente%'
ORDER BY g.glosa;

-- R13. Pares mínimos que solo cambian la configuración de la mano
WITH f AS (
    SELECT sdc.id_sena, g.glosa,
           sdc.datos_fonologicos ->> 'configuracion' AS c,
           COALESCE(sdc.datos_fonologicos ->> 'ubicacion', '')   AS u,
           COALESCE(sdc.datos_fonologicos ->> 'movimiento', '')  AS m,
           COALESCE(sdc.datos_fonologicos ->> 'orientacion', '') AS o
    FROM sena_diccionario sdc
    JOIN sena_glosa sg ON sg.id_sena = sdc.id_sena
    JOIN glosa g       ON g.id_glosa = sg.id_glosa
)
SELECT a.glosa AS sena_a, b.glosa AS sena_b, a.c AS config_a, b.c AS config_b
FROM f a
JOIN f b ON a.id_sena < b.id_sena
WHERE a.c <> b.c AND a.u = b.u AND a.m = b.m AND a.o = b.o
ORDER BY a.glosa, b.glosa;

-- R14. Señas cuyo rasgo no manual es una expresión de las cejas
SELECT g.glosa, sdc.datos_fonologicos ->> 'rasgos_no_manuales' AS rasgos_no_manuales
FROM sena_diccionario sdc
JOIN sena_glosa sg ON sg.id_sena = sdc.id_sena
JOIN glosa g       ON g.id_glosa = sg.id_glosa
WHERE sdc.datos_fonologicos ->> 'rasgos_no_manuales' ILIKE '%ceja%'
ORDER BY g.glosa;

-- R15. Señas con nota cultural (qué comunidad las usa)
SELECT g.glosa, sdc.datos_fonologicos ->> 'nota_cultural' AS nota_cultural
FROM sena_diccionario sdc
JOIN sena_glosa sg ON sg.id_sena = sdc.id_sena
JOIN glosa g       ON g.id_glosa = sg.id_glosa
WHERE sdc.datos_fonologicos ? 'nota_cultural'
ORDER BY g.glosa;

-- R16. Señas icónicas: qué acción o forma imitan
SELECT g.glosa, sdc.datos_fonologicos ->> 'representacion' AS representacion
FROM sena_diccionario sdc
JOIN sena_glosa sg ON sg.id_sena = sdc.id_sena
JOIN glosa g       ON g.id_glosa = sg.id_glosa
WHERE sdc.datos_fonologicos ->> 'representacion' ILIKE 'Simula%'
ORDER BY g.glosa;

-- R17. Lugares: estaciones del Metro y señas de lugares del mundo
SELECT CASE WHEN sdc.datos_fonologicos ->> 'significado' LIKE '%(STC Metro)%' THEN 'Metro CDMX'
            ELSE 'Lugar del mundo' END AS tipo_lugar,
       g.glosa, sdc.datos_fonologicos ->> 'significado' AS significado
FROM sena_diccionario sdc
JOIN sena_glosa sg ON sg.id_sena = sdc.id_sena
JOIN glosa g       ON g.id_glosa = sg.id_glosa
WHERE sdc.datos_fonologicos ->> 'significado' ~ '\((STC Metro|SS[Il])\)'
ORDER BY tipo_lugar, g.glosa;

-- R18. Señas por categoría gramatical (sustantivos, verbos, adjetivos...)
SELECT COALESCE(LOWER(SUBSTRING(d.definicion FROM '^\d?\.?\s*([a-zA-Z]+\.)')), '(otro)') AS categoria,
       COUNT(*) AS num_senas
FROM definicion d
GROUP BY 1
ORDER BY 2 DESC;

-- R19. Búsqueda libre dentro de las definiciones
SELECT g.glosa, d.definicion
FROM definicion d
JOIN sena_definicion x ON x.id_definicion = d.id_definicion
JOIN sena_glosa sg     ON sg.id_sena = x.id_sena
JOIN glosa g           ON g.id_glosa = sg.id_glosa
WHERE d.definicion ILIKE '%comida%'
ORDER BY g.glosa;

-- R20. Señas por grupo de configuración del diccionario (prefijo del código)
SELECT REGEXP_REPLACE(sdc.datos_fonologicos ->> 'codigo', '[- ]?\d+$', '') AS grupo,
       COUNT(*) AS num_senas
FROM sena_diccionario sdc
GROUP BY 1
ORDER BY 2 DESC;
