
CREATE FUNCTION logging.GetCorrelationId()
RETURNS nvarchar(36)
AS
BEGIN
  DECLARE @CorrelationId nvarchar(36);
  
  SELECT @CorrelationId = CONVERT(nvarchar(36), logging.GetSessionParameter(N'CorrelationId'));

  RETURN(@CorrelationId);

END
GO

GRANT EXEC ON logging.GetCorrelationId TO PUBLIC;
GO
