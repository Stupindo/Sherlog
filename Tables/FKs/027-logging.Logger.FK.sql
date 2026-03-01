
ALTER TABLE logging.Logger
WITH NOCHECK 
ADD CONSTRAINT logging_Logger__ApplicationId_FK
FOREIGN KEY(ApplicationId)
REFERENCES logging.Application(Id);

GO

ALTER TABLE logging.Logger NOCHECK CONSTRAINT logging_Logger__ApplicationId_FK;

GO

 