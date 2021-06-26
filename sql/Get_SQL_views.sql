/*
Get list of user created SQL Views
2019-04-05
Simon Anastasiadis
*/

USE IDI_UserCode
GO

SELECT s.Name AS schema_name
	,t.NAME AS table_name
FROM sys.views AS t
LEFT OUTER JOIN sys.schemas AS s
ON t.schema_id = s.schema_id
/* optional filter to just schema of interest */
-- WHERE s.NAME = 'DL-MAA20XX-YY'
GROUP BY s.name, t.name
ORDER BY s.name, t.name
