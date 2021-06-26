/*
Get data type of a column
2021-01-29
Raj Kulkarni
*/

SELECT DISTINCT SQL_VARIANT_PROPERTY([name of variable], 'BaseType') AS BaseType
FROM [db].[schema].[table]
WHERE [name of variable] IS NOT NULL
