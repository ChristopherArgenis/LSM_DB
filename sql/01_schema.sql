-- =====================================================================
-- LSM_DB - Esquema PostgreSQL
-- Réplica del Diagrama Entidad-Relación del proyecto.
--
-- Notas de nomenclatura:
--   * Los nombres con "Ñ" del diagrama se escriben sin ella para evitar
--     identificadores entre comillas: SEÑA -> sena, SEÑANTE -> senante.
--   * "str" del diagrama -> VARCHAR / TEXT, "int" -> INTEGER,
--     "date" -> DATE, "jsonb" -> JSONB.
--   * Las PK se generan automáticamente (GENERATED ALWAYS AS IDENTITY).
-- =====================================================================

DROP SCHEMA IF EXISTS lsm CASCADE;
CREATE SCHEMA lsm;
SET search_path TO lsm;

-- ---------------------------------------------------------------------
-- LENGUA
-- En el diagrama "nombre_completo" aparece como int; se usa VARCHAR
-- porque guarda un nombre (p. ej. "Lengua de Señas Mexicana").
-- ---------------------------------------------------------------------
CREATE TABLE lengua (
    id_lengua        INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre_completo  VARCHAR(150) NOT NULL,
    modalidad        VARCHAR(50)
);

-- ---------------------------------------------------------------------
-- DEFINICION  (LENGUA "Contiene" DEFINICION, 1:N)
-- ---------------------------------------------------------------------
CREATE TABLE definicion (
    id_definicion  INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    definicion     TEXT NOT NULL,
    autor          VARCHAR(150),
    fecha          DATE,
    id_lengua      INTEGER NOT NULL REFERENCES lengua (id_lengua)
);

-- ---------------------------------------------------------------------
-- PALABRA  (LENGUA "Contiene" PALABRA, 1:N)
-- En el diagrama id_lengua no está marcado como FK, pero la relación
-- "Contiene" lo conecta con LENGUA, así que se declara como FK.
-- ---------------------------------------------------------------------
CREATE TABLE palabra (
    id_palabra  INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    palabra     VARCHAR(150) NOT NULL,
    id_lengua   INTEGER NOT NULL REFERENCES lengua (id_lengua)
);

-- ---------------------------------------------------------------------
-- GLOSA  (LENGUA "contiene" GLOSA, 1:N)
-- ---------------------------------------------------------------------
CREATE TABLE glosa (
    id_glosa   INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    glosa      VARCHAR(150) NOT NULL,
    autor      VARCHAR(150),
    fecha      DATE,
    id_lengua  INTEGER NOT NULL REFERENCES lengua (id_lengua)
);

-- ---------------------------------------------------------------------
-- TIPO_SEÑA  (catálogo: TIPO_SEÑA 1:N SENA)
-- ---------------------------------------------------------------------
CREATE TABLE tipo_sena (
    id_tipo_sena  INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tipo          VARCHAR(100) NOT NULL UNIQUE
);

-- ---------------------------------------------------------------------
-- SENA  (LENGUA "Clasifica" SENA, 1:N; TIPO_SEÑA 1:N SENA)
-- ---------------------------------------------------------------------
CREATE TABLE sena (
    id_sena    INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_tipo    INTEGER REFERENCES tipo_sena (id_tipo_sena),
    id_lengua  INTEGER NOT NULL REFERENCES lengua (id_lengua)
);

-- ---------------------------------------------------------------------
-- DICCIONARIO
-- ---------------------------------------------------------------------
CREATE TABLE diccionario (
    id_diccionario  INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre_completo VARCHAR(200) NOT NULL,
    autor           VARCHAR(150)
);

-- ---------------------------------------------------------------------
-- SEÑANTE
-- ---------------------------------------------------------------------
CREATE TABLE senante (
    id_senante     INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    edad           INTEGER CHECK (edad >= 0),
    perfil_nativo  VARCHAR(100)
);

-- ---------------------------------------------------------------------
-- VIDEO  (SEÑANTE "registra" VIDEO, 1:N)
-- ---------------------------------------------------------------------
CREATE TABLE video (
    id_video        INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    mano_dominante  VARCHAR(20),
    tipo_de_toma    VARCHAR(50),
    path            TEXT NOT NULL,
    fecha           DATE,
    id_senante      INTEGER NOT NULL REFERENCES senante (id_senante)
);

-- ---------------------------------------------------------------------
-- Tablas intermedias (relaciones N:M de SENA)
-- ---------------------------------------------------------------------

-- SEÑA_DEFINICION  (SENA "relacion" / DEFINICION "asocia")
CREATE TABLE sena_definicion (
    id_sena_definicion  INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_sena             INTEGER NOT NULL REFERENCES sena (id_sena) ON DELETE CASCADE,
    id_definicion       INTEGER NOT NULL REFERENCES definicion (id_definicion) ON DELETE CASCADE,
    UNIQUE (id_sena, id_definicion)
);

-- SENA_PALABRA  (SENA "relaciona" / PALABRA "asocia")
CREATE TABLE sena_palabra (
    id_sena_palabra  INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_sena          INTEGER NOT NULL REFERENCES sena (id_sena) ON DELETE CASCADE,
    id_palabra       INTEGER NOT NULL REFERENCES palabra (id_palabra) ON DELETE CASCADE,
    UNIQUE (id_sena, id_palabra)
);

