
CREATE PROCEDURE logging.SetCorrelationId
 @CorrelationId nvarchar(36)
AS
BEGIN
 SET NOCOUNT ON

 execute logging.SetSessionParameter @Key = N'CorrelationId', @value = @CorrelationId;

 RETURN(0)
END
 
GO

GRANT EXEC ON logging.SetCorrelationId TO PUBLIC;
GO
