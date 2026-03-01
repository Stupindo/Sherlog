
CREATE PROCEDURE logging.GetLogger
 @ExecutionId bigint OUTPUT,
 @ApplicationId smallint = NULL,
 @LoggerName nvarchar(256) = NULL,
 @CorrelationId nvarchar(36) = NULL
AS
BEGIN
 SET NOCOUNT ON

 DECLARE @proc_name sysname = OBJECT_NAME(@@PROCID);
 DECLARE @tran_check int, @savepoint sysname, @sysname_len int = 128;
 SET @tran_check = case when @@TRANCOUNT > 0 or @@OPTIONS & 2 > 0 then 1 else 0 end;
 SET @savepoint = SUBSTRING(@proc_name,1,@sysname_len-3)+cast(@@nestlevel as varchar(3));
 IF @tran_check = 0 BEGIN TRAN else if not @@OPTIONS&2>0 SAVE TRAN @savepoint;

 BEGIN TRY 
   SET @ExecutionId = logging.GetExecutionId();

   IF @ExecutionId IS NULL
      OR
      NOT EXISTS(SELECT * FROM logging.Logger WHERE Id = @ExecutionId)
    BEGIN
     SELECT @ApplicationId = ISNULL(@ApplicationId, 1), -- 'undefined' - default app level
            @LoggerName = isnull(@LoggerName, N'undefined');

     execute logging.GetNewLogger @ExecutionId = @ExecutionId OUT,
                                  @ApplicationId = @ApplicationId,
                                  @LoggerName = @LoggerName,
                                  @CorrelationId = @CorrelationId;
    END
 END TRY
 BEGIN CATCH
  IF (XACT_STATE() <> -1)
      IF @tran_check = 0 ROLLBACK TRAN ELSE ROLLBACK TRAN @savepoint
     ELSE
      ROLLBACK TRAN;

  SET @ExecutionId = NULL;
  DECLARE @err_message nvarchar(4000) = error_message();
  DECLARE @res int = 1;
  execute @res = logging.HandleException @object_name = @proc_name, @error_message = @err_message;
  RETURN(@res);
 END CATCH
 IF (@tran_check = 0) and (@@TRANCOUNT > 0) COMMIT TRAN;
 RETURN(0)
END

GO

GRANT EXEC ON logging.GetLogger TO PUBLIC;
GO
