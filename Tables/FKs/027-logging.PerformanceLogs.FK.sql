
   ALTER TABLE logging.PerformanceLogs
   ADD CONSTRAINT logging_PerformanceLogs__ExecutionId_FK
   FOREIGN KEY(ExecutionId)
   REFERENCES logging.Logger(Id);

GO
