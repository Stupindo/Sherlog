
CREATE PROCEDURE logging.GetLogsDataJsonByList
 @json nvarchar(max) OUTPUT,
 @logsDataForJson logging.LogsDataJsonTable READONLY
AS
BEGIN
 SET NOCOUNT ON

 DECLARE @proc_name sysname = OBJECT_NAME(@@PROCID);

 BEGIN TRY
  IF NOT EXISTS(SELECT * FROM @logsDataForJson WHERE PropertyName IS NOT NULL AND PropertyValue IS NOT NULL)
   BEGIN
    SET @json = NULL;
    RETURN(0);
   END

  DECLARE @sql nvarchar(max) = N'SELECT ';
  
  SELECT @sql += '[' +  PropertyName + ']='''+replace(isnull(PropertyValue,'NULL'),'''','''''')+ ''','
  FROM @logsDataForJson
  WHERE PropertyName IS NOT NULL;

  SET @sql = LEFT(@sql, LEN(@sql)-1) + ' FOR JSON PATH, WITHOUT_ARRAY_WRAPPER'

  SET @sql = N'SELECT @json = (' + @sql + ')';

  execute sp_executesql @sql, N'@json nvarchar(max) OUTPUT', @json OUTPUT;
 END TRY
 BEGIN CATCH
  SET @json = NULL;

  DECLARE @err_message nvarchar(4000) = error_message();
  DECLARE @res int = 1;
  execute @res = logging.HandleException @object_name = @proc_name, @error_message = @err_message;

  RETURN(@res);
 END CATCH
 RETURN(0)
END

GO

GRANT EXEC ON logging.GetLogsDataJsonByList TO PUBLIC;
GO
