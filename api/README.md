# API y app local

PostgreSQL → **API** (FastAPI, `main.py`) → **app local** (`app/index.html`).
La API solo lee (SELECT); no modifica la base.

## Cómo arrancarla (Windows)

1. Necesitas Python 3.10 o más reciente.
2. Copia `.env.ejemplo` como `.env` y pon tus datos de conexión. La base es la misma que abres en DBeaver (`postgres`, esquema `lsm`).
3. Doble clic en `iniciar.bat`. Instala lo necesario, arranca la API y abre http://localhost:8000.

A mano, desde esta carpeta:

    python -m pip install -r requirements.txt
    python -m uvicorn main:app --port 8000

## Si no recuerdas la contraseña de postgres

En DBeaver (ya conectado) ejecuta esto y usa la contraseña nueva en `.env` y en DBeaver:

    ALTER USER postgres PASSWORD 'nueva_contraseña';

## Cómo se usa la app

La app está pensada para dos públicos: quien lee español y la comunidad sorda usuaria de LSM. Por eso se busca primero con dibujos y después con texto.

**Buscar con dibujos** (pantalla inicial):
1. Toca la forma de la mano. Cada forma lleva la letra o el número del alfabeto manual que se le parece.
2. Toca en la silueta el lugar del cuerpo donde se hace la seña.
3. Elige si es con una mano, con dos o cualquiera.

Los resultados salen como tarjetas: la forma de la mano (naranja = mano principal; azul con borde punteado = mano de apoyo) y un cuerpo pequeño con el lugar marcado.

**Buscar con palabra:** escribe una palabra en español, como «casa». No importan los acentos.

**Ficha de la seña:** muestra la glosa en grande, sus palabras, la forma de la mano paso a paso (O ➜ 5 cuando cambia), el lugar en el cuerpo, el movimiento y, al final, el texto del diccionario.

**Fotos de las formas de mano:** `app/manos/` tiene las 221 fotos de la *Tabla de las Configuraciones Manuales* del DLSM CDMX 2017, una por variante (`B-P_12.png` = B-P.12), con fondo transparente, e `indice.json` (código → archivo). Los botones de mano usan la variante .1 de cada familia; la ficha muestra las variantes exactas que dice el diccionario (por ejemplo O.5 → 5.4). Cubren 108 de los 117 códigos que aparecen en la base (98 % de las menciones; faltan P.13 y A.10, que no vienen en la tabla). Se extrajeron con `scripts/extraer_configuraciones_dlsm.py`. Las fotos son del DLSM: hay que darle el crédito al publicarlas.

**Imágenes o videos:** descarga `ilustraciones_lsm.zip` de Drive y ejecuta `python preparar_imagenes.py ruta\al\ilustraciones_lsm.zip`. Las descomprime en `api/imagenes/` y te dice cuántas señas quedaron con imagen. El nombre de cada archivo debe ser el código de la seña (`B-P 62`, `BP_62` o `b-p62` sirven igual).

La búsqueda con dibujos usa `metadatos/metadatos.json`. Si regeneras METADATOS, reinicia la API.

## Rutas de la API

| Ruta | Qué devuelve |
|---|---|
| `GET /api/estadisticas` | Cuántas señas, palabras, glosas, definiciones y diccionarios hay |
| `GET /api/buscar?q=casa` | Señas cuya palabra o glosa contiene el texto (sin importar acentos) |
| `GET /api/filtrar?configuracion=B-P&ubicacion=pecho&movimiento=arco&tipo=SM` | Señas por su forma (al menos un filtro) |
| `GET /api/tipos` | Tipos de seña y cuántas hay de cada uno |
| `GET /api/visual/opciones` | Formas de mano y lugares del cuerpo, con cuántas señas hay de cada uno |
| `GET /api/visual/filtrar?mano=O&zona=Frente&dos_manos=false` | Señas por mano, lugar y número de manos |
| `GET /api/senas/{id}` | Ficha completa: glosa, palabras, definición y cómo se hace según cada diccionario |

Documentación interactiva para probar cada ruta: http://localhost:8000/docs
