-- =====================================================================
-- LSM_DB · Esquema de METADATOS en notación SQL
--
-- Es el mismo esquema de metadatos/esquema_metadatos.txt, escrito con
-- tipos de PostgreSQL para archivarlo y revisarlo.
--
-- METADATOS NO vive en la base de datos. Este archivo empieza con BEGIN
-- y termina con ROLLBACK: si lo ejecutas (Alt+X en DBeaver), PostgreSQL
-- revisa que la definición sea válida y después lo deshace todo. No
-- deja nada creado.
--
-- Lectura rápida:
--   DOMAIN = lista cerrada de valores permitidos
--   TYPE   = estructura de un objeto JSON (sus claves y tipos)
--   NOT NULL no se puede poner dentro de un TYPE, así que «obligatorio»
--   y «opcional» van en los comentarios. Opcional = la clave se OMITE
--   del JSON cuando no aplica (nunca [] ni null).
-- =====================================================================
BEGIN;

CREATE SCHEMA metadatos_esquema;
SET search_path TO metadatos_esquema;

-- ---------------------------------------------------------------------
-- Listas cerradas
-- ---------------------------------------------------------------------

-- Familias de configuración manual (25, como aparecen en el DLSM CDMX 2017).
-- Solo la familia: «B-P», no «B-P.12».
CREATE DOMAIN cm AS VARCHAR(3)
    CHECK (VALUE IN ('1', '1-I', '2', '3', '4', '5', '8',
                     'A', 'B-P', 'C', 'D', 'E', 'F', 'H', 'I', 'L', 'M',
                     'N', 'O', 'P', 'Q', 'R', 'S', 'U', 'Y'));

-- Zonas del cuerpo (22, de la cabeza hacia abajo).
-- «Mano» = sobre la otra mano (palma, dorso, dedos).
CREATE DOMAIN zona AS VARCHAR(10)
    CHECK (VALUE IN ('Cabeza', 'Frente', 'Sien', 'Ceja', 'Ojo', 'Nariz',
                     'Mejilla', 'Oreja', 'Boca', 'Barbilla', 'Cara',
                     'Cuello', 'Hombro', 'Pecho', 'Plexo', 'Abdomen',
                     'Cintura', 'Cadera', 'Brazo', 'Muñeca', 'Mano',
                     'Espalda'));

-- Orientación de la palma (opcional; no se genera en la versión 1).
CREATE DOMAIN orientacion AS VARCHAR(10)
    CHECK (VALUE IN ('Arriba', 'Abajo', 'Adentro', 'Afuera', 'Centro',
                     'Izquierda', 'Derecha', 'Oblicua'));

-- Movimiento (opcional; no se genera en la versión 1).
CREATE DOMAIN movimiento AS VARCHAR(10)
    CHECK (VALUE IN ('Recto', 'Arco', 'Circular', 'Zigzag', 'Ondulante',
                     'Contacto', 'Desliza', 'Repetido', 'Alternado',
                     'Giro', 'Dedos', 'Agitar'));

-- ---------------------------------------------------------------------
-- «presencia»: resumen de todo lo que aparece en la seña, sin repetir
-- ---------------------------------------------------------------------
CREATE TYPE presencia AS (
    cm_dominante           cm[],           -- Obligatorio
    cm_base                cm[],           -- Opcional. Solo si interviene la mano base
    ubicacion_dominante    zona[],         -- Obligatorio
    ubicacion_base         zona[],         -- Opcional
    orientacion_dominante  orientacion[],  -- Opcional
    orientacion_base       orientacion[],  -- Opcional
    movimiento_dominante   movimiento[],   -- Opcional
    movimiento_base        movimiento[]    -- Opcional
);

-- ---------------------------------------------------------------------
-- Un momento de la «linea_temporal»
-- «pasa de X a Y» = 2 momentos; «I. …; II. …» = uno o más por parte.
-- B-P.2 → B-P.12 son 2 momentos (B-P, B-P): la mano sí cambia.
-- ---------------------------------------------------------------------
CREATE TYPE momento AS (
    orden                  INTEGER,        -- Obligatorio. 1, 2, 3...
    cm_dominante           cm,             -- Obligatorio*. UNA familia por momento
    cm_base                cm,             -- Opcional. UNA familia por momento
    ubicacion_dominante    zona[],         -- Opcional. Solo en señas compuestas (I., II.)
    ubicacion_base         zona[],         -- Opcional. Solo en señas compuestas (I., II.)
    orientacion_dominante  orientacion[],  -- Opcional
    orientacion_base       orientacion[],  -- Opcional
    movimiento_dominante   movimiento[],   -- Opcional
    movimiento_base        movimiento[]    -- Opcional
);
-- * Falta solo si en ese momento actúa únicamente la mano base
--   (HOZ, S-59) o si el diccionario tiene una errata en el código.

-- ---------------------------------------------------------------------
-- METADATOS completo
-- ---------------------------------------------------------------------
CREATE TYPE metadatos AS (
    presencia       presencia,             -- Obligatorio
    linea_temporal  momento[]              -- Obligatorio. Al menos un momento, en orden
);

-- ---------------------------------------------------------------------
-- Una seña en el archivo metadatos.json
-- ---------------------------------------------------------------------
CREATE TYPE sena_metadatos AS (
    codigo     VARCHAR(20),                -- Obligatorio. Código en el diccionario (B-P 52)
    glosa      VARCHAR(150),               -- Obligatorio. Glosa en la base (AVANZADO-B)
    "METADATOS" metadatos                  -- Obligatorio
);

-- ---------------------------------------------------------------------
-- Ejemplo: AVANZADO-B (B-P 52) escrito con estos tipos.
-- Si un valor no está en su lista cerrada, esta consulta da error.
-- ---------------------------------------------------------------------
SELECT ROW(
    'B-P 52',
    'AVANZADO-B',
    ROW(
        ROW(ARRAY['B-P']::cm[], ARRAY['B-P']::cm[],
            ARRAY['Cabeza']::zona[], ARRAY['Pecho']::zona[],
            NULL, NULL, NULL, NULL)::presencia,
        ARRAY[ ROW(1, 'B-P', 'B-P', NULL, NULL, NULL, NULL, NULL, NULL)::momento ]
    )::metadatos
)::sena_metadatos AS ejemplo;

ROLLBACK;   -- deshace todo: no queda nada en la base
