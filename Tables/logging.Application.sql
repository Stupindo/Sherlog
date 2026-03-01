
   CREATE TABLE logging.Application (
     Id smallint NOT NULL,
     Name nvarchar(128) NOT NULL, 
     ParentId smallint NULL, -- self-reference
     Description nvarchar(512) NULL,

     CONSTRAINT logging_Application__Id_PK_CL_IX PRIMARY KEY CLUSTERED 
        (
            Id ASC
        )
    )

GO

  CREATE UNIQUE NONCLUSTERED INDEX logging_Application__Name_UQ_IX 
      ON logging.Application
      (
          Name ASC
      )
GO

  CREATE NONCLUSTERED INDEX logging_Application__ParentId_IX 
      ON logging.Application
      (
          ParentId ASC
      )
GO
