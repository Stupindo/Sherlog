
CREATE PROCEDURE logging.SetExceptionHandlingStrategy
 @StrategyName nvarchar(256), -- 'Suppress', 'ThrowAsWarning', 'ThrowAsIs';
 @LoggerName nvarchar(256) = NULL, -- defines strategy for a particular loggers(subset)
 @ExpirationDate datetimeoffset = NULL -- time when the value is expired
AS
BEGIN
 SET NOCOUNT ON
 --TODO::eliminate code duplication, see other Set* procedures
 DECLARE @settingName nvarchar(256) = N'logging.exception.handlingstrategy' + case when isnull(@LoggerName,N'') = N'' THEN N'' ELSE N'.' END + isnull(@LoggerName,N'');

 IF @StrategyName NOT IN (N'Suppress', N'ThrowAsWarning', N'ThrowAsIs')
  BEGIN
   RAISERROR(N'logging.SetExceptionHandlingStrategy : Unknown Strategy name - %s', 16, 1, @StrategyName);
   RETURN(1);
  END

 MERGE logging.Settings s
 USING (
        SELECT settingName = @settingName,
               settingValue = @StrategyName,
               expirationDate = @ExpirationDate
       ) v ON s.Name = v.settingName
 WHEN MATCHED THEN
      UPDATE SET s.Value = v.settingValue,
                 s.ExpirationDate = v.expirationDate,
                 s.Modifieddate = getdate()
 WHEN NOT MATCHED BY TARGET THEN
      INSERT (name, Value, ExpirationDate)
      VALUES (v.settingName, v.settingValue, v.expirationDate);
 
 RETURN(0)
END
 
GO

GRANT EXEC ON logging.SetExceptionHandlingStrategy TO PUBLIC;
GO
