-- =====================================================================
-- LSM_DB · Generar METADATOS
--
-- Qué hace: lee datos_fonologicos (el texto del diccionario) y arma,
-- para cada seña, su objeto METADATOS: valores discretizados de
-- configuración manual y ubicación, separados por mano y por momento.
--
-- No crea, no modifica y no borra nada en la base: son solo consultas
-- SELECT. METADATOS vive aparte, en un archivo JSON.
--
-- Esquema que sigue: metadatos/esquema_metadatos.txt (y .sql).
--
-- Cómo usarlo en DBeaver:
--   1. Abre este archivo en un editor SQL conectado a la base.
--   2. Ejecuta TODO el archivo con Alt+X («Ejecutar script»).
--      Es una sola consulta larga (WITH …): si usas Ctrl+Enter,
--      selecciona antes todo el texto (Ctrl+A).
--   3. Al final del archivo eliges la salida:
--      · Opción A: una fila por seña (código, glosa, metadatos).
--      · Opción B: un solo valor con todo el JSON. Clic derecho en la
--        celda → Copiar, pégalo en un archivo y guárdalo como
--        metadatos.json.
--        Ojo: «Exportar datos › JSON» de DBeaver mete el valor entre
--        comillas y escapa todo con \" : no lo uses para este archivo.
--
-- Forma más segura de sacar el archivo (CMD, con la Opción B activa):
--   cd "C:\Program Files\PostgreSQL\18\bin"
--   psql -U postgres -d lsm_db -qAt -f "ruta\generar_metadatos.sql" -o "ruta\metadatos.json"
--   (-q quita los mensajes, -A y -t dejan solo el valor, sin tabla).
--
-- Parámetro: id del diccionario a procesar (hoy 1 = DLSM CDMX 2017).
-- Para otro diccionario, cambia ese 1
-- (busca «id_diccionario = 1»). Antes revisa que su notación
-- (códigos de configuración y forma de escribir la ubicación) sea
-- la misma; si no, hay que ajustar los catálogos de abajo.
--
-- Reglas de discretización (versión 1):
--   * Configuración: solo la FAMILIA de la mano (B-P.2 → «B-P»,
--     A.1 → «A», 1-I.1 → «1-I»).
--   * Partes «I. …; II. …» (señas compuestas) y «pasa de X a Y» se
--     convierten en momentos de la linea_temporal, en orden.
--   * Mano base: si el texto separa «MD … MB …», cada mano toma sus
--     códigos; si dice «MD y MB …» o la parte es SS, las dos manos
--     llevan la misma configuración; si no, solo hay mano dominante.
--   * Ubicación: se parte en oraciones. «MD …» → mano dominante;
--     «MB …» → mano base; «MD y MB …» → ambas; sin mano → la
--     dominante, y también la base si en esa parte hay mano base.
--     Si la MD no tiene zona propia («MD sobre MB»), toma la de la MB.
--   * Las claves que no aplican se OMITEN (no se escribe [] ni null).
--   * Orientación y movimiento no se generan en esta versión
--     (son claves opcionales del esquema).
-- =====================================================================
SET search_path TO lsm;

