
-- property logging.level should be always in the settings and the default value is Info;
IF NOT EXISTS(SELECT * FROM logging.Settings WHERE Name = N'logging.level')
 BEGIN
   INSERT INTO logging.Settings(Name, Value)
    VALUES (N'logging.level', N'Info')
 END

GO

-- property logging.performance get value of logging.level - performance is logged on all levels equal and higher;
IF NOT EXISTS(SELECT * FROM logging.Settings WHERE Name = N'logging.performance')
 BEGIN
   INSERT INTO logging.Settings(Name, Value)
    VALUES (N'logging.performance', N'Off')
 END

GO
  
-- property logging.exception.handlestrategy - how exceptions inside of the framework are treated;
-- 1. Suppress - fully supress the exception, nothing is thrown to the main thread(caller);
-- 2. ThrowAsWarning [DEFAULT] - any exception is treated as warning, main thread(caller) is not interrupted;
-- 2. ThrowAsIs - any exception is thrown further into main thread(caller), main thread can be interrupted;
IF NOT EXISTS(SELECT * FROM logging.Settings WHERE Name = N'logging.exception.handlingstrategy')
 BEGIN
   INSERT INTO logging.Settings(Name, Value)
    VALUES (N'logging.exception.handlingstrategy', N'ThrowAsWarning')
 END

GO