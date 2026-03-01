
CREATE PROCEDURE logging.GetLogsWithPerformance
 @ExecutionId bigint = NULL,
 @LoggerName nvarchar(256) = NULL,
 @correlationId nvarchar(36) = NULL,
 @startDate datetimeoffset = NULL,
 @endDate datetimeoffset = NULL
AS
BEGIN
 SET NOCOUNT ON

 DECLARE @vStartDate datetimeoffset = isnull(@startDate, cast('19000101' as datetimeoffset));
 DECLARE @vEndDate datetimeoffset = isnull(@endDate, cast('99991231' as datetimeoffset));

 DECLARE @baseQuery nvarchar(max) = N'
   select ExecutionId = lg.Id,
          LoggerName = lg.Name,
          CorrelationId = lg.CorrelationId,
          LogId = l.Id,
          LogCreatedDate = l.CreatedDate,
          LogLevel = lv.Name,
          LogMessage = l.Message,

          pl.wait_time_ms,
          pl.cpu_time_ms,
          pl.total_elapsed_time_ms,
          pl.reads,
          pl.writes,
          pl.logical_reads,

          wait_time_ms_diff = pl.wait_time_ms - isnull(lag(pl.wait_time_ms, 1, 0) OVER (order by l.CreatedDate),0),
          cpu_time_ms_diff = pl.cpu_time_ms - isnull(lag(pl.cpu_time_ms, 1, 0) OVER (order by l.CreatedDate),0),
          total_elapsed_time_ms_diff = pl.total_elapsed_time_ms - isnull(lag(pl.total_elapsed_time_ms, 1, 0) OVER (order by l.CreatedDate),0),
          reads_diff = pl.reads - isnull(lag(pl.reads, 1, 0) OVER (order by l.CreatedDate),0),
          writes_diff = pl.writes - isnull(lag(pl.writes, 1, 0) OVER (order by l.CreatedDate),0),
          logical_reads_diff = pl.logical_reads - isnull(lag(pl.logical_reads, 1, 0) OVER (order by l.CreatedDate),0)
   from logging.Logs l
   join logging.Logger lg ON l.ExecutionId = lg.Id
   join logging.Level lv ON l.LevelId = lv.Id
   left join logging.PerformanceLogs pl ON l.Id = pl.LogId
 ';

 IF @ExecutionId IS NOT NULL
  BEGIN
   SET @baseQuery += 
    'where l.ExecutionId = @ExecutionId
     and l.CreatedDate between @vStartDate and @vEndDate
     order by l.Id;   
   ';
  END
 ELSE IF @LoggerName IS NOT NULL
  BEGIN
   SET @baseQuery += 
    'where lg.Name = @loggerName
     and l.CreatedDate between @vStartDate and @vEndDate
     order by l.Id;  
   ';
  END
 ELSE IF @correlationId IS NOT NULL
  BEGIN
   -- assumption is that CorrelationId is unique by nature
   DECLARE @vExecutionId bigint = (select top(1) l.Id from logging.Logger l where l.CorrelationId = @correlationId);
   execute logging.GetLogsWithPerformance @ExecutionId = @vExecutionId,
                                          @startDate = @vStartDate,
                                          @endDate = @vEndDate;
    RETURN(0);
  END
 ELSE
  BEGIN
   SET @baseQuery += 
    'order by l.Id;  
   ';
  END

 execute sp_executesql @baseQuery, N'@ExecutionId bigint, @loggerName nvarchar(256), @vStartDate datetimeoffset, @vEndDate datetimeoffset', @ExecutionId, @LoggerName, @vStartDate, @vEndDate

 RETURN(0)
END

GO

GRANT EXEC ON logging.GetLogsWithPerformance TO PUBLIC;
GO
