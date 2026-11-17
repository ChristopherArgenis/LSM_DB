-- =====================================================================
-- LSM_DB - Las 6 limitaciones de la presentación, revisadas con consultas
-- Requiere: 01_schema.sql, 02_datos_dlsm_cdmx.sql, 02b_glosas_dlsm_cdmx.sql
-- En DBeaver: ejecutar el SET y luego cada consulta con Ctrl+Enter.
-- La explicación completa está en docs/LIMITACIONES_REVISADAS.md.
--
--   Limitación                     Veredicto
--   1. Todo depende de la seña     No es problema: es la regla del modelo
--   2. Sentidos mezclados          Ya no es problema: glosa + definición
--   3. Variantes en el texto       Ya no es problema: glosas -A, -B
--   4. Fonología en texto libre    Sigue vigente: falta discretizar
--   5. Solo la palabra exacta      No es del esquema: lo resuelve la búsqueda
--   6. Compuestas sin sus partes   Sigue vigente: trabajo futuro
-- =====================================================================
SET search_path TO lsm;

-- =====================================================================
-- 1. TODO DEPENDE DE LA SEÑA
-- Planteamiento anterior: "si una palabra no tiene seña, queda aislada".
-- Planteamiento nuevo: la base es un diccionario DE SEÑAS; una palabra,
-- glosa o definición solo entra porque describe una seña. Que no haya
-- elementos sueltos es la regla, no un fallo.
-- =====================================================================

-- 1a. Elementos sin seña (esperado: 0, 0, 0)
SELECT (SELECT COUNT(*) FROM palabra p
         WHERE NOT EXISTS (SELECT 1 FROM sena_palabra x WHERE x.id_palabra = p.id_palabra))        AS palabras_sin_sena,
       (SELECT COUNT(*) FROM glosa g
         WHERE NOT EXISTS (SELECT 1 FROM sena_glosa x WHERE x.id_glosa = g.id_glosa))              AS glosas_sin_sena,
       (SELECT COUNT(*) FROM definicion d
         WHERE NOT EXISTS (SELECT 1 FROM sena_definicion x WHERE x.id_definicion = d.id_definicion)) AS definiciones_sin_sena;

-- 1b. Una palabra que no está en el diccionario simplemente no aparece
--     (esperado: 0 filas). No hay nada que "rescatar": no hay seña.
SELECT p.palabra FROM palabra p WHERE LOWER(p.palabra) = 'perro';

-- =====================================================================
-- 2. SENTIDOS MEZCLADOS  (caso ABANDONAR)
-- Planteamiento anterior: "Abandonar tiene 6 señas, ¿cuál es cuál?".
-- Ahora: cada seña tiene su propia glosa y su propia definición, así que
-- la base sí distingue las 6 y dice qué sentido tiene cada una.
-- =====================================================================

-- 2a. Las 6 señas de "Abandonar", cada una con su glosa y su definición
SELECT g.glosa,
       sdc.datos_fonologicos ->> 'codigo'      AS codigo,
       sdc.datos_fonologicos ->> 'significado' AS significado,
       d.definicion
FROM palabra p
JOIN sena_palabra sp      ON sp.id_palabra = p.id_palabra
JOIN sena_glosa sg        ON sg.id_sena = sp.id_sena
JOIN glosa g              ON g.id_glosa = sg.id_glosa
JOIN sena_diccionario sdc ON sdc.id_sena = sp.id_sena
JOIN sena_definicion sd   ON sd.id_sena = sp.id_sena
JOIN definicion d         ON d.id_definicion = sd.id_definicion
WHERE LOWER(p.palabra) = 'abandonar'
ORDER BY g.glosa;

