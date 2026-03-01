 
CREATE PROCEDURE logging.LogError
 @ExecutionId bigint, 
 @Message nvarchar(2000),
 @DataValue nvarchar(max) = NULL
AS
BEGIN
 SET NOCOUNT ON

 execute logging.LogMessage @ExecutionId = @ExecutionId, @LevelName = N'Error', @Message = @Message, @DataValue = @DataValue;

 RETURN(0)
END
GO

GRANT EXEC ON logging.LogError TO PUBLIC;
GO