WITH
-- Patrones de texto que se reutilizan
re AS (
    SELECT
        -- Código de configuración: familia + número (B-P.2, A.1, 1-I.1, B-P. 2)
        '(B-P|1-I|[A-Z]|[0-9])\.\s?[0-9]+'                                   AS codigo_cm,
        -- Separador de partes de una seña compuesta: «I. », «II. », «I. y II. »,
        -- «I., II. y III. » (también «; II MD» y «II.Sobre», erratas del DLSM)
        '(?:^|[\s;:,])(?:IV|I{1,3})\.?(?:\s*(?:,|y)\s*(?:IV|I{1,3})\.?)*(?:[\s:]|(?<=\.)(?=[A-ZÁÉÍÓÚ]))' AS parte
),
-- Catálogo de zonas del cuerpo: patrón (texto sin acentos) → valor
zona (patron, valor) AS (
    VALUES
        ('cabeza|nuca',                       'Cabeza'),
        ('la frente',                         'Frente'),
        ('\msien',                            'Sien'),
        ('\mceja',                            'Ceja'),
        ('\mojos?\M',                         'Ojo'),
        ('nariz',                             'Nariz'),
        ('mejilla|pomulo',                    'Mejilla'),
        ('oreja',                             'Oreja'),
        ('boca|labio|comisura|diente',        'Boca'),
        ('barbilla|menton',                   'Barbilla'),
        ('\mcara\M|rostro',                   'Cara'),
        ('cuello',                            'Cuello'),
        ('hombro|axila',                      'Hombro'),
        ('pecho',                             'Pecho'),
        ('plexo',                             'Plexo'),
        ('abdome|estomago',                   'Abdomen'),
        ('cintura',                           'Cintura'),
        ('cadera',                            'Cadera'),
        ('brazo|sangradura|\mcodo',           'Brazo'),
        ('muneca',                            'Muñeca'),
        ('palma|dorso|dedo|pulgar|menique|nudillo|punta', 'Mano'),
        ('espalda',                           'Espalda')
),
-- 1. Datos de partida: una fila por seña del diccionario
fuente AS (
    SELECT sd.id_sena_diccionario                         AS id,
           sd.datos_fonologicos->>'codigo'                AS codigo,
           (SELECT string_agg(g.glosa, ' / ' ORDER BY g.glosa)
              FROM sena_glosa sg JOIN glosa g ON g.id_glosa = sg.id_glosa
             WHERE sg.id_sena = sd.id_sena)               AS glosa,
           COALESCE(sd.datos_fonologicos->>'tipo_sena', '')     AS tipo,
           COALESCE(sd.datos_fonologicos->>'configuracion', '') AS conf,
           COALESCE(sd.datos_fonologicos->>'ubicacion', '')     AS ubic
      FROM sena_diccionario sd
     WHERE sd.id_diccionario = 1
),
-- 2. Partes de la configuración («I. …; II. …»). Una seña simple = 1 parte.
--    «I. y II. A.1» es una sola parte que vale para los dos momentos
partes AS (
    SELECT f.id, p.n AS parte, p.txt
      FROM fuente f, re,
           LATERAL (SELECT t.txt, row_number() OVER (ORDER BY t.o) AS n
                      FROM regexp_split_to_table(f.conf, re.parte) WITH ORDINALITY AS t(txt, o)
                     WHERE btrim(t.txt) <> '') p
    UNION ALL   -- señas sin texto de configuración: una parte vacía
    SELECT f.id, 1, '' FROM fuente f WHERE btrim(f.conf) = ''
),
-- 3. Tipo de seña por parte («SC: I. SM; II. SB»). Si hay una sola
--    etiqueta para todo («I. y II. SS»), vale para todas las partes
tipo_partes AS (
    SELECT f.id, t.n, t.txt, count(*) OVER (PARTITION BY f.id) AS total
      FROM fuente f, re,
           LATERAL (SELECT s.txt, row_number() OVER (ORDER BY s.o) AS n
                      FROM regexp_split_to_table(regexp_replace(f.tipo, '^SC:?\s*', ''), re.parte)
                           WITH ORDINALITY AS s(txt, o)
                     WHERE btrim(s.txt) <> '') t
),
-- 4. Qué texto corresponde a cada mano en cada parte
manos AS (
    SELECT p.id, p.parte, p.txt,
           COALESCE((SELECT tp.txt FROM tipo_partes tp
                      WHERE tp.id = p.id AND (tp.n = p.parte OR tp.total = 1)
                      ORDER BY tp.n LIMIT 1), f.tipo)            AS tipo_parte
      FROM partes p JOIN fuente f ON f.id = p.id
),
manos2 AS (
    SELECT m.id, m.parte,
           CASE WHEN m.txt ~ 'MB' AND m.txt ~ 'MD' AND m.txt !~ 'MD y MB'
                THEN substr(m.txt, 1, strpos(m.txt, 'MB') - 1)
                WHEN m.txt ~ '^\s*MB' AND m.txt !~ 'MD'          -- parte solo de la mano base
                THEN ''
                ELSE m.txt END                                    AS txt_dom,
           CASE WHEN m.txt ~ 'MB' AND m.txt ~ 'MD' AND m.txt !~ 'MD y MB'
                THEN substr(m.txt, strpos(m.txt, 'MB'))
                WHEN m.txt ~ '^\s*MB' AND m.txt !~ 'MD'
                THEN m.txt
                WHEN m.txt ~ 'MD y MB' OR m.tipo_parte ~ 'SS'
                THEN m.txt
                ELSE '' END                                       AS txt_base
      FROM manos m
),
-- 5. Familias de configuración por mano, en el orden en que aparecen.
--    «Configuración D» (sin número, errata del DLSM) se lee como D.0
familias AS (
    SELECT m.id, m.parte,
           ARRAY(SELECT x.c[1] FROM regexp_matches(regexp_replace(m.txt_dom,  'onfiguración (B-P|1-I|[A-Z]|[0-9])\M(?![.-])', 'onfiguración \1.0', 'g'),
                                                   re.codigo_cm, 'g') WITH ORDINALITY x(c, o) ORDER BY x.o) AS dom,
           ARRAY(SELECT x.c[1] FROM regexp_matches(regexp_replace(m.txt_base, 'onfiguración (B-P|1-I|[A-Z]|[0-9])\M(?![.-])', 'onfiguración \1.0', 'g'),
                                                   re.codigo_cm, 'g') WITH ORDINALITY x(c, o) ORDER BY x.o) AS base
      FROM manos2 m, re
),
-- 6. Momentos: «pasa de X a Y» da 2 momentos; si una mano tiene menos
--    códigos que la otra, conserva su última configuración.
--    Aunque solo se guarda la familia, B-P.2 → B-P.12 sigue siendo
--    2 momentos (B-P, B-P): así se conserva que la mano cambia
--    (CASA-B frente a CASA-A)
momentos AS (
    SELECT f.id, f.parte, k,
           row_number() OVER (PARTITION BY f.id ORDER BY f.parte, k)   AS orden,
           COALESCE(f.dom[k],  f.dom[cardinality(f.dom)])               AS cm_dom,
           COALESCE(f.base[k], f.base[cardinality(f.base)])             AS cm_base
      FROM familias f,
           generate_series(1, GREATEST(cardinality(f.dom), cardinality(f.base), 1)) AS k
),
num_partes AS (
    SELECT id, max(parte) AS total FROM partes GROUP BY id
),
tiene_base AS (
    SELECT id, bool_or(cm_base IS NOT NULL) AS si FROM momentos GROUP BY id
),
tiene_base_parte AS (
    SELECT id, parte, bool_or(cm_base IS NOT NULL) AS si FROM momentos GROUP BY id, parte
),
-- 7. Ubicación: partes («I. …; II. …») y oraciones, cada una con su mano
ubic_partes AS (
    SELECT f.id, u.n AS parte, u.txt, count(*) OVER (PARTITION BY f.id) AS total
      FROM fuente f, re,
           LATERAL (SELECT s.txt, row_number() OVER (ORDER BY s.o) AS n
                      FROM regexp_split_to_table(f.ubic, re.parte) WITH ORDINALITY AS s(txt, o)
                     WHERE btrim(s.txt) <> '') u
),
oraciones AS (
    SELECT up.id, up.parte, up.total, o.txt,
           CASE WHEN btrim(o.txt) ~* '^(las? )?MD y (la )?MB' THEN 'ambas'
                WHEN btrim(o.txt) ~* '^(la )?MB'               THEN 'base'
                WHEN btrim(o.txt) ~* '^(la )?MD'               THEN 'dom'
                ELSE 'general' END                                AS mano
      FROM ubic_partes up,
           LATERAL regexp_split_to_table(up.txt, '[.;:]\s*|,\s+(?=M[DB]\s)') AS o(txt)
     WHERE btrim(o.txt) <> ''
),
ubic_zonas_texto AS (
    SELECT DISTINCT o.id, o.parte, o.total, z.valor,
           (o.mano IN ('dom', 'ambas', 'general'))                         AS para_dom,
           (o.mano IN ('base', 'ambas')
            OR (o.mano = 'general' AND CASE WHEN o.total > 1 THEN COALESCE(tbp.si, false)
                                            ELSE tb.si END))       AS para_base
      FROM oraciones o
      JOIN tiene_base tb ON tb.id = o.id
      LEFT JOIN tiene_base_parte tbp ON tbp.id = o.id AND tbp.parte = o.parte
      JOIN zona z ON translate(lower(o.txt), 'áéíóúüñ', 'aeiouun') ~ z.patron
),
-- «MD sobre MB. MB a la altura del pecho»: si la mano dominante no tiene
-- zona propia (en esa parte), toma la de la mano base
ubic_zonas AS (
    SELECT * FROM ubic_zonas_texto
    UNION
    SELECT u.id, u.parte, u.total, u.valor, true, false
      FROM ubic_zonas_texto u
     WHERE u.para_base
       AND NOT EXISTS (SELECT 1 FROM ubic_zonas_texto d
                        WHERE d.id = u.id AND d.parte = u.parte AND d.para_dom)
),
-- Orden fijo de las zonas (de la cabeza hacia abajo), para que la salida sea estable
zona_orden AS (
    SELECT valor, row_number() OVER () AS n FROM zona
),
-- 8. Cada momento con sus valores. La ubicación por momento solo se
--    escribe en señas compuestas (en las demás sería igual a presencia)
momento_json AS (
    SELECT m.id, m.orden,
           json_strip_nulls(json_build_object(
               'orden',        m.orden,
               'cm_dominante', m.cm_dom,
               'cm_base',      m.cm_base,
               'ubicacion_dominante', CASE WHEN np.total > 1 THEN
                   (SELECT json_agg(uz.valor ORDER BY zo.n) FROM ubic_zonas uz JOIN zona_orden zo USING (valor)
                     WHERE uz.id = m.id AND uz.para_dom AND (uz.parte = m.parte OR uz.total = 1)) END,
               'ubicacion_base', CASE WHEN np.total > 1 AND m.cm_base IS NOT NULL THEN
                   (SELECT json_agg(uz.valor ORDER BY zo.n) FROM ubic_zonas uz JOIN zona_orden zo USING (valor)
                     WHERE uz.id = m.id AND uz.para_base AND (uz.parte = m.parte OR uz.total = 1)) END
           )) AS j
      FROM momentos m JOIN num_partes np ON np.id = m.id
),
-- 9. Resumen «presencia»: todo lo que aparece en la seña, sin repetir
presencia AS (
    SELECT f.id,
           json_strip_nulls(json_build_object(
               'cm_dominante', (SELECT json_agg(x.v ORDER BY x.o) FROM
                                  (SELECT cm_dom AS v, min(orden) AS o FROM momentos
                                    WHERE id = f.id AND cm_dom IS NOT NULL GROUP BY cm_dom) x),
               'cm_base',      (SELECT json_agg(x.v ORDER BY x.o) FROM
                                  (SELECT cm_base AS v, min(orden) AS o FROM momentos
                                    WHERE id = f.id AND cm_base IS NOT NULL GROUP BY cm_base) x),
               'ubicacion_dominante', (SELECT json_agg(x.valor ORDER BY x.n) FROM
                                  (SELECT DISTINCT uz.valor, zo.n FROM ubic_zonas uz JOIN zona_orden zo USING (valor)
                                    WHERE uz.id = f.id AND uz.para_dom) x),
               'ubicacion_base', (SELECT json_agg(x.valor ORDER BY x.n) FROM
                                  (SELECT DISTINCT uz.valor, zo.n FROM ubic_zonas uz JOIN zona_orden zo USING (valor)
                                    WHERE uz.id = f.id AND uz.para_base) x)
           )) AS j
      FROM fuente f
),
resultado AS (
    SELECT f.codigo,
           f.glosa,
           json_build_object(
               'presencia',      p.j,
               'linea_temporal', (SELECT json_agg(mj.j ORDER BY mj.orden) FROM momento_json mj WHERE mj.id = f.id)
           ) AS metadatos
      FROM fuente f
      JOIN presencia p ON p.id = f.id
)
-- ---------------------------------------------------------------------
-- SALIDA. Deja activa SOLO UNA de las dos opciones:
--
-- Opción A (activa): una fila por seña, para revisar en la tabla.
SELECT codigo, glosa, metadatos
  FROM resultado
 ORDER BY glosa;
--
-- Opción B: todo en un solo valor JSON, listo para guardarse como
-- metadatos.json. Comenta la Opción A (las 3 líneas del SELECT) y
-- quita los «--» de las 3 líneas siguientes:
-- SELECT json_agg(json_build_object('codigo', codigo, 'glosa', glosa, 'METADATOS', metadatos)
--                 ORDER BY glosa) AS metadatos_json
--   FROM resultado;
