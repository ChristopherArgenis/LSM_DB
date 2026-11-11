-- =====================================================================
-- LSM_DB - Consultas que muestran las limitaciones de la base
-- Requiere: 01_schema.sql, 02_datos_dlsm_cdmx.sql, 02b_glosas_dlsm_cdmx.sql
-- En DBeaver: ejecutar primero el SET y luego cada consulta con Ctrl+Enter.
--
-- Hay dos tipos de límite:
--   [DISEÑO]   La pregunta tiene sentido, pero el modelo no guarda lo que
--              hace falta para responderla. La consulta DA resultados, pero
--              se ve que no alcanzan para contestar.
--   [SIN DATOS] La consulta está bien escrita, pero la tabla está vacía.
--              Sale con 0 filas: hoy no se puede, aunque se quiera.
-- Cada consulta dice qué se quiere, por qué no se puede y qué esperar.
-- =====================================================================
SET search_path TO lsm;

-- ---------------------------------------------------------------------
-- L1. [DISEÑO] Sentidos mezclados
-- Se quiere: saber cuál de las señas de "Abandonar" se usa para decir
--            "dejé mi trabajo".
-- Por qué no: la definición pertenece a la seña, no al sentido de la
--            palabra, y las definiciones son casi iguales.
-- Resultado: 6 filas que no permiten elegir.
-- ---------------------------------------------------------------------
SELECT g.glosa, d.definicion
FROM palabra p
JOIN sena_palabra sp    ON sp.id_palabra = p.id_palabra
JOIN sena_glosa sg      ON sg.id_sena = sp.id_sena
JOIN glosa g            ON g.id_glosa = sg.id_glosa
JOIN sena_definicion sd ON sd.id_sena = sp.id_sena
JOIN definicion d       ON d.id_definicion = sd.id_definicion
WHERE p.palabra = 'Abandonar'
ORDER BY g.glosa;

-- ---------------------------------------------------------------------
-- L2. [DISEÑO] Solo la palabra exacta
-- Se quiere: encontrar la seña buscando "bonita" o "comí".
-- Por qué no: se guarda el lema (Bonito, Comer) y la búsqueda compara
--            el texto completo; no hay lematización.
-- Resultado: la primera consulta da 0 filas; la segunda sí encuentra.
-- ---------------------------------------------------------------------
SELECT p.palabra, g.glosa
FROM palabra p
JOIN sena_palabra sp ON sp.id_palabra = p.id_palabra
JOIN sena_glosa sg   ON sg.id_sena = sp.id_sena
JOIN glosa g         ON g.id_glosa = sg.id_glosa
WHERE LOWER(p.palabra) IN ('bonita', 'comí');

SELECT p.palabra, g.glosa
FROM palabra p
JOIN sena_palabra sp ON sp.id_palabra = p.id_palabra
JOIN sena_glosa sg   ON sg.id_sena = sp.id_sena
JOIN glosa g         ON g.id_glosa = sg.id_glosa
WHERE LOWER(p.palabra) IN ('bonito', 'comer');

-- ---------------------------------------------------------------------
-- L3. [DISEÑO] Fonología en texto libre
-- Se quiere: todas las señas que se hacen "en el pecho".
-- Por qué no: la ubicación es una frase libre; la misma idea está
--            escrita de muchas formas y una comparación exacta solo
--            encuentra una de ellas.
-- Resultado: la exacta encuentra pocas; la lista muestra cuántas
--            redacciones distintas hay.
-- ---------------------------------------------------------------------
SELECT COUNT(*) AS con_texto_exacto
FROM sena_diccionario
WHERE datos_fonologicos ->> 'ubicacion' = 'Sobre el pecho.';

SELECT datos_fonologicos ->> 'ubicacion' AS redaccion, COUNT(*) AS senas
FROM sena_diccionario
WHERE datos_fonologicos ->> 'ubicacion' ILIKE '%pecho%'
GROUP BY 1
ORDER BY 2 DESC;

-- ---------------------------------------------------------------------
-- L4. [DISEÑO] Señas compuestas sin sus partes
-- Se quiere: saber de qué señas se forma AMANTE (seña compuesta).
-- Por qué no: no hay una tabla que relacione una seña con otras; las
--            partes solo están descritas en el texto del JSON.
-- Resultado: solo se obtiene la descripción en texto, no las señas.
-- ---------------------------------------------------------------------
SELECT g.glosa,
       sdc.datos_fonologicos ->> 'tipo_sena'     AS partes,
       sdc.datos_fonologicos ->> 'configuracion' AS configuracion
FROM glosa g
JOIN sena_glosa sg        ON sg.id_glosa = g.id_glosa
JOIN sena_diccionario sdc ON sdc.id_sena = sg.id_sena
WHERE g.glosa = 'AMANTE';

