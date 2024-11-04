/*
Get list of user created SQL Tables
2018-01-26
Simon Anastasiadis
*/

USE IDI_Sandpit
GO

SELECT s.Name AS schema_name
	,t.NAME AS table_name
	,t.create_date
	,t.modify_date
	,p.rows AS row_count
	,8 * SUM(a.total_pages) AS total_space_KB
	,8.0 * SUM(a.total_pages) / 1024.0 / 1024 AS total_space_GB
	,p.data_compression
	,p.data_complression_desc
FROM sys.tables AS t
INNER JOIN sys.indexes AS i
ON t.OBJECT_ID = i.OBJECT_ID
INNER JOIN sys.partitions AS p
ON i.OBJECT_ID = p.OBJECT_ID
AND i.index_id = p.index_id
INNER JOIN sys.allocation_units AS a
ON p.partition_id = a.container_id
LEFT OUTER JOIN sys.schemas AS s
ON t.schema_id = s.schema_id
WHERE t.name NOT LIKE 'dt%'
AND t.is_ms_shipped = 0
AND i.object_id > 255
/* optional filter to just schema of interest */
-- WHERE s.NAME = 'DL-MAA20XX-YY'
GROUP BY s.name, t.name, p.rows, t.create_date, t.modify_date, p.data_compression, p.data_complression_desc
ORDER BY s.name, t.name

/*
Code to compress tables that are very large and save space:

ALTER TABLE [IDI_Sandpit].[DL-MAA20XX-YY].[table_name] REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE)
*/
