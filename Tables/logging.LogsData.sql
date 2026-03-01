
CREATE TABLE logging.LogsData (
  LogId bigint NOT NULL,
  ExecutionId bigint NOT NULL, -- references Logger.Id column
   
  Value nvarchar(max) NULL,

  CONSTRAINT logging_LogsData__LogId_PK_CL_IX PRIMARY KEY (LogId)
)

GO
