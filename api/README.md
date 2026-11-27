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

## Rutas de la API

| Ruta | Qué devuelve |
|---|---|
| `GET /api/estadisticas` | Cuántas señas, palabras, glosas, definiciones y diccionarios hay |
| `GET /api/buscar?q=casa` | Señas cuya palabra o glosa contiene el texto (sin importar acentos) |
| `GET /api/filtrar?configuracion=B-P&ubicacion=pecho&movimiento=arco&tipo=SM` | Señas por su forma (al menos un filtro) |
| `GET /api/tipos` | Tipos de seña y cuántas hay de cada uno |
| `GET /api/senas/{id}` | Ficha completa: glosa, palabras, definición y cómo se hace según cada diccionario |

Documentación interactiva para probar cada ruta: http://localhost:8000/docs
