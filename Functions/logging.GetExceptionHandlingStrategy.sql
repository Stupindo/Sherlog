
CREATE FUNCTION logging.GetExceptionHandlingStrategy(@ExecutionId bigint = 0)
RETURNS nvarchar(256)
AS
BEGIN
  DECLARE @HandlingStrategyValue nvarchar(256);
  DECLARE @settingName nvarchar(256) = N'logging.exception.handlingstrategy';
  DECLARE @dt datetimeoffset = sysdatetimeoffset();

  IF @ExecutionId > 0
   BEGIN
    DECLARE @LoggerName nvarchar(256) = (select top(1) Name from logging.Logger where Id = @ExecutionId);

    SET @settingName = @settingName + case when isnull(@LoggerName,N'') = N'' THEN N'' ELSE N'.' END + isnull(@LoggerName,N'');
   END

   SELECT @HandlingStrategyValue = s.Value
   FROM logging.Settings s
   WHERE s.Name = @settingName
   AND isnull(s.ExpirationDate,'99991231') >= @dt;

  -- if no level found that is specific to the logger, return the default(not tagged) level
  IF @HandlingStrategyValue IS NULL AND @ExecutionId > 0
   SET @HandlingStrategyValue = logging.GetExceptionHandlingStrategy(DEFAULT);

  RETURN(@HandlingStrategyValue);

END
GO

GRANT EXEC ON logging.GetExceptionHandlingStrategy TO PUBLIC;
GO
