--
-- PostgreSQL database dump
--

-- Dumped from database version 12.16 (Ubuntu 12.16-0ubuntu0.20.04.1)
-- Dumped by pg_dump version 12.16 (Ubuntu 12.16-0ubuntu0.20.04.1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: actualizar_volumen_mensual(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.actualizar_volumen_mensual() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE Cliente
    SET volumen_mensual = volumen_mensual + NEW.unidades
    WHERE id_cliente = NEW.id_cliente;
    RETURN NEW;
END;
$$;


--
-- Name: calcular_descuento(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.calcular_descuento() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;


--
-- Name: calcular_precio_venta(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.calcular_precio_venta() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
   descuento_cliente DECIMAL;
BEGIN
   SELECT precio INTO NEW.precio FROM Producto WHERE id_producto = NEW.id_producto;
   SELECT descuento INTO descuento_cliente FROM Cliente WHERE id_cliente = NEW.id_cliente;
   NEW.precio := NEW.precio * NEW.unidades * (1 - descuento_cliente);
   RETURN NEW;
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: cliente; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cliente (
    id_cliente integer NOT NULL,
    fidelizacion boolean,
    volumen_mensual numeric,
    descuento numeric
);


--
-- Name: disponibilidad; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.disponibilidad (
    id_producto integer NOT NULL,
    id_zona integer NOT NULL,
    id_vivero integer NOT NULL,
    stock integer NOT NULL,
    CONSTRAINT disponibilidad_stock_check CHECK ((stock >= 0))
);


--
-- Name: empleado; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.empleado (
    id_empleado integer NOT NULL,
    id_zona integer NOT NULL,
    id_vivero integer NOT NULL,
    historico_trabajado text
);


--
-- Name: producto; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.producto (
    id_producto integer NOT NULL,
    precio numeric NOT NULL,
    CONSTRAINT producto_precio_check CHECK ((precio >= (0)::numeric))
);


--
-- Name: trabajo; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.trabajo (
    id_empleado integer NOT NULL,
    id_zona integer NOT NULL,
    id_vivero integer NOT NULL,
    fecha_inicio date NOT NULL,
    fecha_fin date,
    CONSTRAINT trabajo_check CHECK ((fecha_inicio <= fecha_fin))
);


--
-- Name: ventas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ventas (
    id_venta integer NOT NULL,
    precio numeric NOT NULL,
    unidades integer NOT NULL,
    id_producto integer NOT NULL,
    id_empleado integer NOT NULL,
    id_cliente integer NOT NULL,
    CONSTRAINT ventas_precio_check CHECK ((precio >= (0)::numeric)),
    CONSTRAINT ventas_unidades_check CHECK ((unidades > 0))
);


--
-- Name: vivero; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.vivero (
    id_vivero integer NOT NULL,
    nombre_vivero character varying(255) NOT NULL
);


--
-- Name: zona; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.zona (
    id_zona integer NOT NULL,
    id_vivero integer NOT NULL,
    nombre_zona character varying(255) NOT NULL,
    latitud numeric NOT NULL,
    longitud numeric NOT NULL,
    historico text
);


--
-- Name: cliente cliente_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cliente
    ADD CONSTRAINT cliente_pkey PRIMARY KEY (id_cliente);


--
-- Name: disponibilidad disponibilidad_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.disponibilidad
    ADD CONSTRAINT disponibilidad_pkey PRIMARY KEY (id_producto, id_zona);


--
-- Name: empleado empleado_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.empleado
    ADD CONSTRAINT empleado_pkey PRIMARY KEY (id_empleado);


--
-- Name: producto producto_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.producto
    ADD CONSTRAINT producto_pkey PRIMARY KEY (id_producto);


--
-- Name: trabajo trabajo_id_empleado_fecha_inicio_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trabajo
    ADD CONSTRAINT trabajo_id_empleado_fecha_inicio_key UNIQUE (id_empleado, fecha_inicio);


--
-- Name: trabajo trabajo_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trabajo
    ADD CONSTRAINT trabajo_pkey PRIMARY KEY (id_empleado, id_zona, fecha_inicio);


--
-- Name: ventas ventas_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ventas
    ADD CONSTRAINT ventas_pkey PRIMARY KEY (id_venta);


--
-- Name: vivero vivero_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vivero
    ADD CONSTRAINT vivero_pkey PRIMARY KEY (id_vivero);


--
-- Name: zona zona_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.zona
    ADD CONSTRAINT zona_pkey PRIMARY KEY (id_zona, id_vivero);


--
-- Name: ventas actualizar_volumen_mensual_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER actualizar_volumen_mensual_trigger AFTER INSERT ON public.ventas FOR EACH ROW EXECUTE FUNCTION public.actualizar_volumen_mensual();


--
-- Name: cliente descuento_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER descuento_trigger BEFORE INSERT OR UPDATE ON public.cliente FOR EACH ROW EXECUTE FUNCTION public.calcular_descuento();


--
-- Name: ventas precio_venta_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER precio_venta_trigger BEFORE INSERT OR UPDATE ON public.ventas FOR EACH ROW EXECUTE FUNCTION public.calcular_precio_venta();


--
-- Name: disponibilidad disponibilidad_id_producto_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.disponibilidad
    ADD CONSTRAINT disponibilidad_id_producto_fkey FOREIGN KEY (id_producto) REFERENCES public.producto(id_producto) ON DELETE CASCADE;


--
-- Name: disponibilidad disponibilidad_id_zona_id_vivero_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.disponibilidad
    ADD CONSTRAINT disponibilidad_id_zona_id_vivero_fkey FOREIGN KEY (id_zona, id_vivero) REFERENCES public.zona(id_zona, id_vivero) ON DELETE CASCADE;


--
-- Name: empleado empleado_id_zona_id_vivero_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.empleado
    ADD CONSTRAINT empleado_id_zona_id_vivero_fkey FOREIGN KEY (id_zona, id_vivero) REFERENCES public.zona(id_zona, id_vivero) ON DELETE CASCADE;


--
-- Name: trabajo trabajo_id_empleado_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trabajo
    ADD CONSTRAINT trabajo_id_empleado_fkey FOREIGN KEY (id_empleado) REFERENCES public.empleado(id_empleado) ON DELETE CASCADE;


--
-- Name: trabajo trabajo_id_zona_id_vivero_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trabajo
    ADD CONSTRAINT trabajo_id_zona_id_vivero_fkey FOREIGN KEY (id_zona, id_vivero) REFERENCES public.zona(id_zona, id_vivero) ON DELETE CASCADE;


--
-- Name: ventas ventas_id_cliente_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ventas
    ADD CONSTRAINT ventas_id_cliente_fkey FOREIGN KEY (id_cliente) REFERENCES public.cliente(id_cliente);


--
-- Name: ventas ventas_id_empleado_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ventas
    ADD CONSTRAINT ventas_id_empleado_fkey FOREIGN KEY (id_empleado) REFERENCES public.empleado(id_empleado) ON DELETE CASCADE;


--
-- Name: ventas ventas_id_producto_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ventas
    ADD CONSTRAINT ventas_id_producto_fkey FOREIGN KEY (id_producto) REFERENCES public.producto(id_producto) ON DELETE CASCADE;


--
-- Name: zona zona_id_vivero_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.zona
    ADD CONSTRAINT zona_id_vivero_fkey FOREIGN KEY (id_vivero) REFERENCES public.vivero(id_vivero) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