-- 2b. La pregunta de la presentación: "¿qué seña uso para decir que dejé
--     mi trabajo?" Se busca el sentido en la definición.
--     Resultado: ABANDONAR-2 (acepción 2: suspender una actividad u
--     ocupación) y ABANDONAR-C (dejar por desdeño una actividad).
SELECT g.glosa, d.definicion
FROM palabra p
JOIN sena_palabra sp    ON sp.id_palabra = p.id_palabra
JOIN sena_glosa sg      ON sg.id_sena = sp.id_sena
JOIN glosa g            ON g.id_glosa = sg.id_glosa
JOIN sena_definicion sd ON sd.id_sena = sp.id_sena
JOIN definicion d       ON d.id_definicion = sd.id_definicion
WHERE LOWER(p.palabra) = 'abandonar'
  AND (d.definicion ILIKE '%actividad%' OR d.definicion ILIKE '%ocupación%')
ORDER BY g.glosa;

-- 2c. Por qué hay -1, -2, -3 y también -A, -B, -C:
--     -A/-B/-C: el diccionario las marca como variantes "(A)", "(B)", "(C)".
--     -1/-2/-3: el diccionario repite "Abandonar" sin letra en códigos
--     distintos (A-7, S-4, C-1); son señas distintas y la glosa necesita
--     un número para ser única (ID-glosa).
SELECT g.glosa,
       sdc.datos_fonologicos ->> 'codigo'        AS codigo,
       sdc.datos_fonologicos ->> 'configuracion' AS configuracion,
       sdc.datos_fonologicos ->> 'ubicacion'     AS ubicacion
FROM glosa g
JOIN sena_glosa sg        ON sg.id_glosa = g.id_glosa
JOIN sena_diccionario sdc ON sdc.id_sena = sg.id_sena
WHERE g.glosa LIKE 'ABANDONAR%'
ORDER BY g.glosa;

-- =====================================================================
-- 3. VARIANTES EN EL TEXTO  (caso CASA)
-- Planteamiento anterior: "la letra (A)/(B) solo vive en el texto".
-- Ahora: la glosa la vuelve dato: CASA-A y CASA-B se pueden consultar,
-- contar y agrupar.
-- =====================================================================

-- 3a. Las dos variantes de Casa y en qué se diferencian
SELECT g.glosa,
       sdc.datos_fonologicos ->> 'codigo'        AS codigo,
       sdc.datos_fonologicos ->> 'configuracion' AS configuracion,
       sdc.datos_fonologicos ->> 'ubicacion'     AS ubicacion
FROM glosa g
JOIN sena_glosa sg        ON sg.id_glosa = g.id_glosa
JOIN sena_diccionario sdc ON sdc.id_sena = sg.id_sena
WHERE g.glosa LIKE 'CASA-%'
ORDER BY g.glosa;

-- 3b. Cuántas glosas son variantes (terminan en -A, -B, -C...)
SELECT COUNT(*) AS glosas_variante FROM glosa WHERE glosa ~ '-[A-Z]$';

-- 3c. Las palabras con más variantes
SELECT REGEXP_REPLACE(glosa, '-[A-Z]$', '') AS glosa_base,
       COUNT(*) AS variantes,
       STRING_AGG(glosa, ', ' ORDER BY glosa) AS glosas
FROM glosa
WHERE glosa ~ '-[A-Z]$'
GROUP BY 1
HAVING COUNT(*) >= 3
ORDER BY 2 DESC, 1;

-- =====================================================================
-- 4. FONOLOGÍA EN TEXTO LIBRE
-- Sigue vigente. La configuración usa códigos (A.1, B-P.2) y se compara
-- bien; ubicación y movimiento son frases y una misma idea se escribe de
-- muchas formas. Lo resuelve la metadata discretizada (pendiente: JSON
-- del asesor).
-- =====================================================================

-- 4a. Valores distintos por campo (muchos para ubicación y movimiento)
SELECT COUNT(DISTINCT datos_fonologicos ->> 'configuracion') AS configuraciones,
       COUNT(DISTINCT datos_fonologicos ->> 'ubicacion')     AS ubicaciones,
       COUNT(DISTINCT datos_fonologicos ->> 'movimiento')    AS movimientos
FROM sena_diccionario;

