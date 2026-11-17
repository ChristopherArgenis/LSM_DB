-- =====================================================================
-- LSM_DB - Quitar la referencia redundante SEÑA_DICCIONARIO -> LENGUA
-- (columna sena_diccionario.id_lengua y la relación "identifica")
--
-- En DBeaver: "Ejecutar script" (Alt+X). El cambio va en un solo bloque:
-- si la verificación falla, no se borra nada.
-- =====================================================================
--
-- FUNDAMENTO
-- ----------
-- 1. Qué es una redundancia.
--    En el modelo relacional, un dato es redundante cuando se puede
--    deducir de otro que ya está guardado. Guardarlo dos veces no aporta
--    información nueva y abre la puerta a que ambas copias digan cosas
--    distintas (una "anomalía de actualización").
--
-- 2. Por qué sena_diccionario.id_lengua es redundante.
--    Una fila de sena_diccionario es "una seña descrita por un
--    diccionario": tiene id_sena e id_diccionario. La lengua de esa
--    entrada es, por definición, la lengua de la seña que describe, y esa
--    lengua ya está en sena.id_lengua. Por lo tanto:
--
--        sena_diccionario.id_sena  ->  sena.id_lengua
--
--    determina la lengua de la entrada sin necesidad de guardarla otra
--    vez. En términos de normalización, id_lengua depende de id_sena y no
--    de la llave de sena_diccionario: es una dependencia transitiva, lo
--    que la Tercera Forma Normal (3FN) pide eliminar.
--
-- 3. Qué riesgo concreto tiene.
--    Ninguna regla obliga a que las dos columnas coincidan. Se podría
--    guardar una entrada con id_lengua = ASL para una seña cuya
--    sena.id_lengua = LSM, y la base lo aceptaría. Con un solo
--    diccionario no pasa, pero al cargar más diccionarios y lenguas el
--    riesgo crece (techo L10 en 05_consultas_limitaciones.sql).
--
-- 4. Por qué NO se pierde información.
--    No se quita "la lengua" del modelo, solo su copia:
--      * La lengua de la seña sigue en sena.id_lengua.
--      * La lengua de cada texto sigue en palabra, glosa y definicion
--        (el idioma en que está escrito: Español, Inglés...).
--    Antes de borrar, el script comprueba que todas las entradas tengan
--    la misma lengua que su seña. Si alguna no coincide, se detiene sin
--    tocar nada, porque esa diferencia sí sería información a revisar.
--
-- 5. Lengua y diccionario no se confunden.
--    Son ejes independientes: la lengua dice EN QUÉ idioma está algo; el
--    diccionario dice QUÉ FUENTE lo afirma. Un diccionario bilingüe tiene
--    textos en dos idiomas, y un idioma tiene muchos diccionarios. Por eso
--    la lengua no debe vivir en la relación con el diccionario, sino en
--    lo que describe (la seña o el texto).
--
-- 6. Cómo se obtiene la lengua después del cambio.
--    Con un JOIN a sena (ver la consulta del final). Es la misma
--    información, leída de un solo lugar.
--
-- QUÉ HACE ESTE SCRIPT
-- --------------------
--   a) Verifica que sena_diccionario.id_lengua = sena.id_lengua en todas
--      las filas.
--   b) Borra el índice idx_sena_diccionario_lengua.
--   c) Borra la llave foránea sena_diccionario -> lengua.
--   d) Borra la columna sena_diccionario.id_lengua.
--
-- DESPUÉS DE EJECUTARLO
-- ---------------------
--   * El diagrama ER ya no tiene el atributo FK id_lengua en SEÑA_DICCIONARIO
--     ni la línea "identifica" (docs/img/diagrama_er.png).
--   * Los scripts del repositorio ya están actualizados (este cambio solo
--     hace falta en bases creadas antes del 2026-11-11):
--       01_schema.sql, 02_datos_dlsm_cdmx.sql, 03_consultas.sql (I3)
--       y 05_consultas_limitaciones.sql (L10).
-- =====================================================================
SET search_path TO lsm;

DO $$
DECLARE
    distintas INTEGER;
BEGIN
    -- Si la columna ya no existe, no hay nada que hacer
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_schema = 'lsm' AND table_name = 'sena_diccionario'
                     AND column_name = 'id_lengua') THEN
        RAISE NOTICE 'sena_diccionario.id_lengua ya no existe: nada que hacer.';
        RETURN;
    END IF;

    -- a) Verificación: la lengua de cada entrada debe ser la de su seña
    EXECUTE 'SELECT COUNT(*) FROM lsm.sena_diccionario sdc
             JOIN lsm.sena s ON s.id_sena = sdc.id_sena
             WHERE sdc.id_lengua IS DISTINCT FROM s.id_lengua'
    INTO distintas;

    IF distintas > 0 THEN
        RAISE EXCEPTION '% entradas tienen una lengua distinta a la de su seña. Revísalas antes de quitar la columna.', distintas;
    END IF;

    -- b) c) d) Quitar índice, llave foránea y columna
    DROP INDEX IF EXISTS lsm.idx_sena_diccionario_lengua;
    ALTER TABLE lsm.sena_diccionario DROP CONSTRAINT IF EXISTS sena_diccionario_id_lengua_fkey;
    ALTER TABLE lsm.sena_diccionario DROP COLUMN id_lengua;

    RAISE NOTICE 'Listo: se quitó sena_diccionario.id_lengua (todas las entradas coincidían con su seña).';
END $$;

-- ---------------------------------------------------------------------
-- Comprobación: columnas de sena_diccionario después del cambio
-- (ya no aparece id_lengua)
-- ---------------------------------------------------------------------
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'lsm' AND table_name = 'sena_diccionario'
ORDER BY ordinal_position;

-- ---------------------------------------------------------------------
-- Cómo obtener ahora la lengua de cada entrada de diccionario:
-- a través de la seña.
-- ---------------------------------------------------------------------
SELECT dic.nombre_completo AS diccionario,
       l.nombre_completo   AS lengua_de_la_sena,
       COUNT(*)            AS entradas
FROM sena_diccionario sdc
JOIN sena s          ON s.id_sena = sdc.id_sena
JOIN lengua l        ON l.id_lengua = s.id_lengua
JOIN diccionario dic ON dic.id_diccionario = sdc.id_diccionario
GROUP BY dic.nombre_completo, l.nombre_completo;
