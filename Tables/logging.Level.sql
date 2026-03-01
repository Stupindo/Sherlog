
   CREATE TABLE logging.Level (
     Id tinyint NOT NULL,
     Name nvarchar(128) NOT NULL, 
     Value tinyint NOT NULL,
     Description nvarchar(512) NULL,

     CONSTRAINT logging_Level__Id_PK_CL_IX PRIMARY KEY CLUSTERED 
	    (
		    Id ASC
	    )
    )
GO

  CREATE UNIQUE NONCLUSTERED INDEX logging_Level__Name_UQ_IX 
	  ON logging.Level
	  (
		  Name ASC
	  )
GO
 