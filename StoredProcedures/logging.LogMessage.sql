
CREATE PROCEDURE logging.LogMessage
 @ExecutionId bigint, 
 @LevelName nvarchar(128), 
 @Message nvarchar(2000),
 @LogId bigint = NULL OUTPUT,
 @DataValue nvarchar(max) = NULL
AS
BEGIN
 SET NOCOUNT ON

 DECLARE @proc_name sysname = OBJECT_NAME(@@PROCID);
 DECLARE @tran_check int, @savepoint sysname, @sysname_len int = 128;
 SET @tran_check = case when @@TRANCOUNT > 0 or @@OPTIONS & 2 > 0 then 1 else 0 end;
 SET @savepoint = SUBSTRING(@proc_name,1,@sysname_len-3)+cast(@@nestlevel as varchar(3));
 IF @tran_check = 0 BEGIN TRAN else if not @@OPTIONS&2>0 SAVE TRAN @savepoint;

 DECLARE @LevelId tinyint;
 DECLARE @LevelValue tinyint;
 DECLARE @LevelValueCurrent tinyint;
 DECLARE @PerformanceLevelValueCurrent tinyint;

 BEGIN TRY
   SELECT @LevelId = l.Id,
          @LevelValue = l.Value,
          @LevelValueCurrent = logging.GetLevelValue(@ExecutionId)
   FROM logging.Level l
   WHERE l.Name = @LevelName;

   IF @LevelId IS NOT NULL
      AND
      @LevelValue <= @LevelValueCurrent
    BEGIN
     INSERT INTO logging.Logs(ExecutionId, LevelId, Message)
     VALUES (@ExecutionId, @LevelId, @Message);

     SET @LogId = scope_identity();
    END
   ELSE
    BEGIN
     SET @LogId = NULL;
    END

   -- performance logging, if needed
   SET @PerformanceLevelValueCurrent = logging.GetPerformanceLevelValue(@ExecutionId)

   IF @LogId IS NOT NULL
      AND
      @LevelValue <= @PerformanceLevelValueCurrent
    BEGIN
     execute logging.WritePerformanceSnapshot @LogId = @LogId, @ExecutionId = @ExecutionId;
    END

   IF @DataValue IS NOT NULL AND @LogId IS NOT NULL
    BEGIN
     execute logging.SetLogsData @LogId = @LogId, @ExecutionId = @ExecutionId, @Value = @DataValue;
    END
 END TRY
 BEGIN CATCH
  IF (XACT_STATE() <> -1)
      IF @tran_check = 0 ROLLBACK TRAN ELSE ROLLBACK TRAN @savepoint
     ELSE
      ROLLBACK TRAN;

  DECLARE @err_message nvarchar(4000) = error_message();
  DECLARE @res int = 1;
  execute @res = logging.HandleException @object_name = @proc_name, @error_message = @err_message;
  RETURN(@res);
 END CATCH
 IF (@tran_check = 0) and (@@TRANCOUNT > 0) COMMIT TRAN;
 RETURN(0)
END
GO

GRANT EXEC ON logging.LogMessage TO PUBLIC;
GO
