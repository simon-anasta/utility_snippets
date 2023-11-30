/*
Fetch SQL text defined by prefix

Key idea is to locate the end of the text by looking for a space on the end.
Does require that text does do not include space, brackets, or newline characters.
Which seems a pretty safe requirement.
*/

DECLARE @input_text NVARCHAR(MAX)
	, @found INT
	, @start INT
	, @end INT
	, @content NVARCHAR(500)
	, @prefix NVARCHAR(20)

SET @input_text = '
DROP TABLE dbo.my_table
CREATE TABLE dbo.my_table (
col1 INT,
col2 CHAR(1)
)
'

SET @prefix = 'DROP TABLE '

-- text cleaning
SET @input_text = REPLACE(@input_text, '(', ' (') -- brackets add a space before
SET @input_text = REPLACE(@input_text, CHAR(13) + CHAR(10), ' ') -- newline becomes space
SET @input_text = REPLACE(@input_text, '  ', ' ') -- double space becomes single space
-- add additional cleaning rules here as required

PRINT @input_text

-- locate
SET @found = IIF(CHARINDEX(@prefix, @input_text) > 0, 1, 0)
SET @start = CHARINDEX(@prefix, @input_text) + LEN(@prefix) + 1
SET @end = CHARINDEX(' ', @input_text, @start)

PRINT @found
PRINT @start
PRINT @end

-- extract suffix
SET @content = SUBSTRING(@input_text, @start, @end - @start)

PRINT @content
