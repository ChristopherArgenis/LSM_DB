"""
Genera sql/02b_glosas_dlsm_cdmx.sql: una glosa por cada seña del Diccionario LSM CDMX 2017.

El diccionario no trae glosas, así que se construyen a partir del campo Significado:

  1. Base: la primera palabra del significado, en MAYÚSCULAS, sin signos de puntuación
     y con guiones en lugar de espacios.      "¿Por qué?"            -> POR-QUÉ
                                               "Buenas noches"       -> BUENAS-NOCHES
                                               "Abajo – Debajo"      -> ABAJO
                                               "Bonito, ta – Bello…" -> BONITO
  2. Variante: si el significado trae una letra (A), (B), (C), se agrega.
                                               "Casa (A)" -> CASA-A,  "Casa (B)" -> CASA-B
  3. Si dos señas quedan con la misma glosa, se agrega la aclaración entre paréntesis
     que trae el diccionario.                  "Crema (cosmético)" -> CREMA-COSMÉTICO
                                               "Brasil (SSI)"      -> BRASIL-SSI
  4. Si aún se repiten (el diccionario no da nada que las distinga), se numeran
     en el orden del diccionario.              Adorar, Adorar      -> ADORAR-1, ADORAR-2

Uso:
    python3 scripts/generar_glosas_dlsm_cdmx.py
"""
import re
import sys
from collections import defaultdict
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import importar_dlsm_cdmx as dlsm  # noqa: E402

SALIDA = dlsm.RAIZ / "sql" / "02b_glosas_dlsm_cdmx.sql"
AUTOR = "LSM_DB (generadas a partir del DLSM CDMX 2017)"
FECHA = "2026-11-11"

# Errores de OCR en las aclaraciones: "(SSl)" es "(SSI)"
ACLARACION_CORREGIDA = {"SSL": "SSI"}


def a_glosa(texto):
    texto = re.sub(r"[^\w\s-]", "", texto)        # ¿ ? ¡ ! . , ´ ® ...
    texto = re.sub(r"[\s_-]+", "-", texto.strip())
    return texto.upper().strip("-")


def letra_variante(significado):
    m = re.search(r"\(([A-Z])\)", significado)
    return m.group(1) if m else None


def aclaracion(significado):
    """Primera aclaración entre paréntesis que no sea una letra de variante."""
    for contenido in re.findall(r"\(([^)]*)\)", significado):
        if not re.fullmatch(r"[A-Z]", contenido.strip()):
            texto = a_glosa(contenido)
            return ACLARACION_CORREGIDA.get(texto, texto)
    return None


def construir():
    entradas = [dlsm.procesar(f) for f in dlsm.leer_filas()]
    filas = []
    for n, e in enumerate(entradas, start=1):
        f = e["fono"]
        glosa = a_glosa(e["palabras"][0])
        letra = letra_variante(f["significado"])
        if letra:
            glosa += f"-{letra}"
        filas.append({"n": n, "codigo": f["codigo"], "significado": f["significado"], "glosa": glosa})

    # Paso 3: desempatar con la aclaración del diccionario
    grupos = defaultdict(list)
    for fila in filas:
        grupos[fila["glosa"]].append(fila)
    for repetidas in grupos.values():
        if len(repetidas) > 1:
            for fila in repetidas:
                fila["antes"] = fila["glosa"]
                extra = aclaracion(fila["significado"])
                if extra:
                    fila["glosa"] += f"-{extra}"

    # Paso 4: numerar lo que siga repetido
    grupos = defaultdict(list)
    for fila in filas:
        grupos[fila["glosa"]].append(fila)
    numeradas = []
    for glosa, repetidas in grupos.items():
        if len(repetidas) > 1:
            # Si la aclaración no las distinguió, se numera sobre la glosa corta
            base = repetidas[0].get("antes", glosa)
            for i, fila in enumerate(sorted(repetidas, key=lambda x: x["n"]), start=1):
                fila["glosa"] = f"{base}-{i}"
            numeradas.append(base)
    return filas, numeradas


