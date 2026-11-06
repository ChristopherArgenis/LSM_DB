"""
Genera sql/02_datos_dlsm_cdmx.sql a partir del scrapeo del
Diccionario de Lengua de Señas Mexicana de la Ciudad de México (2017).

Uso:
    pip install openpyxl
    python3 scripts/importar_dlsm_cdmx.py [data/LSM_diccionario_Scraper.xlsx] [sql/02_datos_dlsm_cdmx.sql]

Qué llena:
    lengua (LSM, Español), diccionario, tipo_sena (SM, SB, SS, SC),
    sena, sena_diccionario (con datos_fonologicos), palabra, sena_palabra,
    definicion, sena_definicion.
Qué NO llena (el diccionario no trae esa información):
    glosa, sena_glosa, senante, video, sena_video.
"""
import json
import re
import sys
from pathlib import Path

import openpyxl

RAIZ = Path(__file__).resolve().parent.parent
ENTRADA = Path(sys.argv[1]) if len(sys.argv) > 1 else RAIZ / "data" / "LSM_diccionario_Scraper.xlsx"
SALIDA = Path(sys.argv[2]) if len(sys.argv) > 2 else RAIZ / "sql" / "02_datos_dlsm_cdmx.sql"

DICCIONARIO = "Diccionario de Lengua de Señas Mexicana de la Ciudad de México (DLSM, 2017)"
# Página de créditos del diccionario: "Coordinador y editor del DLSM"
AUTOR_DICCIONARIO = "Lic. César Ernesto Escobedo Delgado (coordinador y editor)"
# Autor de las definiciones: el equipo de lexicografía del mismo diccionario
AUTOR_DEFINICIONES = "Equipo de Lexicografía, DLSM CDMX 2017"
LENGUA_SENAS = "Lengua de Señas Mexicana"
LENGUA_ORAL = "Español"

# Columna del Excel -> clave del JSON datos_fonologicos
COLUMNAS = {
    "Codigo": "codigo",
    "Significado": "significado",
    "Tipo de Seña": "tipo_sena",
    "Configuración": "configuracion",
    "Orientación": "orientacion",
    "Ubicación": "ubicacion",
    "Movimiento": "movimiento",
    "Rasgos no manuales": "rasgos_no_manuales",
    "Representación": "representacion",
    "Definición": "definicion",
    "Nota cultural": "nota_cultural",
}

# Códigos a los que el scraper les quitó el prefijo (están entre S-119 y S-122)
CODIGOS_CORREGIDOS = {"120": "S-120", "121": "S-121"}

correcciones = []  # registro de lo que se corrigió, para el reporte


def limpiar(texto):
    """Quita espacios sobrantes y une palabras cortadas con guion por el PDF ('alimen- to')."""
    if texto is None:
        return None
    texto = re.sub(r"\s+", " ", str(texto)).strip()
    texto = re.sub(r"([A-Za-zÁÉÍÓÚÑáéíóúñü])- ([a-záéíóúñü])", r"\1\2", texto)
    return texto or None


def tipo_principal(tipo):
    """'SM' / 'SB' / 'SS' / 'SC' (compuesta) a partir del texto de la columna; None si no se reconoce."""
    if re.match(r"^SC\b", tipo) or re.search(r"\bI[.:]", tipo):
        return "SC"
    if tipo in ("SM", "SB", "SS"):
        return tipo
    return None


def palabras_de(significado):
    """
    Extrae las palabras en español del campo Significado.
      '/'  separa acepciones numeradas:  'Abrir 1 / Abierto, ta 2 (A)'
      '–'  separa sinónimos:             'Abajo – Debajo'
      '(A)' marca variante; '(LSM)', '(STC Metro)', '(ley, presupuesto)' son aclaraciones.
      ', ta' / ', -a' es la terminación femenina.
    """
    resultado = []
    for acepcion in re.split(r"\s*/\s*", significado):
        acepcion = re.sub(r"\([^)]*\)", " ", acepcion)            # aclaraciones y variantes
        for parte in re.split(r"\s*–\s*|\s+-\s+", acepcion):     # sinónimos
            parte = re.sub(r"(\s*\d+)+\s*$", "", parte.strip())     # número(s) de acepción
            parte = re.sub(r",\s*-?[a-záéíóúñ]{1,4}$", "", parte)    # terminación femenina
            parte = parte.strip(" ,.;:")
            if parte:
                resultado.append(parte)
    return list(dict.fromkeys(resultado))  # sin repetidos, en orden


def leer_filas():
    hoja = openpyxl.load_workbook(ENTRADA, read_only=True).worksheets[0]
    filas = list(hoja.iter_rows(values_only=True))
    encabezado = filas[0]
    for fila in filas[1:]:
        if any(fila):
            yield dict(zip(encabezado, fila))


