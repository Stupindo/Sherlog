
CREATE FUNCTION logging.GetPerformanceLevelValue(@ExecutionId bigint = 0)
RETURNS tinyint
AS
BEGIN
  DECLARE @LevelValue tinyint;
  DECLARE @settingName nvarchar(256) = N'logging.performance';
  DECLARE @dt datetimeoffset = sysdatetimeoffset();

  IF @ExecutionId > 0
   BEGIN
    DECLARE @LoggerName nvarchar(256) = (select top(1) Name from logging.Logger where Id = @ExecutionId);

    SET @settingName = @settingName + case when isnull(@LoggerName,N'') = N'' THEN N'' ELSE N'.' END + isnull(@LoggerName,N'');
   END

   SELECT @LevelValue = l.Value
   FROM logging.Settings s
   JOIN logging.Level l ON s.Value = l.Name
   WHERE s.Name = @settingName
   AND isnull(s.ExpirationDate,'99991231') >= @dt;

  -- if no level found that is specific to the logger, return the default(not tagged) level
  IF @LevelValue IS NULL AND @ExecutionId > 0
   SET @LevelValue = logging.GetPerformanceLevelValue(DEFAULT);

  RETURN(@LevelValue);

END
GO

GRANT EXEC ON logging.GetPerformanceLevelValue TO PUBLIC;
GO
