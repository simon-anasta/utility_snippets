/*
Get all SQL procedures and functions from the database.
2023-07-05
*/

USE IDI_Raw
GO

SELECT s.[name] AS [schema_name]
	,o.[name] AS [object_name]
	,[type_desc] AS [object_type]
	,[definition] AS [object_definition]
	,LEN([definition]) AS num_characters
FROM sys.sql_modules AS m
INNER JOIN sys.objects AS o
ON m.[object_id] = o.[object_id]
LEFT JOIN sys.schemas AS s
ON o.[schema_id] = s.[schema_id]
WHERE [type_desc] NOT LIKE '%view%'
GO

/*
Time created and modified
*/

SELECT SPECIFIC_CATALOG
	,SPECIFIC_SCHEMA
	,SPECIFIC_NAME
	,ROUTINE_TYPE
	,ROUTINE_BODY
	,CREATED
	,LAST_ALTERED
FROM IDI_Raw.INFORMATION_SCHEMA.ROUTINES
WHERE ROUTINE_BODY <> 'EXTERNAL'

