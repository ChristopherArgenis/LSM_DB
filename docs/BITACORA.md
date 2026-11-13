# Bitácora del proyecto

Registro de discusiones y decisiones abiertas sobre el diseño de LSM_DB.

## 2026-11-13 · Revisión de la presentación «Avances» (9 al 13 de noviembre)

### Cómo empezó

La discusión empezó con la numeración de las glosas homónimas, por ejemplo **ADORAR-1** (B-P 15) y **ADORAR-2** (A-21).

### Observaciones

1. **La numeración -1, -2 parece jerárquica.** Da a entender un orden o una prioridad entre las señas, y no la hay.
2. **La diferencia entre ADORAR-1 y ADORAR-2 no basta para justificar el número.** Las dos tienen la misma definición en el DLSM; solo cambia la nota cultural: una la usa la comunidad sorda de los Testigos de Jehová y la otra la comunidad sorda cristiana y mormona.
3. **Glosas de varias palabras.** ¿«MUCHAS GRACIAS» sería una sola glosa (MUCHAS-GRACIAS) o dos glosas independientes (MUCHAS + GRACIAS)? ¿Qué es lo que distingue un caso del otro? *Ejemplo ilustrativo: el DLSM CDMX 2017 no trae esa entrada.*
4. **Pregunta de fondo: ¿se puede representar la seña como unidad dentro de un esquema de base de datos?** Aunque se tenga la seña, ¿cómo se codifica? Hoy la tabla SENA es un identificador, y la forma de la seña vive en sus descripciones: el texto de `datos_fonologicos`, los METADATOS y los videos.

### Acuerdo

Hacer una **mesa redonda** para revisar otra vez el diseño de la base. Se busca decidir si esta es la manera en que se va a usar y dar razones y justificaciones de esa decisión.

- **Fecha tentativa:** martes 17 o jueves 19 de noviembre de 2026.

### Pendiente para la mesa redonda

- Argumentar cómo se representa la seña en el esquema y por qué.
- Proponer alternativas a la numeración -1, -2 de las glosas homónimas.
- Definir el criterio para glosas de varias palabras: una glosa o varias.
