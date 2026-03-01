# Sherlog — SQL Server Logging Framework

> Created by Sergiy Stupnytskyy

---

## Table of Contents

- [Purpose](#purpose)
- [Basic Principles](#basic-principles)
- [Methods](#methods)
- [Quick Guide by Examples](#quick-guide-by-examples)
  - [1. Plain Scenario](#1-plain-scenario)
    - [1.1. Explicitly get a new Logger using `GetNewLogger`](#11-explicitly-get-a-new-logger-using-getnewlogger-sproc)
    - [1.2. Get an existing Logger using `GetLogger`](#12-get-an-existing-logger-using-getlogger-sproc)
    - [1.3. Get a new or existing using the same `GetLogger`](#13-get-a-new-or-existing-using-the-same-getlogger-sproc)
  - [2. Using Levels](#2-using-levels)
    - [2.1. Global Level](#21-global-level)
    - [2.2. Local Level](#22-local-level)
    - [2.3. Local Level with Expiration](#23-local-level-with-expiration)
  - [3. Performance Logging](#3-performance-logging)
  - [4. Suggested Interaction Between Routines](#4-suggested-interaction-between-routines)
    - [4.1. Explicitly Passing ExecutionId](#41-explicitly-passing-executionid)
    - [4.2. Passing Id Through SESSION_CONTEXT](#42-passing-id-through-session_context)
    - [4.3. Linking Multi-Execution Processes Using Correlation Id](#43-linking-multi-execution-processes-using-correlation-id)
  - [5. Logging from Inside of a Transaction](#5-logging-from-inside-of-a-transaction)
  - [6. Framework Performance Overhead](#6-framework-performance-overhead)

---

## Purpose

In some solutions (e.g. ETL) developers have most of the logic implemented on the database side, including nested calls to stored procedures, loops, etc.
It is necessary to have a detailed log for such executions in the following scenarios:

- **Development stage** — when newly written code is tested and debugged.
- **Performance testing stage** — when performance metrics are captured and evaluated.
- **Debugging stage** — when unexpected behavior has to be investigated on dev/qa/prod environments.
- **Changes and refactoring** — when changes are made to existing code (along with unit testing).

Having a unified approach to logging can help increase implementation effectiveness and save development time. It may also encourage developers new to the area to use logging.

It is also recommended to utilize the principle of **correlation id** as a common method of linkage between consecutive or parallel processes that work on the same subject instance.

---

## Basic Principles

In order to start logging, code has to initiate a Logger first (see procedures `GetLogger` and `GetNewLogger`).

The output of the Logger initiation is a unique identifier of type `bigint` — **ExecutionId**. This `ExecutionId` is dedicated for the whole single run of the logged stored procedure and all nested calls.

Additionally, the Logger is associated with a **CorrelationId** that can link multiple executions if they are part of the same process.

Logger's main descriptive properties are **name** and **application**. Application is the area where the process belongs — e.g. `etl.delta`, `etl.initial`, etc. Application is a mandatory parameter. However, its default value is `1='undefined'` for cases when the user is not interested in splitting the business area into applications.

The logging framework uses `SESSION_CONTEXT` to pass the `ExecutionId` and `CorrelationId` between procedures within the scope of the same session.
When a Logger is initiated, it sets `SESSION_CONTEXT` keys named `ExecutionId` and `CorrelationId` to the proper values. In general, the developer does not need to access those `SESSION_CONTEXT` keys directly.

---

## Methods

The following "public" methods cover the logging framework functionality:

| Method Name                      | Parameters                                                                                                                                                                        | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| -------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `logging.GetLogger`              | `@ExecutionId bigint OUTPUT`<br>`@ApplicationId smallint = NULL`<br>`@LoggerName nvarchar(256) = NULL`<br>`@CorrelationId nvarchar(36) = NULL`                                    | Tries to get a previously initiated Logger based on `SESSION_CONTEXT` keys. If no existing Logger is found, creates a new one. In either case `@ExecutionId` is returned for use with other logging procedures.<br><br>`@CorrelationId` can be NULL, but it is recommended to use a proper business value to help identify the process.<br>`@ApplicationId` defines the application or area. Defaults to `1="undefined"`. This procedure is a wrapper around `GetNewLogger`. |
| `logging.GetNewLogger`           | `@ExecutionId bigint OUTPUT`<br>`@ApplicationId smallint`<br>`@LoggerName nvarchar(256)`<br>`@CorrelationId nvarchar(36) = NULL`                                                  | Explicitly initiates a new Logger and returns the `ExecutionId`. `@ApplicationId` and `@LoggerName` are required. A new Logger is initiated even if one already exists with the same signature (`applicationId + LoggerName + CorrelationId`). Also sets `CONTEXT_INFO` with `@ExecutionId` and `@CorrelationId` values.                                                                                                                                                     |
| `logging.SetLevel`               | `@LevelName nvarchar(128)`<br>`@LoggerName nvarchar(256) = NULL`<br>`@ExpirationDate datetimeoffset = NULL`                                                                       | Sets the logging level by name — `Debug`/`Info`/`Error`/... If `@LoggerName` is NULL, sets the common (global) level. `@ExpirationDate` can be used to auto-expire a custom level; it can only be set for specific levels assigned to a specific Logger. Default level is `Info (3)`.                                                                                                                                                                                        |
| `logging.SetPerformanceLevel`    | `@LevelName nvarchar(128)`<br>`@LoggerName nvarchar(256) = NULL`<br>`@ExpirationDate datetimeoffset = NULL`                                                                       | Sets the logging level at which performance metrics are captured. Works similarly to `SetLevel` — every suitable log message will also write the performance metrics.                                                                                                                                                                                                                                                                                                        |
| `logging.LogFatal`               | `@ExecutionId bigint`<br>`@Message nvarchar(2000)`                                                                                                                                | Logs a Fatal message. Record is written only if the current level is ≤ Fatal.                                                                                                                                                                                                                                                                                                                                                                                                |
| `logging.LogError`               | `@ExecutionId bigint`<br>`@Message nvarchar(2000)`                                                                                                                                | Logs an Error message. Record is written only if the current level is ≤ Error.                                                                                                                                                                                                                                                                                                                                                                                               |
| `logging.LogWarning`             | `@ExecutionId bigint`<br>`@Message nvarchar(2000)`                                                                                                                                | Logs a Warning message. Record is written only if the current level is ≤ Warning.                                                                                                                                                                                                                                                                                                                                                                                            |
| `logging.LogInfo`                | `@ExecutionId bigint`<br>`@Message nvarchar(2000)`                                                                                                                                | Logs an Info message. Record is written only if the current level is ≤ Info.                                                                                                                                                                                                                                                                                                                                                                                                 |
| `logging.LogDebug`               | `@ExecutionId bigint`<br>`@Message nvarchar(2000)`                                                                                                                                | Logs a Debug message. Record is written only if the current level is ≤ Debug.                                                                                                                                                                                                                                                                                                                                                                                                |
| `logging.LogStart`               | `@ExecutionId bigint`<br>`@ProcessName nvarchar(1000)`<br>`@Message nvarchar(2000) = NULL`                                                                                        | A wrapper around `LogInfo` (same logging level — Info). The log message starts with the key-phrase `'Started executing'` and the process name. `@Message` is optional. Recommended for use at the beginning of a business process.                                                                                                                                                                                                                                           |
| `logging.LogEnd`                 | `@ExecutionId bigint`<br>`@ProcessName nvarchar(1000)`<br>`@Message nvarchar(2000) = NULL`                                                                                        | A wrapper around `LogInfo` (same logging level — Info). The log message starts with the key-phrase `'Finished executing'` and the process name. `@Message` is optional. Also sets `CONTEXT_INFO` with NULL values and marks the Logger with `ReleasedDate`. Recommended for use at the end of a business process.                                                                                                                                                            |
| `logging.GetLogs`                | `@loggerId bigint = NULL`<br>`@loggerName nvarchar(256) = NULL`<br>`@correlationId nvarchar(36) = NULL`<br>`@startDate datetimeoffset = NULL`<br>`@endDate datetimeoffset = NULL` | Returns logs in a suitable format, using parameters to filter records.                                                                                                                                                                                                                                                                                                                                                                                                       |
| `logging.GetLogsWithPerformance` | `@loggerId bigint = NULL`<br>`@loggerName nvarchar(256) = NULL`<br>`@correlationId nvarchar(36) = NULL`<br>`@startDate datetimeoffset = NULL`<br>`@endDate datetimeoffset = NULL` | Returns logs with performance metrics in a suitable format, using parameters to filter records.                                                                                                                                                                                                                                                                                                                                                                              |
| `logging.PurgeLogs`              | `@loggerName nvarchar(256) = NULL`<br>`@beforeDate datetimeoffset = NULL`<br>`@doTruncate bit = 0`<br>`@rowsDeleted int = NULL OUTPUT`                                            | Cleans out logs in table `logging.Logs`.                                                                                                                                                                                                                                                                                                                                                                                                                                     |
| `logging.RetentionCleanup`       | _(none)_                                                                                                                                                                          | Cleans up old Loggers, Logs, and Settings that are expired. The retention period is currently hard-coded to **30 days**.                                                                                                                                                                                                                                                                                                                                                     |

---

## Quick Guide by Examples

### 1. Plain Scenario

#### 1.1. Explicitly get a new Logger using `GetNewLogger` sproc

The following code shows how to initialize a logger and write a single message:

```sql
--initialize a new Logger
DECLARE @executionId bigint;
execute logging.GetNewLogger @ExecutionId = @executionId OUT, @LoggerName = 'logging.demo.1', @ApplicationId = 1;

-- write a log message
execute logging.LogInfo @executionId, N'This is a simple information message!';

execute logging.GetLogs @ExecutionId = @executionId; --> output
```

The output (by `logging.GetLogs`):

| ExecutionId | LoggerName     | CorrelationId | LogId | LogCreatedDate                     | LogLevel | LogMessage                            |
| ----------- | -------------- | ------------- | ----- | ---------------------------------- | -------- | ------------------------------------- |
| 10146       | logging.demo.1 | NULL          | 15    | 2020-05-05 23:00:12.9225490 -04:00 | Info     | This is a simple information message! |

---

#### 1.2. Get an existing Logger using `GetLogger` sproc

This code shows possible scenarios when the user attempts to get an existing Logger:

```sql
--initialize a new Logger
DECLARE @ExecutionId bigint;
execute logging.GetNewLogger @ExecutionId = @ExecutionId OUT, @LoggerName = 'logging.demo.1', @ApplicationId = 1;

-- write a log message
execute logging.LogInfo @ExecutionId, N'This is a simple information message 1!';

GO

-- get existing logger - it is available because we get it in the same session/connection
DECLARE @ExecutionId bigint;
execute logging.GetLogger @ExecutionId = @ExecutionId OUT;

-- write a log message
execute logging.LogInfo @ExecutionId, N'This is a simple information message 2!';

execute logging.GetLogs @ExecutionId = @ExecutionId; --> output

GO
```

The output:

| ExecutionId | LoggerName     | CorrelationId | LogId | LogCreatedDate                     | LogLevel | LogMessage                              |
| ----------- | -------------- | ------------- | ----- | ---------------------------------- | -------- | --------------------------------------- |
| 31          | logging.demo.1 | NULL          | 8     | 2020-09-08 16:55:38.4067149 -04:00 | Info     | This is a simple information message 1! |
| 31          | logging.demo.1 | NULL          | 9     | 2020-09-08 16:55:38.4845060 -04:00 | Info     | This is a simple information message 2! |

---

#### 1.3. Get a new or existing using the same `GetLogger` sproc

The following example shows usage of the generic procedure `logging.GetLogger`:

```sql
-- using the generic procedure that creates a new or gets an existing logger
DECLARE @executionId bigint;
execute logging.GetLogger @ExecutionId = @executionId OUT, @LoggerName = 'logging.demo.1', @ApplicationId = 2, @CorrelationId = N'random1';

-- write a log message
execute logging.LogInfo @executionId, N'This is a simple information message 1!';

GO

-- get existing logger using the same procedure - no additional parameters needed, @ExecutionId is taken from SESSION_CONTEXT
DECLARE @ExecutionId bigint;
execute logging.GetLogger @ExecutionId = @ExecutionId OUT;

-- write a log message
execute logging.LogInfo @ExecutionId, N'This is a simple information message 2!';

execute logging.GetLogs @ExecutionId = @ExecutionId; --> output

GO
```

The output:

| ExecutionId | ApplicationName | LoggerName     | CorrelationId | LogId | LogCreatedDate                     | LogLevel | LogMessage                              |
| ----------- | --------------- | -------------- | ------------- | ----- | ---------------------------------- | -------- | --------------------------------------- |
| 34          | etl             | logging.demo.1 | random1       | 16    | 2020-09-09 09:45:39.5365816 -04:00 | Info     | This is a simple information message 1! |
| 34          | etl             | logging.demo.1 | random1       | 17    | 2020-09-09 09:45:39.5525431 -04:00 | Info     | This is a simple information message 2! |

---

### 2. Using Levels

The logging framework uses levels to identify what kind of messages are persisted:

| Id  | Name    | Value | Description                                                                          |
| --- | ------- | ----- | ------------------------------------------------------------------------------------ |
| 1   | All     | 100   | Lowest level — turns on all logging.                                                 |
| 2   | Debug   | 50    | Detailed messages that help to debug the process.                                    |
| 3   | Info    | 40    | Informational messages that indicate process progress or milestones.                 |
| 4   | Warning | 30    | Abnormal situations that can potentially cause process failure.                      |
| 5   | Error   | 20    | Errors that usually lead to process failure but can be handled at application level. |
| 6   | Fatal   | 10    | Severe events that usually lead to application failure.                              |
| 7   | Off     | 0     | Highest level — turns off all logging.                                               |

Level can be defined on a **global scope** (parameter `logging.level` in table `logging.Settings`) or on a **local scope** — for a predefined area defined by a logger name. The default global level is `4 - Info`.

Additionally, users may need to capture **Performance snapshots**, which is also defined by a level in settings. Performance logging is defined separately and sets at what level performance snapshots are written. See [Section 3](#3-performance-logging) for more details.

---

#### 2.1. Global Level

The following code shows how to set a level and how it affects logging:

```sql
DECLARE @ExecutionId bigint;
execute logging.GetNewLogger @ExecutionId = @ExecutionId OUT, @LoggerName = 'logging.demo.2', @ApplicationId = 1;

execute logging.SetLevel 'Info'
select LevelValue = logging.GetLevelValue(DEFAULT) --> output 1

execute logging.LogInfo @ExecutionId, N'This is the Info message!';
execute logging.LogDebug @ExecutionId, N'Debug message is NOT written because the current level is higher!';
execute logging.LogWarning @ExecutionId, N'Warning message is written because Warning is higher than Info!';

execute logging.SetLevel 'All'
select LevelValue = logging.GetLevelValue(DEFAULT) --> output 2

execute logging.LogDebug @ExecutionId, N'Now, this Debug message is written because we changed the setting!';

execute logging.GetLogs @ExecutionId = @ExecutionId; --> output 3
```

The output:

```
LevelValue
40

LevelValue
100
```

| ExecutionId | ApplicationName | LoggerName     | CorrelationId | LogId | LogCreatedDate                     | LogLevel | LogMessage                                                         |
| ----------- | --------------- | -------------- | ------------- | ----- | ---------------------------------- | -------- | ------------------------------------------------------------------ |
| 41          | undefined       | logging.demo.2 | NULL          | 31    | 2020-09-09 11:24:16.2342387 -04:00 | Info     | This is the Info message!                                          |
| 41          | undefined       | logging.demo.2 | NULL          | 32    | 2020-09-09 11:24:16.2342387 -04:00 | Warning  | Warning message is written because Warning is higher than Info!    |
| 41          | undefined       | logging.demo.2 | NULL          | 33    | 2020-09-09 11:24:16.2352053 -04:00 | Debug    | Now, this Debug message is written because we changed the setting! |

---

#### 2.2. Local Level

Local level is defined using the same procedure — `logging.SetLevel` — but the additional parameter `@LoggerName` must be provided. In practice it is recommended to use the `LoggerName` for the `@LoggerName` value.

```sql
DECLARE @ExecutionId bigint;
execute logging.GetLogger @ExecutionId = @ExecutionId OUT, @LoggerName = 'logging.demo.2.2';

-- set global level to Info
execute logging.SetLevel 'Info'
select LevelValue_Global = logging.GetLevelValue(DEFAULT) --> output 1

-- set local level to Warning
execute logging.SetLevel @LevelName = 'Warning', @LoggerName = 'logging.demo.2.2';
select LevelValue_Local = logging.GetLevelValue(@ExecutionId) --> output 2

execute logging.LogInfo @ExecutionId, N'This is the Info message that will NOT be persisted!';
execute logging.LogDebug @ExecutionId, N'Debug message is NOT persisted too because the local level is higher!';
execute logging.LogWarning @ExecutionId, N'Warning message is written because it matches the local level!';
execute logging.LogError @ExecutionId, N'Error message is written because Error is higher than Warning!';

-- set global level to All
execute logging.SetLevel 'All'
select LevelValue_Global = logging.GetLevelValue(DEFAULT) --> output 3

execute logging.LogDebug @ExecutionId, N'Even Now, this Debug message is NOT written because the local setting remained at Warning level!';

execute logging.GetLogs @ExecutionId = @ExecutionId; --> output 4
```

Output:

```
LevelValue_Global
40

LevelValue_Local
30

LevelValue_Global
100
```

| ExecutionId | ApplicationName | LoggerName       | CorrelationId | LogId | LogCreatedDate                     | LogLevel | LogMessage                                                     |
| ----------- | --------------- | ---------------- | ------------- | ----- | ---------------------------------- | -------- | -------------------------------------------------------------- |
| 44          | undefined       | logging.demo.2.2 | NULL          | 48    | 2020-09-09 11:34:07.0614858 -04:00 | Warning  | Warning message is written because it matches the local level! |
| 44          | undefined       | logging.demo.2.2 | NULL          | 49    | 2020-09-09 11:34:07.0634803 -04:00 | Error    | Error message is written because Error is higher than Warning! |

---

#### 2.3. Local Level with Expiration

For a local level, an expiration date can be set. A practical scenario may arise in production when detailed logging needs to be enabled for a certain area and should be automatically turned off at a predefined time (e.g. after 2 hours).

Expiration date can be set using the same `logging.SetLevel` procedure by providing a value for the `@ExpirationDate` parameter.

---

### 3. Performance Logging

When a developer needs to capture performance metrics, they simply need to activate performance logging via `logging.SetPerformanceLevel`.

Every time a log message at the configured level or higher is written, an additional record with current metrics is also recorded in the extension table `logging.PerformanceLogs`.

For example, if the performance level is set to `Info`, then all messages of level `Info`/`Warning`/`Error`/`Fatal` will also capture performance metrics.

Since `LogStart` and `LogEnd` use level `Info`, it is recommended to set the Performance Level to `Info` or higher.

To get the snapshot values with differences, call `logging.GetLogsWithPerformance`.

```sql
DECLARE @ExecutionId bigint;
execute logging.GetLogger @ExecutionId = @ExecutionId OUT, @LoggerName = 'logging.demo.3';

execute logging.SetLevel 'Debug'
execute logging.SetPerformanceLevel 'Info'

execute logging.LogDebug @ExecutionId, N'This message will NOT measure the performance!';
execute logging.LogStart @ExecutionId, N'Here we starting the performance measurement!';
execute logging.LogInfo @ExecutionId, N'this message will also capture the performance metrics!';
declare @cnt int;
select @cnt = count(*) from dbo.wv_vitals;
execute logging.LogEnd @ExecutionId, N'Finish measuring the performance!';

execute logging.GetLogsWithPerformance @ExecutionId = @ExecutionId; --> output 1
execute logging.GetLogs @ExecutionId = @ExecutionId; --> output 2
```

The output (note the columns with the `_diff` suffix that show the difference between snapshots):

| ExecutionId | LoggerName     | CorrelationId | LogId | LogCreatedDate                     | LogLevel | LogMessage                                              | wait_time_ms | cpu_time_ms | total_elapsed_time_ms | reads | writes | logical_reads | wait_time_ms_diff | cpu_time_ms_diff | total_elapsed_time_ms_diff | reads_diff | writes_diff | logical_reads_diff |
| ----------- | -------------- | ------------- | ----- | ---------------------------------- | -------- | ------------------------------------------------------- | ------------ | ----------- | --------------------- | ----- | ------ | ------------- | ----------------- | ---------------- | -------------------------- | ---------- | ----------- | ------------------ |
| 47          | logging.demo.3 | NULL          | 55    | 2020-09-09 12:57:25.0104251 -04:00 | Debug    | This message will NOT measure the performance!          | NULL         | NULL        | NULL                  | NULL  | NULL   | NULL          | NULL              | NULL             | NULL                       | NULL       | NULL        | NULL               |
| 47          | logging.demo.3 | NULL          | 56    | 2020-09-09 12:57:25.0134165 -04:00 | Info     | Here we starting the performance measurement!           | 0            | 21          | 23                    | 0     | 9      | 1737          | 0                 | 21               | 23                         | 0          | 9           | 1737               |
| 47          | logging.demo.3 | NULL          | 57    | 2020-09-09 12:57:25.0154110 -04:00 | Info     | this message will also capture the performance metrics! | 0            | 22          | 24                    | 0     | 9      | 1778          | 0                 | 1                | 1                          | 0          | 0           | 41                 |
| 47          | logging.demo.3 | NULL          | 58    | 2020-09-09 12:57:25.0443702 -04:00 | Info     | Finish measuring the performance!                       | 0            | 213         | 53                    | 8     | 11     | 8249          | 0                 | 191              | 29                         | 8          | 2           | 6471               |

---

### 4. Suggested Interaction Between Routines

When logging messages, it is important to support consistent and traceable logging between different routines (e.g. nested calls of stored procedures).

#### 4.1. Explicitly Passing ExecutionId

The most explicit and reliable way is to pass `ExecutionId` and/or `CorrelationId` to get all related logged messages linked.

In the following example, `ExecutionId` is passed to the nested call explicitly:

```sql
-- interaction between procedures
CREATE OR ALTER PROCEDURE dbo.TestProcess
as
BEGIN
    DECLARE @ExecutionId bigint;
    execute logging.GetNewLogger @ExecutionId = @ExecutionId OUT, @LoggerName = 'logging.demo.4', @ApplicationId = 1;

    execute logging.LogInfo @ExecutionId, N'Test process started!';
    -- do some important work here
    declare @cnt int;
    select @cnt = count(*) from dbo.wv_vitals;
    -- call nested procedure
    execute dbo.TestSubProcess @ExecutionId = @ExecutionId;
    -- finish
    execute logging.LogInfo @ExecutionId, N'Test process finished!';
END

GO

CREATE OR ALTER PROCEDURE dbo.TestSubProcess @ExecutionId bigint
as
BEGIN
    execute logging.LogInfo @ExecutionId, N'Test SUB-process started!';
    -- do some important work here
    declare @cnt int;
    select @cnt = count(*) from dbo.wv_vitals;
    -- finish
    execute logging.LogInfo @ExecutionId, N'Test SUB-process finished!';
END

GO

execute dbo.TestProcess;

execute logging.GetLogs @LoggerName = 'logging.demo.4';

GO

DROP PROCEDURE dbo.TestProcess;
DROP PROCEDURE dbo.TestSubProcess;

GO
```

The output:

| ExecutionId | ApplicationName | LoggerName     | CorrelationId | LogId | LogCreatedDate                     | LogLevel | LogMessage                 |
| ----------- | --------------- | -------------- | ------------- | ----- | ---------------------------------- | -------- | -------------------------- |
| 49          | undefined       | logging.demo.4 | NULL          | 63    | 2020-09-09 14:16:45.1443446 -04:00 | Info     | Test process started!      |
| 49          | undefined       | logging.demo.4 | NULL          | 64    | 2020-09-09 14:16:45.1772594 -04:00 | Info     | Test SUB-process started!  |
| 49          | undefined       | logging.demo.4 | NULL          | 65    | 2020-09-09 14:16:45.2121314 -04:00 | Info     | Test SUB-process finished! |
| 49          | undefined       | logging.demo.4 | NULL          | 66    | 2020-09-09 14:16:45.2231029 -04:00 | Info     | Test process finished!     |

---

#### 4.2. Passing Id Through SESSION_CONTEXT

In some cases it is too expensive to change a legacy procedure's signature, or it is simply not feasible to pass the `ExecutionId` explicitly. When a process is executed in a single DB session/connection, the Logging Framework passes `ExecutionId` and `CorrelationId` through `SESSION_CONTEXT`. The corresponding keys are `ExecutionId` and `CorrelationId`. See procedures `SetSessionExecutionId` and `SetSessionCorrelationId` for details. These procedures can also be used explicitly to inject the `ExecutionId` and/or `CorrelationId` into the DB before a process starts.

In the following example, `GetLogger` uses `SESSION_CONTEXT` to retrieve the Logger:

```sql
-- interaction between procedures
CREATE OR ALTER PROCEDURE dbo.TestProcess2
as
BEGIN
    DECLARE @ExecutionId bigint;
    execute logging.GetLogger @ExecutionId = @ExecutionId OUT, @LoggerName = 'logging.demo.5', @ApplicationId = 1;

    execute logging.LogInfo @ExecutionId, N'Test process 2 started!';
    -- do some important work here
    declare @cnt int;
    select @cnt = count(*) from dbo.wv_vitals;
    -- call nested procedure (no @ExecutionId passed - will be picked up from SESSION_CONTEXT)
    execute dbo.TestSubProcess2;
    -- finish
    execute logging.LogInfo @ExecutionId, N'Test process 2 finished!';
END

GO

CREATE OR ALTER PROCEDURE dbo.TestSubProcess2
as
BEGIN
    DECLARE @ExecutionId bigint;
    execute logging.GetLogger @ExecutionId = @ExecutionId OUT;

    execute logging.LogInfo @ExecutionId, N'Test SUB-process 2 started!';
    -- do some important work here
    declare @cnt int;
    select @cnt = count(*) from dbo.wv_vitals;
    -- finish
    execute logging.LogInfo @ExecutionId, N'Test SUB-process 2 finished!';
END

GO

execute dbo.TestProcess2;

execute logging.GetLogs @LoggerName = 'logging.demo.5';

GO

DROP PROCEDURE dbo.TestProcess2;
DROP PROCEDURE dbo.TestSubProcess2;

GO
```

The output:

| ExecutionId | ApplicationName | LoggerName     | CorrelationId | LogId | LogCreatedDate                     | LogLevel | LogMessage                   |
| ----------- | --------------- | -------------- | ------------- | ----- | ---------------------------------- | -------- | ---------------------------- |
| 50          | undefined       | logging.demo.5 | NULL          | 71    | 2020-09-09 14:43:03.5517842 -04:00 | Info     | Test process 2 started!      |
| 50          | undefined       | logging.demo.5 | NULL          | 72    | 2020-09-09 14:43:03.5937228 -04:00 | Info     | Test SUB-process 2 started!  |
| 50          | undefined       | logging.demo.5 | NULL          | 73    | 2020-09-09 14:43:03.6235924 -04:00 | Info     | Test SUB-process 2 finished! |
| 50          | undefined       | logging.demo.5 | NULL          | 74    | 2020-09-09 14:43:03.6245886 -04:00 | Info     | Test process 2 finished!     |

---

#### 4.3. Linking Multi-Execution Processes Using Correlation Id

If a process involves multiple executions with different DB sessions, those can be linked using **Correlation Id**.

Correlation Id can be explicitly written into `SESSION_CONTEXT` before a stored procedure is called. A special procedure `SetSessionCorrelationId` can be used for that.

The following example illustrates how it works, assuming the Correlation Id is available in `SESSION_CONTEXT`:

**Execution 1:**

```sql
execute logging.SetCorrelationId @CorrelationId = 'random.logging.demo.6';

DECLARE @ExecutionId bigint;
-- here a new Logger is initiated and Correlation id from SESSION_CONTEXT is used
execute logging.GetLogger @ExecutionId = @ExecutionId OUT, @LoggerName = 'logging.demo.6';

execute logging.LogStart @ExecutionId, N'Test process 3 started!';

execute logging.LogEnd @ExecutionId, N'Test process 3 finished!';

GO
```

**Execution 2:**

```sql
execute logging.SetCorrelationId @CorrelationId = 'random.logging.demo.6';

DECLARE @ExecutionId bigint;
-- here a new Logger is initiated and Correlation id from SESSION_CONTEXT is used
execute logging.GetLogger @ExecutionId = @ExecutionId OUT, @LoggerName = 'logging.demo.6.2';

execute logging.LogStart @ExecutionId, N'Test process 4 started!';

execute logging.LogEnd @ExecutionId, N'Test process 4 finished!';

execute logging.GetLogs @ExecutionId = @ExecutionId;

GO
```

At the end, the records found in the log look like this:

| ExecutionId | ApplicationName | LoggerName       | CorrelationId         | LogId | LogCreatedDate                     | LogLevel | LogMessage               |
| ----------- | --------------- | ---------------- | --------------------- | ----- | ---------------------------------- | -------- | ------------------------ |
| 52          | undefined       | logging.demo.6.1 | random.logging.demo.6 | 77    | 2020-09-09 15:01:47.9445826 -04:00 | Info     | Test process 3 started!  |
| 52          | undefined       | logging.demo.6.1 | random.logging.demo.6 | 78    | 2020-09-09 15:01:47.9525601 -04:00 | Info     | Test process 3 finished! |
| 53          | undefined       | logging.demo.6.2 | random.logging.demo.6 | 79    | 2020-09-09 15:02:44.4492616 -04:00 | Info     | Test process 4 started!  |
| 53          | undefined       | logging.demo.6.2 | random.logging.demo.6 | 80    | 2020-09-09 15:02:44.4572665 -04:00 | Info     | Test process 4 finished! |

> Note that even though `ExecutionId`s are different (52 and 53), the `CorrelationId` is the same, and all related log records can be identified together.

---

### 5. Logging from Inside of a Transaction

In some cases we need to log messages from inside of a multi-statement explicit transaction that can be rolled back.

To avoid losing those messages we can work around this using **table variables**. The coding around this is not as clean and concise, but it is currently the recommended solution.

```sql
DECLARE @ExecutionId bigint;
execute logging.GetLogger @ExecutionId = @ExecutionId OUT, @LoggerName = 'logging.demo.7';
DECLARE @tblLogs logging.LogsTable;

BEGIN TRY
BEGIN TRAN
    INSERT INTO @tblLogs(ExecutionId, levelName, Message)
    VALUES(@ExecutionId, N'Info', N'Demo of logging from transaction.');

    SELECT 1/0 as err

COMMIT TRAN
END TRY
BEGIN CATCH
    -- error handling is here
    INSERT INTO @tblLogs(ExecutionId, levelName, Message)
    VALUES(@ExecutionId, N'Error', N'An exception happened!');
    ROLLBACK TRAN;
    execute logging.LogMessageS @tblLogs;
END CATCH

execute logging.GetLogs @LoggerName = 'logging.demo.7';

GO
```

Output:

| ExecutionId | ApplicationName | LoggerName     | CorrelationId | LogId | LogCreatedDate                     | LogLevel | LogMessage                        |
| ----------- | --------------- | -------------- | ------------- | ----- | ---------------------------------- | -------- | --------------------------------- |
| 54          | undefined       | logging.demo.6 | NULL          | 81    | 2020-09-09 15:07:40.7010119 -04:00 | Info     | Demo of logging from transaction. |
| 54          | undefined       | logging.demo.6 | NULL          | 82    | 2020-09-09 15:07:40.7059907 -04:00 | Error    | An exception happened!            |

---

### 6. Framework Performance Overhead

From testing done on the development environment, the time depends directly on the insertion of records into the logging framework tables. In the development environment, testing was done by continuously inserting information into the logging tables **200,000 times**. Based on the results, it takes on average **1 millisecond** to insert a record.
