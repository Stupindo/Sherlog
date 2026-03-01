
CREATE PROCEDURE logging.PurgeLogs
 @loggerName nvarchar(256) = NULL,
 @beforeDate datetimeoffset = NULL,
 @doTruncate bit = 0,
 @rowsDeleted int = NULL OUTPUT
AS
BEGIN
 SET NOCOUNT ON

   SET @rowsDeleted = 0;

   IF @doTruncate = 1 AND
      (@loggerName IS NOT NULL OR @beforeDate IS NOT NULL)
    BEGIN
     SET @rowsDeleted = 0;
     RAISERROR(N'Parameter @doTruncate value 1 is only valid when other parameters are empty!', 16, 1);
     RETURN(1);
    END

   IF @doTruncate = 0
    BEGIN
     -- TODO::introduce batching
     delete ld
     from logging.Logs l
     join logging.Logger lg ON l.ExecutionId = lg.Id
     join logging.LogsData ld ON l.Id = ld.LogId
     where (lg.Name = @loggerName or @loggerName IS NULL)
     and l.CreatedDate < @beforeDate;

     delete pl
     from logging.Logs l
     join logging.Logger lg ON l.ExecutionId = lg.Id
     join logging.PerformanceLogs pl ON l.Id = pl.LogId
     where (lg.Name = @loggerName or @loggerName IS NULL)
     and l.CreatedDate < @beforeDate;

     delete l
     from logging.Logs l
     join logging.Logger lg ON l.ExecutionId = lg.Id
     where (lg.Name = @loggerName or @loggerName IS NULL)
     and l.CreatedDate < @beforeDate;

     SET @rowsDeleted = @@ROWCOUNT;

     RAISERROR(N'Purged %d records from Logs table.',1,1,@rowsDeleted)
    END
   ELSE
    BEGIN
     TRUNCATE TABLE logging.Logs;

     TRUNCATE TABLE logging.PerformanceLogs;

     RAISERROR(N'Logs table is truncated!',1,1,@rowsDeleted)
    END

   
 RETURN(0)
END

GO

GRANT EXEC ON logging.PurgeLogs TO PUBLIC;
GO
