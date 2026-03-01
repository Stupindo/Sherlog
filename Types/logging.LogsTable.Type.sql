
   CREATE TYPE logging.LogsTable AS TABLE(
     Id bigint NOT NULL IDENTITY(1,1),
     ExecutionId bigint NOT NULL,
     LevelName nvarchar(128) NOT NULL,
     Message nvarchar(2000) NOT NULL,

     CreatedDate datetimeoffset NOT NULL DEFAULT(sysdatetimeoffset())
    )
