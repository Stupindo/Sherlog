
   CREATE TABLE logging.Logs (
     Id bigint NOT NULL IDENTITY(1,1),
     ExecutionId bigint NOT NULL, -- references Logger.Id column
     LevelId tinyint NOT NULL,
     Message nvarchar(2000) NOT NULL,

     CreatedDate datetimeoffset NOT NULL DEFAULT(sysdatetimeoffset()),

     CONSTRAINT logging_Logs__Id_PK_CL_IX PRIMARY KEY CLUSTERED 
        (
            [Id] ASC
        )
    )
GO
 
  CREATE NONCLUSTERED INDEX logging_Logs__ExecutionId_IX 
      ON logging.Logs
      (
          ExecutionId ASC
      )
GO

  CREATE NONCLUSTERED INDEX logging_Logs__CreatedDate_LevelId_IX 
      ON logging.Logs
      (
          CreatedDate ASC,
      LevelId ASC
      )
GO 
 