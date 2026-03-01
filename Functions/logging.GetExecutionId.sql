
CREATE FUNCTION logging.GetExecutionId()
RETURNS bigint
AS
BEGIN
  DECLARE @ExecutionId bigint;
  
  SELECT @ExecutionId = CONVERT(bigint, logging.GetSessionParameter(N'ExecutionId'));

  RETURN(@ExecutionId);

END
GO

GRANT EXEC ON logging.GetExecutionId TO PUBLIC;
GO
