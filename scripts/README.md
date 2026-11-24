# scripts/

Scripts de Python que **generan** archivos del repositorio. Solo hacen falta si cambia el Excel del diccionario o las reglas de las glosas; para usar la base basta con los `.sql` ya generados.

Se ejecutan desde la raíz del repositorio con Python 3.

| Script | Entrada | Salida | Requisitos |
|---|---|---|---|
| `importar_dlsm_cdmx.py` | `data/LSM_diccionario_Scraper.xlsx` | `sql/02_datos_dlsm_cdmx.sql` | `pip install openpyxl` |
| `generar_glosas_dlsm_cdmx.py` | El mismo Excel (usa `importar_dlsm_cdmx.py`) | `sql/02b_glosas_dlsm_cdmx.sql` | `pip install openpyxl` |
| `generar_salidas.py` | La base ya cargada (por defecto `lsm_db`; otra con la variable `PGDATABASE`) | `docs/SALIDAS.md` | `psql` en el PATH |

## Orden si cambia el diccionario

```bash
python3 scripts/importar_dlsm_cdmx.py
```

```bash
python3 scripts/generar_glosas_dlsm_cdmx.py
```

Después vuelve a crear la base con los pasos de `sql/README.md` y, si quieres actualizar los resultados de las consultas:

```bash
python3 scripts/generar_salidas.py
```

`generar_salidas.py` también acepta códigos de consulta para ver solo esas en pantalla, por ejemplo `python3 scripts/generar_salidas.py A1 D7`.

En Windows usa `python` en lugar de `python3` si así está instalado.

METADATOS no se genera con Python: ver `metadatos/README.md`.
