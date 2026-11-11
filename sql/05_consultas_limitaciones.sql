-- =====================================================================
-- LSM_DB - Limitaciones del DISEÑO de la base de datos
-- Requiere: 01_schema.sql, 02_datos_dlsm_cdmx.sql, 02b_glosas_dlsm_cdmx.sql
-- En DBeaver: ejecutar primero el SET y luego cada consulta con Ctrl+Enter.
--
-- Estos límites NO dependen del Diccionario CDMX ni de la LSM: vienen de
-- cómo están hechas las tablas. Seguirían ahí aunque se cargaran diez
-- diccionarios, cien lenguas y miles de videos.
--
-- Cada límite tiene:
--   * Qué se quiere preguntar.
--   * Por qué el modelo no lo permite (qué tabla o columna falta).
--   * Qué pasa cuando haya más diccionarios o lenguas.
--   * Una DEMOSTRACIÓN: a veces con datos (da filas, pero no alcanzan para
--     responder) y a veces sobre la estructura (information_schema), que
--     sale con 0 filas porque la columna o tabla necesaria no existe.
--   * Qué cambio al modelo lo resolvería.
-- =====================================================================
SET search_path TO lsm;

-- =====================================================================
-- L1. La definición pertenece a la seña, no a la palabra ni al sentido
-- ---------------------------------------------------------------------
-- Se quiere:  la definición de una palabra en un sentido concreto
--             ("Abandonar" en el sentido de dejar un trabajo).
-- Por qué no: sena_definicion une seña con definición; ninguna tabla
--             une palabra con definición, ni define "acepciones".
-- Con más diccionarios: cada diccionario sumará definiciones a la misma
--             seña y se mezclarán todavía más sentidos.
-- Lo resolvería: una tabla de acepciones (sentido) ligada a palabra,
--             seña y definición.
-- =====================================================================

-- Demostración con datos: 6 señas y definiciones casi iguales, sin forma
-- de saber cuál corresponde a cada sentido.
SELECT g.glosa, d.definicion
FROM palabra p
JOIN sena_palabra sp    ON sp.id_palabra = p.id_palabra
JOIN sena_glosa sg      ON sg.id_sena = sp.id_sena
JOIN glosa g            ON g.id_glosa = sg.id_glosa
JOIN sena_definicion sd ON sd.id_sena = sp.id_sena
JOIN definicion d       ON d.id_definicion = sd.id_definicion
WHERE p.palabra = 'Abandonar'
ORDER BY g.glosa;

-- Demostración sobre la estructura: definicion no tiene llave hacia
-- palabra ni hacia una acepción (0 filas).
SELECT column_name
FROM information_schema.columns
WHERE table_schema = 'lsm' AND table_name = 'definicion'
  AND column_name IN ('id_palabra', 'id_acepcion', 'numero_acepcion');

-- =====================================================================
-- L2. No se sabe de qué diccionario viene una palabra, glosa o definición
-- ---------------------------------------------------------------------
-- Se quiere:  "¿qué palabras usa el diccionario X para esta seña?" o
--             "¿qué definición da el diccionario Y?".
-- Por qué no: sena_palabra, sena_glosa y sena_definicion unen con la seña,
--             no con la entrada de diccionario (sena_diccionario). Solo los
--             datos fonológicos quedan ligados a su diccionario.
-- Con más diccionarios: todas las palabras y definiciones de todos los
--             diccionarios quedarán revueltas en la misma seña.
-- Lo resolvería: ligar palabra, glosa y definición a sena_diccionario
--             (o agregar id_diccionario a esas tablas intermedias).
-- =====================================================================

-- Demostración sobre la estructura: ninguna de esas tablas tiene
-- id_diccionario ni id_sena_diccionario (0 filas).
SELECT table_name, column_name
FROM information_schema.columns
WHERE table_schema = 'lsm'
  AND table_name IN ('sena_palabra', 'sena_glosa', 'sena_definicion', 'definicion', 'glosa')
  AND column_name IN ('id_diccionario', 'id_sena_diccionario');

-- Comparación: sena_diccionario sí lo tiene (por eso la fonología sí se
-- puede atribuir a un diccionario).
SELECT table_name, column_name
FROM information_schema.columns
WHERE table_schema = 'lsm' AND table_name = 'sena_diccionario'
  AND column_name = 'id_diccionario';

