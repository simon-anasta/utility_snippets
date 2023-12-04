/*
Access permissions are managed via roles.

For each role, find all the tables that the role grants permissions for
*/

USE IDI_Clean_YYYYMM
GO

SELECT DISTINCT rp.name AS role_name
	, PermissionType = pm.class_desc
	, COALESCE(ss1.name, ss2.name) AS [schema_name]
	, COALESCE(obj1.name, obj2.name) AS [table_name]
	, COALESCE(ss1.name, ss2.name) + '.' + COALESCE(obj1.name, obj2.name) AS full_name
	--, pm.permission_name
	--, pm.state_desc AS permission_state
				
FROM sys.database_principals AS rp
INNER JOIN sys.database_permissions AS pm
ON rp.principal_id = pm.grantee_principal_id

/*
permissions grant direct table access
schema follows from table
*/
LEFT JOIN sys.objects obj1
ON pm.major_id = obj1.[object_id]
AND pm.class_desc = 'OBJECT_OR_COLUMN'
LEFT JOIN sys.schemas AS ss1
ON obj1.[schema_id] = ss1.schema_id

/*
permissions grant schema access
all contained tables included
*/
LEFT JOIN sys.schemas AS ss2
ON pm.major_id = ss2.schema_id
AND pm.class_desc = 'SCHEMA'
LEFT JOIN sys.objects AS obj2
ON ss2.schema_id = obj2.[schema_id]

WHERE  rp.type_desc = 'DATABASE_ROLE' 
AND rp.name <> 'public'
AND pm.class_desc <> 'DATABASE' 
AND pm.state_desc = 'GRANT'
