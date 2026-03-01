# Sherlog

_Formerly known as "Logging framework"_

**Sherlog** is a unified, detailed logging framework designed specifically for database-side logic in SQL Server. It is highly useful for environments containing complex business logic, nested stored procedure calls, loops, and ETL processes.

The framework is built to assist developers during all stages of a database project's lifecycle, including development, performance testing, debugging, and refactoring.

## Basic Principles

- **Logger Initiation:** To begin logging, the code must first initiate a Logger using the `logging.GetLogger` or `logging.GetNewLogger` stored procedures.
- **Execution Identifier (`ExecutionId`):** Initiating a Logger outputs a unique `bigint` identifier called an `ExecutionId`. This ID is dedicated to the entire single run of the logged stored procedure, including all nested calls.
- **Process Linkage (`CorrelationId`):** A Logger is also associated with a `CorrelationId`, which serves as a common method of linkage between consecutive or parallel processes working on the same subject instance.
- **Application Grouping:** Loggers require an "Application" property to define the business area the process belongs to (e.g., `etl.delta`, `etl.initial`). If splitting into business areas is not needed, a default value of `1` ("undefined") is used.
- **Session Context:** To prevent developers from needing to alter legacy procedure signatures, Sherlog seamlessly passes the `ExecutionId` and `CorrelationId` between procedures in the same DB session using `SESSION_CONTEXT`.

## Logging Levels

The framework uses a hierarchical level system to determine which messages are persisted. By default, the global level is set to **Info (40)**. Levels can be defined globally or restricted to a local scope (via a specific logger name) with an optional automatic expiration date.

| Id  | Name        | Value | Description                                                                              |
| :-- | :---------- | :---- | :--------------------------------------------------------------------------------------- |
| 1   | **All**     | 100   | Lowest level - turns on all logging.                                                     |
| 2   | **Debug**   | 50    | Detailed messages that help to debug the process.                                        |
| 3   | **Info**    | 40    | Informational messages that indicate process progress or milestones.                     |
| 4   | **Warning** | 30    | Abnormal situations that can potentially fail the process.                               |
| 5   | **Error**   | 20    | Errors that usually lead to process failure but can be handled on the application level. |
| 6   | **Fatal**   | 10    | Severe events that usually lead to application failure.                                  |
| 7   | **Off**     | 0     | Highest level - turns off all logging.                                                   |

## Performance Logging

When performance metrics need to be captured, developers can activate performance logging by setting a specific level using the `logging.SetPerformanceLevel` method. When active, any log message that meets or exceeds the specified performance level will simultaneously capture current system metrics and record them into a dedicated extension table (`logging.PerformanceLogs`).

## Quick Start Guide

### 1. Plain Scenario: Writing a simple log

```sql
-- Initialize a new Logger
DECLARE @executionId bigint;
EXECUTE logging.GetNewLogger
    @ExecutionId = @executionId OUT,
    @LoggerName = 'logging.demo.1',
    @ApplicationId = 1;

-- Write a log message
EXECUTE logging.LogInfo @executionId, N'This is a simple information message!';

-- Retrieve the logs
EXECUTE logging.GetLogs @ExecutionId = @executionId;


```
