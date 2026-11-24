# sql/

Scripts de la base de datos. Todos trabajan en el esquema `lsm`.

## Orden para crear la base

| Paso | Archivo | Qué hace |
|---|---|---|
| 1 | `01_schema.sql` | Borra y vuelve a crear el esquema `lsm`: 15 tablas, llaves, índices y validación de `datos_fonologicos`. **Reinicia la base:** borra lo que haya. |
| 2 | `02_datos_dlsm_cdmx.sql` | Carga el DLSM CDMX 2017 (1,006 señas). **Generado** por `scripts/importar_dlsm_cdmx.py`: no editar a mano. |
| 3 | `02b_glosas_dlsm_cdmx.sql` | Carga una glosa por seña. **Generado** por `scripts/generar_glosas_dlsm_cdmx.py`. Se puede correr más de una vez sin duplicar. |

En CMD o terminal, desde la raíz del repositorio:

```bash
createdb -U postgres lsm_db
```

```bash
psql -U postgres -d lsm_db -f sql/01_schema.sql -f sql/02_datos_dlsm_cdmx.sql -f sql/02b_glosas_dlsm_cdmx.sql
```

En DBeaver: abre cada archivo, en ese orden, y ejecútalo completo con **Alt+X**.

Comprobación: `SELECT count(*) FROM lsm.sena_diccionario;` debe dar **1006**.

## Consultas (no cambian los datos)

Requieren los pasos 1 a 3. En DBeaver, ejecuta primero la línea `SET search_path TO lsm;` y luego cada consulta con **Ctrl+Enter**. Los valores entre comillas (`'Casa'`, `'ABAJO'`) son ejemplos: cámbialos.

| Archivo | Contenido |
|---|---|
| `03_consultas.sql` | Catálogo completo de consultas (A1…K6) |
| `04_consultas_relevantes.sql` | 20 consultas para explorar el diccionario |
| `05_consultas_limitaciones.sql` | 13 límites del diseño de la base, con demostración |
| `06_consultas_api.sql` | Funciones `api.*` que devuelven JSON, como endpoints. **Crea** esas funciones en el esquema `api` (no toca los datos). |
| `07_limitaciones_revisadas.sql` | Las 6 limitaciones de la presentación, revisadas |

Los resultados de todas están en `docs/SALIDAS.md` (generado por `scripts/generar_salidas.py`).

## migraciones/: actualizar una base que ya tienes

Si tu base se creó antes y **no quieres borrarla ni volver a cargarla**, usa el archivo de `migraciones/` en lugar de repetir los pasos 1 a 3:

| Archivo | Qué hace |
|---|---|
| `2026-11-25_definicion_video_y_mano_dominante.sql` | Crea `definicion_video`, agrega `id_definicion_video` a `definicion` con su relación (FK) y pasa `mano_dominante` de `video` a `senante`. |

En DBeaver: ábrelo conectado a tu base y ejecútalo con **Alt+X**. Va entre `BEGIN` y `COMMIT` (si algo falla, no cambia nada) y al final muestra las columnas nuevas para comprobarlo. Córrelo una sola vez. Haz un respaldo antes.

Una base nueva no lo necesita: `01_schema.sql` ya la crea así.

## Respaldo y mudanza

Ver `docs/MANUAL_RESPALDO.md` (o el `.pdf`).
