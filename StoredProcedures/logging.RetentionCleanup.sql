
CREATE PROCEDURE logging.RetentionCleanup
AS
BEGIN
 SET NOCOUNT ON

 --TODO::get retention date based on settings value
 DECLARE @dt_retention datetimeoffset = dateadd(DD,-30,sysdatetimeoffset()) 

 execute logging.PurgeLogs @beforeDate = @dt_retention;

 delete from logging.Logger WHERE CreatedDate < @dt_retention;

 delete from logging.Settings where ExpirationDate < @dt_retention;
   
 RETURN(0)
END

GO

GRANT EXEC ON logging.RetentionCleanup TO PUBLIC;
GO
