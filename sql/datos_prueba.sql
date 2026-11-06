-- =====================================================================
-- LSM_DB - Datos de prueba
-- Datos INVENTADOS para probar consultas (docs/CONSULTAS.md).
-- Ejecutar sobre un esquema recién creado (01_schema.sql), SIN los datos
-- del diccionario, porque los INSERT suponen que los id empiezan en 1.
--
-- Casos incluidos a propósito para probar consultas:
--   * Seña con palabras y definiciones en dos idiomas (es / en).
--   * Polisemia: "banco" (dinero) y "banco" (asiento) -> dos señas.
--   * Seña LSM y seña ASL que comparten palabra (HOLA / HELLO).
--   * Huecos: palabra sin seña (perro), seña sin nada (id 11),
--     MAMÁ sin definición en inglés, señante sin videos,
--     video sin seña, seña ASL sin diccionario.
--   * Misma seña en dos diccionarios con datos fonológicos distintos.
--   * Par mínimo fonológico: AGUA / MAMÁ (solo cambia configuración).
--   * Un video con dos señas (frase).
--   * Sinónimos: casa / vivienda comparten seña.
-- =====================================================================
SET search_path TO lsm;

-- LENGUA -------------------------------------------------------------
INSERT INTO lengua (nombre_completo, modalidad) VALUES
    ('Lengua de Señas Mexicana', 'viso-gestual'),   -- 1
    ('Español',                  'oral-auditiva'),  -- 2
    ('American Sign Language',   'viso-gestual'),   -- 3
    ('Inglés',                   'oral-auditiva');  -- 4

-- TIPO_SEÑA ----------------------------------------------------------
INSERT INTO tipo_sena (tipo) VALUES
    ('icónica'),     -- 1
    ('deletreada'),  -- 2
    ('arbitraria'),  -- 3
    ('compuesta');   -- 4

-- DICCIONARIO --------------------------------------------------------
INSERT INTO diccionario (completo, autor) VALUES
    ('Diccionario de Lengua de Señas Mexicana (DIELSEME)', 'SEP'),            -- 1
    ('Manos con Voz',                                       'CONAPRED'),       -- 2
    ('Diccionario LSM UABC (prueba)',                       'Equipo LSM_DB');  -- 3

-- PALABRA ------------------------------------------------------------
INSERT INTO palabra (palabra, id_lengua) VALUES
    ('casa', 2),       -- 1
    ('agua', 2),       -- 2
    ('comer', 2),      -- 3
    ('gracias', 2),    -- 4
    ('mamá', 2),       -- 5
    ('hola', 2),       -- 6
    ('banco', 2),      -- 7  (polisemia)
    ('perro', 2),      -- 8  (sin seña)
    ('house', 4),      -- 9
    ('water', 4),      -- 10
    ('eat', 4),        -- 11
    ('thank you', 4),  -- 12
    ('mom', 4),        -- 13
    ('hello', 4),      -- 14
    ('bank', 4),       -- 15
    ('bench', 4),      -- 16
    ('vivienda', 2);   -- 17 (sinónimo de casa)

-- SENA ---------------------------------------------------------------
INSERT INTO sena (id_tipo, id_lengua) VALUES
    (1, 1),     -- 1  CASA            (LSM)
    (2, 1),     -- 2  AGUA            (LSM)
    (1, 1),     -- 3  COMER           (LSM)
    (3, 1),     -- 4  GRACIAS         (LSM)
    (3, 1),     -- 5  MAMÁ            (LSM)
    (3, 1),     -- 6  HOLA            (LSM)
    (3, 1),     -- 7  BANCO-DINERO    (LSM)
    (1, 1),     -- 8  BANCO-ASIENTO   (LSM)
    (1, 3),     -- 9  HOUSE           (ASL)
    (3, 3),     -- 10 HELLO           (ASL)
    (NULL, 1);  -- 11 seña sin tipo, glosa, palabra ni definición