-- =====================================================================
-- L3. No hay relaciones entre señas
-- ---------------------------------------------------------------------
-- Se quiere:  de qué señas se forma una compuesta, cuáles son variantes
--             de otra, o qué seña de ASL equivale a una de LSM.
-- Por qué no: no existe una tabla seña-seña. Las partes de una compuesta
--             solo están descritas en texto, y la equivalencia entre
--             lenguas solo se puede adivinar si comparten una palabra.
-- Con más lenguas: comparar LSM con ASL dependería de que ambas señas
--             tengan la misma palabra escrita, lo cual es poco fiable.
-- Lo resolvería: una tabla sena_relacion (id_sena_a, id_sena_b, tipo),
--             con tipos como "parte_de", "variante_de", "equivale_a".
-- =====================================================================

-- Demostración con datos: AMANTE es compuesta, pero solo hay texto.
SELECT g.glosa, sdc.datos_fonologicos ->> 'tipo_sena' AS partes_en_texto
FROM glosa g
JOIN sena_glosa sg        ON sg.id_glosa = g.id_glosa
JOIN sena_diccionario sdc ON sdc.id_sena = sg.id_sena
WHERE g.glosa = 'AMANTE';

-- Demostración sobre la estructura: no hay tabla que relacione dos
-- señas, es decir, con dos llaves hacia sena (0 filas).
SELECT tc.table_name, COUNT(*) AS llaves_hacia_sena
FROM information_schema.table_constraints tc
JOIN information_schema.constraint_column_usage ccu
  ON ccu.constraint_name = tc.constraint_name AND ccu.table_schema = tc.table_schema
WHERE tc.table_schema = 'lsm' AND tc.constraint_type = 'FOREIGN KEY'
  AND ccu.table_name = 'sena'
GROUP BY tc.table_name
HAVING COUNT(*) > 1;

-- =====================================================================
-- L4. La fonología es texto libre dentro de un JSON
-- ---------------------------------------------------------------------
-- Se quiere:  todas las señas que se hacen "en el pecho", o comparar la
--             ubicación de una seña entre dos diccionarios.
-- Por qué no: el esquema obliga a usar las mismas claves, pero el valor
--             de cada clave es una frase libre. La misma idea se escribe
--             de muchas formas y no se puede comparar con exactitud.
-- Con más diccionarios: cada diccionario redacta distinto; comparar
--             "A la altura del pecho." con "Pecho" no da coincidencia.
-- Lo resolvería: catálogos de parámetros (ubicacion, movimiento,
--             orientacion, configuracion) con códigos, y el JSON
--             apuntando a esos códigos.
-- =====================================================================

-- Demostración con datos: la comparación exacta encuentra pocas...
SELECT COUNT(*) AS senas_con_texto_exacto
FROM sena_diccionario
WHERE datos_fonologicos ->> 'ubicacion' = 'Sobre el pecho.';

-- ...pero hay cientos de redacciones distintas que mencionan el pecho.
SELECT COUNT(DISTINCT datos_fonologicos ->> 'ubicacion') AS redacciones_distintas_con_pecho
FROM sena_diccionario
WHERE datos_fonologicos ->> 'ubicacion' ILIKE '%pecho%';

-- =====================================================================
-- L5. Solo se guarda una forma de cada palabra
-- ---------------------------------------------------------------------
-- Se quiere:  encontrar la seña buscando "bonita", "bonitos" o "comí".
-- Por qué no: palabra guarda un texto; no hay tabla de formas (femenino,
--             plural, conjugaciones) ni un campo de lema.
-- Con más lenguas: cada lengua tiene su propia morfología; el problema
--             crece con cada idioma que se agregue.
-- Lo resolvería: una tabla forma_palabra (forma, id_palabra) o una
--             búsqueda con lematización (full-text search de PostgreSQL).
-- =====================================================================

-- Demostración con datos: 0 filas con las formas flexionadas...
SELECT p.palabra
FROM palabra p
WHERE LOWER(p.palabra) IN ('bonita', 'bonitos', 'comí', 'comimos');

