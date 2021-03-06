<#
 The sample scripts are not supported under any Microsoft standard support 
 program or service. The sample scripts are provided AS IS without warranty  
 of any kind. Microsoft further disclaims all implied warranties including,  
 without limitation, any implied warranties of merchantability or of fitness for 
 a particular purpose. The entire risk arising out of the use or performance of  
 the sample scripts and documentation remains with you. In no event shall 
 Microsoft, its authors, or anyone else involved in the creation, production, or 
 delivery of the scripts be liable for any damages whatsoever (including, 
 without limitation, damages for loss of business profits, business interruption, 
 loss of business information, or other pecuniary loss) arising out of the use 
 of or inability to use the sample scripts or documentation, even if Microsoft 
 has been advised of the possibility of such damages. 
#>

Param(
[Parameter(Mandatory = $true, position = 0)][string] $ServerName,
[Parameter(Mandatory = $true, position = 1)][string] $FilePath
)
if(Test-Path $FilePath)
{
        #check if the instance name is available on the server
        
         [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo") |Out-Null
         $srv = New-Object ('Microsoft.SqlServer.Management.Smo.Server') $ServerName 
         if($ServerName.contains($env:COMPUTERNAME) -and ($srv.VersionString))
         {
            $jobs = $srv.JobServer.Jobs | Where-Object {$_.category -notlike "*repl*" -and $_.category -notlike "*shipping*" 

#-and $_.category -notlike "*Maintenance*" 

}  
 
            ForEach ( $job in $jobs) 
               { 
                     $jobname = $FilePath +'\' + $job.Name.replace(" ","_").replace("\","_").replace("[","_").replace("]","_").replace(".","_").replace(":","_").replace("*","_") + ".sql" 
                     $job.Script() | Out-File $jobname 
                Write-Host 'Scripting out ' $job ' successfully!'
               }
         }
        else 
        {
        Write-Host 'The server name you entered is not available!'
        }

}
else
{
Write-Host 'The path does not exist, please retype again!'
}