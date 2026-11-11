-- =====================================================================
-- LSM_DB - Consultas estilo API
-- Requiere: 01_schema.sql, 02_datos_dlsm_cdmx.sql, 02b_glosas_dlsm_cdmx.sql
--
-- Cada "endpoint" es una función SQL que recibe parámetros y devuelve
-- JSON, igual que respondería una API. Así se pueden probar desde DBeaver
-- antes de construir la API real:
--
--   Endpoint propuesto                         Función
--   GET /palabras/{palabra}                    api.palabra('Casa')
--   GET /palabras/{palabra}/definicion?lengua= api.definicion('Banco', 'Español')
--   GET /senas/{glosa}                         api.sena('ABAJO')
--   GET /senas/{glosa}/sinonimos               api.sinonimos('AUTO')
--   GET /buscar?q=                             api.buscar('cas')
--   POST /senas/buscar (filtro fonológico)     api.senas_por_fonologia('{"configuracion": "A.1"}')
--   GET /senas?pagina=&por_pagina=             api.senas(1, 20)
--   GET /tipos                                 api.tipos()
--   GET /estadisticas                          api.estadisticas()
--
-- Las funciones viven en un esquema aparte, "api", y solo leen datos.
-- En DBeaver: ejecutar todo el archivo con "Ejecutar script" (Alt+X) para
-- crear las funciones; después probar los ejemplos del final con Ctrl+Enter.
-- Una respuesta NULL equivale a un "404: no encontrado".
-- =====================================================================
CREATE SCHEMA IF NOT EXISTS api;

-- ---------------------------------------------------------------------
-- GET /palabras/{palabra}
-- Las señas de una palabra, con su glosa, código, tipo y definición.
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION api.palabra(p_palabra TEXT)
RETURNS JSONB LANGUAGE sql STABLE AS $$
    SELECT jsonb_build_object(
        'palabra', p_palabra,
        'total',   COUNT(g.glosa),
        'senas',   COALESCE(jsonb_agg(jsonb_build_object(
                        'glosa',      g.glosa,
                        'codigo',     sdc.datos_fonologicos ->> 'codigo',
                        'tipo',       t.tipo,
                        'definicion', d.definicion) ORDER BY g.glosa)
                     FILTER (WHERE g.glosa IS NOT NULL), '[]'::jsonb))
    FROM lsm.palabra p
    JOIN lsm.sena_palabra sp      ON sp.id_palabra = p.id_palabra
    JOIN lsm.sena s               ON s.id_sena = sp.id_sena
    LEFT JOIN lsm.tipo_sena t     ON t.id_tipo_sena = s.id_tipo
    JOIN lsm.sena_glosa sg        ON sg.id_sena = s.id_sena
    JOIN lsm.glosa g              ON g.id_glosa = sg.id_glosa
    JOIN lsm.sena_diccionario sdc ON sdc.id_sena = s.id_sena
    LEFT JOIN lsm.sena_definicion sd ON sd.id_sena = s.id_sena
    LEFT JOIN lsm.definicion d       ON d.id_definicion = sd.id_definicion
    WHERE LOWER(p.palabra) = LOWER(p_palabra)
$$;

-- ---------------------------------------------------------------------
-- GET /palabras/{palabra}/definicion?lengua=Español
-- Las definiciones de una palabra en una lengua. Con 'Inglés' hoy
-- devuelve una lista vacía: la ruta existe, faltan los datos.
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION api.definicion(p_palabra TEXT, p_lengua TEXT DEFAULT 'Español')
RETURNS JSONB LANGUAGE sql STABLE AS $$
    SELECT jsonb_build_object(
        'palabra', p_palabra,
        'lengua',  p_lengua,
        'definiciones', COALESCE(jsonb_agg(DISTINCT jsonb_build_object(
                            'glosa', g.glosa, 'texto', d.definicion))
                          FILTER (WHERE d.id_definicion IS NOT NULL), '[]'::jsonb))
    FROM lsm.palabra p
    JOIN lsm.sena_palabra sp    ON sp.id_palabra = p.id_palabra
    JOIN lsm.sena_glosa sg      ON sg.id_sena = sp.id_sena
    JOIN lsm.glosa g            ON g.id_glosa = sg.id_glosa
    JOIN lsm.sena_definicion sd ON sd.id_sena = sp.id_sena
    JOIN lsm.definicion d       ON d.id_definicion = sd.id_definicion
    JOIN lsm.lengua l           ON l.id_lengua = d.id_lengua
    WHERE LOWER(p.palabra) = LOWER(p_palabra)
      AND l.nombre_completo = p_lengua
$$;

