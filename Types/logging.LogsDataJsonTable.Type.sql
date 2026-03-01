
-- this table type is used to pass name and value to form JSON for LogsData

CREATE TYPE logging.LogsDataJsonTable AS TABLE(
  PropertyName nvarchar(128) NOT NULL,
  PropertyValue nvarchar(max) NULL
)

GO
 