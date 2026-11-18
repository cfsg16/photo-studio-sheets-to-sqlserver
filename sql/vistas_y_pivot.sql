/*
  Proyecto: Consolidación Operativa - Estudio Fotográfico (Sheets -> SQL Server)
  Archivo:  04_vistas_y_pivot.sql
  Autor:    Christian Santos
  Objetivo: Vistas analíticas de flujo de caja, función de margen y consulta PIVOT.
*/

USE PhotoStudioDB;
GO

CREATE OR ALTER VIEW vw_ResumenFlujoCajaDiario AS
WITH IngresosDia AS (
    SELECT Fecha, SUM(MontoCobrado) AS TotalIngresos, COUNT(VentaID) AS CantVentas
    FROM Ventas
    GROUP BY Fecha
),
GastosDia AS (
    SELECT Fecha, SUM(MontoGasto) AS TotalEgresos, COUNT(GastoID) AS CantGastos
    FROM Gastos
    GROUP BY Fecha
)
SELECT 
    COALESCE(i.Fecha, g.Fecha) AS FechaOperacion,
    ISNULL(i.TotalIngresos, 0.00) AS TotalIngresos,
    ISNULL(g.TotalEgresos, 0.00) AS TotalEgresos,
    (ISNULL(i.TotalIngresos, 0.00) - ISNULL(g.TotalEgresos, 0.00)) AS UtilidadNetaDia,
    ISNULL(i.CantVentas, 0) AS NumeroVentas,
    ISNULL(g.CantGastos, 0) AS NumeroGastos
FROM IngresosDia i
FULL OUTER JOIN GastosDia g ON i.Fecha = g.Fecha;
GO

CREATE OR ALTER VIEW vw_DetalleVentas3FN AS
SELECT 
    v.VentaID,
    v.Fecha,
    ISNULL(v.NumeroSobre, 'Sin Sobre') AS NumeroSobre,
    c.NombreCliente,
    cat.NombreCategoria AS CategoriaServicio,
    s.NombreServicio,
    v.MontoCobrado
FROM Ventas v
INNER JOIN Clientes c ON v.ClienteID = c.ClienteID
INNER JOIN Servicios s ON v.ServicioID = s.ServicioID
INNER JOIN CategoriasServicio cat ON s.CategoriaServicioID = cat.CategoriaServicioID;
GO

CREATE OR ALTER FUNCTION fn_CalcularMargenOperativo (
    @FechaInicio DATE,
    @FechaFin DATE
)
RETURNS DECIMAL(5,2)
AS
BEGIN
    DECLARE @Ingresos DECIMAL(12,2);
    DECLARE @Egresos DECIMAL(12,2);
    DECLARE @Margen DECIMAL(5,2);

    SELECT @Ingresos = ISNULL(SUM(MontoCobrado), 0)
    FROM Ventas
    WHERE Fecha BETWEEN @FechaInicio AND @FechaFin;

    SELECT @Egresos = ISNULL(SUM(MontoGasto), 0)
    FROM Gastos
    WHERE Fecha BETWEEN @FechaInicio AND @FechaFin;

    IF @Ingresos = 0
        SET @Margen = 0.00;
    ELSE
        SET @Margen = ROUND(((@Ingresos - @Egresos) / @Ingresos) * 100.0, 2);

    RETURN @Margen;
END;
GO

-- Comparativa horizontal de ingresos por categoría y fecha usando PIVOT
SELECT 
    CategoriaServicio,
    ISNULL([2026-03-02], 0.00) AS [Ingresos_02_Mar],
    ISNULL([2026-03-03], 0.00) AS [Ingresos_03_Mar],
    (ISNULL([2026-03-02], 0.00) + ISNULL([2026-03-03], 0.00)) AS TotalCategoria
FROM (
    SELECT 
        cat.NombreCategoria AS CategoriaServicio,
        v.Fecha,
        v.MontoCobrado
    FROM Ventas v
    INNER JOIN Servicios s ON v.ServicioID = s.ServicioID
    INNER JOIN CategoriasServicio cat ON s.CategoriaServicioID = cat.CategoriaServicioID
) AS FuenteDatos
PIVOT (
    SUM(MontoCobrado)
    FOR Fecha IN ([2026-03-02], [2026-03-03])
) AS TablaPivote
ORDER BY TotalCategoria DESC;
GO