-- =====================================================================
-- LSM_DB - Datos de prueba
-- Ejecutar después de 01_schema.sql
-- =====================================================================
SET search_path TO lsm;

INSERT INTO lengua (nombre_completo, modalidad) VALUES
    ('Lengua de Señas Mexicana', 'viso-gestual'),   -- 1
    ('Español',                  'oral-auditiva'),  -- 2
    ('American Sign Language',   'viso-gestual');   -- 3

INSERT INTO diccionario (completo, autor) VALUES
    ('Diccionario de Lengua de Señas Mexicana (DIELSEME)', 'SEP'),          -- 1
    ('Manos con Voz',                                       'CONAPRED'),     -- 2
    ('Diccionario LSM UABC (prueba)',                       'Equipo LSM_DB');-- 3

INSERT INTO palabra (palabra, id_lengua) VALUES
    ('casa', 2), ('agua', 2), ('comer', 2), ('gracias', 2), ('mamá', 2),
    ('house', 3), ('water', 3);

INSERT INTO glosa (glosa, autor, fecha, id_lengua) VALUES
    ('CASA',    'Equipo LSM_DB', '2026-01-10', 1),
    ('AGUA',    'Equipo LSM_DB', '2026-01-10', 1),
    ('COMER',   'Equipo LSM_DB', '2026-01-11', 1),
    ('GRACIAS', 'Equipo LSM_DB', '2026-01-11', 1),
    ('MAMÁ',    'Equipo LSM_DB', '2026-01-12', 1),
    ('HOUSE',   'ASL team',      '2026-02-01', 3);

INSERT INTO definicion (definicion, autor, fecha, id_lengua) VALUES
    ('Edificio para habitar.',                         'RAE', '2026-01-05', 2),
    ('Líquido transparente, incoloro e inodoro.',      'RAE', '2026-01-05', 2),
    ('Ingerir alimento.',                              'RAE', '2026-01-06', 2),
    ('Expresión de agradecimiento.',                   'RAE', '2026-01-06', 2),
    ('Madre.',                                         'RAE', '2026-01-07', 2);

-- Señas (id_tipo se llena después de crear tipo_sena)
INSERT INTO sena (id_lengua) VALUES (1), (1), (1), (1), (1), (3);

INSERT INTO tipo_sena (id_tipo_sena, id_sena, tipo) VALUES
    (1, 1, 'icónica'),
    (2, 2, 'deletreada'),
    (1, 3, 'icónica'),
    (3, 4, 'arbitraria'),
    (3, 5, 'arbitraria'),
    (1, 6, 'icónica');

UPDATE sena s SET id_tipo = t.id_tipo_sena
FROM tipo_sena t WHERE t.id_sena = s.id_sena;

INSERT INTO sena_palabra (id_sena, id_palabra) VALUES
    (1, 1), (2, 2), (3, 3), (4, 4), (5, 5), (6, 6);

INSERT INTO sena_glosa (id_sena, id_glosa) VALUES
    (1, 1), (2, 2), (3, 3), (4, 4), (5, 5), (6, 6);

INSERT INTO sena_definicion (id_sena, id_definicion) VALUES
    (1, 1), (2, 2), (3, 3), (4, 4), (5, 5);

INSERT INTO sena_diccionario (id_sena, id_diccionario, id_lengua, datos_fonologicos) VALUES
    (1, 1, 1, '{"configuracion": "B", "ubicacion": "espacio neutro", "movimiento": "descendente", "orientacion": "palmas hacia adentro", "rasgos_no_manuales": []}'),
    (1, 3, 1, '{"configuracion": "B", "ubicacion": "espacio neutro", "movimiento": "descendente", "orientacion": "palmas hacia adentro"}'),
    (2, 1, 1, '{"configuracion": "W", "ubicacion": "barbilla", "movimiento": "toque repetido", "orientacion": "palma hacia un lado"}'),
    (3, 2, 1, '{"configuracion": "O", "ubicacion": "boca", "movimiento": "toque repetido", "orientacion": "palma hacia adentro"}'),
    (4, 1, 1, '{"configuracion": "B", "ubicacion": "boca", "movimiento": "hacia afuera", "orientacion": "palma hacia adentro", "rasgos_no_manuales": ["sonrisa"]}'),
    (5, 3, 1, '{"configuracion": "5", "ubicacion": "barbilla", "movimiento": "toque", "orientacion": "palma hacia un lado"}');

INSERT INTO senante (edad, perfil_nativo) VALUES
    (28, 'sordo nativo'),
    (45, 'CODA'),
    (33, 'intérprete');

INSERT INTO video (mano_dominante, tipo_de_toma, path, fecha, id_senante) VALUES
    ('derecha',   'frontal', '/videos/senante1/casa_frontal.mp4',    '2026-03-01', 1),
    ('derecha',   'lateral', '/videos/senante1/casa_lateral.mp4',    '2026-03-01', 1),
    ('izquierda', 'frontal', '/videos/senante2/agua_frontal.mp4',    '2026-03-02', 2),
    ('derecha',   'frontal', '/videos/senante3/comer_frontal.mp4',   '2026-03-03', 3),
    ('derecha',   'frontal', '/videos/senante1/gracias_frontal.mp4', '2026-03-04', 1);

INSERT INTO sena_video (id_video, id_sena_diccionario) VALUES
    (1, 1), (2, 1), (3, 3), (4, 4), (5, 5);
