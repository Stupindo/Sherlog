
CREATE FUNCTION logging.GetSessionParameter(@Key nvarchar(128))
RETURNS sql_variant
AS
BEGIN
  DECLARE @result sql_variant;
  
  SELECT @result = SESSION_CONTEXT(@Key);

  RETURN(@result);

END
GO

GRANT EXEC ON logging.GetSessionParameter TO PUBLIC;
GO
