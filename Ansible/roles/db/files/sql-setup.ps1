# Install SQL Server
c:\temp\sql-server-2017.exe /ConfigurationFile="C:\temp\sql-config.ini" /MediaPath="C:\Temp\SQL" /iacceptsqlserverlicenseterms /indicateprogress=false /Q

# Create DB
# SQLPS
# Set-Location SQLSERVER:\SQL

# cd $env:COMPUTERNAME
# $srv = Get-Item $database

# $db = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Database -argumentlist $srv, "eb-${environment}-sc1"
# $db.create()