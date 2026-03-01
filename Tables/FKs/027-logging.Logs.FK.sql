
   ALTER TABLE logging.Logs
   ADD CONSTRAINT logging_Logs__ExecutionId_FK
   FOREIGN KEY(ExecutionId)
   REFERENCES logging.Logger(Id);
GO

   ALTER TABLE logging.Logs
   ADD CONSTRAINT logging_Logs__LevelId_FK
   FOREIGN KEY(LevelId)
   REFERENCES logging.Level(Id);

GO

 