 
CREATE PROCEDURE logging.LogFatal
 @ExecutionId bigint, 
 @Message nvarchar(2000),
 @DataValue nvarchar(max) = NULL
AS
BEGIN
 SET NOCOUNT ON

 execute logging.LogMessage @ExecutionId = @ExecutionId, @LevelName = N'Fatal', @Message = @Message, @DataValue = @DataValue;

 RETURN(0)
END
GO

GRANT EXEC ON logging.LogFatal TO PUBLIC;
GO