-- ...y sí aparece la forma del diccionario.
SELECT p.palabra
FROM palabra p
WHERE LOWER(p.palabra) IN ('bonito', 'comer');

-- =====================================================================
-- L6. Sin región ni variación geográfica
-- ---------------------------------------------------------------------
-- Se quiere:  "¿qué seña de CASA se usa en Monterrey?" o "¿de dónde es
--             el señante del video?".
-- Por qué no: ninguna tabla (sena, senante, video, sena_diccionario)
--             tiene región, estado o comunidad.
-- Con más diccionarios regionales: no se podría distinguir la seña de
--             Monterrey de la de la CDMX, salvo por el nombre del
--             diccionario.
-- Lo resolvería: un catálogo region y una columna id_region en senante,
--             video y/o sena_diccionario.
-- =====================================================================

-- Demostración sobre la estructura (0 filas).
SELECT table_name, column_name
FROM information_schema.columns
WHERE table_schema = 'lsm'
  AND (column_name ILIKE '%region%' OR column_name ILIKE '%estado%'
       OR column_name ILIKE '%ciudad%' OR column_name ILIKE '%comunidad%');

-- =====================================================================
-- L7. Los videos dependen de un diccionario y no marcan tiempos
-- ---------------------------------------------------------------------
-- Se quiere:  (a) guardar el video de una seña que no está en ningún
--             diccionario (un corpus libre); (b) saber en qué segundo de
--             un video de una frase aparece cada seña.
-- Por qué no: sena_video apunta a sena_diccionario, no a sena; y no tiene
--             columnas de inicio y fin.
-- Con más videos: los videos de conversación o de corpus no se podrían
--             etiquetar seña por seña.
-- Lo resolvería: permitir sena_video -> sena, y agregar inicio_ms y fin_ms.
-- =====================================================================

-- Demostración sobre la estructura: columnas de sena_video.
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'lsm' AND table_name = 'sena_video'
ORDER BY ordinal_position;

-- No hay columnas de tiempo (0 filas).
SELECT column_name
FROM information_schema.columns
WHERE table_schema = 'lsm' AND table_name = 'sena_video'
  AND (column_name ILIKE '%inicio%' OR column_name ILIKE '%fin%' OR column_name ILIKE '%tiempo%');

-- =====================================================================
-- L8. El señante tiene muy pocos datos y la edad es fija
-- ---------------------------------------------------------------------
-- Se quiere:  la edad del señante cuando grabó, su lengua materna o su
--             nivel de dominio de la lengua.
-- Por qué no: senante solo tiene edad (un número fijo que envejece) y
--             perfil_nativo (texto libre); no se relaciona con lengua.
-- Con más señantes: no se podrían hacer estudios sociolingüísticos.
-- Lo resolvería: fecha_nacimiento en lugar de edad, e id_lengua_materna.
-- =====================================================================

-- Demostración sobre la estructura.
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'lsm' AND table_name = 'senante'
ORDER BY ordinal_position;

-- =====================================================================
-- L9. El código de cada diccionario no está protegido
-- ---------------------------------------------------------------------
-- Se quiere:  que cada código (B-P 4) identifique una sola seña dentro de
--             su diccionario.
-- Por qué no: el código vive dentro del JSON y no tiene restricción
--             UNIQUE por diccionario. Ya ocurrió con C-84.
-- Con más diccionarios: cada uno tendrá su propio sistema de códigos y
--             nada impedirá repetidos ni errores de captura.
-- Lo resolvería: una columna codigo en sena_diccionario con
--             UNIQUE (id_diccionario, codigo).
-- =====================================================================

-- Demostración con datos.
SELECT sdc.datos_fonologicos ->> 'codigo' AS codigo,
       STRING_AGG(g.glosa, ', ' ORDER BY g.glosa) AS glosas
FROM sena_diccionario sdc
JOIN sena_glosa sg ON sg.id_sena = sdc.id_sena
JOIN glosa g       ON g.id_glosa = sg.id_glosa
GROUP BY sdc.id_diccionario, 1
HAVING COUNT(*) > 1;

