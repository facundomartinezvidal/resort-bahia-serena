CREATE OR ALTER FUNCTION dbo.fn_calcular_margen_servicio(@id_servicio_adicional INT)
RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @margen DECIMAL(10,2);
    
    SELECT @margen = precio - costo
    FROM dbo.servicio_adicional
    WHERE id_servicio_adicional = @id_servicio_adicional
    AND fecha_eliminacion IS NULL;
    
    RETURN ISNULL(@margen, 0);
END;

