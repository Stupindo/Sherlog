
CREATE PROCEDURE logging.SetLevel
 @LevelName nvarchar(128),
 @LoggerName nvarchar(256) = NULL, -- defines logging level for particular loggers(subset)
 @ExpirationDate datetimeoffset = NULL -- time when the setting value is expired
AS
BEGIN
 SET NOCOUNT ON

 DECLARE @settingName nvarchar(256) = N'logging.level' + case when isnull(@LoggerName,N'') = N'' THEN N'' ELSE N'.' END + isnull(@LoggerName,N'');

 MERGE logging.Settings s
 USING (
        SELECT settingName = @settingName,
               settingValue = @LevelName,
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

GRANT EXEC ON logging.SetLevel TO PUBLIC;
GO
