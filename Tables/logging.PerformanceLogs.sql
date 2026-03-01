
  CREATE TABLE logging.PerformanceLogs (
   LogId bigint NOT NULL,
   ExecutionId bigint NOT NULL, -- references Logger.Id column
   -- section from from sys.dm_exec_requests
   wait_time_ms int,-- from sys.dm_exec_requests
   cpu_time_ms int,-- from sys.dm_exec_requests
   total_elapsed_time_ms int,-- from sys.dm_exec_requests
   reads bigint,-- from sys.dm_exec_requests
   writes bigint,-- from sys.dm_exec_requests
   logical_reads bigint-- from sys.dm_exec_requests
   CONSTRAINT logging_PerformanceLogs__LogId_PK_CL_IX PRIMARY KEY (LogId)
  )

GO
