"""Descomprime ilustraciones_lsm.zip en api/imagenes y dice cuántas señas quedaron con imagen.

Uso:  python preparar_imagenes.py            (usa data/ilustraciones_lsm.zip)
      python preparar_imagenes.py ruta\\al\\archivo.zip
"""
import json, sys, zipfile
from pathlib import Path

AQUI = Path(__file__).parent
destino = AQUI / "imagenes"
zip_path = Path(sys.argv[1]) if len(sys.argv) > 1 else AQUI.parent / "data" / "ilustraciones_lsm.zip"
with zipfile.ZipFile(zip_path) as z:
    z.extractall(destino)

clave = lambda t: "".join(c for c in t.upper() if c.isalnum())
archivos = {clave(f.stem): f.name for f in destino.rglob("*") if f.is_file()}
codigos = [m["codigo"] for m in json.loads((AQUI.parent / "metadatos" / "metadatos.json").read_text(encoding="utf-8"))]
con = [c for c in codigos if clave(c) in archivos]
print(f"Señas con imagen: {len(con)} de {len(codigos)}")
if len(con) < len(codigos):
    print("Ejemplos de archivos en el zip:", list(archivos.values())[:5])
    print("Ejemplos de códigos sin imagen:", [c for c in codigos if clave(c) not in archivos][:5])