-- Comprobación: no existe ninguna tabla de relación entre señas
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'lsm' AND table_name ILIKE '%relacion%';

-- ---------------------------------------------------------------------
-- L5. [DISEÑO] Acepciones juntas en una sola definición
-- Se quiere: la segunda acepción de una palabra.
-- Por qué no: el diccionario da "1. ... 2. ..." en un solo texto y se
--            guardó en una sola fila.
-- Resultado: cuántas definiciones tienen varias acepciones mezcladas.
-- ---------------------------------------------------------------------
SELECT COUNT(*) AS definiciones_con_varias_acepciones
FROM definicion
WHERE definicion ~ '(^|\s)2\.\s*';

SELECT g.glosa, d.definicion
FROM definicion d
JOIN sena_definicion sd ON sd.id_definicion = d.id_definicion
JOIN sena_glosa sg      ON sg.id_sena = sd.id_sena
JOIN glosa g            ON g.id_glosa = sg.id_glosa
WHERE g.glosa = 'ABAJO';

-- ---------------------------------------------------------------------
-- L6. [DISEÑO] Variantes sin región
-- Se quiere: saber si CASA-A o CASA-B se usa en Monterrey.
-- Por qué no: no existe ninguna columna de región; la letra de variante
--            solo vive en el texto.
-- Resultado: la búsqueda de columnas de región da 0 filas.
-- ---------------------------------------------------------------------
SELECT table_name, column_name
FROM information_schema.columns
WHERE table_schema = 'lsm' AND (column_name ILIKE '%region%' OR column_name ILIKE '%estado%');

SELECT g.glosa, sdc.datos_fonologicos ->> 'significado' AS significado
FROM glosa g
JOIN sena_glosa sg        ON sg.id_glosa = g.id_glosa
JOIN sena_diccionario sdc ON sdc.id_sena = sg.id_sena
WHERE g.glosa LIKE 'CASA-%';

-- ---------------------------------------------------------------------
-- L7. [DISEÑO] Glosas que no se pueden distinguir
-- Se quiere: saber en qué se diferencian ADORAR-1 y ADORAR-2.
-- Por qué no: el diccionario no trae nada que las distinga en el
--            significado; se numeraron. Solo la nota cultural da pistas.
-- Resultado: las 15 glosas numeradas.
-- ---------------------------------------------------------------------
SELECT g.glosa, sdc.datos_fonologicos ->> 'codigo' AS codigo,
       sdc.datos_fonologicos ->> 'nota_cultural'  AS nota_cultural
FROM glosa g
JOIN sena_glosa sg        ON sg.id_glosa = g.id_glosa
JOIN sena_diccionario sdc ON sdc.id_sena = sg.id_sena
WHERE g.glosa ~ '-[0-9]+$'
ORDER BY g.glosa;

-- ---------------------------------------------------------------------
-- L8. [DISEÑO] Una palabra sin seña queda aislada
-- Se quiere: la definición de "perro".
-- Por qué no: palabra y definición solo se unen a través de una seña;
--            si la palabra no tiene seña en el diccionario, no hay ruta.
-- Resultado: 0 filas.
-- ---------------------------------------------------------------------
SELECT p.palabra, d.definicion
FROM palabra p
JOIN sena_palabra sp    ON sp.id_palabra = p.id_palabra
JOIN sena_definicion sd ON sd.id_sena = sp.id_sena
JOIN definicion d       ON d.id_definicion = sd.id_definicion
WHERE LOWER(p.palabra) = 'perro';

-- ---------------------------------------------------------------------
-- L9. [SIN DATOS] Definición en inglés de una palabra en español
-- Se quiere: la definición en inglés de "Banco".
-- Por qué no: solo hay definiciones en español.
-- Resultado: 0 filas (la ruta existe; faltan los datos).
-- ---------------------------------------------------------------------
SELECT p.palabra, g.glosa, d.definicion
FROM palabra p
JOIN sena_palabra sp    ON sp.id_palabra = p.id_palabra
JOIN sena_glosa sg      ON sg.id_sena = sp.id_sena
JOIN glosa g            ON g.id_glosa = sg.id_glosa
JOIN sena_definicion sd ON sd.id_sena = sp.id_sena
JOIN definicion d       ON d.id_definicion = sd.id_definicion
JOIN lengua l           ON l.id_lengua = d.id_lengua
WHERE p.palabra = 'Banco' AND l.nombre_completo = 'Inglés';

