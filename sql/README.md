# Consolidación Operativa y Financiera: Google Sheets a SQL Server

Módulo de migración, normalización y reportería en **Microsoft SQL Server (T-SQL)** diseñado para consolidar los registros operativos diarios capturados en hojas de cálculo (Google Sheets / Apps Script), provenientes originalmente de libros contables físicos de un estudio fotográfico.

## Contexto y Problema Resuelto
La captura manual y las hojas de cálculo planas presentaban tres limitaciones operativas:
1. Riesgo de errores de suma y pérdida de trazabilidad en cierres de caja diarios.
2. Nombres de clientes y servicios sin estandarizar (espacios extra, texto libre sin categorías).
3. Mezcla de gastos operativos (insumos de taller, viáticos y caja menor) sin clasificación contable.

## Arquitectura de la Solución
El flujo está dividido en tres capas secuenciales:

1. **Capa Staging (`Staging_Ingresos`, `Staging_Gastos`):** Recibe las exportaciones planas de Google Sheets en formato texto (`VARCHAR`) para evitar fallos de carga por formatos heterogéneos.
2. **Proceso de Transformación (`sp_ProcesarCargaOperativa`):**
   - Valida fechas y valores monetarios mediante `TRY_CONVERT` y `TRY_CAST` antes de procesar.
   - Normaliza catálogos (`Clientes`, `CategoriasServicio`, `Servicios`, `CategoriasGasto`) utilizando `MERGE` para prevenir duplicados.
   - Ejecuta la carga dentro de bloques `BEGIN TRANSACTION` y `TRY...CATCH` para garantizar atomicidad e integridad referencial en Tercera Forma Normal (3FN).
3. **Capa de Reportería (`vw_ResumenFlujoCajaDiario`, `vw_DetalleVentas3FN`, `fn_CalcularMargenOperativo`):**
   - Consolida ingresos, egresos y utilidad neta diaria mediante CTEs y `FULL OUTER JOIN`.
   - Incluye consultas con `PIVOT` para comparar ingresos por categoría entre distintas jornadas.

## Estructura del Repositorio
- `sql/01_crear_tablas_3fn.sql`: Definición de base de datos, tablas Staging, modelo en 3FN e índices.
- `sql/02_cargar_staging.sql`: Script de ingesta de muestra con registros reales de operación.
- `sql/03_sp_procesar_carga.sql`: Procedimiento almacenado de limpieza, validación y carga.
- `sql/04_vistas_y_pivot.sql`: Vistas consolidadas, función escalar de margen operativo y consulta `PIVOT`.

## Orden de Ejecución
1. Ejecutar `sql/01_crear_tablas_3fn.sql` en SQL Server Management Studio (SSMS).
2. Ejecutar `sql/02_cargar_staging.sql` para poblar la capa temporal.
3. Crear y ejecutar el procedimiento con `sql/03_sp_procesar_carga.sql` (`EXEC sp_ProcesarCargaOperativa;`).
4. Ejecutar `sql/04_vistas_y_pivot.sql` para generar las vistas y consultar los indicadores.