-- GLOSA --------------------------------------------------------------
INSERT INTO glosa (glosa, autor, fecha, id_lengua) VALUES
    ('CASA',          'Equipo LSM_DB', '2026-01-10', 1),  -- 1
    ('AGUA',          'Equipo LSM_DB', '2026-01-10', 1),  -- 2
    ('COMER',         'Equipo LSM_DB', '2026-01-11', 1),  -- 3
    ('GRACIAS',       'Equipo LSM_DB', '2026-01-11', 1),  -- 4
    ('MAMÁ',          'Equipo LSM_DB', '2026-01-12', 1),  -- 5
    ('HOLA',          'Equipo LSM_DB', '2026-01-12', 1),  -- 6
    ('BANCO-DINERO',  'Equipo LSM_DB', '2026-01-13', 1),  -- 7
    ('BANCO-ASIENTO', 'Equipo LSM_DB', '2026-01-13', 1),  -- 8
    ('HOUSE',         'ASL team',      '2026-02-01', 3),  -- 9
    ('HELLO',         'ASL team',      '2026-02-01', 3);  -- 10

-- DEFINICION ---------------------------------------------------------
INSERT INTO definicion (definicion, autor, fecha, id_lengua) VALUES
    ('Edificio para habitar.',                               'RAE',    '2026-01-05', 2),  -- 1
    ('A building for people to live in.',                    'Oxford', '2026-01-05', 4),  -- 2
    ('Líquido transparente, incoloro e inodoro.',            'RAE',    '2026-01-05', 2),  -- 3
    ('A clear liquid with no colour, taste or smell.',       'Oxford', '2026-01-05', 4),  -- 4
    ('Ingerir alimento.',                                    'RAE',    '2026-01-06', 2),  -- 5
    ('To put food in the mouth and swallow it.',             'Oxford', '2026-01-06', 4),  -- 6
    ('Expresión de agradecimiento.',                         'RAE',    '2026-01-06', 2),  -- 7
    ('Used to express gratitude.',                           'Oxford', '2026-01-06', 4),  -- 8
    ('Madre.',                                               'RAE',    '2026-01-07', 2),  -- 9 (sin versión en inglés)
    ('Saludo que se usa al encontrarse con alguien.',        'RAE',    '2026-01-07', 2),  -- 10
    ('Used as a greeting when meeting someone.',             'Oxford', '2026-01-07', 4),  -- 11
    ('Entidad que guarda y presta dinero.',                  'RAE',    '2026-01-08', 2),  -- 12
    ('An organization that keeps and lends money.',          'Oxford', '2026-01-08', 4),  -- 13
    ('Asiento largo para varias personas.',                  'RAE',    '2026-01-08', 2),  -- 14
    ('A long seat for several people.',                      'Oxford', '2026-01-08', 4);  -- 15

-- SENA_PALABRA -------------------------------------------------------
INSERT INTO sena_palabra (id_sena, id_palabra) VALUES
    (1, 1), (1, 9),     -- CASA       : casa / house
    (1, 17),            -- CASA       : vivienda (sinónimo)
    (2, 2), (2, 10),    -- AGUA       : agua / water
    (3, 3), (3, 11),    -- COMER      : comer / eat
    (4, 4), (4, 12),    -- GRACIAS    : gracias / thank you
    (5, 5), (5, 13),    -- MAMÁ       : mamá / mom
    (6, 6), (6, 14),    -- HOLA       : hola / hello
    (7, 7), (7, 15),    -- BANCO-DIN. : banco / bank
    (8, 7), (8, 16),    -- BANCO-ASI. : banco / bench
    (9, 9), (9, 1),     -- HOUSE (ASL): house / casa
    (10, 14), (10, 6);  -- HELLO (ASL): hello / hola

-- SENA_GLOSA ---------------------------------------------------------
INSERT INTO sena_glosa (id_sena, id_glosa) VALUES
    (1, 1), (2, 2), (3, 3), (4, 4), (5, 5),
    (6, 6), (7, 7), (8, 8), (9, 9), (10, 10);

-- SENA_DEFINICION ----------------------------------------------------
INSERT INTO sena_definicion (id_sena, id_definicion) VALUES
    (1, 1), (1, 2),
    (2, 3), (2, 4),
    (3, 5), (3, 6),
    (4, 7), (4, 8),
    (5, 9),
    (6, 10), (6, 11),
    (7, 12), (7, 13),
    (8, 14), (8, 15),
    (9, 2),
    (10, 11);

