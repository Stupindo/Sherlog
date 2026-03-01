 
CREATE PROCEDURE logging.LogDebug
 @ExecutionId bigint, 
 @Message nvarchar(2000),
 @DataValue nvarchar(max) = NULL
AS
BEGIN
 SET NOCOUNT ON

 execute logging.LogMessage @ExecutionId = @ExecutionId, @LevelName = N'Debug', @Message = @Message, @DataValue = @DataValue;

 RETURN(0)
END
GO

GRANT EXEC ON logging.LogDebug TO PUBLIC;
GO
