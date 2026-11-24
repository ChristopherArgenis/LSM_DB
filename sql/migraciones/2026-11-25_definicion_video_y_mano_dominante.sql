-- =====================================================================
-- LSM_DB - Actualizar la base que ya tienes (sin borrarla)
--
--   1. Crear la tabla definicion_video.
--   2. Agregar el atributo id_definicion_video a definicion.
--   3. Relacionarlas: definicion.id_definicion_video -> definicion_video.
--   4. Pasar mano_dominante de video a senante.
--
-- En DBeaver: abre este archivo conectado a tu base y ejecútalo
-- completo con Alt+X. Va entre BEGIN y COMMIT: si un paso falla, no se
-- aplica ninguno. Córrelo una sola vez.
--
-- Una base nueva no lo necesita: sql/01_schema.sql ya la crea así.
-- =====================================================================
BEGIN;

SET search_path TO lsm;

-- 1. Nueva tabla: el video de una definición (solo su ruta)
CREATE TABLE definicion_video (
    id_definicion_video  INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    path                 TEXT NOT NULL
);

-- 2. Nuevo atributo en definicion (opcional: hoy ninguna tiene video)
ALTER TABLE definicion
    ADD COLUMN id_definicion_video INTEGER;

-- 3. Relación DEFINICIÓN «Tiene» DEFINICIÓN_VIDEO (N definiciones, 1 video)
ALTER TABLE definicion
    ADD CONSTRAINT definicion_id_definicion_video_fkey
    FOREIGN KEY (id_definicion_video)
    REFERENCES definicion_video (id_definicion_video)
    ON DELETE SET NULL;

CREATE INDEX idx_definicion_video ON definicion (id_definicion_video);

-- 4. mano_dominante pasa de video a senante (es de la persona)
ALTER TABLE senante
    ADD COLUMN mano_dominante VARCHAR(20);

--    Si ya había videos con ese dato, se copia a su señante
UPDATE senante st
   SET mano_dominante = v.mano_dominante
  FROM (SELECT DISTINCT ON (id_senante) id_senante, mano_dominante
          FROM video
         WHERE mano_dominante IS NOT NULL
         ORDER BY id_senante) v
 WHERE v.id_senante = st.id_senante;

ALTER TABLE video
    DROP COLUMN mano_dominante;

COMMIT;

-- Comprobación: deben salir 4 filas
--   definicion|id_definicion_video, definicion_video|id_definicion_video,
--   definicion_video|path, senante|mano_dominante
SELECT table_name, column_name
FROM information_schema.columns
WHERE table_schema = 'lsm'
  AND (table_name = 'definicion_video'
       OR (table_name = 'definicion' AND column_name = 'id_definicion_video')
       OR (table_name IN ('senante', 'video') AND column_name = 'mano_dominante'))
ORDER BY table_name, column_name;
