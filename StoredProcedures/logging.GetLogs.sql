
CREATE PROCEDURE logging.GetLogs
 @ExecutionId bigint = NULL,
 @loggerName nvarchar(256) = NULL,
 @correlationId nvarchar(36) = NULL,
 @startDate datetimeoffset = NULL,
 @endDate datetimeoffset = NULL
AS
BEGIN
 SET NOCOUNT ON

 DECLARE @vStartDate datetimeoffset = isnull(@startDate, cast('19000101' as datetimeoffset));
 DECLARE @vEndDate datetimeoffset = isnull(@endDate, cast('99991231' as datetimeoffset));

 DECLARE @vLoggerName nvarchar(256);
 DECLARE @vCorrelationId nvarchar(36);
 DECLARE @vApplicationName nvarchar(128);

 IF @ExecutionId IS NOT NULL
  BEGIN
   SELECT @vLoggerName = l.Name,
          @vCorrelationId = l.CorrelationId,
          @vApplicationName = a.Name
   FROM logging.Logger l
   JOIN logging.Application a ON l.ApplicationId = a.Id
   WHERE l.Id = @ExecutionId;

   select ExecutionId = @ExecutionId,
          ApplicationName = @vApplicationName,
          LoggerName = @vLoggerName,
          CorrelationId = @vCorrelationId,
          LogId = l.Id,
          LogCreatedDate = l.CreatedDate,
          LogLevel = lv.Name,
          LogMessage = l.Message
   from logging.Logs l
   join logging.Level lv ON l.LevelId = lv.Id
   where l.ExecutionId = @ExecutionId
   and l.CreatedDate between @vStartDate and @vEndDate
   order by l.Id;
  END
 ELSE IF @loggerName IS NOT NULL
  BEGIN
   select ExecutionId = l.ExecutionId,
          ApplicationName = a.Name,
          LoggerName = lg.Name,
          CorrelationId = lg.CorrelationId,
          LogId = l.Id,
          LogCreatedDate = l.CreatedDate,
          LogLevel = lv.Name,
          LogMessage = l.Message
   from logging.Logs l
   join logging.Logger lg ON l.ExecutionId = lg.Id
   join logging.Level lv ON l.LevelId = lv.Id
   join logging.Application a ON lg.ApplicationId = a.Id
   where lg.Name = @loggerName
   and l.CreatedDate between @vStartDate and @vEndDate
   order by l.Id;
  END
 ELSE IF @correlationId IS NOT NULL
  BEGIN
   DECLARE @vExecutionId bigint = (select top(1) l.Id from logging.Logger l where l.CorrelationId = @correlationId);
   execute logging.GetLogs @ExecutionId = @vExecutionId,
                           @startDate = @vStartDate,
                           @endDate = @vEndDate;
  END
 ELSE
  BEGIN
   select ExecutionId = l.ExecutionId,
          ApplicationName = a.Name,
          LoggerName = lg.Name,
          CorrelationId = lg.CorrelationId,
          LogId = l.Id,
          LogCreatedDate = l.CreatedDate,
          LogLevel = lv.Name,
          LogMessage = l.Message 
   from logging.Logs l
   join logging.Logger lg ON l.ExecutionId = lg.Id
   join logging.Level lv ON l.LevelId = lv.Id
   join logging.Application a ON lg.ApplicationId = a.Id
   where l.CreatedDate between @vStartDate and @vEndDate
   order by l.Id;
  END

 RETURN(0)
END

GO

GRANT EXEC ON logging.GetLogs TO PUBLIC;
GO