-- ---------------------------------------------------------------------
-- GET /senas/{glosa}
-- Ficha completa de una seña. NULL si la glosa no existe.
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION api.sena(p_glosa TEXT)
RETURNS JSONB LANGUAGE sql STABLE AS $$
    SELECT jsonb_build_object(
        'glosa',       g.glosa,
        'codigo',      sdc.datos_fonologicos ->> 'codigo',
        'tipo',        t.tipo,
        'lengua',      l.nombre_completo,
        'diccionario', dic.nombre_completo,
        'palabras',    (SELECT jsonb_agg(p.palabra ORDER BY p.palabra)
                        FROM lsm.sena_palabra x JOIN lsm.palabra p ON p.id_palabra = x.id_palabra
                        WHERE x.id_sena = s.id_sena),
        'definiciones', (SELECT jsonb_agg(jsonb_build_object('lengua', ld.nombre_completo, 'texto', d.definicion))
                         FROM lsm.sena_definicion x
                         JOIN lsm.definicion d ON d.id_definicion = x.id_definicion
                         JOIN lsm.lengua ld    ON ld.id_lengua = d.id_lengua
                         WHERE x.id_sena = s.id_sena),
        'datos_fonologicos', sdc.datos_fonologicos)
    FROM lsm.glosa g
    JOIN lsm.sena_glosa sg        ON sg.id_glosa = g.id_glosa
    JOIN lsm.sena s               ON s.id_sena = sg.id_sena
    JOIN lsm.lengua l             ON l.id_lengua = s.id_lengua
    LEFT JOIN lsm.tipo_sena t     ON t.id_tipo_sena = s.id_tipo
    JOIN lsm.sena_diccionario sdc ON sdc.id_sena = s.id_sena
    JOIN lsm.diccionario dic      ON dic.id_diccionario = sdc.id_diccionario
    WHERE g.glosa = UPPER(p_glosa)
    LIMIT 1
$$;

-- ---------------------------------------------------------------------
-- GET /senas/{glosa}/sinonimos
-- Las palabras que comparten una misma seña.
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION api.sinonimos(p_glosa TEXT)
RETURNS JSONB LANGUAGE sql STABLE AS $$
    SELECT jsonb_build_object(
        'glosa',    UPPER(p_glosa),
        'palabras', COALESCE(jsonb_agg(p.palabra ORDER BY p.palabra), '[]'::jsonb))
    FROM lsm.glosa g
    JOIN lsm.sena_glosa sg   ON sg.id_glosa = g.id_glosa
    JOIN lsm.sena_palabra sp ON sp.id_sena = sg.id_sena
    JOIN lsm.palabra p       ON p.id_palabra = sp.id_palabra
    WHERE g.glosa = UPPER(p_glosa)
$$;

-- ---------------------------------------------------------------------
-- GET /buscar?q=cas&limite=10
-- Autocompletar: palabras o glosas que empiezan con el texto.
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION api.buscar(p_q TEXT, p_limite INT DEFAULT 10)
RETURNS JSONB LANGUAGE sql STABLE AS $$
    SELECT jsonb_build_object(
        'q', p_q,
        'resultados', COALESCE(jsonb_agg(r ORDER BY r ->> 'palabra', r ->> 'glosa'), '[]'::jsonb))
    FROM (
        SELECT DISTINCT jsonb_build_object('palabra', p.palabra, 'glosa', g.glosa) AS r
        FROM lsm.palabra p
        JOIN lsm.sena_palabra sp ON sp.id_palabra = p.id_palabra
        JOIN lsm.sena_glosa sg   ON sg.id_sena = sp.id_sena
        JOIN lsm.glosa g         ON g.id_glosa = sg.id_glosa
        WHERE LOWER(p.palabra) LIKE LOWER(p_q) || '%'
           OR g.glosa LIKE UPPER(p_q) || '%'
        ORDER BY 1
        LIMIT p_limite
    ) x
$$;

-- ---------------------------------------------------------------------
-- POST /senas/buscar   cuerpo: {"configuracion": "A.1", "ubicacion": "..."}
-- Señas cuyos datos fonológicos contienen todos los valores del filtro.
-- Usa el índice GIN sobre datos_fonologicos.
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION api.senas_por_fonologia(p_filtro JSONB)
RETURNS JSONB LANGUAGE sql STABLE AS $$
    SELECT jsonb_build_object(
        'filtro', p_filtro,
        'total',  COUNT(*),
        'glosas', COALESCE(jsonb_agg(g.glosa ORDER BY g.glosa), '[]'::jsonb))
    FROM lsm.sena_diccionario sdc
    JOIN lsm.sena_glosa sg ON sg.id_sena = sdc.id_sena
    JOIN lsm.glosa g       ON g.id_glosa = sg.id_glosa
    WHERE sdc.datos_fonologicos @> p_filtro
