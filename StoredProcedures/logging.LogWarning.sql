 
CREATE PROCEDURE logging.LogWarning
 @ExecutionId bigint, 
 @Message nvarchar(2000),
 @DataValue nvarchar(max) = NULL
AS
BEGIN
 SET NOCOUNT ON

 execute logging.LogMessage @ExecutionId = @ExecutionId, @levelName = N'Warning', @Message = @Message, @DataValue = @DataValue;

 RETURN(0)
END
GO

GRANT EXEC ON logging.LogWarning TO PUBLIC;
GO
