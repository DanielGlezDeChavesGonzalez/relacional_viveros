# relacional_viveros

Vivero (id_vivero, nombre_vivero) CP: id_vivero
Zona (id_vivero, id_zona, nombre_zona, latitud, longitud, historico) CP: id_vivero, id_zona
Cliente (id_cliente, fidelizacion, volumen_mensual, descuento(calculado en base al volumen)) CP: id_cliente
Empleado (id_empleado, id_zona, id_vivero, historico_trabajado) CP: id_empleado
Trabajo (id_empleado, id_zona, id_vivero, fecha_inicio, fecha_fin) solo se puede trabajar en una misma zona a la vez. CP: id_empleado, id_zona
Producto (id_producto, precio) CP: id_producto
Ventas (id_venta, precio, unidades, id_producto, id_empleado, id_cliente) CP: id_venta
Disponibilidad (id_producto, id_zona, stock) CP: id_producto, id_zona

sudo -i -u postgres
psql

\c viveros ;
\c postgres ;

DROP DATABASE viveros;
CREATE DATABASE viveros;

CREATE TABLE Vivero (
    id_vivero INT PRIMARY KEY,
    nombre_vivero VARCHAR(255) NOT NULL
);

CREATE TABLE Zona (
    id_zona INT,
    id_vivero INT NOT NULL,
    nombre_zona VARCHAR(255) NOT NULL,
    latitud DECIMAL NOT NULL,
    longitud DECIMAL NOT NULL,
    historico TEXT,
    PRIMARY KEY (id_zona, id_vivero),
    FOREIGN KEY (id_vivero) REFERENCES Vivero(id_vivero) ON DELETE CASCADE
);

CREATE TABLE Cliente (
    id_cliente INT PRIMARY KEY,
    fidelizacion BOOLEAN,
    volumen_mensual DECIMAL,
    descuento DECIMAL
);

CREATE OR REPLACE FUNCTION calcular_descuento()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.fidelizacion THEN
        NEW.descuento := CASE 
            WHEN NEW.volumen_mensual > 100 THEN 0.20 
            WHEN NEW.volumen_mensual > 50 THEN 0.10 
            ELSE 0 
        END;
    ELSE
        NEW.descuento := 0;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER descuento_trigger
BEFORE INSERT OR UPDATE ON Cliente
FOR EACH ROW EXECUTE PROCEDURE calcular_descuento();

CREATE OR REPLACE FUNCTION actualizar_volumen_mensual()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE Cliente
    SET volumen_mensual = volumen_mensual + NEW.unidades
    WHERE id_cliente = NEW.id_cliente;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER actualizar_volumen_mensual_trigger
AFTER INSERT ON Ventas
FOR EACH ROW EXECUTE PROCEDURE actualizar_volumen_mensual();

CREATE TABLE Empleado (
    id_empleado INT PRIMARY KEY,
    id_zona INT NOT NULL,
    id_vivero INT NOT NULL,
    historico_trabajado TEXT,
    FOREIGN KEY (id_zona, id_vivero) REFERENCES Zona(id_zona, id_vivero) ON DELETE CASCADE
);

CREATE TABLE Trabajo (
    id_empleado INT NOT NULL,
    id_zona INT NOT NULL,
    id_vivero INT NOT NULL,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE,
    CHECK (fecha_inicio <= fecha_fin),
    PRIMARY KEY (id_empleado, id_zona, fecha_inicio),
    UNIQUE (id_empleado, fecha_inicio),
    FOREIGN KEY (id_empleado) REFERENCES Empleado(id_empleado) ON DELETE CASCADE,
    FOREIGN KEY (id_zona, id_vivero) REFERENCES Zona(id_zona, id_vivero) ON DELETE CASCADE
);

CREATE TABLE Producto (
    id_producto INT PRIMARY KEY,
    precio DECIMAL NOT NULL CHECK (precio >= 0)
);

CREATE TABLE Ventas (
    id_venta INT PRIMARY KEY,
    precio DECIMAL NOT NULL CHECK (precio >= 0),
    unidades INT NOT NULL CHECK (unidades > 0),
    id_producto INT NOT NULL,
    id_empleado INT NOT NULL,
    id_cliente INT NOT NULL,
    FOREIGN KEY (id_producto) REFERENCES Producto(id_producto) ON DELETE CASCADE,
    FOREIGN KEY (id_empleado) REFERENCES Empleado(id_empleado) ON DELETE CASCADE,
    FOREIGN KEY (id_cliente) REFERENCES Cliente(id_cliente)
);

CREATE OR REPLACE FUNCTION calcular_precio_venta()
RETURNS TRIGGER AS $$
DECLARE
   descuento_cliente DECIMAL;