$$;

-- ---------------------------------------------------------------------
-- GET /senas?pagina=1&por_pagina=20
-- Lista paginada de todas las señas, en orden alfabético de glosa.
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION api.senas(p_pagina INT DEFAULT 1, p_por_pagina INT DEFAULT 20)
RETURNS JSONB LANGUAGE sql STABLE AS $$
    SELECT jsonb_build_object(
        'pagina',     p_pagina,
        'por_pagina', p_por_pagina,
        'total',      (SELECT COUNT(*) FROM lsm.glosa),
        'items',      COALESCE((
            SELECT jsonb_agg(jsonb_build_object('glosa', x.glosa, 'tipo', x.tipo, 'codigo', x.codigo) ORDER BY x.glosa)
            FROM (
                SELECT g.glosa, t.tipo, sdc.datos_fonologicos ->> 'codigo' AS codigo
                FROM lsm.glosa g
                JOIN lsm.sena_glosa sg        ON sg.id_glosa = g.id_glosa
                JOIN lsm.sena s               ON s.id_sena = sg.id_sena
                LEFT JOIN lsm.tipo_sena t     ON t.id_tipo_sena = s.id_tipo
                JOIN lsm.sena_diccionario sdc ON sdc.id_sena = s.id_sena
                ORDER BY g.glosa
                LIMIT p_por_pagina OFFSET (GREATEST(p_pagina, 1) - 1) * p_por_pagina
            ) x), '[]'::jsonb))
$$;

-- ---------------------------------------------------------------------
-- GET /tipos
-- Catálogo de tipos de seña con su conteo.
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION api.tipos()
RETURNS JSONB LANGUAGE sql STABLE AS $$
    SELECT jsonb_agg(jsonb_build_object('tipo', t.tipo, 'senas', n) ORDER BY n DESC)
    FROM (SELECT t.tipo, COUNT(s.id_sena) AS n
          FROM lsm.tipo_sena t
          LEFT JOIN lsm.sena s ON s.id_tipo = t.id_tipo_sena
          GROUP BY t.tipo) t
$$;

-- ---------------------------------------------------------------------
-- GET /estadisticas
-- Resumen de lo que hay en la base.
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION api.estadisticas()
RETURNS JSONB LANGUAGE sql STABLE AS $$
    SELECT jsonb_build_object(
        'senas',        (SELECT COUNT(*) FROM lsm.sena),
        'glosas',       (SELECT COUNT(*) FROM lsm.glosa),
        'palabras',     (SELECT COUNT(*) FROM lsm.palabra),
        'definiciones', (SELECT COUNT(*) FROM lsm.definicion),
        'videos',       (SELECT COUNT(*) FROM lsm.video),
        'diccionarios', (SELECT jsonb_agg(nombre_completo) FROM lsm.diccionario),
        'lenguas',      (SELECT jsonb_agg(nombre_completo ORDER BY id_lengua) FROM lsm.lengua))
$$;

-- =====================================================================
-- Ejemplos para probar (Ctrl+Enter en cada uno)
-- jsonb_pretty() solo da formato legible a la respuesta.
-- =====================================================================

-- GET /palabras/Casa              -> CASA-A y CASA-B
SELECT jsonb_pretty(api.palabra('Casa'));

-- GET /palabras/Banco/definicion?lengua=Español
SELECT jsonb_pretty(api.definicion('Banco', 'Español'));

-- GET /palabras/Banco/definicion?lengua=Inglés   -> lista vacía (faltan datos)
SELECT jsonb_pretty(api.definicion('Banco', 'Inglés'));

-- GET /senas/ABAJO                -> ficha completa con su JSON
SELECT jsonb_pretty(api.sena('ABAJO'));

-- GET /senas/NO-EXISTE            -> NULL (equivale a 404)
SELECT api.sena('NO-EXISTE');

-- GET /senas/AUTO/sinonimos       -> Auto, Automóvil, Carro, Coche
SELECT jsonb_pretty(api.sinonimos('AUTO'));

-- GET /buscar?q=cas
SELECT jsonb_pretty(api.buscar('cas'));

-- POST /senas/buscar  {"configuracion": "A.1", "ubicacion": "A la altura del pecho."}
SELECT jsonb_pretty(api.senas_por_fonologia('{"configuracion": "A.1", "ubicacion": "A la altura del pecho."}'));

-- GET /senas?pagina=2&por_pagina=5
SELECT jsonb_pretty(api.senas(2, 5));

-- GET /tipos
SELECT jsonb_pretty(api.tipos());

-- GET /estadisticas
SELECT jsonb_pretty(api.estadisticas());
