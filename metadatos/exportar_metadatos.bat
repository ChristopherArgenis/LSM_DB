@echo off
REM ==================================================================
REM  LSM_DB - Genera metadatos.json (METADATOS de todas las señas)
REM  Corre generar_metadatos.sql con psql y guarda el resultado junto
REM  a este archivo. Solo lee la base: no la modifica.
REM  Ajusta estas 3 variables si tu instalación es distinta:
REM ==================================================================
set "PSQL=C:\Program Files\PostgreSQL\18\bin\psql.exe"
set "BD=lsm_db"
set "USUARIO=postgres"

set "PGCLIENTENCODING=UTF8"
set "CARPETA=%~dp0"

echo Generando metadatos.json desde la base %BD% ...
"%PSQL%" -U %USUARIO% -d %BD% -v ON_ERROR_STOP=1 -qAt -f "%CARPETA%generar_metadatos.sql" -o "%CARPETA%metadatos.json"
if errorlevel 1 (
  echo.
  echo ERROR: no se pudo generar metadatos.json.
  echo Revisa que el servicio de PostgreSQL este iniciado y que la base y el usuario sean correctos.
  pause
  exit /b 1
)
echo.
echo Listo: %CARPETA%metadatos.json
pause
