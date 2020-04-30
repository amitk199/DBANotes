DECLARE
@EmailSubject varchar(100),
@TextTitle varchar(100),
@TableHTML nvarchar(max),
@Body nvarchar(max),
@DBName varchar(50)

SET @DBName = 'Database Name'
SET @EmailSubject = 'Missing Index Suggestion For ' + @DBName + ' Database'
SET @TextTitle = 'Missing Index Suggestion For ' + @DBName + ' Database'
SET @TableHTML =
'<html>'+
'<head><style>'+
-- Data cells styles / font size etc
'td {border:1px solid #ddd;padding-left:5px;padding-right:5px;padding-top:1px;padding-bottom:1px;font-size:10pt}'+
'</style></head>'+
'<body>'+
-- TextTitle style
'<div style="margin-top:15px; margin-left:15px; margin-bottom:15px; font-weight:bold; font-size:13pt; font-family:calibri;">' + @TextTitle +'</div>' +
-- Color and columns names
'<div style="font-family:Calibri; "><table>'+'<tr bgcolor=#00881d>'+
'<td align=left><font face="calibri" color=White><b>Database Name</b></font></td>'+ -- Database Name
'<td align=left><font face="calibri" color=White><b>Table Name</b></font></td>'+ -- Table Name
'<td align=left><font face="calibri" color=White><b>Equality Columns</b></font></td>'+ -- Equality Columns
'<td align=left><font face="calibri" color=White><b>Inequality Columns</b></font></td>'+ -- Inequality Columns
'<td align=left><font face="calibri" color=White><b>Included Columns</b></font></td>'+  -- Included Columns
'<td align=left><font face="calibri" color=White><b>Overal Impact Value</b></font></td>'+ -- Overal Impact Value
'<td align=left><font face="calibri" color=White><b>Create Index Statement</b></font></td>'+ -- Create Index Statement
'</tr></div>'

----------------------------------------------------------
----- Querying the plan cache for missing indexes --------
----------------------------------------------------------
IF OBJECT_ID('tempdb..#MissingIndexTable') IS NOT NULL DROP Table #MissingIndexTable
SELECT
  @DBName  as db_name,
  mid.statement as table_name,
  IsNull(mid.equality_columns, '') as equality_columns, 
  IsNull(mid.inequality_columns, '') as inequality_columns,
  IsNull(mid.included_columns, '') as included_columns,
  migs.avg_total_user_cost * migs.avg_user_impact * (migs.user_seeks + migs.user_scans) AS overal_impact_value,
  'CREATE INDEX [NCIX_' + REPLACE(REPLACE(REPLACE(mid.equality_columns, '[', ''), ']',''),',','_')+ ']' 
  + ' ON ' + mid.statement
  + ' (' + ISNULL (mid.equality_columns,'')
  + CASE WHEN mid.equality_columns IS NOT NULL AND mid.inequality_columns IS NOT NULL THEN ',' ELSE '' END
  + ISNULL (mid.inequality_columns, '')
  + ')'
  + ISNULL (' INCLUDE (' + mid.included_columns + ')', '') AS create_index_statement

into  #MissingIndexTable
FROM sys.dm_db_missing_index_groups mig
INNER JOIN sys.dm_db_missing_index_group_stats migs ON migs.group_handle = mig.index_group_handle
INNER JOIN sys.dm_db_missing_index_details mid ON mig.index_handle = mid.index_handle
LEFT OUTER JOIN sys.databases dbs ON mid.database_id=dbs.database_id
WHERE migs.avg_total_user_cost * migs.avg_user_impact * (migs.user_seeks + migs.user_scans) > 1000 and dbs.database_id > 4

----------------------------------------------------------
----------------------------------------------------------

SELECT @Body =(
SELECT
td = @DBName,
td = table_name,
td = equality_columns,
td = inequality_columns,
td = included_columns,
td = CONVERT(DECIMAL(16,2),overal_impact_value),
td = create_index_statement
FROM
#MissingIndexTable
ORDER BY CONVERT(DECIMAL(16,2), overal_impact_value) desc
for XML raw('tr'), elements)

SET @body = REPLACE(@body, '<td>', '<td align=left><font face="calibri">')
SET @tableHTML = @tableHTML + @body + '</table></div></body></html>'
SET @tableHTML = '<div style="color:Black; font-size:8pt; font-family:Calibri; width:auto;">' + @tableHTML + '</div>'

exec msdb.dbo.sp_send_dbmail
@profile_name = 'Your Database Mail Profile',
@recipients = 'recipient@email.com',
@body = @tableHTML,
@subject = @emailSubject,
@body_format = 'HTML'

