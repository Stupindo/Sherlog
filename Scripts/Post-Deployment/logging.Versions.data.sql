

IF NOT EXISTS(SELECT * FROM logging.Versions WHERE Name = N'1.0.0')
 BEGIN
   INSERT INTO logging.Versions(Name, VersionDate, Description)
    VALUES (N'1.0.0', N'20201016', N'First version released.')
 END

GO

IF NOT EXISTS(SELECT * FROM logging.Versions WHERE Name = N'1.0.1')
 BEGIN
  INSERT INTO logging.Versions(Name, VersionDate, Description)
      VALUES (N'1.0.1', N'20201201', N'Stability(minor) improvement to GetLogger procedure.')
 END

GO

IF NOT EXISTS(SELECT * FROM logging.Versions WHERE Name = N'1.1.0')
 BEGIN
  INSERT INTO logging.Versions(Name, VersionDate, Description)
      VALUES (N'1.1.0', N'20201220', N'Added custom exception handling inside of the logging framework.')
 END

GO

IF NOT EXISTS(SELECT * FROM logging.Versions WHERE Name = N'1.1.1')
 BEGIN
  INSERT INTO logging.Versions(Name, VersionDate, Description)
      VALUES (N'1.1.1', N'20201222', N'Added versions (this).')
 END

GO

IF NOT EXISTS(SELECT * FROM logging.Versions WHERE Name = N'1.1.2')
 BEGIN
  INSERT INTO logging.Versions(Name, VersionDate, Description)
      VALUES (N'1.1.2', N'20210105', N'Fixes and improvements.')
 END

GO

IF NOT EXISTS(SELECT * FROM logging.Versions WHERE Name = N'1.2.0')
 BEGIN
  INSERT INTO logging.Versions(Name, VersionDate, Description)
      VALUES (N'1.2.0', N'20210915', N'Introduced LogsData to store additional data associated with logs.')
 END

IF NOT EXISTS(SELECT * FROM logging.Versions WHERE Name = N'1.2.1')
 BEGIN
  INSERT INTO logging.Versions(Name, VersionDate, Description)
      VALUES (N'1.2.1', N'20211105', N'Fixed json generator to escape a single quote.')
 END

GO