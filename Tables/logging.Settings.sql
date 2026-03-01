
   CREATE TABLE logging.Settings (
     Name nvarchar(256) NOT NULL, 
     Value nvarchar(256) NOT NULL,

     CreatedDate datetimeoffset NOT NULL DEFAULT(sysdatetimeoffset()),
     ModifiedDate datetimeoffset NULL,
     ExpirationDate datetimeoffset NULL,

     CONSTRAINT logging_Settings__Name_PK_CL_IX PRIMARY KEY CLUSTERED 
        (
            Name ASC
        )
    )
GO
  