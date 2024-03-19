/*
A simple pattern for loops in SQL
2024-03-20
*/

--------------------------------------------------
-- What we want to loop over
--------------------------------------------------

SELECT schema_name
    ,table_name
	,column_name
INTO #cursor_table
FROM source_tables

SELECT TOP 10 *
FROM #cursor_table

-- confirm that for each row I want to do the same thing

-- write out examples of the query you would run
select distinct 'schema1.table1', column1
from schema1.table1

-- made with copy & paste manually
select distinct 'schema2.table2', column2
from schema2,table2

-- observe that these queries can be made via copy & paste from the table
-- let's get the computer to copy & paste for us automatically

--------------------------------------------------
-- create table to hold results
--------------------------------------------------

CREATE TABLE #output
(
  source_table VARCHAR(1000),
  column_value VARCHAR(100)
)
-- the examples on lines 22-27 have 2 output columns so this table needs two output columns

-- this allows us to write results to a location we can review later
-- so all the copy & paste queries can run and we will review once at the end

--------------------------------------------------
-- iterate
--------------------------------------------------

-- 1) give parts some names
DECLARE @schema VARCHAR(50)
DECLARE @table VARCHAR(50)
DECLARE @column VARCHAR(50)
-- #cursor_table has 3 columns hence we need three variables

DECLARE @sql_code VARCHAR(2000)

-- 2) make the cursor
DECLARE db_cursor CURSOR FOR 
SELECT *
FROM #cursor_table
-- for testing can use SELECT TOP 10 * on line 60

-- 3) get first row from into named pieces
OPEN db_cursor  
FETCH NEXT FROM db_cursor INTO @schema, @table, @column
-- #cursor_table has 3 columns hence we need three variables

-- 4) start iterating
WHILE @@FETCH_STATUS = 0  
BEGIN  
	-- interesting / custom part
	SELECT @sql_code = 'insert into #output select distinct ''@schema.@table'', @column from @schema.@table'
	-- this query should match those on lines 22-27
	
	-- replace (copy & paste)
	SET @sql_code = REPLACE(@sql_code, '@schema', @schema)
	SET @sql_code = REPLACE(@sql_code, '@table', @table)
	SET @sql_code = REPLACE(@sql_code, '@column', @column)
	-- #cursor_table has 3 columns hence we need three variables

	-- check what will run
	PRINT (@sql_code)
	-- comment out when executing
	
	
	-- run code
	EXEC (@sql_code)
	-- comment out if just testing

	-- get next value from cursor
	FETCH NEXT FROM db_cursor INTO @schema, @table, @column 
	-- #cursor_table has 3 columns hence we need three variables
END 

-- 5) tidy up
CLOSE db_cursor  
DEALLOCATE db_cursor

-- 6) review results
SELECT *
FROM #output

/*
Most of this code is boiler plate - standardised code that will not need adjusting.

The key things to adjust are
1) The creation of the input table, lines 10-14
2) The test queries, lines 22-27
3) The #output table should match the number of columns produced by the test queries, lines 37-40
4) The number of variables declared should match the number of columns in the input table, lines 51-53
5) When fetching from cursor, we need to list all the declared variables, lines 66 and 92
6) A general form of the test queries should be written into the look, lines 73
7) We replace each variable in the test query, same as the number of variables, lines 77-79

This is ~25 lines to update out of 100 lines.
So 75% of this code is standard/boiler plate code.
*/
