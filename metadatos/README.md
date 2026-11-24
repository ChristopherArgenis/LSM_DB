# METADATOS

Índice de búsqueda con valores de lista cerrada (familia de configuración manual y zona del cuerpo) para cada seña. Se **genera** a partir de `datos_fonologicos` y vive **aparte**, en `metadatos.json`: no se guarda en la base.

| Archivo | Para qué |
|---|---|
| `generar_metadatos.sql` | La consulta que arma METADATOS. Solo lee la base (SELECT). |
| `exportar_metadatos.bat` | Windows: corre la consulta y escribe `metadatos.json`. |
| `metadatos.json` | Resultado actual: 1,006 señas del DLSM CDMX 2017, una por línea. |
| `esquema_metadatos.txt` / `.sql` | El esquema: claves, obligatorias y opcionales, listas cerradas. |

## Requisitos

1. PostgreSQL con la base cargada desde el repositorio:
   `sql/01_schema.sql`, `sql/02_datos_dlsm_cdmx.sql` y `sql/02b_glosas_dlsm_cdmx.sql`.
2. El servicio de PostgreSQL iniciado.

## Generar `metadatos.json`

**Windows:** abre `exportar_metadatos.bat` con doble clic. Pide la contraseña de `postgres` y deja `metadatos.json` en esta carpeta.
Si tu instalación es distinta, edita las 3 variables del inicio del `.bat` (`PSQL`, `BD`, `USUARIO`).

**Windows a mano (CMD), desde esta carpeta:**

```bash
set PGCLIENTENCODING=UTF8
```

```bash
"C:\Program Files\PostgreSQL\18\bin\psql.exe" -U postgres -d lsm_db -v ON_ERROR_STOP=1 -qAt -f generar_metadatos.sql -o metadatos.json
```

**Linux / macOS:**

```bash
PGCLIENTENCODING=UTF8 psql -U postgres -d lsm_db -v ON_ERROR_STOP=1 -qAt -f generar_metadatos.sql -o metadatos.json
```

Qué hace cada opción: `-qAt` deja solo el JSON (sin mensajes, tabla ni encabezado), `-v ON_ERROR_STOP=1` se detiene si algo falla y `PGCLIENTENCODING=UTF8` conserva acentos y la Ñ.

## Comprobar el resultado

- El archivo empieza con `[` y termina con `]`, con una seña por línea.
- Debe tener **1,006** señas. Por ejemplo, en Python: `len(json.load(open("metadatos.json", encoding="utf-8")))`.
- No debe contener `\"`. Si aparece, el archivo se sacó con «Exportar datos › JSON» de DBeaver: vuelve a generarlo con `psql` como arriba.

## Generarlo desde DBeaver

1. Abre `generar_metadatos.sql` conectado a la base y ejecútalo con **Alt+X**. Sale **una sola celda** (`metadatos_json`).
2. Selecciona esa celda y presiona **Shift+Enter**: se abre el editor del valor completo.
3. En ese editor usa **Guardar en archivo** (*Save to file…*) y guárdalo como `metadatos.json`.
   También sirve **Ctrl+A** y **Ctrl+C** dentro del editor, pegar en un editor de texto y guardar con codificación **UTF-8**.
4. **No uses «Exportar datos» (Export data) ni copies desde la tabla de resultados:** DBeaver trata el valor como texto de una columna, lo encierra en comillas y escapa todo con `\"`.

## Revisar en DBeaver (sin generar el archivo)

Abre `generar_metadatos.sql`, ejecútalo con **Alt+X** y mira la celda. Para ver una fila por seña, usa la **salida de revisión** que está comentada al final del script.

## Otro diccionario

Cambia `id_diccionario = 1` en el script. Antes revisa que el diccionario use la misma notación (códigos como `B-P.2` y frases como «A la altura del pecho»); si no, hay que ajustar los patrones y el catálogo de zonas del script. Ver `docs/TRABAJO_FUTURO.md`, sección 4.
