
CREATE PROCEDURE logging.SetSessionParameter
 @Key nvarchar(128),
 @Value sql_variant
AS
BEGIN
 SET NOCOUNT ON

 execute sys.sp_set_session_context @key = @Key, @value = @Value, @read_only = 0;

 RETURN(0)
END
 
GO

GRANT EXEC ON logging.SetSessionParameter TO PUBLIC;
GO
