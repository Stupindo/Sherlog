
   CREATE TABLE logging.Logger (
   Id bigint NOT NULL IDENTITY(1,1), -- this id is treated as execution id in the code
   ApplicationId smallint NOT NULL DEFAULT(1), -- value 1 represents "Undefined", see logging.Application table
   Name nvarchar(256) NOT NULL,
   CorrelationId nvarchar(36) NULL, -- correlation id represents application context id and also can be used to link multiple executions

   CreatedDate datetimeoffset NOT NULL DEFAULT(sysdatetimeoffset()),
   ReleasedDate datetimeoffset NULL

   CONSTRAINT logging_Logger__Id_PK_CL_IX PRIMARY KEY CLUSTERED 
	  (
		  [Id] ASC
	  )
  )

GO

  CREATE NONCLUSTERED INDEX logging_Logger__ApplicationId_Name_IX 
	  ON logging.Logger
	  (
		  ApplicationId ASC,
      Name ASC
	  )

GO
 