def procesar(fila):
    datos = {clave: limpiar(fila.get(col)) for col, clave in COLUMNAS.items()}
    codigo = datos["codigo"]

    if codigo in CODIGOS_CORREGIDOS:
        correcciones.append(f"{codigo}: código corregido a {CODIGOS_CORREGIDOS[codigo]}")
        datos["codigo"] = codigo = CODIGOS_CORREGIDOS[codigo]

    # El scraper pasó el inicio del Significado a la columna Tipo ('SM Bonito,' + 'ta – Bello…')
    m = re.match(r"^(SM|SB|SS)\s+(.+)$", datos["tipo_sena"])
    if m:
        sobrante = m.group(2).strip(" |")
        datos["tipo_sena"] = m.group(1)
        if sobrante:
            datos["significado"] = f"{sobrante} {datos['significado']}"
        correcciones.append(f"{codigo}: tipo '{m.group(0)}' -> '{m.group(1)}', significado -> '{datos['significado']}'")

    # La orientación quedó dentro de la configuración ('A.1 Orientación: Palmas hacia adentro.')
    if not datos["orientacion"] and datos["configuracion"] and "Orientación:" in datos["configuracion"]:
        config, orient = datos["configuracion"].split("Orientación:", 1)
        datos["configuracion"], datos["orientacion"] = config.strip(), orient.strip()
        correcciones.append(f"{codigo}: orientación separada de la configuración")

    tipo = tipo_principal(datos["tipo_sena"])
    if tipo is None:
        correcciones.append(f"{codigo}: tipo '{datos['tipo_sena']}' no reconocido -> sena.id_tipo queda NULL")

    fono = {k: v for k, v in datos.items() if v is not None}
    if fila.get("Pagina_PDF") is not None:
        fono["pagina"] = int(fila["Pagina_PDF"])

    return {
        "tipo": tipo,
        "fono": fono,
        "palabras": palabras_de(datos["significado"]),
        "definicion": datos["definicion"],
    }


def sql_texto(valor):
    if valor is None:
        return "NULL"
    return "'" + str(valor).replace("'", "''") + "'"


def sql_arreglo(valores):
    return "ARRAY[" + ", ".join(sql_texto(v) for v in valores) + "]::text[]"