-- SENA_GLOSA  (SENA "relaciona" / GLOSA "asocia")
CREATE TABLE sena_glosa (
    id_sena_glosa  INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_sena        INTEGER NOT NULL REFERENCES sena (id_sena) ON DELETE CASCADE,
    id_glosa       INTEGER NOT NULL REFERENCES glosa (id_glosa) ON DELETE CASCADE,
    UNIQUE (id_sena, id_glosa)
);

-- ---------------------------------------------------------------------
-- Validación de datos_fonologicos (JSONB)
-- Misma definición que schemas/datos_fonologicos.schema.json y
-- docs/DATOS_FONOLOGICOS.md. Si cambias una, cambia las tres.
--   * Obligatorias: codigo, significado, tipo_sena, configuracion, ubicacion
--   * Opcionales:   orientacion, movimiento, rasgos_no_manuales,
--                   representacion, definicion, nota_cultural, pagina
--   * Todas son texto no vacío, salvo pagina (entero >= 1).
--   * No se permiten claves fuera de esta lista (evita "config" vs
--     "configuracion").
-- ---------------------------------------------------------------------
CREATE FUNCTION valida_datos_fonologicos(d JSONB) RETURNS BOOLEAN
LANGUAGE sql IMMUTABLE AS $$
    SELECT d IS NULL OR (
        jsonb_typeof(d) = 'object'
        AND d ?& ARRAY['codigo', 'significado', 'tipo_sena', 'configuracion', 'ubicacion']
        AND NOT EXISTS (
            SELECT 1 FROM jsonb_each(d) e
            WHERE e.key NOT IN ('codigo', 'significado', 'tipo_sena', 'configuracion',
                                'orientacion', 'ubicacion', 'movimiento',
                                'rasgos_no_manuales', 'representacion',
                                'definicion', 'nota_cultural', 'pagina')
               OR (e.key <> 'pagina' AND (jsonb_typeof(e.value) <> 'string'
                                          OR btrim(e.value #>> '{}') = ''))
               OR (e.key = 'pagina' AND (jsonb_typeof(e.value) <> 'number'
                                         OR (e.value #>> '{}')::numeric < 1
                                         OR (e.value #>> '{}')::numeric % 1 <> 0))
        )
    )
$$;

-- SEÑA_DICCIONARIO
--   SENA "pertenece", DICCIONARIO "contiene", LENGUA "identifica"
CREATE TABLE sena_diccionario (
    id_sena_diccionario  INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_sena              INTEGER NOT NULL REFERENCES sena (id_sena) ON DELETE CASCADE,
    id_diccionario       INTEGER NOT NULL REFERENCES diccionario (id_diccionario) ON DELETE CASCADE,
    id_lengua            INTEGER NOT NULL REFERENCES lengua (id_lengua),
    datos_fonologicos    JSONB CONSTRAINT datos_fonologicos_validos
                         CHECK (valida_datos_fonologicos(datos_fonologicos)),
    UNIQUE (id_sena, id_diccionario)
);

-- SENA_VIDEO
--   VIDEO "registra", SEÑA_DICCIONARIO "documenta"
--   En el diagrama id_sena_video aparece como FK pero subrayado como
--   identificador; se implementa como PK.
CREATE TABLE sena_video (
    id_sena_video        INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_video             INTEGER NOT NULL REFERENCES video (id_video) ON DELETE CASCADE,
    id_sena_diccionario  INTEGER NOT NULL REFERENCES sena_diccionario (id_sena_diccionario) ON DELETE CASCADE,
    UNIQUE (id_video, id_sena_diccionario)
);

-- ---------------------------------------------------------------------
-- Índices sobre llaves foráneas (PostgreSQL no los crea solo)
-- ---------------------------------------------------------------------
CREATE INDEX idx_definicion_lengua        ON definicion (id_lengua);
CREATE INDEX idx_palabra_lengua           ON palabra (id_lengua);
CREATE INDEX idx_palabra_lower            ON palabra (LOWER(palabra));
CREATE INDEX idx_glosa_lengua             ON glosa (id_lengua);
CREATE INDEX idx_sena_lengua              ON sena (id_lengua);
CREATE INDEX idx_sena_tipo                ON sena (id_tipo);
CREATE INDEX idx_video_senante            ON video (id_senante);
CREATE INDEX idx_sena_definicion_def      ON sena_definicion (id_definicion);
CREATE INDEX idx_sena_palabra_palabra     ON sena_palabra (id_palabra);
CREATE INDEX idx_sena_glosa_glosa         ON sena_glosa (id_glosa);
CREATE INDEX idx_sena_diccionario_dic     ON sena_diccionario (id_diccionario);
CREATE INDEX idx_sena_diccionario_lengua  ON sena_diccionario (id_lengua);
CREATE INDEX idx_sena_video_sd            ON sena_video (id_sena_diccionario);
CREATE INDEX idx_sena_diccionario_fono    ON sena_diccionario USING GIN (datos_fonologicos);
CREATE INDEX idx_sena_diccionario_codigo  ON sena_diccionario ((datos_fonologicos ->> 'codigo'));
