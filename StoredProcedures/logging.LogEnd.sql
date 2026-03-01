 
CREATE PROCEDURE logging.LogEnd
 @ExecutionId bigint,
 @ProcessName nvarchar(1000),
 @Message nvarchar(2000) = NULL,
 @ResetContext bit = 1 -- clean up context values at the end?
AS
BEGIN
 SET NOCOUNT ON

 DECLARE @proc_name sysname = OBJECT_NAME(@@PROCID);
 DECLARE @tran_check int, @savepoint sysname, @sysname_len int = 128;
 SET @tran_check = case when @@TRANCOUNT > 0 or @@OPTIONS & 2 > 0 then 1 else 0 end;
 SET @savepoint = SUBSTRING(@proc_name,1,@sysname_len-3)+cast(@@nestlevel as varchar(3));
 IF @tran_check = 0 BEGIN TRAN else if not @@OPTIONS&2>0 SAVE TRAN @savepoint;

 BEGIN TRY
   --TODO::replace with concat_ws when version of SQL DB allows
   DECLARE @endMessage nvarchar(2000) = N'Finished executing'+
                                        iif(@ProcessName IS NULL,N'',N' ')+
                                        isnull(@ProcessName, N'.')+
                                        iif(@ProcessName IS NULL,N'',N'.')+
                                        iif(@Message IS NULL,N'',N' ')+
                                        isnull(@Message,N'');
  
   execute logging.LogInfo @ExecutionId = @ExecutionId, @Message = @endMessage;
  
   -- additionally, mark Logger as released
   UPDATE logging.Logger
   SET ReleasedDate = sysdatetimeoffset()
   WHERE Id = @ExecutionId;
   
   -- reset session context
   IF @ResetContext = 1
    BEGIN
     execute logging.SetExecutionId NULL;
     execute logging.SetCorrelationId NULL;
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

 RETURN(0)
END
GO

GRANT EXEC ON logging.LogEnd TO PUBLIC;
GO
