DECLARE @tableHTML  NVARCHAR(MAX) ;

 SET @tableHTML =
  N'<H1>Databases Backup Report</H1>' +
  N'<table border="1">' +
  N'<tr><th>Server Name</th><th>DatabaseName</th>
  <th>[BackupStartDate]</th>
  <th>[BackupFinishDate]</th>
  <th>[Status24hrs]</th>
  <th>[BackupAge (Hours)]</th>
  <th>BackupSizeGB</th>
  <th>Type</th>
  <th>DaysSinceLastBackup</th>
  </tr>' +
  CAST ( (   
  Select 
  td=SERVERPROPERTY('ServerName'),' ',
  td=db.name,' ',
  td =CONVERT(VARCHAR(10), b.backup_start_date, 103) +   + convert(VARCHAR(8), b.backup_start_date, 14),' ',
  td=CONVERT(VARCHAR(10), b.backup_finish_date, 103) +   + convert(VARCHAR(8), b.backup_finish_date, 14),' ',
  td= case
		when (DATEDIFF(hour, b.backup_start_date, getdate())<24)then 'Success'
		when (DATEDIFF(hour, b.backup_start_date, getdate())>=24)then 'Failed'
	  end,' ',
td= DATEDIFF(hh, b.backup_finish_date, GETDATE()),' ',
td=(b.backup_size/1024/1024/1024 ),' ',
td=case b.[type]
WHEN 'D' THEN 'Full'
WHEN 'I' THEN 'Differential'
WHEN 'L' THEN 'Transaction Log'
END ,' ',
td=ISNULL(STR(ABS(DATEDIFF(day, GetDate(),(Backup_finish_date)))), 'NEVER'),' '
FROM sys.sysdatabases db 
Left OUTER JOIN (SELECT * , ROW_NUMBER() OVER(PARTITION BY database_name ORDER BY backup_finish_date DESC) AS RNUM
FROM msdb.dbo.backupset) b ON b.database_name = db.name  AND RNUM = 1
where dbid<>2
      FOR XML PATH('tr'), TYPE 
  ) AS NVARCHAR(MAX) ) +
  N'</table>' ;

 EXEC msdb.dbo.sp_send_dbmail @recipients='pjayaram@appvion.com',
  @subject = 'Database Backup',
  @body = @tableHTML,
  @body_format = 'HTML' ;
  