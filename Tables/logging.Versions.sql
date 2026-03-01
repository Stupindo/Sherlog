
   CREATE TABLE logging.Versions (
     Name nvarchar(64) NOT NULL, 
     VersionDate datetimeoffset NOT NULL DEFAULT(sysdatetimeoffset()),
     Description nvarchar(1000) NULL,

     CONSTRAINT logging_Versions__Name_PK_CL_IX PRIMARY KEY CLUSTERED 
        (
            Name ASC
        )
    )
GO
  