-- =====================================================================
-- LSM_DB - Actualizar una base EXISTENTE al diagrama ER actual
-- (docs/img/diagrama_er.png), sin borrarla ni volver a cargarla.
--
-- Para bases creadas antes del 2026-11-25. Una base nueva no lo
-- necesita: sql/01_schema.sql ya crea todo así.
--
-- CÓMO CORRERLO EN DBEAVER
--   1. (Recomendado) Haz un respaldo antes: docs/MANUAL_RESPALDO.pdf.
--   2. Abre este archivo conectado a tu base.
--   3. Ejecútalo completo con Alt+X («Ejecutar script»).
--   4. Revisa la pestaña de salida: cada cambio avisa si se aplicó o si
--      ya estaba.
--
-- Es un solo bloque: si algo falla, no se aplica NADA. Se puede correr
-- más de una vez: lo que ya está hecho, lo salta.
--
-- QUÉ CAMBIA
--   1. Nueva tabla definicion_video (id_definicion_video PK, path) y la
--      FK opcional definicion.id_definicion_video
--      (DEFINICIÓN «Tiene» DEFINICIÓN_VIDEO: N definiciones, 1 video).
--   2. sena_diccionario.id_lengua: si la base no la tiene, la agrega y
--      la llena con la lengua de cada seña (redundancia a propósito
--      para consultas por lengua; la consulta I3 vigila que coincida).
--   3. mano_dominante pasa de video a senante (es de la persona).
--      Si ya había videos con ese dato, se copia a su señante antes de
--      quitar la columna de video.
-- =====================================================================
DO $$
DECLARE
    conflictos integer;
BEGIN
    -- -----------------------------------------------------------------
    -- 1. definicion_video
    -- -----------------------------------------------------------------
    IF to_regclass('lsm.definicion_video') IS NULL THEN
        CREATE TABLE lsm.definicion_video (
            id_definicion_video  INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
            path                 TEXT NOT NULL
        );
        RAISE NOTICE '1a. Tabla definicion_video creada.';
    ELSE
        RAISE NOTICE '1a. La tabla definicion_video ya existía.';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_schema = 'lsm' AND table_name = 'definicion'
                     AND column_name = 'id_definicion_video') THEN
        ALTER TABLE lsm.definicion
            ADD COLUMN id_definicion_video INTEGER
            REFERENCES lsm.definicion_video (id_definicion_video) ON DELETE SET NULL;
        CREATE INDEX idx_definicion_video ON lsm.definicion (id_definicion_video);
        RAISE NOTICE '1b. Columna definicion.id_definicion_video agregada.';
    ELSE
        RAISE NOTICE '1b. definicion.id_definicion_video ya existía.';
    END IF;

    -- -----------------------------------------------------------------
    -- 2. sena_diccionario.id_lengua
    -- -----------------------------------------------------------------
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_schema = 'lsm' AND table_name = 'sena_diccionario'
                     AND column_name = 'id_lengua') THEN
        ALTER TABLE lsm.sena_diccionario
            ADD COLUMN id_lengua INTEGER REFERENCES lsm.lengua (id_lengua);
        UPDATE lsm.sena_diccionario sdc
           SET id_lengua = s.id_lengua
          FROM lsm.sena s
         WHERE s.id_sena = sdc.id_sena;
        ALTER TABLE lsm.sena_diccionario ALTER COLUMN id_lengua SET NOT NULL;
        CREATE INDEX idx_sena_diccionario_lengua ON lsm.sena_diccionario (id_lengua);
        RAISE NOTICE '2. Columna sena_diccionario.id_lengua agregada y llenada con la lengua de cada seña.';
    ELSE
        RAISE NOTICE '2. sena_diccionario.id_lengua ya existía.';
    END IF;

    -- -----------------------------------------------------------------
    -- 3. mano_dominante: de video a senante
    -- -----------------------------------------------------------------
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_schema = 'lsm' AND table_name = 'senante'
                     AND column_name = 'mano_dominante') THEN
        ALTER TABLE lsm.senante ADD COLUMN mano_dominante VARCHAR(20);
        RAISE NOTICE '3a. Columna senante.mano_dominante agregada.';
    ELSE
        RAISE NOTICE '3a. senante.mano_dominante ya existía.';
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.columns
               WHERE table_schema = 'lsm' AND table_name = 'video'
                 AND column_name = 'mano_dominante') THEN
        -- Un señante con videos de manos distintas no se puede mover solo.
        EXECUTE 'SELECT count(*) FROM (
                     SELECT id_senante FROM lsm.video
                      WHERE mano_dominante IS NOT NULL
                      GROUP BY id_senante
                     HAVING count(DISTINCT mano_dominante) > 1) x'
           INTO conflictos;
        IF conflictos > 0 THEN
            RAISE EXCEPTION '3b. % señante(s) tienen videos con distinta mano_dominante. Corrígelos antes; no se cambió nada.', conflictos;
        END IF;

        EXECUTE 'UPDATE lsm.senante st
                    SET mano_dominante = v.mano_dominante
                   FROM (SELECT DISTINCT id_senante, mano_dominante
                           FROM lsm.video WHERE mano_dominante IS NOT NULL) v
                  WHERE v.id_senante = st.id_senante
                    AND st.mano_dominante IS NULL';
        ALTER TABLE lsm.video DROP COLUMN mano_dominante;
        RAISE NOTICE '3b. mano_dominante copiada a senante y quitada de video.';
    ELSE
        RAISE NOTICE '3b. video ya no tenía mano_dominante.';
    END IF;
END
$$;

-- Comprobación (debe mostrar las columnas nuevas)
SELECT table_name, column_name
FROM information_schema.columns
WHERE table_schema = 'lsm'
  AND ((table_name = 'definicion_video')
    OR (table_name = 'definicion'       AND column_name = 'id_definicion_video')
    OR (table_name = 'sena_diccionario' AND column_name = 'id_lengua')
    OR (table_name IN ('senante', 'video') AND column_name = 'mano_dominante'))
ORDER BY table_name, column_name;
