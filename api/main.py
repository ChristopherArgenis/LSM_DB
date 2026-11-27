"""API de LSM_DB: PostgreSQL -> API (FastAPI) -> app local.

Solo hace consultas de lectura (SELECT). Los datos de conexión se leen de
variables de entorno o del archivo api/.env (ver api/.env.ejemplo).
"""
import os
from pathlib import Path

import psycopg2
import psycopg2.extras
from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

AQUI = Path(__file__).parent

# Lee api/.env si existe (formato CLAVE=valor, una por línea)
env = AQUI / ".env"
if env.exists():
    for linea in env.read_text(encoding="utf-8").splitlines():
        if "=" in linea and not linea.strip().startswith("#"):
            k, v = linea.split("=", 1)
            os.environ.setdefault(k.strip(), v.strip())

CONEXION = dict(
    host=os.getenv("PGHOST", "localhost"),
    port=os.getenv("PGPORT", "5432"),
    dbname=os.getenv("PGDATABASE", "postgres"),
    user=os.getenv("PGUSER", "postgres"),
    password=os.getenv("PGPASSWORD", ""),
    options="-c search_path=lsm",
    client_encoding="UTF8",
)


def consulta(sql, params=()):
    with psycopg2.connect(**CONEXION) as con:
        with con.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            cur.execute("SET TRANSACTION READ ONLY")
            cur.execute(sql, params)
            return cur.fetchall()


# Quita acentos sin depender de la extensión unaccent
SIN_ACENTO = "translate(lower({}), 'áéíóúüñ', 'aeiouun')"

app = FastAPI(title="API LSM_DB", version="1.0",
              description="Consultas de solo lectura sobre la base de diccionarios de LSM.")
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["GET"], allow_headers=["*"])

RESUMEN = """
SELECT s.id_sena,
       sd.datos_fonologicos->>'codigo'        AS codigo,
       sd.datos_fonologicos->>'significado'   AS significado,
       sd.datos_fonologicos->>'tipo_sena'     AS tipo,
       (SELECT string_agg(g.glosa, ', ' ORDER BY g.glosa)
          FROM sena_glosa sg JOIN glosa g USING (id_glosa)
         WHERE sg.id_sena = s.id_sena)        AS glosa
FROM sena s
JOIN sena_diccionario sd ON sd.id_sena = s.id_sena
"""


@app.get("/api/estadisticas")
def estadisticas():
    """Cuántos registros hay en las tablas principales."""
    return consulta("""
        SELECT (SELECT count(*) FROM sena)        AS senas,
               (SELECT count(*) FROM palabra)     AS palabras,
               (SELECT count(*) FROM glosa)       AS glosas,
               (SELECT count(*) FROM definicion)  AS definiciones,
               (SELECT count(*) FROM diccionario) AS diccionarios""")[0]


@app.get("/api/buscar")
def buscar(q: str = Query(..., min_length=1, description="Palabra en español o glosa")):
    """Señas cuya palabra o glosa contiene el texto (sin importar acentos ni mayúsculas)."""
    patron = f"%{q}%"
    return consulta(RESUMEN + f"""
        WHERE EXISTS (SELECT 1 FROM sena_palabra sp JOIN palabra p USING (id_palabra)
                       WHERE sp.id_sena = s.id_sena
                         AND {SIN_ACENTO.format('p.palabra')} LIKE {SIN_ACENTO.format('%s')})
           OR EXISTS (SELECT 1 FROM sena_glosa sg JOIN glosa g USING (id_glosa)
                       WHERE sg.id_sena = s.id_sena
                         AND {SIN_ACENTO.format('g.glosa')} LIKE {SIN_ACENTO.format('%s')})
        ORDER BY glosa LIMIT 100""", (patron, patron))


@app.get("/api/filtrar")
def filtrar(configuracion: str = "", ubicacion: str = "", movimiento: str = "", tipo: str = ""):
    """Señas por parámetros fonológicos (texto contenido en datos_fonologicos)."""
    condiciones, params = [], []
    for clave, valor in (("configuracion", configuracion), ("ubicacion", ubicacion),
                         ("movimiento", movimiento)):
        if valor:
            campo = SIN_ACENTO.format(f"sd.datos_fonologicos->>'{clave}'")
            condiciones.append(f"{campo} LIKE {SIN_ACENTO.format('%s')}")
            params.append(f"%{valor}%")
    if tipo:
        condiciones.append("sd.datos_fonologicos->>'tipo_sena' = %s")
        params.append(tipo)
    if not condiciones:
        raise HTTPException(400, "Indica al menos un filtro.")
    return consulta(RESUMEN + " WHERE " + " AND ".join(condiciones) + " ORDER BY glosa LIMIT 200", params)


@app.get("/api/tipos")
def tipos():
    """Tipos de seña con cuántas señas tiene cada uno."""
    return consulta("""SELECT datos_fonologicos->>'tipo_sena' AS tipo, count(*) AS senas
                       FROM sena_diccionario GROUP BY 1 ORDER BY 2 DESC""")


@app.get("/api/senas/{id_sena}")
def sena(id_sena: int):
    """Ficha completa de una seña: glosas, palabras, definiciones y descripción por diccionario."""
    base = consulta(RESUMEN + " WHERE s.id_sena = %s", (id_sena,))
    if not base:
        raise HTTPException(404, "No existe esa seña.")
    ficha = dict(base[0])
    ficha["palabras"] = [r["palabra"] for r in consulta(
        """SELECT p.palabra FROM sena_palabra sp JOIN palabra p USING (id_palabra)
           WHERE sp.id_sena = %s ORDER BY p.palabra""", (id_sena,))]
    ficha["definiciones"] = consulta(
        """SELECT d.definicion, d.autor, l.nombre_completo AS lengua
           FROM sena_definicion sd JOIN definicion d USING (id_definicion)
           JOIN lengua l USING (id_lengua) WHERE sd.id_sena = %s""", (id_sena,))
    ficha["diccionarios"] = consulta(
        """SELECT dc.nombre_completo AS diccionario, sd.datos_fonologicos
           FROM sena_diccionario sd JOIN diccionario dc USING (id_diccionario)
           WHERE sd.id_sena = %s""", (id_sena,))
    return ficha


# La app local (api/app/index.html) se sirve en http://localhost:8000/
app.mount("/", StaticFiles(directory=AQUI / "app", html=True), name="app")
