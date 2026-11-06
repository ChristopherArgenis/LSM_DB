# LSM_DB
Base de Datos de Diccionarios de Lengua de Seña

Réplica en PostgreSQL del Diagrama Entidad-Relación del proyecto.

## Estructura

| Archivo | Contenido |
|---|---|
| `sql/01_schema.sql` | Crea el esquema `lsm` con las 14 tablas, llaves e índices |
| `sql/02_seed.sql` | Datos de prueba (lenguas, señas, glosas, diccionarios, videos…) |
| `sql/03_consultas.sql` | Catálogo de consultas posibles (A1…J1) |
| `docs/CONSULTAS.md` | Limitaciones del esquema y explicación de cada consulta |

## Instalación

```bash
createdb lsm_db
psql -d lsm_db -f sql/01_schema.sql -f sql/02_seed.sql
psql -d lsm_db -f sql/03_consultas.sql   # opcional: ejecuta todas las consultas
```

`01_schema.sql` borra y vuelve a crear el esquema `lsm`, así que se puede ejecutar varias veces para reiniciar la base.

## Tablas

- **Catálogos:** `lengua`, `diccionario`, `senante`
- **Contenido por lengua:** `palabra`, `glosa`, `definicion`, `sena`
- **Catálogo de tipos:** `tipo_sena` (un tipo por seña)
- **Grabaciones:** `video`
- **Tablas intermedias:** `sena_palabra`, `sena_glosa`, `sena_definicion`, `sena_diccionario` (con `datos_fonologicos` JSONB), `sena_video`

## Diferencias con el diagrama

1. **Nombres sin Ñ:** `SEÑA` → `sena`, `SEÑANTE` → `senante`, etc.
2. **`lengua.nombre_completo`** aparece como `int`; se usa `VARCHAR` porque guarda un nombre.
3. **`palabra.id_lengua`** no está marcado como FK en el diagrama, pero la relación "Contiene" lo une con `lengua`; se declara FK.
4. **`tipo_sena`** es un catálogo (`id_tipo_sena`, `tipo`) y `sena.id_tipo` es FK hacia él (corregido en el diagrama).
5. **`sena_video.id_sena_video`** aparece como FK pero subrayado; se implementa como PK.
6. Se agregaron restricciones `UNIQUE` en las tablas intermedias para evitar pares duplicados, y un índice GIN sobre `datos_fonologicos`.
