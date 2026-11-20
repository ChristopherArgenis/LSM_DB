# Manual: respaldo, rollback y mudanza de la base de datos

Base: `lsm_db` · Usuario: `postgres` · PostgreSQL 18 en Windows.
Cada operación tiene dos opciones: **1. CMD** (directo en PostgreSQL) y **2. DBeaver** (interfaz visual).

---

## 1. Respaldo (backup)

Genera un solo archivo `.backup` con toda la base (tablas, datos, funciones).

### Opción 1 · CMD

```bash
cd "C:\Program Files\PostgreSQL\18\bin"
```

```bash
pg_dump -U postgres -h localhost -p 5432 -F c -f "C:\respaldos\lsm_db.backup" lsm_db
```

Pide la contraseña de `postgres`. La carpeta `C:\respaldos` debe existir.

### Opción 2 · DBeaver

1. Clic derecho en la base `lsm_db` › **Tools** › **Backup**.
2. Marca el esquema `lsm` › **Next**.
3. **Format:** Custom. **Output folder:** `C:\respaldos`. **File name pattern:** `lsm_db`.
4. **Start**.

> Si DBeaver pide un *Local client*, elige `C:\Program Files\PostgreSQL\18\bin`.

---

## 2. Mudanza a otra máquina (restaurar)

**Requisitos en la otra máquina:** PostgreSQL 18 (o mayor) instalado y el archivo `lsm_db.backup` copiado (USB, nube, etc.).

### Opción 1 · CMD

```bash
cd "C:\Program Files\PostgreSQL\18\bin"
```

```bash
createdb -U postgres -h localhost -p 5432 lsm_db
```

```bash
pg_restore -U postgres -h localhost -p 5432 -d lsm_db "C:\respaldos\lsm_db.backup"
```

### Opción 2 · DBeaver

1. Crea la conexión a PostgreSQL de la otra máquina (`localhost`, puerto `5432`, usuario `postgres`).
2. Clic derecho en **Databases** › **Create New Database** › nombre `lsm_db` › **OK**.
3. Clic derecho en `lsm_db` › **Tools** › **Restore**.
4. **Format:** Custom. **Backup file:** `lsm_db.backup`.
5. **Start**.

### Verificar

En un editor SQL conectado a `lsm_db`:

```sql
SELECT count(*) FROM lsm.sena_diccionario;   -- debe dar 1006
```

---

## 3. Rollback (deshacer cambios)

Deshace cambios **antes** de confirmarlos. Un cambio ya confirmado (COMMIT o auto-commit) no se deshace: para eso está el respaldo.

### Opción 1 · CMD (psql)

```bash
psql -U postgres -d lsm_db
```

```sql
BEGIN;
-- cambios (INSERT, UPDATE, DELETE...)
ROLLBACK;   -- deshace todo desde BEGIN
-- o COMMIT; para guardarlos
```

Para deshacer solo una parte: `SAVEPOINT punto1;` … `ROLLBACK TO punto1;`

### Opción 2 · DBeaver

1. En la barra superior, cambia **Auto-Commit** a **Manual Commit**.
2. Ejecuta los cambios.
3. Botón **Rollback** para deshacer, o **Commit** para guardar.
4. Al terminar, regresa a **Auto-Commit**.

---

## Errores comunes

| Error | Solución |
|---|---|
| `Connection refused` | El servicio está apagado: `services.msc` › `postgresql-x64-18` › Iniciar |
| `database "lsm_db" already exists` | Usa otro nombre o borra la base vacía antes de restaurar |
| `pg_restore: unsupported version` | La máquina destino tiene PostgreSQL más antiguo: instala la 18 |
| `password authentication failed` | Contraseña de `postgres` incorrecta en esa máquina |
