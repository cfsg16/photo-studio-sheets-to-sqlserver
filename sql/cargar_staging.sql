/*
  Proyecto: Consolidación Operativa - Estudio Fotográfico (Sheets -> SQL Server)
  Archivo:  02_cargar_staging.sql
  Autor:    Christian Santos
  Objetivo: Carga de registros de prueba desde exportación operativa en Staging.
*/

USE PhotoStudioDB;
GO

TRUNCATE TABLE Staging_Ingresos;
TRUNCATE TABLE Staging_Gastos;
GO

INSERT INTO Staging_Ingresos (Fecha, NombreCliente, DetalleServicio, Precio, NumeroSobre) VALUES
('02/03/2026', '  Vidal ', '15x20', '5.000', '3006'),
('02/03/2026', 'Sonia Muñoz', '3x4', '13.000', '4018'),
('02/03/2026', 'Cristian Morales', '20x25', '18.000', '4020'),
('02/03/2026', 'Elieter Loreto', 'Marco 20x30', '150.000', '4019'),
('02/03/2026', 'Valentina', '3x4', '18.000', '4017'),
('02/03/2026', 'Orozco', '15x20', '5.000', '3004'),
('02/03/2026', 'Yorina', '5x7', '5.000', '4016'),
('02/03/2026', 'Lucia Bettin', '10x15', '10.000', '3003'),
('02/03/2026', 'Viviana Palencia', '10x15', '25.000', '3002'),
('02/03/2026', 'Jhon Henry', 'Estudio 20x30', '100.000', '4018'),
('02/03/2026', 'Daniel', '3x4', '18.000', '4013'),
('02/03/2026', 'Lidia Sierra', '20x30', '50.000', '4012'),
('02/03/2026', 'Carolina', '3x4', '13.000', '4014'),
('02/03/2026', 'Orozco', '10x15', '5.000', '3001'),
('02/03/2026', 'Yarelis', 'VISA', '20.000', '4010'),
('02/03/2026', 'Cliente Mostrador', 'Album grande', '90.000', NULL),
('02/03/2026', 'Liliana', 'VISA', '15.000', '4011'),
('02/03/2026', 'Orozco', '15x20', '7.500', NULL),
('03/03/2026', 'María Fernández', 'Estudio 20x30', '110.000', '4021'),
('03/03/2026', 'Carlos Gómez', 'VISA', '20.000', '4022'),
('03/03/2026', 'Sonia Muñoz', 'Marco 20x30', '150.000', '4023'),
('03/03/2026', 'Andrés López', '3x4', '13.000', '4024'),
('03/03/2026', 'Valentina', '10x15', '15.000', '4025');
GO

INSERT INTO Staging_Gastos (Fecha, ConceptoGasto, Monto) VALUES
('02/03/2026', 'Consignación para cuadros', '26.000'),
('02/03/2026', 'Guayabas', '5.000'),
('02/03/2026', 'Canasta de Huevos + Electrolit', '29.000'),
('02/03/2026', 'Canela', '5.000'),
('02/03/2026', 'Almuerzo y pasajes Luis', '14.000'),
('02/03/2026', 'Saldo pendiente Luis', '20.000'),
('02/03/2026', 'Almuerzo y pasajes Maria', '14.000'),
('02/03/2026', 'Fotos B/quilla', '10.000'),
('02/03/2026', 'Agua', '3.000'),
('02/03/2026', 'Recibo caja menor', '6.400'),
('03/03/2026', 'Compra papel fotográfico 10x15', '45.000'),
('03/03/2026', 'Almuerzo y pasajes Luis', '14.000'),
('03/03/2026', 'Recibo caja menor', '8.500');
GO