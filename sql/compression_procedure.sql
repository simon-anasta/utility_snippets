/*
Rebuild Table with Compression
Simon Anastasiadis
2025-11-04

ChatGPT assisted development

This proceedure provides an alternative way of undertaking compression.
The direct approach:
ALTER TABLE ... REBUILD WITH (DATA_COMPRESSION = PAGE)
is a fully logged operation that can not take full advantage of parallel processing.
Often this approach locks the server, hindering others use of it.

The recommended approach:
CREATE TABLE ... WITH (DATA_COMPERESSION = PAGE)
and copying the data into this new table is much faster:
> runs with minimal logging
> can leverage batch copy operations and parallel inserts.

However, the recommended approach tends to require more code.
Hence I wrote the below proceedure to simplify the process.


We do not compress the indexes, as we did not do this by default before
and the size reduction is expected to be small compared to the increased delays
due to CPU overhead.

Key limitation:
Currently hardcoded to the SIA_Sandpit. Needs adjusting for use in IDI_Sandpit.

Excellent performance.
Test case of ~10 GB table ran in 2 minutes.


Example use:
EXEC [IDI_UserCode].[DL-MAA2023-46].[compress_table] @table = '[SIA_Sandpit].[DL-MAA2023-55].[non_neet_spells]'

To keep the original and compressed table:
EXEC [IDI_UserCode].[DL-MAA2023-46].[compress_table] @table = '[SIA_Sandpit].[DL-MAA2023-55].[non_neet_spells]', @swap_tables = 0

To just review the commands that will be executed:
EXEC [IDI_UserCode].[DL-MAA2023-46].[compress_table] @table = '[SIA_Sandpit].[DL-MAA2023-55].[non_neet_spells]', @debug = 1
*/

USE IDI_UserCode
GO

DROP PROCEDURE IF EXISTS [DL-MAA2023-46].[compress_table]
GO

CREATE PROCEDURE [DL-MAA2023-46].[compress_table]
	@table NVARCHAR(392) -- 128 characters for database, schema, and table + 6 characters for [] + 2 characters for .
	, @compression_type NVARCHAR(5) = 'PAGE' -- PAGE | ROW
	, @swap_tables BIT = 1
	, @debug BIT = 0
