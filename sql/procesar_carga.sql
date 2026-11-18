/*
  Proyecto: Consolidación Operativa - Estudio Fotográfico (Sheets -> SQL Server)
  Archivo:  03_sp_procesar_carga.sql
  Autor:    Christian Santos
  Objetivo: Limpieza, validación de calidad y carga transaccional hacia tablas 3FN.
*/

USE PhotoStudioDB;
GO

CREATE OR ALTER PROCEDURE sp_ProcesarCargaOperativa
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Validación de integridad de formatos antes de transformar
        IF EXISTS (
            SELECT 1 FROM Staging_Ingresos
            WHERE TRY_CAST(REPLACE(REPLACE(Precio, '.', ''), ',', '.') AS DECIMAL(12,2)) IS NULL
               OR TRY_CONVERT(DATE, Fecha, 103) IS NULL
        )
        BEGIN;
            THROW 50001, 'Error de calidad en Staging_Ingresos: fechas o precios inválidos.', 1;
        END

        IF EXISTS (
            SELECT 1 FROM Staging_Gastos
            WHERE TRY_CAST(REPLACE(REPLACE(Monto, '.', ''), ',', '.') AS DECIMAL(12,2)) IS NULL
               OR TRY_CONVERT(DATE, Fecha, 103) IS NULL
        )
        BEGIN;
            THROW 50002, 'Error de calidad en Staging_Gastos: fechas o montos inválidos.', 1;
        END

        -- Carga de categorías de servicio sin duplicados
        MERGE CategoriasServicio AS Target
        USING (
            SELECT DISTINCT
                CASE 
                    WHEN UPPER(DetalleServicio) LIKE '%VISA%' THEN 'Trámites y Documentos'
                    WHEN UPPER(DetalleServicio) LIKE '%MARCO%' OR UPPER(DetalleServicio) LIKE '%ALBUM%' THEN 'Accesorios y Marcos'
                    WHEN UPPER(DetalleServicio) LIKE '%ESTUDIO%' THEN 'Fotografía de Estudio'
                    ELSE 'Impresión Fotográfica'
                END AS NombreCategoria
            FROM Staging_Ingresos
            WHERE DetalleServicio IS NOT NULL
        ) AS Source
        ON Target.NombreCategoria = Source.NombreCategoria
        WHEN NOT MATCHED THEN
            INSERT (NombreCategoria) VALUES (Source.NombreCategoria);

        -- Carga de catálogo de servicios vinculado a su categoría (3FN)
        MERGE Servicios AS Target
        USING (
            SELECT DISTINCT
                LTRIM(RTRIM(s.DetalleServicio)) AS NombreServicio,
                cat.CategoriaServicioID
            FROM Staging_Ingresos s
            INNER JOIN CategoriasServicio cat ON cat.NombreCategoria = (
                CASE 
                    WHEN UPPER(s.DetalleServicio) LIKE '%VISA%' THEN 'Trámites y Documentos'
                    WHEN UPPER(s.DetalleServicio) LIKE '%MARCO%' OR UPPER(s.DetalleServicio) LIKE '%ALBUM%' THEN 'Accesorios y Marcos'
                    WHEN UPPER(s.DetalleServicio) LIKE '%ESTUDIO%' THEN 'Fotografía de Estudio'
                    ELSE 'Impresión Fotográfica'
                END
            )
            WHERE s.DetalleServicio IS NOT NULL
        ) AS Source
        ON Target.NombreServicio = Source.NombreServicio
        WHEN NOT MATCHED THEN
            INSERT (NombreServicio, CategoriaServicioID)
            VALUES (Source.NombreServicio, Source.CategoriaServicioID);

        -- Normalización de clientes eliminando espacios de captura manual
        MERGE Clientes AS Target
        USING (
            SELECT DISTINCT LTRIM(RTRIM(NombreCliente)) AS NombreCliente
            FROM Staging_Ingresos
            WHERE NombreCliente IS NOT NULL AND LTRIM(RTRIM(NombreCliente)) <> ''
        ) AS Source
        ON Target.NombreCliente = Source.NombreCliente
        WHEN NOT MATCHED THEN
            INSERT (NombreCliente) VALUES (Source.NombreCliente);

        -- Clasificación contable de categorías de gasto
        MERGE CategoriasGasto AS Target
        USING (
            SELECT DISTINCT
                CASE 
                    WHEN UPPER(ConceptoGasto) LIKE '%ALMUERZO%' OR UPPER(ConceptoGasto) LIKE '%GUAYABAS%'
                         OR UPPER(ConceptoGasto) LIKE '%HUEVOS%' OR UPPER(ConceptoGasto) LIKE '%CANELA%'
                         OR UPPER(ConceptoGasto) LIKE '%AGUA%' THEN 'Alimentación y Refrigerio'
                    WHEN UPPER(ConceptoGasto) LIKE '%CUADROS%' OR UPPER(ConceptoGasto) LIKE '%B/QUILLA%'
                         OR UPPER(ConceptoGasto) LIKE '%PAPEL%' THEN 'Insumos y Producción'
                    WHEN UPPER(ConceptoGasto) LIKE '%LUIS%' OR UPPER(ConceptoGasto) LIKE '%MARIA%' THEN 'Viáticos y Personal'
                    ELSE 'Caja Menor / Varios'
                END AS NombreCategoria
            FROM Staging_Gastos
            WHERE ConceptoGasto IS NOT NULL
        ) AS Source
        ON Target.NombreCategoria = Source.NombreCategoria
        WHEN NOT MATCHED THEN
            INSERT (NombreCategoria) VALUES (Source.NombreCategoria);

        -- Inserción transaccional de ventas
        INSERT INTO Ventas (Fecha, NumeroSobre, ClienteID, ServicioID, MontoCobrado)
        SELECT 
            TRY_CONVERT(DATE, s.Fecha, 103),
            NULLIF(LTRIM(RTRIM(s.NumeroSobre)), ''),
            c.ClienteID,
            srv.ServicioID,
            TRY_CAST(REPLACE(REPLACE(s.Precio, '.', ''), ',', '.') AS DECIMAL(12,2))
        FROM Staging_Ingresos s
        INNER JOIN Clientes c ON LTRIM(RTRIM(s.NombreCliente)) = c.NombreCliente
        INNER JOIN Servicios srv ON LTRIM(RTRIM(s.DetalleServicio)) = srv.NombreServicio;

        -- Inserción transaccional de gastos operativos
        INSERT INTO Gastos (Fecha, CategoriaGastoID, DescripcionConcepto, MontoGasto)
        SELECT 
            TRY_CONVERT(DATE, g.Fecha, 103),
            cat.CategoriaGastoID,
            LTRIM(RTRIM(g.ConceptoGasto)),
            TRY_CAST(REPLACE(REPLACE(g.Monto, '.', ''), ',', '.') AS DECIMAL(12,2))
        FROM Staging_Gastos g
        INNER JOIN CategoriasGasto cat ON cat.NombreCategoria = (
            CASE 
                WHEN UPPER(g.ConceptoGasto) LIKE '%ALMUERZO%' OR UPPER(g.ConceptoGasto) LIKE '%GUAYABAS%'
                     OR UPPER(g.ConceptoGasto) LIKE '%HUEVOS%' OR UPPER(g.ConceptoGasto) LIKE '%CANELA%'
                     OR UPPER(g.ConceptoGasto) LIKE '%AGUA%' THEN 'Alimentación y Refrigerio'
                WHEN UPPER(g.ConceptoGasto) LIKE '%CUADROS%' OR UPPER(g.ConceptoGasto) LIKE '%B/QUILLA%'
                     OR UPPER(g.ConceptoGasto) LIKE '%PAPEL%' THEN 'Insumos y Producción'
                WHEN UPPER(g.ConceptoGasto) LIKE '%LUIS%' OR UPPER(g.ConceptoGasto) LIKE '%MARIA%' THEN 'Viáticos y Personal'
                ELSE 'Caja Menor / Varios'
            END
        );

        TRUNCATE TABLE Staging_Ingresos;
        TRUNCATE TABLE Staging_Gastos;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMsg NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMsg, 16, 1);
    END CATCH
END;
GO