-- ---------------------------------------------------------------------
-- L10. [SIN DATOS] Videos de una seña y quién la hizo
-- Se quiere: ver cómo se hace CASA-A en video.
-- Por qué no: no hay videos ni señantes cargados.
-- Resultado: 0 filas.
-- ---------------------------------------------------------------------
SELECT g.glosa, v.path, v.mano_dominante, st.perfil_nativo
FROM glosa g
JOIN sena_glosa sg        ON sg.id_glosa = g.id_glosa
JOIN sena_diccionario sdc ON sdc.id_sena = sg.id_sena
JOIN sena_video sv        ON sv.id_sena_diccionario = sdc.id_sena_diccionario
JOIN video v              ON v.id_video = sv.id_video
JOIN senante st           ON st.id_senante = v.id_senante
WHERE g.glosa = 'CASA-A';

-- ---------------------------------------------------------------------
-- L11. [SIN DATOS] Equivalente en otra lengua de señas
-- Se quiere: la seña de ASL que corresponde a CASA-A.
-- Por qué no: solo está cargada la LSM.
-- Resultado: 0 filas.
-- ---------------------------------------------------------------------
SELECT g1.glosa AS lsm, g2.glosa AS otra_lengua, l2.nombre_completo
FROM glosa g1
JOIN sena_glosa sg1   ON sg1.id_glosa = g1.id_glosa
JOIN sena_palabra sp1 ON sp1.id_sena = sg1.id_sena
JOIN sena_palabra sp2 ON sp2.id_palabra = sp1.id_palabra AND sp2.id_sena <> sp1.id_sena
JOIN sena s2          ON s2.id_sena = sp2.id_sena
JOIN lengua l2        ON l2.id_lengua = s2.id_lengua
JOIN sena_glosa sg2   ON sg2.id_sena = s2.id_sena
JOIN glosa g2         ON g2.id_glosa = sg2.id_glosa
WHERE g1.glosa = 'CASA-A' AND l2.nombre_completo <> 'Lengua de Señas Mexicana';

-- ---------------------------------------------------------------------
-- L12. [SIN DATOS] Comparar cómo describen dos diccionarios la misma seña
-- Se quiere: ver si otro diccionario describe ABAJO con otra ubicación.
-- Por qué no: solo hay un diccionario.
-- Resultado: 0 filas.
-- ---------------------------------------------------------------------
SELECT g.glosa, d1.nombre_completo AS dic_a, d2.nombre_completo AS dic_b,
       a.datos_fonologicos ->> 'ubicacion' AS ubicacion_a,
       b.datos_fonologicos ->> 'ubicacion' AS ubicacion_b
FROM sena_diccionario a
JOIN sena_diccionario b ON b.id_sena = a.id_sena AND b.id_diccionario <> a.id_diccionario
JOIN diccionario d1     ON d1.id_diccionario = a.id_diccionario
JOIN diccionario d2     ON d2.id_diccionario = b.id_diccionario
JOIN sena_glosa sg      ON sg.id_sena = a.id_sena
JOIN glosa g            ON g.id_glosa = sg.id_glosa
WHERE g.glosa = 'ABAJO';

-- ---------------------------------------------------------------------
-- L13. [INTEGRIDAD] Lo que el esquema no impide
-- Se quiere: que cada código del diccionario identifique una sola seña.
-- Por qué no: el código vive dentro del JSON y no tiene restricción
--            UNIQUE; el diccionario repite C-84.
-- Resultado: 1 fila (C-84).
-- ---------------------------------------------------------------------
SELECT sdc.datos_fonologicos ->> 'codigo' AS codigo,
       STRING_AGG(g.glosa, ', ' ORDER BY g.glosa) AS glosas
FROM sena_diccionario sdc
JOIN sena_glosa sg ON sg.id_sena = sdc.id_sena
JOIN glosa g       ON g.id_glosa = sg.id_glosa
GROUP BY 1
HAVING COUNT(*) > 1;

-- ---------------------------------------------------------------------
-- Resumen: cuántas señas tienen cada tipo de información
-- ---------------------------------------------------------------------
SELECT COUNT(*) AS senas,
       COUNT(*) FILTER (WHERE EXISTS (SELECT 1 FROM sena_glosa      x WHERE x.id_sena = s.id_sena)) AS con_glosa,
       COUNT(*) FILTER (WHERE EXISTS (SELECT 1 FROM sena_definicion x
                                      JOIN definicion d USING (id_definicion)
                                      JOIN lengua l ON l.id_lengua = d.id_lengua
                                      WHERE x.id_sena = s.id_sena AND l.nombre_completo = 'Inglés')) AS con_def_ingles,
       COUNT(*) FILTER (WHERE EXISTS (SELECT 1 FROM sena_diccionario x
                                      JOIN sena_video v USING (id_sena_diccionario)
                                      WHERE x.id_sena = s.id_sena)) AS con_video
FROM sena s;
