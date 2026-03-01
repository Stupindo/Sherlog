
CREATE PROCEDURE logging.SetExecutionId
 @ExecutionId bigint
AS
BEGIN
 SET NOCOUNT ON

 execute logging.SetSessionParameter @Key = N'ExecutionId', @value = @ExecutionId;

 RETURN(0)
END
 
GO

GRANT EXEC ON logging.SetExecutionId TO PUBLIC;
GO
