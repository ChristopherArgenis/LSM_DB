# LSM_DB
Base de Datos de Diccionarios de Lengua de Seña

Réplica en PostgreSQL del Diagrama Entidad-Relación del proyecto, cargada con el
Diccionario de Lengua de Señas Mexicana de la Ciudad de México (2017).

## Estructura

| Archivo | Contenido |
|---|---|
| `sql/01_schema.sql` | Crea el esquema `lsm`: 14 tablas, llaves, índices y validación del JSON |
| `sql/02_datos_dlsm_cdmx.sql` | Diccionario LSM CDMX 2017 (1,006 señas). **Generado**, no editar a mano |
| `sql/03_consultas.sql` | Catálogo de consultas (A1…K13) |
| `sql/datos_prueba.sql` | Datos inventados para probar consultas (hola/hello, ASL, videos…) |
| `data/LSM_diccionario_Scraper.xlsx` | Scrapeo original del diccionario |
| `scripts/importar_dlsm_cdmx.py` | Convierte el Excel en `02_datos_dlsm_cdmx.sql` |
| `schemas/datos_fonologicos.schema.json` | JSON Schema de `datos_fonologicos` |
| `docs/DATOS_FONOLOGICOS.md` | Campos del JSON, cuáles son obligatorios y ejemplos |
| `docs/IMPORTACION_DLSM_CDMX.md` | Qué se importó, correcciones aplicadas y pendientes |
| `docs/CONSULTAS.md` | Limitaciones del esquema y explicación de cada consulta |

## Instalación

Con el diccionario real:

```bash
createdb lsm_db
psql -d lsm_db -f sql/01_schema.sql -f sql/02_datos_dlsm_cdmx.sql
```

Con los datos de prueba (en otra base, porque suponen ids desde 1):

```bash
createdb lsm_prueba
psql -d lsm_prueba -f sql/01_schema.sql -f sql/datos_prueba.sql
```

Para ver todas las consultas: `psql -d <base> -f sql/03_consultas.sql`.

`01_schema.sql` borra y vuelve a crear el esquema `lsm`, así que se puede ejecutar varias veces para reiniciar la base.

Para regenerar el SQL del diccionario después de cambiar el Excel o el script:

```bash
pip install openpyxl
python3 scripts/importar_dlsm_cdmx.py
```

## Tablas

- **Catálogos:** `lengua`, `diccionario`, `senante`, `tipo_sena` (un tipo por seña)
- **Contenido por lengua:** `palabra`, `glosa`, `definicion`, `sena`
- **Grabaciones:** `video`
- **Tablas intermedias:** `sena_palabra`, `sena_glosa`, `sena_definicion`, `sena_diccionario` (con `datos_fonologicos` JSONB validado), `sena_video`

## Diferencias con el diagrama

1. **Nombres sin Ñ:** `SEÑA` → `sena`, `SEÑANTE` → `senante`, etc.
2. **`lengua.nombre_completo`** aparece como `int`; se usa `VARCHAR` porque guarda un nombre.
3. **`palabra.id_lengua`** no está marcado como FK en el diagrama, pero la relación "Contiene" lo une con `lengua`; se declara FK.
4. **`tipo_sena`** es un catálogo (`id_tipo_sena`, `tipo`) y `sena.id_tipo` es FK hacia él (corregido en el diagrama).
5. **`sena_video.id_sena_video`** aparece como FK pero subrayado; se implementa como PK.
6. Se agregaron restricciones `UNIQUE` en las tablas intermedias, índices sobre las FK, un índice GIN sobre `datos_fonologicos` y la validación del JSON (`docs/DATOS_FONOLOGICOS.md`).
