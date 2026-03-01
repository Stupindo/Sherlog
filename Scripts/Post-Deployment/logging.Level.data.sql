
IF NOT EXISTS(SELECT * FROM logging.Level)
 BEGIN
   INSERT INTO logging.Level(Id, Name, Value, Description)
   VALUES(1, N'All', 100, N'Lowest level - turns on all logging.'),
         (2, N'Debug', 50, N'Detailed messages that help to debug the process.'),
         (3, N'Info', 40, N'Informational messages that indicate process progress or milestones.'),
         (4, N'Warning', 30, N'Abnormal situations that can potentially failure the process.'),
         (5, N'Error', 20, N'Errors that usually lead to process failure but can be handled on application level.'),
         (6, N'Fatal', 10, N'Severe events that usually lead to application failure.'),
         (7, N'Off', 0,  N'Highest level - turns off all logging.');
 END

GO
  