def generar(entradas):
    lineas = [
        "-- =====================================================================",
        f"-- {DICCIONARIO}",
        "-- ARCHIVO GENERADO por scripts/importar_dlsm_cdmx.py — no editar a mano.",
        "-- Ejecutar después de 01_schema.sql. Busca lengua, diccionario y tipos",
        "-- por nombre, así que se puede cargar junto con otros datos.",
        "-- No llena: glosa, sena_glosa, senante, video, sena_video.",
        "-- =====================================================================",
        "SET search_path TO lsm;",
        "BEGIN;",
        "",
        "-- Catálogos ----------------------------------------------------------",
        f"INSERT INTO lengua (nombre_completo, modalidad)",
        f"SELECT v.n, v.m FROM (VALUES ({sql_texto(LENGUA_SENAS)}, 'viso-gestual'), ({sql_texto(LENGUA_ORAL)}, 'oral-auditiva')) v(n, m)",
        "WHERE NOT EXISTS (SELECT 1 FROM lengua l WHERE l.nombre_completo = v.n);",
        "",
        "INSERT INTO tipo_sena (tipo) VALUES ('SM'), ('SB'), ('SS'), ('SC') ON CONFLICT (tipo) DO NOTHING;",
        "",
        f"INSERT INTO diccionario (completo, autor)",
        f"SELECT {sql_texto(DICCIONARIO)}, {sql_texto(AUTOR_DICCIONARIO)}",
        f"WHERE NOT EXISTS (SELECT 1 FROM diccionario WHERE completo = {sql_texto(DICCIONARIO)});",
        "",
        "-- Tabla temporal con cada entrada del diccionario ---------------------",
        "CREATE TEMP TABLE dlsm_entrada (",
        "    n           INTEGER PRIMARY KEY,",
        "    tipo        TEXT,",
        "    fono        JSONB NOT NULL,",
        "    palabras    TEXT[] NOT NULL,",
        "    definicion  TEXT,",
        "    id_sena     INTEGER,",
        "    id_definicion INTEGER",
        ") ON COMMIT DROP;",
        "",
        "INSERT INTO dlsm_entrada (n, tipo, fono, palabras, definicion) VALUES",
    ]
    valores = []
    for n, e in enumerate(entradas, start=1):
        valores.append(
            f"({n}, {sql_texto(e['tipo'])}, {sql_texto(json.dumps(e['fono'], ensure_ascii=False))}, "
            f"{sql_arreglo(e['palabras'])}, {sql_texto(e['definicion'])})"
        )
    lineas.append(",\n".join(valores) + ";")
    lineas += [
        "",
        "-- Reservar id para cada seña y definición (mantiene la correspondencia fila -> id)",
        "UPDATE dlsm_entrada e SET id_sena = s.id",
        "FROM (SELECT n, nextval(pg_get_serial_sequence('lsm.sena', 'id_sena')) AS id",
        "      FROM (SELECT n FROM dlsm_entrada ORDER BY n) o) s",
        "WHERE s.n = e.n;",
        "UPDATE dlsm_entrada e SET id_definicion = s.id",
        "FROM (SELECT n, nextval(pg_get_serial_sequence('lsm.definicion', 'id_definicion')) AS id",
        "      FROM (SELECT n FROM dlsm_entrada WHERE definicion IS NOT NULL ORDER BY n) o) s",
        "WHERE s.n = e.n;",
        "",
        "-- SENA ----------------------------------------------------------------",
        "INSERT INTO sena (id_sena, id_tipo, id_lengua) OVERRIDING SYSTEM VALUE",
        "SELECT e.id_sena, t.id_tipo_sena,",
        f"       (SELECT id_lengua FROM lengua WHERE nombre_completo = {sql_texto(LENGUA_SENAS)})",
        "FROM dlsm_entrada e",
        "LEFT JOIN tipo_sena t ON t.tipo = e.tipo",
        "ORDER BY e.n;",
        "",
        "-- SENA_DICCIONARIO (datos_fonologicos) --------------------------------",
        "INSERT INTO sena_diccionario (id_sena, id_diccionario, id_lengua, datos_fonologicos)",
        "SELECT e.id_sena,",
        f"       (SELECT id_diccionario FROM diccionario WHERE completo = {sql_texto(DICCIONARIO)}),",
        f"       (SELECT id_lengua FROM lengua WHERE nombre_completo = {sql_texto(LENGUA_SENAS)}),",
        "       e.fono",
        "FROM dlsm_entrada e",
        "ORDER BY e.n;",
        "",
        "-- DEFINICION ----------------------------------------------------------",
        "INSERT INTO definicion (id_definicion, definicion, autor, fecha, id_lengua) OVERRIDING SYSTEM VALUE",
        f"SELECT e.id_definicion, e.definicion, {sql_texto(AUTOR_DEFINICIONES)}, NULL,",
        f"       (SELECT id_lengua FROM lengua WHERE nombre_completo = {sql_texto(LENGUA_ORAL)})",
        "FROM dlsm_entrada e",
        "WHERE e.id_definicion IS NOT NULL",
        "ORDER BY e.n;",
        "",
        "INSERT INTO sena_definicion (id_sena, id_definicion)",
        "SELECT id_sena, id_definicion FROM dlsm_entrada WHERE id_definicion IS NOT NULL ORDER BY n;",
        "",
        "-- PALABRA (sin duplicar las que ya existan en español) -----------------",
        "INSERT INTO palabra (palabra, id_lengua)",
        "SELECT DISTINCT ON (LOWER(p.palabra)) p.palabra,",
        f"       (SELECT id_lengua FROM lengua WHERE nombre_completo = {sql_texto(LENGUA_ORAL)})",
        "FROM dlsm_entrada e, UNNEST(e.palabras) WITH ORDINALITY p(palabra, orden)",
        "WHERE NOT EXISTS (",
        "    SELECT 1 FROM palabra x",
        "    WHERE LOWER(x.palabra) = LOWER(p.palabra)",
        f"      AND x.id_lengua = (SELECT id_lengua FROM lengua WHERE nombre_completo = {sql_texto(LENGUA_ORAL)}))",
        "ORDER BY LOWER(p.palabra), e.n, p.orden;",
        "",
        "INSERT INTO sena_palabra (id_sena, id_palabra)",
        "SELECT DISTINCT e.id_sena, x.id_palabra",
        "FROM dlsm_entrada e, UNNEST(e.palabras) p(palabra)",
        "JOIN palabra x ON LOWER(x.palabra) = LOWER(p.palabra)",
        f"             AND x.id_lengua = (SELECT id_lengua FROM lengua WHERE nombre_completo = {sql_texto(LENGUA_ORAL)})",
        "ON CONFLICT (id_sena, id_palabra) DO NOTHING;",
        "",
        "COMMIT;",
        "",
    ]
    return "\n".join(lineas)


def main():
    entradas = [procesar(f) for f in leer_filas()]
    SALIDA.write_text(generar(entradas), encoding="utf-8")
    print(f"{len(entradas)} entradas -> {SALIDA}")
    print(f"{len({p.lower() for e in entradas for p in e['palabras']})} palabras distintas")
    print("Correcciones:")
    for c in correcciones:
        print("  -", c)


if __name__ == "__main__":
    main()
