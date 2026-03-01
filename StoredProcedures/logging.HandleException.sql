 
CREATE PROCEDURE logging.HandleException
 @object_name sysname,
 @error_message nvarchar(4000) = NULL,
 @caller_data nvarchar(4000) = NULL
AS
BEGIN
 SET NOCOUNT ON

 DECLARE @exceptionHandlingStrategy nvarchar(128) = logging.GetExceptionHandlingStrategy(default);

 DECLARE @error_message_local nvarchar(max) = @object_name + N': ' + @error_message;

 IF @exceptionHandlingStrategy = N'Suppress'
  BEGIN
   RETURN(1)
  END
 ELSE IF @exceptionHandlingStrategy = N'ThrowAsWarning'
  BEGIN
   RAISERROR(@error_message_local, 1, 1);
   RETURN(1)
  END
 ELSE
  BEGIN
   RAISERROR(@error_message_local, 16, 1);
   RETURN(1);
  END

 RETURN(0)
END
GO

GRANT EXEC ON logging.HandleException TO PUBLIC;
GO
