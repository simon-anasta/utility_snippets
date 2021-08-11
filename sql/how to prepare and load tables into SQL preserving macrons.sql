/*
How to prepare and load tables into SQL while preserving macrons.
Author: Simon Anastasiadis

Motivation:
Characters in text containing Te reo Mäori can contain macrons above vowels.
For example: "Ngäi" and "Hapü". However, these are treated as non-standard
characters by some software and if not handled correctly can be lost when
transfering data between different softwares.

One context this applies is loading data files (e.g. tables from Excel)
(.xlsx format) into SQL server while preserving this formatting.

Key technical details:
To transfer letters with macrons into SQL they must be encoded/stored as Unicode
(UTF-8). As unicode is not the default format for many programs, we need to be
deliberate exporting and importing the data in this format.

File preparation:
Given the Excel file containing the table the following process outputs a
Unicode file suitable for importing:
1) Open the Excel file
2) Click 'save as"
3) Enter the file name
4) Underneath the filename field there should be a drop-down menu labelled
	"Save as type". Select "Unicode Text (*.txt)".
5) Click Save.
6) Avoid opening and resaving the new file. If you open the new file to
	inspect its contents do not save when you close the file.

File loading:
The code below imports a unicode text file into SQL server. Notes are provided
with each section explaining key details. Review the code and notes, update
as needed, and run.

File history:
2021-04-19 SA version 1
*/

/************************************************
Delete table if it exists
*************************************************
Update to match the database, schema, and table name where you want the new
table to be located.
Ensure that the same database, schema, and table names are used throughout
the file.
*/
IF OBJECT_ID('[database_name].[schema_name].[table_name]', 'U') IS NOT NULL
DROP TABLE [database_name].[schema_name].[table_name];
GO

/************************************************
Create empty table
*************************************************
This command requires one row for each column in the input file.
When updating, I recommend copying the column names from Excel directly
into this file. Best practice is for column names to use underscores ("_")
instead of spaces (" ") and to not contain any special characters.

We use NCHAR and NVARCHAR instead of CHAR and VARCHAR as the N prefix
indicates that the column will be of type unicode.

The number in brackets after NCHAR or NVARCHAR is the maximum number of characters
for the column. Current values are based of the original input file. Importing
will likely fail if a cell contains more characters than allowed.
You can use the LEN() function in Excel to check the number of characters in a
cell should you need to update the size of these columns.
*/
CREATE TABLE [database_name].[schema_name].[table_name] (
	col1	NCHAR(4),
	col2	NVARCHAR(85),
	col3	NCHAR(4),
	col4	NVARCHAR(85),
	col5	NVARCHAR(45),
);
GO

/************************************************
Read data file in to SQL
*************************************************
SQL Server requires the full file path when working on a network drive. It can not
use drive mappings. So "I:\my folder\my file.txt" will fail if "I:" is a network location.
Instead you will need to enter the drive name "\\drive\drive folder\my folder\my file.txt".

DATAFILETYPE = 'widechar' and CODEPAGE = '65001' are the settings for reading Unicode files.
FIRSTROW = 2 indicates that the data starts on row 2, because row 1 is column names.
FIELDTERMINATOR = '\t' indicates that the file is tab seperated.
*/
BULK INSERT [database_name].[schema_name].[table_name]
FROM '\\drive\drive folder\folder\folder\file name.txt'
WITH (
	DATAFILETYPE = 'widechar',
	CODEPAGE = '65001',
	FIRSTROW = 2,
	FIELDTERMINATOR = '\t',
	ROWTERMINATOR = '\n',
	TABLOCK
);
GO

/************************************************
View table contents to confirm performance
*************************************************
Recommended to confirm loading is correct.
For small tables, you can copy the entire contents back into Excel and test
that all cells are equal. If you do this, note that the order of the rows may
have changed.
*/
SELECT *
FROM [database_name].[schema_name].[table_name]
