/******************************************************************************
Condition for finding spells that overlap for the same person

Key rule is:
spell A starts before spell B ends
and
spell B starts before spell A ends

To understand the logic it is often easier to think of the reverse:
If spell A starts after spell B ends, then the two can not overlap as spell B starts and finishes before spell A starts.

This rule assumes start_date <= end_date for both spells.
******************************************************************************/
SELECT *
FROM table_A AS a
JOIN table_B AS b
ON a.snz_uid = b.snz_uid
AND a.start_date <= b.end_date
AND b.start_date <= a.end_date

/******************************************************************************
When two spells overlap, get just the period that overlaps

Assumes there is an overlap
We want to keep the latest start date - as both spells must have started for there to be an overlap,
and the earliest end date - as neither spell can have ended for there to be an overlap.
******************************************************************************/
SELECT *
	,IIF(start_a < start_b, start_b, start_a) AS trimmed_start -- latest start date
	,IIF(end_a < end_b    , end_a  , end_b  ) AS trimmed_end   -- earliest end date
FROM my_table

/******************************************************************************
Merge all overlapping spells
also called spell condensing

In the anti-join subclause WHERE NOT EXISTS (...)
can use DATEADD(DAY, n, ___) to merge spells that are within n days of each other.

For example:

WHERE s1.snz_uid = s2.snz_uid
AND s2.[start_date] < s1.[start_date]
AND s1.[start_date] <= DATEADD(DAY, 1, s2.[end_date])
-- this will merge adjacent, but not-overlapping, spells (are 1 day different)

******************************************************************************/

WITH
/* exclude start dates that are within another spell */
valid_spell_starts AS (
	SELECT [snz_uid]
	    ,[start_date]
	    ,[end_date]
	FROM my_table AS s1
	WHERE NOT EXISTS (
		SELECT 1
		FROM my_table AS s2
		WHERE s1.snz_uid = s2.snz_uid
		AND s2.[start_date] < s1.[start_date] -- must use inequality here otherwise every record matches to itself
		AND s1.[start_date] <= s2.[end_date]
	)
),
/* exclude end dates that are within another spell */
valid_spell_ends AS (
	SELECT [snz_uid]
	    ,[start_date]
	    ,[end_date]
	FROM my_table AS e1
	WHERE NOT EXISTS (
		SELECT 1 
		FROM my_table AS e2
		WHERE e1.snz_uid = e2.snz_uid
		AND e2.[start_date] <= e1.[end_date] 
		AND e1.[end_date] < e2.[end_date] -- must use inequality here otherwise every record matches to itself
	)
)
/* for each valid start date, find the minimum valid end date after it */
SELECT s.snz_uid
	,s.[start_date]
	,MIN(e.[end_date]) as [end_date]
FROM valid_spell_starts AS s
INNER JOIN valid_spell_ends AS e
ON s.snz_uid = e.snz_uid
AND s.[start_date] <= e.[end_date]
GROUP BY s.snz_uid, s.[start_date]

/******************************************************************************
Invert spells

For example:
- turn overseas spells into within-country spells
- turn EET spells into NEET spells

******************************************************************************/

WITH 
/* the non-spell after each spell */
non_spells_forward AS (

	SELECT [snz_uid]
		  ,DATEADD(DAY, 1, [end_date]) AS [start_date]
		  ,LEAD(DATEADD(DAY, -1, [start_date]), 1, '9999-01-01') OVER (
				PARTITION BY [snz_uid]
				ORDER BY [start_date]
			) AS [end_date]
	FROM input_table

),
/* the non-spell before any spell */
non_spell_backward AS (

	SELECT [snz_uid]
		  ,'1900-01-01' AS [start_date]
		  ,DATEADD(DAY, -1, MIN([start_date])) AS [end_date]
	FROM input_table
	GROUP BY [snz_uid]

),
/* all non-spells */
non_spells AS (

	SELECT * FROM non_spells_forward
	UNION ALL
	SELECT * FROM non_spell_backward
	
)
SELECT [snz_uid]
	  ,[start_date]
	  ,[end_date]
FROM non_spells
WHERE [start_date] <= [end_date]
AND '1900-01-01' <= [start_date] 
AND [end_date] <= '9999-01-01'