-- 4b. "Pecho" escrito de muchas formas
SELECT datos_fonologicos ->> 'ubicacion' AS ubicacion, COUNT(*) AS senas
FROM sena_diccionario
WHERE datos_fonologicos ->> 'ubicacion' ILIKE '%pecho%'
GROUP BY 1
ORDER BY 2 DESC
LIMIT 10;

-- 4c. Igualdad exacta vs. búsqueda por texto (125 vs. 623)
SELECT (SELECT COUNT(*) FROM sena_diccionario
         WHERE datos_fonologicos ->> 'ubicacion' = 'A la altura del pecho.')  AS igualdad_exacta,
       (SELECT COUNT(*) FROM sena_diccionario
         WHERE datos_fonologicos ->> 'ubicacion' ILIKE '%pecho%')             AS contiene_pecho;

-- =====================================================================
-- 5. SOLO LA PALABRA EXACTA
-- Planteamiento anterior: "bonita y comí no dan resultados".
-- Planteamiento nuevo: el diccionario guarda lemas (forma de cita), como
-- todo diccionario. Pasar de "comí" a "comer" es tarea de la búsqueda,
-- no del esquema; PostgreSQL ya lo hace con su búsqueda de texto en
-- español, sin cambiar ninguna tabla.
-- =====================================================================

-- 5a. Igualdad exacta: 0 filas
SELECT palabra FROM palabra WHERE LOWER(palabra) IN ('bonita', 'comí');

-- 5b. Búsqueda de texto en español: "comí" -> COMER, "bonita" -> BONITO
SELECT b.buscado, g.glosa, p.palabra
FROM (VALUES ('comí'), ('bonita'), ('comiendo'), ('abandoné')) b(buscado)
JOIN palabra p       ON to_tsvector('spanish', p.palabra) @@ plainto_tsquery('spanish', b.buscado)
JOIN sena_palabra sp ON sp.id_palabra = p.id_palabra
JOIN sena_glosa sg   ON sg.id_sena = sp.id_sena
JOIN glosa g         ON g.id_glosa = sg.id_glosa
ORDER BY b.buscado, g.glosa;

-- 5c. Por qué funciona: las tres formas se reducen a la misma raíz
SELECT ts_lexize('spanish_stem', 'comí')     AS comi,
       ts_lexize('spanish_stem', 'comiendo') AS comiendo,
       ts_lexize('spanish_stem', 'comer')    AS comer;

-- =====================================================================
-- 6. COMPUESTAS SIN SUS PARTES  (caso ACTA-DE-NACIMIENTO)
-- Sigue vigente. Las 140 señas compuestas describen sus partes (I., II.)
-- dentro del texto, pero la base no sabe qué seña es cada parte.
-- =====================================================================

-- 6a. Cuántas señas compuestas hay
SELECT COUNT(*) AS compuestas
FROM sena s JOIN tipo_sena t ON t.id_tipo_sena = s.id_tipo
WHERE t.tipo = 'SC';

-- 6b. Se ve a simple vista que ACTA-DE-NACIMIENTO = ACTA + NACER
--     (parte I igual a ACTA; parte II casi igual a NACER), pero no hay
--     ninguna fila que lo diga.
SELECT g.glosa,
       sdc.datos_fonologicos ->> 'configuracion' AS configuracion,
       sdc.datos_fonologicos ->> 'ubicacion'     AS ubicacion,
       sdc.datos_fonologicos ->> 'movimiento'    AS movimiento
FROM glosa g
JOIN sena_glosa sg        ON sg.id_glosa = g.id_glosa
JOIN sena_diccionario sdc ON sdc.id_sena = sg.id_sena
WHERE g.glosa IN ('ACTA', 'NACER', 'ACTA-DE-NACIMIENTO')
ORDER BY g.glosa;

-- 6c. Demostración sobre la estructura: no existe una tabla que ligue
--     una seña compuesta con sus partes (0 filas).
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'lsm' AND table_name ILIKE '%compo%';
