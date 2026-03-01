
   ALTER TABLE logging.Application
   ADD CONSTRAINT logging_Application__ParentId_FK
   FOREIGN KEY(ParentId)
   REFERENCES logging.Application(Id);
GO

 