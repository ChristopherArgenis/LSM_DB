"""
Ejecuta cada consulta de sql/03_consultas.sql y escribe sus resultados en docs/SALIDAS.md.

Uso:
    python3 scripts/generar_salidas.py                 # todas las consultas
    python3 scripts/generar_salidas.py A1 D7           # solo esas, se imprimen en pantalla

Requisitos: psql en el PATH y una base ya cargada (01_schema.sql + 02_datos_dlsm_cdmx.sql).
La conexión usa las variables normales de PostgreSQL (PGDATABASE, PGUSER, PGHOST...);
si no se indica PGDATABASE, se usa "lsm_db".
"""
import csv
import io
import os
import re
import subprocess
import sys
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
CONSULTAS = RAIZ / "sql" / "03_consultas.sql"
SALIDA = RAIZ / "docs" / "SALIDAS.md"
MAX_FILAS = 20       # filas que se muestran por consulta
MAX_CELDA = 180      # caracteres por celda

RE_BLOQUE = re.compile(r"^-- ([A-Z])\. (.+)$")
RE_CONSULTA = re.compile(r"^-- ([A-Z]\d+)\. (.+)$")


def leer_consultas():
    """Devuelve una lista de bloques: (letra, titulo, [(codigo, descripcion, sql), ...])."""
    bloques, actual = [], None
    for linea in CONSULTAS.read_text(encoding="utf-8").splitlines():
        if m := RE_BLOQUE.match(linea):
            bloques.append([m.group(1), m.group(2), []])
            continue
        if m := RE_CONSULTA.match(linea):
            actual = {"codigo": m.group(1), "descripcion": [m.group(2)], "sql": []}
            bloques[-1][2].append(actual)
            continue
        if actual is None:
            continue
        if linea.startswith("-- ====="):
            actual = None
        elif linea.startswith("--") and not actual["sql"]:
            actual["descripcion"].append(linea.lstrip("- ").strip())
        elif linea.strip():
            actual["sql"].append(linea)
    return [
        (letra, titulo, [(c["codigo"], " ".join(c["descripcion"]), "\n".join(c["sql"]).rstrip(";\n "))
                         for c in consultas])
        for letra, titulo, consultas in bloques
    ]


def psql(sql):
    """Ejecuta una consulta y devuelve sus filas (encabezado incluido) como lista de listas."""
    env = dict(os.environ)
    env.setdefault("PGDATABASE", "lsm_db")
    proceso = subprocess.run(
        ["psql", "-X", "-q", "-v", "ON_ERROR_STOP=1", "--csv",
         "-c", "SET search_path TO lsm", "-c", sql],
        capture_output=True, text=True, env=env,
    )
    if proceso.returncode != 0:
        raise RuntimeError(proceso.stderr.strip())
    return list(csv.reader(io.StringIO(proceso.stdout)))


def ejecutar(sql):
    total = int(psql(f"SELECT COUNT(*) AS n FROM ({sql}) q")[1][0])
    filas = psql(f"SELECT * FROM ({sql}) q LIMIT {MAX_FILAS}")
    return total, filas


def celda(valor):
    valor = re.sub(r"\s+", " ", valor).strip()
    if len(valor) > MAX_CELDA:
        valor = valor[:MAX_CELDA - 1] + "…"
    return valor.replace("|", "\\|") or " "


def tabla_markdown(filas):
    encabezado, *datos = filas
    lineas = ["| " + " | ".join(celda(c) for c in encabezado) + " |",
              "|" + "---|" * len(encabezado)]
    lineas += ["| " + " | ".join(celda(c) for c in fila) + " |" for fila in datos]
    return "\n".join(lineas)


def resultado(total, filas):
    if total == 0:
        return "**Sin resultados (0 filas).**"
    texto = tabla_markdown(filas)
    if total > MAX_FILAS:
        return f"{texto}\n\n*Se muestran {MAX_FILAS} de {total} filas.*"
    return f"{texto}\n\n*{total} fila{'s' if total != 1 else ''}.*"


def main():
    bloques = leer_consultas()
    pedidas = {c.upper() for c in sys.argv[1:]}

    if pedidas:  # modo rápido: imprimir en pantalla
        for _, _, consultas in bloques:
            for codigo, descripcion, sql in consultas:
                if codigo in pedidas:
                    total, filas = ejecutar(sql)
                    print(f"## {codigo}. {descripcion}\n\n{resultado(total, filas)}\n")
        return

    partes = [
        "# Salidas de las consultas",
        "",
        "Generado por `scripts/generar_salidas.py` sobre el Diccionario LSM CDMX 2017 "
        "(`sql/02_datos_dlsm_cdmx.sql`). No editar a mano: vuelve a ejecutar el script.",
        "",
        f"Cada consulta muestra hasta {MAX_FILAS} filas; las celdas largas se recortan. "
        "El SQL completo está en `sql/03_consultas.sql`.",
        "",
    ]
    indice, cuerpo, vacias, controles, n = [], [], [], [], 0
    for letra, titulo, consultas in bloques:
        indice.append(f"- **{letra}. {titulo.capitalize()}**: "
                      + ", ".join(f"[{c}](#{c.lower()})" for c, _, _ in consultas))
        cuerpo.append(f"## {letra}. {titulo.capitalize()}\n")
        for codigo, descripcion, sql in consultas:
            total, filas = ejecutar(sql)
            n += 1
            if total == 0 and "[VACÍA HOY" in descripcion:
                vacias.append(codigo)
            elif total == 0 and "[CONTROL" in descripcion:
                controles.append(codigo)
            cuerpo.append(f'### <a id="{codigo.lower()}"></a>{codigo}. {descripcion}\n')
            cuerpo.append(f"<details><summary>SQL</summary>\n\n```sql\n{sql};\n```\n\n</details>\n")
            cuerpo.append(resultado(total, filas) + "\n")
    partes += [f"**{n} consultas.**", "",
               f"- Vacías porque falta información (inglés, ASL, videos, otro diccionario): {', '.join(vacias) or 'ninguna'}.",
               f"- Controles de calidad sin problemas encontrados: {', '.join(controles) or 'ninguno'}.", "",
               "## Índice", "", *indice, "", *cuerpo]
    SALIDA.write_text("\n".join(partes), encoding="utf-8")
    print(f"{n} consultas -> {SALIDA} | vacías por falta de datos: {', '.join(vacias) or 'ninguna'}"
          f" | controles sin problemas: {', '.join(controles) or 'ninguno'}")


if __name__ == "__main__":
    main()