-- =====================================================================
-- L10. La lengua se guarda dos veces y puede contradecirse
-- ---------------------------------------------------------------------
-- Se quiere:  confiar en que una entrada de diccionario es de la misma
--             lengua que su seña.
-- Por qué no: sena.id_lengua y sena_diccionario.id_lengua son columnas
--             independientes; ninguna regla obliga a que coincidan.
--             Lo mismo pasa entre sena y glosa.
-- Con más lenguas: se podría ligar una entrada de ASL a una seña de LSM
--             sin que la base lo impida.
-- Lo resolvería: quitar el dato duplicado, o una regla (CHECK o trigger)
--             que compare ambas lenguas.
-- =====================================================================

-- Demostración sobre la estructura: no hay ninguna restricción CHECK ni
-- trigger que compare las lenguas (0 filas).
SELECT conname
FROM pg_constraint
WHERE conrelid = 'lsm.sena_diccionario'::regclass AND contype = 'c'
  AND pg_get_constraintdef(oid) ILIKE '%lengua%';

SELECT tgname
FROM pg_trigger
WHERE tgrelid IN ('lsm.sena_diccionario'::regclass, 'lsm.sena_glosa'::regclass)
  AND NOT tgisinternal;

-- =====================================================================
-- L11. Un solo tipo por seña y sin datos gramaticales
-- ---------------------------------------------------------------------
-- Se quiere:  todos los verbos, o señas que sean a la vez compuestas e
--             icónicas.
-- Por qué no: sena.id_tipo admite un solo valor, y palabra no tiene
--             categoría gramatical; solo se puede adivinar leyendo el
--             inicio de la definición ("v.", "sust.").
-- Con más diccionarios: cada uno abrevia distinto y la adivinanza falla.
-- Lo resolvería: una tabla sena_tipo (N:M) y una columna categoria en
--             palabra o en la acepción.
-- =====================================================================

-- Demostración con datos: "categorías" sacadas del texto, con ruido
-- ('(otro)', 'intej.', mayúsculas).
SELECT COALESCE(SUBSTRING(d.definicion FROM '^\d?\.?\s*([a-zA-Z]+\.)'), '(otro)') AS categoria_adivinada,
       COUNT(*) AS definiciones
FROM definicion d
GROUP BY 1
ORDER BY 2 DESC;

-- =====================================================================
-- L12. Sin historial ni autoría en la mayoría de las tablas
-- ---------------------------------------------------------------------
-- Se quiere:  saber quién capturó o cambió una seña o una palabra, y cuándo.
-- Por qué no: solo glosa y definicion tienen autor y fecha; sena, palabra,
--             sena_diccionario y video no.
-- Con más colaboradores: no habría forma de revisar ni revertir cambios.
-- Lo resolvería: columnas creado_por / creado_en en cada tabla, o una
--             tabla de auditoría.
-- =====================================================================

-- Demostración sobre la estructura: qué tablas tienen autor o fecha.
SELECT t.table_name,
       BOOL_OR(c.column_name = 'autor') AS tiene_autor,
       BOOL_OR(c.column_name = 'fecha') AS tiene_fecha
FROM information_schema.tables t
JOIN information_schema.columns c
  ON c.table_schema = t.table_schema AND c.table_name = t.table_name
WHERE t.table_schema = 'lsm' AND t.table_type = 'BASE TABLE'
GROUP BY t.table_name
ORDER BY tiene_autor DESC, t.table_name;

-- =====================================================================
-- L13. Palabra y glosa sin restricciones de unicidad
-- ---------------------------------------------------------------------
-- Se quiere:  que "Casa" exista una sola vez por lengua y que una glosa
--             no se repita.
-- Por qué no: palabra y glosa no tienen UNIQUE; el script de carga evita
--             duplicados, pero la base no lo garantiza.
-- Con más diccionarios: cada carga podría duplicar palabras y glosas.
-- Lo resolvería: UNIQUE (LOWER(palabra), id_lengua) y UNIQUE (glosa, id_lengua).
-- =====================================================================

-- Demostración sobre la estructura: restricciones UNIQUE de esas tablas
-- (0 filas).
SELECT tc.table_name, tc.constraint_name
FROM information_schema.table_constraints tc
WHERE tc.table_schema = 'lsm' AND tc.constraint_type = 'UNIQUE'
  AND tc.table_name IN ('palabra', 'glosa');