AS
BEGIN
	SET NOCOUNT ON;

	-- declarations
	DECLARE
		@database NVARCHAR(128)
		,@schema NVARCHAR(128)
		,@tbl NVARCHAR(128)
		,@new_tbl NVARCHAR(128)
		,@tbl_full NVARCHAR(384)
		,@new_tbl_full NVARCHAR(384)
		,@sql NVARCHAR(MAX)

	-- get database, schema and table
	SET @table = TRIM(@table)

	SET @database = PARSENAME(@table, 3)
	SET @schema = PARSENAME(@table, 2)
	SET @tbl = PARSENAME(@table, 1)

	-- new table name
	SET @new_tbl = CONCAT(@tbl, '_rebuild')
	
	SET @tbl_full = CONCAT('[', @database, '].[', @schema, '].[', @tbl, ']')
	SET @new_tbl_full = CONCAT('[', @database, '].[', @schema, '].[', @new_tbl, ']')

	-- require table exists and new table does not exist
	IF @database IS NULL -- no database provided
	THROW 81000, 'input table is missing database', 1;

	IF OBJECT_ID(@tbl_full) IS NULL -- input table does not exist
	THROW 82000, 'input table does not exist', 1;

	IF OBJECT_ID(@new_tbl_full) IS NOT NULL -- working table already exists
	THROW 83000, 'working table *_rebuild already exists', 1;

	-- create empty table
	SET @sql = N'SELECT TOP 0 * INTO @new_tbl_full@ FROM @tbl_full@;'
	SET @sql = REPLACE(@sql, '@new_tbl_full@', @new_tbl_full)
	SET @sql = REPLACE(@sql, '@tbl_full@', @tbl_full)

	IF @debug = 1
		PRINT @sql
	ELSE
		EXEC sp_executesql @sql;
	
	-- apply compression
	SET @sql = N'ALTER TABLE @new_tbl_full@ REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = @compression_type@);'
	SET @sql = REPLACE(@sql, '@new_tbl_full@', @new_tbl_full)
	SET @sql = REPLACE(@sql, '@compression_type@', @compression_type)

	IF @debug = 1
		PRINT @sql
	ELSE
		EXEC sp_executesql @sql;
	
	-- copy data into compressed table
	SET @sql = N'INSERT INTO @new_tbl_full@ WITH (TABLOCK) SELECT * FROM @tbl_full@;'
	SET @sql = REPLACE(@sql, '@new_tbl_full@', @new_tbl_full)
	SET @sql = REPLACE(@sql, '@tbl_full@', @tbl_full)

	IF @debug = 1
		PRINT @sql
	ELSE
		EXEC sp_executesql @sql;
	
	-- reindex
	DECLARE @index_name NVARCHAR(128)
		,@is_unique BIT
		,@is_primary_key BIT
		,@index_columns NVARCHAR(MAX)
		,@include_columns NVARCHAR(MAX)

	DECLARE index_cursor CURSOR FAST_FORWARD FOR
	SELECT i.name
		, i.is_unique
		, i.is_primary_key
	FROM SIA_Sandpit.sys.indexes AS i
	INNER JOIN SIA_Sandpit.sys.objects AS o
	ON i.object_id = o.object_id
	INNER JOIN SIA_Sandpit.sys.schemas AS s
	ON o.schema_id = s.schema_id
	WHERE o.name = @tbl
	AND s.name = @schema
	AND i.type_desc = 'NONCLUSTERED'
	AND i.is_hypothetical = 0

	OPEN index_cursor
	FETCH NEXT FROM index_cursor INTO @index_name, @is_unique, @is_primary_key

	WHILE @@FETCH_STATUS = 0
	BEGIN
		-- list of index columns
		SELECT @index_columns = STRING_AGG(QUOTENAME(c.name) + IIF(ic.is_descending_key = 1, ' DESC', ' ASC'), ', ')
		FROM SIA_Sandpit.sys.index_columns AS ic
		INNER JOIN SIA_Sandpit.sys.columns AS c
		ON ic.object_id = c.object_id
		AND ic.column_id = c.column_id
		WHERE ic.object_id = OBJECT_ID(@tbl_full)
		AND ic.index_id = (
			SELECT index_id
			FROM SIA_Sandpit.sys.indexes
			WHERE name = @index_name
			AND object_id = OBJECT_ID(@tbl_full)
		)
		AND ic.is_included_column = 0

		
		-- list of include columns
		SELECT @include_columns = STRING_AGG(QUOTENAME(c.name), ', ')
		FROM SIA_Sandpit.sys.index_columns AS ic
		INNER JOIN SIA_Sandpit.sys.columns AS c
		ON ic.object_id = c.object_id
		AND ic.column_id = c.column_id
		WHERE ic.object_id = OBJECT_ID(@tbl_full)
		AND ic.index_id = (
			SELECT index_id
			FROM SIA_Sandpit.sys.indexes
			WHERE name = @index_name
			AND object_id = OBJECT_ID(@tbl_full)
		)
		AND ic.is_included_column = 1

		
		-- assemble sql statment
		-- SET @sql = N'CREATE @is_unique@ NONCLUSTERED INDEX @index_name@ ON @new_tbl_full@ (@index_columns@) @include_columns@ WITH (DATA_COMPRESSION = @compression_type@);' -- disabled as not compressing indexes
		
		SET @sql = N'CREATE @is_unique@ NONCLUSTERED INDEX @index_name@ ON @new_tbl_full@ (@index_columns@) @include_columns@;'
		SET @sql = REPLACE(@sql, '@is_unique@', IIF(@is_unique = 1, 'UNIQUE', ''))
		SET @sql = REPLACE(@sql, '@index_name@', @index_name)
		SET @sql = REPLACE(@sql, '@new_tbl_full@', @new_tbl_full)
		SET @sql = REPLACE(@sql, '@index_columns@', @index_columns)
		SET @sql = REPLACE(@sql, '@include_columns@', IIF(@include_columns IS NULL, '', 'INCLUDE (@include_columns@)'))
		SET @sql = REPLACE(@sql, '@include_columns@', ISNULL(@include_columns, ''))
		-- SET @sql = REPLACE(@sql, '@compression_type@', @compression_type) -- disabled as not compressing indexes

		IF @debug = 1
			PRINT @sql
		ELSE
			EXEC sp_executesql @sql;
	
		FETCH NEXT FROM index_cursor INTO @index_name, @is_unique, @is_primary_key
	END

	CLOSE index_cursor
	DEALLOCATE index_cursor

	-- swap tables
	IF @swap_tables = 1
	BEGIN
		BEGIN TRANSACTION T1;
			-- drop old table
			SET @sql = N'DROP TABLE @tbl_full@;'
			SET @sql = REPLACE(@sql, '@tbl_full@', @tbl_full)

			IF @debug = 1
				PRINT @sql
			ELSE
				EXEC sp_executesql @sql;

			-- rename new table
			SET @sql = 'EXEC SIA_Sandpit.dbo.sp_rename ''[@schema@].[@new_tbl@]'', ''@tbl@'''
			SET @sql = REPLACE(@sql, '@schema@', @schema)
			SET @sql = REPLACE(@sql, '@new_tbl@', @new_tbl)
			SET @sql = REPLACE(@sql, '@tbl@', @tbl)

			IF @debug = 1
				PRINT @sql
			ELSE
				EXEC (@sql)

		COMMIT TRANSACTION T1;
	END

END