def generar(filas):
    t = dlsm.sql_texto
    valores = ",\n".join(
        f"({f['n']}, {t(f['codigo'])}, {t(f['significado'])}, {t(f['glosa'])})" for f in filas
    )
    return f"""-- =====================================================================
-- Glosas del {dlsm.DICCIONARIO}
-- ARCHIVO GENERADO por scripts/generar_glosas_dlsm_cdmx.py — no editar a mano.
-- Ejecutar después de 01_schema.sql y 02_datos_dlsm_cdmx.sql.
-- Llena: glosa y sena_glosa (una glosa por seña, {len(filas)} en total).
-- Cada glosa se liga a su seña por el código y el significado del
-- diccionario (el código C-84 aparece dos veces, así que el código solo
-- no basta). Se puede ejecutar más de una vez sin duplicar.
-- =====================================================================
SET search_path TO lsm;
BEGIN;

CREATE TEMP TABLE dlsm_glosa (
    n           INTEGER PRIMARY KEY,
    codigo      TEXT NOT NULL,
    significado TEXT NOT NULL,
    glosa       TEXT NOT NULL,
    id_sena     INTEGER,
    id_glosa    INTEGER
) ON COMMIT DROP;

INSERT INTO dlsm_glosa (n, codigo, significado, glosa) VALUES
{valores};

-- Encontrar la seña de cada glosa
UPDATE dlsm_glosa g SET id_sena = sdc.id_sena
FROM sena_diccionario sdc
JOIN diccionario dic ON dic.id_diccionario = sdc.id_diccionario
WHERE dic.nombre_completo = {t(dlsm.DICCIONARIO)}
  AND sdc.datos_fonologicos ->> 'codigo'      = g.codigo
  AND sdc.datos_fonologicos ->> 'significado' = g.significado;

DO $$
DECLARE faltan INTEGER;
BEGIN
    SELECT COUNT(*) INTO faltan FROM dlsm_glosa WHERE id_sena IS NULL;
    IF faltan > 0 THEN
        RAISE EXCEPTION '% glosas no encontraron su seña: ¿se cargó 02_datos_dlsm_cdmx.sql?', faltan;
    END IF;
END $$;

-- Reutilizar glosas que ya existan (si el script se ejecuta otra vez)
UPDATE dlsm_glosa g SET id_glosa = x.id_glosa
FROM glosa x
WHERE x.glosa = g.glosa
  AND x.id_lengua = (SELECT id_lengua FROM lengua WHERE nombre_completo = {t(dlsm.LENGUA_SENAS)});

-- Reservar id para las nuevas
UPDATE dlsm_glosa g SET id_glosa = s.id
FROM (SELECT n, nextval(pg_get_serial_sequence('lsm.glosa', 'id_glosa')) AS id
      FROM (SELECT n FROM dlsm_glosa WHERE id_glosa IS NULL ORDER BY n) o) s
WHERE s.n = g.n;

-- GLOSA ---------------------------------------------------------------
INSERT INTO glosa (id_glosa, glosa, autor, fecha, id_lengua) OVERRIDING SYSTEM VALUE
SELECT g.id_glosa, g.glosa, {t(AUTOR)}, DATE {t(FECHA)},
       (SELECT id_lengua FROM lengua WHERE nombre_completo = {t(dlsm.LENGUA_SENAS)})
FROM dlsm_glosa g
WHERE NOT EXISTS (SELECT 1 FROM glosa x WHERE x.id_glosa = g.id_glosa)
ORDER BY g.n;

-- SENA_GLOSA ----------------------------------------------------------
INSERT INTO sena_glosa (id_sena, id_glosa)
SELECT id_sena, id_glosa FROM dlsm_glosa ORDER BY n
ON CONFLICT (id_sena, id_glosa) DO NOTHING;

COMMIT;
"""


def main():
    filas, numeradas = construir()
    SALIDA.write_text(generar(filas), encoding="utf-8")
    print(f"{len(filas)} glosas -> {SALIDA}")
    print(f"{len({f['glosa'] for f in filas})} distintas")
    print("Numeradas por no tener nada que las distinga:", ", ".join(sorted(numeradas)))


if __name__ == "__main__":
    main()
