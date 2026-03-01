 
CREATE PROCEDURE logging.WritePerformanceSnapshot
 @LogId bigint,
 @ExecutionId bigint
AS
BEGIN
 SET NOCOUNT ON

 DECLARE @proc_name sysname = OBJECT_NAME(@@PROCID);
 DECLARE @tran_check int, @savepoint sysname, @sysname_len int = 128;
 SET @tran_check = case when @@TRANCOUNT > 0 or @@OPTIONS & 2 > 0 then 1 else 0 end;
 SET @savepoint = SUBSTRING(@proc_name,1,@sysname_len-3)+cast(@@nestlevel as varchar(3));
 IF @tran_check = 0 BEGIN TRAN else if not @@OPTIONS&2>0 SAVE TRAN @savepoint;

 BEGIN TRY
   INSERT INTO logging.PerformanceLogs(LogId,
                                       ExecutionId,
                                       -- section from from sys.dm_exec_requests
                                       wait_time_ms,
                                       cpu_time_ms,
                                       total_elapsed_time_ms,
                                       reads,
                                       writes,
                                       logical_reads)
     select @LogId,
            @ExecutionId,
            r.wait_time,
            r.cpu_time,
            r.total_elapsed_time,
            r.reads,
            r.writes,
            r.logical_reads
    from sys.dm_exec_requests r 
    where r.session_id = @@SPID;
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

GRANT EXEC ON logging.WritePerformanceSnapshot TO PUBLIC;
GO
