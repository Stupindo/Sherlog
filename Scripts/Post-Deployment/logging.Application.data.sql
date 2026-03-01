
-- define applications 
IF NOT EXISTS(SELECT * FROM logging.Application)
 BEGIN
   INSERT INTO logging.Application(Id, Name, ParentId, Description)
    VALUES (1, N'undefined', NULL, N'Undefined application, used by default.')
           ;
 END

GO
  