BEGIN
   SELECT precio INTO NEW.precio FROM Producto WHERE id_producto = NEW.id_producto;
   SELECT descuento INTO descuento_cliente FROM Cliente WHERE id_cliente = NEW.id_cliente;
   NEW.precio := NEW.precio * NEW.unidades * (1 - descuento_cliente);
   RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER precio_venta_trigger
BEFORE INSERT OR UPDATE ON Ventas
FOR EACH ROW EXECUTE PROCEDURE calcular_precio_venta();


CREATE TABLE Disponibilidad (
    id_producto INT NOT NULL,
    id_zona INT NOT NULL,
    id_vivero INT NOT NULL,
    stock INT NOT NULL CHECK (stock >= 0),
    PRIMARY KEY (id_producto, id_zona),
    FOREIGN KEY (id_producto) REFERENCES Producto(id_producto) ON DELETE CASCADE,
    FOREIGN KEY (id_zona, id_vivero) REFERENCES Zona(id_zona, id_vivero) ON DELETE CASCADE
);


SELECT * FROM Vivero;
SELECT * FROM Zona;
SELECT * FROM Cliente;
SELECT * FROM Empleado;
SELECT * FROM Trabajo;
SELECT * FROM Producto;
SELECT * FROM Ventas;
SELECT * FROM Disponibilidad;


DELETE FROM Disponibilidad;
DELETE FROM Ventas;
DELETE FROM Producto;
DELETE FROM Trabajo;
DELETE FROM Empleado;
DELETE FROM Cliente;
DELETE FROM Zona;
DELETE FROM Vivero;


DELETE FROM Zona WHERE id_zona = 2 AND id_vivero = 1;


INSERT INTO Vivero (id_vivero, nombre_vivero)
VALUES
    (1, 'Vivero A'),
    (2, 'Vivero B'),
    (3, 'Vivero C'),
    (4, 'Vivero D'),
    (5, 'Vivero E');


INSERT INTO Zona (id_zona, id_vivero, nombre_zona, latitud, longitud, historico)
VALUES
    (1, 1, 'Zona 1', 40.1234, -74.5678, 'Historico Zona 1'),
    (2, 1, 'Zona 2', 40.2345, -74.6789, 'Historico Zona 2'),
    (3, 2, 'Zona 1', 40.3456, -74.7890, 'Historico Zona 1'),
    (2, 3, 'Zona 1', 40.4567, -74.8901, 'Historico Zona 1'),
    (1, 4, 'Zona 1', 40.5678, -74.9012, 'Historico Zona 1'),
    (3, 3, 'Zona 3', 40.1234, -74.5678, 'Historico Zona 3'),
    (1, 2, 'Zona 1', 40.1234, -74.5678, 'Historico Zona 2'),
    (4, 4, 'Zona 4', 40.1234, -74.5678, 'Historico Zona 4');
    
INSERT INTO Cliente (id_cliente, fidelizacion, volumen_mensual)
VALUES
    (1, true, 0),
    (2, false, 0),
    (3, true, 0),
    (4, false, 0),
    (5, true, 0);


INSERT INTO Empleado (id_empleado, id_zona, id_vivero, historico_trabajado)
VALUES
    (1, 1, 1, 'Historico Empleado 1'),
    (2, 2, 1, 'Historico Empleado 2'),
    (3, 1, 2, 'Historico Empleado 3'),
    (4, 3, 3, 'Historico Empleado 4'),
    (5, 4, 4, 'Historico Empleado 5');


INSERT INTO Trabajo (id_empleado, id_zona, id_vivero, fecha_inicio, fecha_fin)
VALUES
    (1, 1, 1, '2023-10-01', '2023-10-15'),
    (2, 2, 1, '2023-10-02', '2023-10-16'),
    (3, 1, 2, '2023-10-03', '2023-10-17'),
    (4, 3, 3, '2023-10-04', '2023-10-18'),
    (5, 4, 4, '2023-10-05', '2023-10-19');


INSERT INTO Producto (id_producto, precio)
VALUES
    (1, 10.99),
    (2, 5.99),
    (3, 15.99),
    (4, 8.99),
    (5, 12.99);

INSERT INTO Ventas (id_venta, precio, unidades, id_producto, id_empleado, id_cliente)
VALUES
    (1, 0, 10, 1, 1, 1),  
    (2, 0, 5, 2, 2, 2),   
    (3, 0, 3, 3, 3, 3),  
    (4, 0, 8, 4, 4, 4),  
    (5, 0, 12, 5, 5, 5); 


INSERT INTO Disponibilidad (id_producto, id_zona, id_vivero, stock)
VALUES
    (1, 1, 1, 100),
    (2, 2, 1, 50),
    (3, 1, 2, 75),
    (4, 3, 3, 60),
    (5, 4, 4, 90);


pg_dump --schema-only --no-owner -U postgres -d viveros -f viveros.sql


