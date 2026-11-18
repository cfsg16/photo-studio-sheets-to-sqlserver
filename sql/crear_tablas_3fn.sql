/*
  Proyecto: Consolidación Operativa - Estudio Fotográfico (Sheets -> SQL Server)
  Archivo:  01_crear_tablas_3fn.sql
  Autor:    Christian Santos
  Objetivo: Creación de base de datos, capa Staging y modelo relacional en 3FN.
*/

IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'PhotoStudioDB')
BEGIN
    CREATE DATABASE PhotoStudioDB;
END
GO

USE PhotoStudioDB;
GO

-- Capa Staging para recepción de exportaciones planas desde Google Sheets
CREATE TABLE Staging_Ingresos (
    StagingIngresoID INT IDENTITY(1,1) PRIMARY KEY,
    Fecha VARCHAR(20),
    NombreCliente VARCHAR(100),
    DetalleServicio VARCHAR(50),
    Precio VARCHAR(50),
    NumeroSobre VARCHAR(20),
    FechaIngesta DATETIME DEFAULT GETDATE()
);
GO

CREATE TABLE Staging_Gastos (
    StagingGastoID INT IDENTITY(1,1) PRIMARY KEY,
    Fecha VARCHAR(20),
    ConceptoGasto VARCHAR(150),
    Monto VARCHAR(50),
    FechaIngesta DATETIME DEFAULT GETDATE()
);
GO

-- Modelo Relacional en Tercera Forma Normal (3FN)
CREATE TABLE Clientes (
    ClienteID INT IDENTITY(1,1) PRIMARY KEY,
    NombreCliente VARCHAR(100) NOT NULL UNIQUE,
    FechaRegistro DATETIME DEFAULT GETDATE()
);
GO

CREATE TABLE CategoriasServicio (
    CategoriaServicioID INT IDENTITY(1,1) PRIMARY KEY,
    NombreCategoria VARCHAR(50) NOT NULL UNIQUE
);
GO

CREATE TABLE Servicios (
    ServicioID INT IDENTITY(1,1) PRIMARY KEY,
    NombreServicio VARCHAR(50) NOT NULL UNIQUE,
    CategoriaServicioID INT NOT NULL FOREIGN KEY REFERENCES CategoriasServicio(CategoriaServicioID)
);
GO

CREATE TABLE CategoriasGasto (
    CategoriaGastoID INT IDENTITY(1,1) PRIMARY KEY,
    NombreCategoria VARCHAR(50) NOT NULL UNIQUE
);
GO

CREATE TABLE Ventas (
    VentaID BIGINT IDENTITY(1,1) PRIMARY KEY,
    Fecha DATE NOT NULL,
    NumeroSobre VARCHAR(20) NULL,
    ClienteID INT NOT NULL FOREIGN KEY REFERENCES Clientes(ClienteID),
    ServicioID INT NOT NULL FOREIGN KEY REFERENCES Servicios(ServicioID),
    MontoCobrado DECIMAL(12,2) NOT NULL CHECK (MontoCobrado >= 0),
    FechaProcesamiento DATETIME DEFAULT GETDATE()
);
GO

CREATE TABLE Gastos (
    GastoID BIGINT IDENTITY(1,1) PRIMARY KEY,
    Fecha DATE NOT NULL,
    CategoriaGastoID INT NOT NULL FOREIGN KEY REFERENCES CategoriasGasto(CategoriaGastoID),
    DescripcionConcepto VARCHAR(150) NOT NULL,
    MontoGasto DECIMAL(12,2) NOT NULL CHECK (MontoGasto >= 0),
    FechaProcesamiento DATETIME DEFAULT GETDATE()
);
GO

CREATE NONCLUSTERED INDEX IX_Ventas_Fecha ON Ventas(Fecha);
CREATE NONCLUSTERED INDEX IX_Gastos_Fecha ON Gastos(Fecha);
GO