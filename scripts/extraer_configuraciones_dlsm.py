"""Extrae las fotos de la Tabla de las Configuraciones Manuales del DLSM CDMX 2017.

Cada foto se guarda como <codigo>.png (B-P.12 -> B-P_12.png), con fondo transparente,
y indice.json relaciona código -> archivo. Empareja cada imagen con la etiqueta de texto
que tiene justo debajo en la página.

Uso:  pip install pymupdf
      python scripts/extraer_configuraciones_dlsm.py "Diccionario_HD_...pdf" api/app/manos

Nota: B-P.16 trae la máscara dañada (sale con fondo negro); se recortó a mano del render de la página.
"""
import re, sys, json, pymupdf
from pathlib import Path
pdf, out = sys.argv[1], Path(sys.argv[2]); out.mkdir(parents=True, exist_ok=True)
doc = pymupdf.open(pdf)
cod = re.compile(r'^[0-9A-Z]+(?:-[A-Z0-9]+)?\.\s?\d+$')
res = {}
for pno in range(len(doc)):
    pg = doc[pno]
    labels = []
    for b in pg.get_text("dict")["blocks"]:
        for l in b.get("lines", []):
            t = "".join(s["text"] for s in l["spans"]).strip()
            if cod.match(t): labels.append((t.replace(" ", ""), pymupdf.Rect(l["bbox"])))
    if len(labels) < 3: continue
    for info in pg.get_image_info(xrefs=True):
        r = pymupdf.Rect(info["bbox"]); x = info["xref"]
        if not x or r.width < 8: continue
        cx = (r.x0 + r.x1) / 2
        cand = [(lb.y0 - r.y1, t) for t, lb in labels if lb.x0 - 25 < cx < lb.x1 + 25 and -15 < lb.y0 - r.y1 < 60]
        if not cand: continue
        t = min(cand)[1]
        if t in res: continue
        pix = pymupdf.Pixmap(doc, x)
        sm = doc.extract_image(x).get("smask")
        if sm:
            mask = pymupdf.Pixmap(doc, sm)
            try: pix = pymupdf.Pixmap(pix, mask)
            except Exception: pass
        if pix.n - pix.alpha > 3: pix = pymupdf.Pixmap(pymupdf.csRGB, pix)
        f = out / (t.replace(".", "_") + ".png"); pix.save(f)
        res[t] = {"archivo": f.name, "pagina_pdf": pno + 1}
json.dump(res, open(out / "indice.json", "w"), ensure_ascii=False, indent=1)
print(len(res)); print(sorted(res)[:200])
