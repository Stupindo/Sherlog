CREATE   PROCEDURE logging.GetLogsDataJson  
 @json nvarchar(max) OUTPUT,  
 @PropertyName1 nvarchar(128) = NULL, @PropertyValue1 nvarchar(max) = NULL,  
 @PropertyName2 nvarchar(128) = NULL, @PropertyValue2 nvarchar(max) = NULL,  
 @PropertyName3 nvarchar(128) = NULL, @PropertyValue3 nvarchar(max) = NULL,  
 @PropertyName4 nvarchar(128) = NULL, @PropertyValue4 nvarchar(max) = NULL,  
 @PropertyName5 nvarchar(128) = NULL, @PropertyValue5 nvarchar(max) = NULL,  
 @PropertyName6 nvarchar(128) = NULL, @PropertyValue6 nvarchar(max) = NULL,  
 @PropertyName7 nvarchar(128) = NULL, @PropertyValue7 nvarchar(max) = NULL,  
 @PropertyName8 nvarchar(128) = NULL, @PropertyValue8 nvarchar(max) = NULL,  
 @PropertyName9 nvarchar(128) = NULL, @PropertyValue9 nvarchar(max) = NULL,  
 @PropertyName10 nvarchar(128) = NULL, @PropertyValue10 nvarchar(max) = NULL  
AS  
/*  
 simplified version of GetLogsDataJsonByList procedure;  
*/  
BEGIN  
 SET NOCOUNT ON  
  
  DECLARE @logsDataForJson logging.LogsDataJsonTable;  
  
  INSERT INTO @logsDataForJson(PropertyName, PropertyValue)  
  SELECT PropertyName, PropertyValue  
  FROM (  
        VALUES(@PropertyName1, @PropertyValue1),  
              (@PropertyName2, @PropertyValue2),  
              (@PropertyName3, @PropertyValue3),  
              (@PropertyName4, @PropertyValue4),  
              (@PropertyName5, @PropertyValue5),  
              (@PropertyName6, @PropertyValue6),  
              (@PropertyName7, @PropertyValue7),  
              (@PropertyName8, @PropertyValue8),  
              (@PropertyName9, @PropertyValue9),  
              (@PropertyName10, @PropertyValue10)  
       ) ld(PropertyName, PropertyValue)  
   WHERE PropertyName IS NOT NULL;  
  
 execute logging.GetLogsDataJsonByList @json = @json OUTPUT,  
                                       @logsDataForJson = @logsDataForJson;  
  
 RETURN(0)  
END 

GO

GRANT EXEC ON logging.GetLogsDataJson TO PUBLIC;
GO