-- SENA_DICCIONARIO ---------------------------------------------------
INSERT INTO sena_diccionario (id_sena, id_diccionario, id_lengua, datos_fonologicos) VALUES
    (1, 1, 1, '{"codigo": "P-1", "significado": "Casa", "tipo_sena": "SS", "configuracion": "B", "ubicacion": "espacio neutro", "movimiento": "descendente", "orientacion": "palmas adentro"}'),                                     -- 1
    (1, 3, 1, '{"codigo": "U-1", "significado": "Casa", "tipo_sena": "SS", "configuracion": "B", "ubicacion": "espacio neutro", "movimiento": "descendente", "orientacion": "palmas abajo"}'),                                       -- 2 (difiere de 1)
    (2, 1, 1, '{"codigo": "P-2", "significado": "Agua", "tipo_sena": "SM", "configuracion": "W", "ubicacion": "barbilla", "movimiento": "toque repetido", "orientacion": "palma lateral"}'),                                       -- 3
    (3, 2, 1, '{"codigo": "M-1", "significado": "Comer", "tipo_sena": "SM", "configuracion": "O", "ubicacion": "boca", "movimiento": "toque repetido", "orientacion": "palma adentro", "rasgos_no_manuales": "Mejillas infladas."}'), -- 4
    (4, 1, 1, '{"codigo": "P-3", "significado": "Gracias", "tipo_sena": "SM", "configuracion": "B", "ubicacion": "barbilla", "movimiento": "hacia afuera", "orientacion": "palma adentro", "rasgos_no_manuales": "Sonrisa."}'),     -- 5
    (5, 3, 1, '{"codigo": "U-2", "significado": "Mamá", "tipo_sena": "SM", "configuracion": "5", "ubicacion": "barbilla", "movimiento": "toque repetido", "orientacion": "palma lateral"}'),                                       -- 6
    (6, 1, 1, '{"codigo": "P-4", "significado": "Hola", "tipo_sena": "SM", "configuracion": "B", "ubicacion": "frente", "movimiento": "hacia afuera", "orientacion": "palma afuera", "rasgos_no_manuales": "Sonrisa."}'),          -- 7
    (6, 2, 1, '{"codigo": "M-2", "significado": "Hola", "tipo_sena": "SM", "configuracion": "B", "ubicacion": "frente", "movimiento": "hacia afuera", "orientacion": "palma afuera", "rasgos_no_manuales": "Sonrisa."}'),          -- 8 (igual a 7 salvo el código)
    (7, 2, 1, '{"codigo": "M-3", "significado": "Banco (dinero)", "tipo_sena": "SM", "configuracion": "B", "ubicacion": "espacio neutro", "movimiento": "golpe", "orientacion": "palma abajo"}'),                                  -- 9
    (8, 3, 1, '{"codigo": "U-3", "significado": "Banco (asiento)", "tipo_sena": "SB", "configuracion": "V", "ubicacion": "espacio neutro", "movimiento": "descendente", "orientacion": "palma abajo", "pagina": 12}');             -- 10

-- SEÑANTE ------------------------------------------------------------
INSERT INTO senante (edad, perfil_nativo) VALUES
    (28, 'sordo nativo'),  -- 1
    (45, 'CODA'),          -- 2
    (33, 'intérprete'),    -- 3
    (60, 'sordo nativo');  -- 4 (sin videos)

-- VIDEO --------------------------------------------------------------
INSERT INTO video (mano_dominante, tipo_de_toma, path, fecha, id_senante) VALUES
    ('derecha',   'frontal', '/videos/s1/casa_frontal.mp4',    '2026-03-01', 1),  -- 1
    ('derecha',   'lateral', '/videos/s1/casa_lateral.mp4',    '2026-03-01', 1),  -- 2
    ('izquierda', 'frontal', '/videos/s2/agua_frontal.mp4',    '2026-03-02', 2),  -- 3
    ('derecha',   'frontal', '/videos/s3/comer_frontal.mp4',   '2026-03-03', 3),  -- 4
    ('derecha',   'frontal', '/videos/s1/gracias_frontal.mp4', '2026-03-04', 1),  -- 5
    ('izquierda', 'frontal', '/videos/s2/hola_frontal.mp4',    '2026-03-05', 2),  -- 6
    ('derecha',   'frontal', '/videos/s3/hola_frontal.mp4',    '2026-03-05', 3),  -- 7
    ('derecha',   'frontal', '/videos/s1/frase_hola_casa.mp4', '2026-03-06', 1),  -- 8 (dos señas)
    ('izquierda', 'lateral', '/videos/s2/sin_etiquetar.mp4',   '2026-03-07', 2);  -- 9 (sin seña)

-- SENA_VIDEO ---------------------------------------------------------
INSERT INTO sena_video (id_video, id_sena_diccionario) VALUES
    (1, 1), (2, 1), (3, 3), (4, 4), (5, 5),
    (6, 7), (7, 7),
    (8, 7), (8, 1);
