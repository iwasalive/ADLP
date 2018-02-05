# msiexec.exe /log logfile-projectwise.txt /i "C:\software\BentleyDownloads\ebi150601115en\Server Installation\eB Engineering Designer Database Files\eB Engineering Designer Database Files (x64).msi" /qn /passive

# msiexec.exe /log logfile-projectwise.txt /i "C:\Users\sunlab\
# Downloads\BentleyDownloads\ebi150601115en\Server Installation\eB ProjectWise Connector\eB ProjectWise Database Files (x64).msi" /qn /passive

# msiexec.exe /log logfile-projectwise.txt /i "C:\Users\sunlab\
# Downloads\BentleyDownloads\ebi150601115en\Server Installation\eB SSIS Components\eB SSIS Components (x64).msi" /qn /passive


# Stop eb 
Stop-Service "eB Service Manager"

# Get all apps
$comAdmin = New-Object -com ("COMAdmin.COMAdminCatalog.1")
$applications = $comAdmin.GetCollection("Applications") 
$applications.Populate() 

# Shut down and disable
$ebInsightApp = $applications | ? {$_.name -eq "eB Insight"}
$comAdmin.ShutdownApplication("eB Insight")
$ebInsightApp.Value("IsEnabled") = $false
$applications.SaveChanges()

# Enable application and start
$ebInsightApp.Value("IsEnabled") = $true
$comAdmin.StartApplication("eB Insight")
$applications.SaveChanges()

# eB Shared Path
$ebSharedPath = "C:\Program Files\Bentley\eB\Shared"

# Call Scripts 

Invoke-sqlcmd -ServerInstance $server -Database $db -InputFile $filename

$listOfFiles | % { Invoke-sqlcmd -ServerInstance $server -Database $db -InputFile $_ } 

$iisAppName = "MyApp"

# IIS disable anon auth and windows auth 
Write-Host Disable anonymous authentication
Set-WebConfigurationProperty -Filter "/system.webServer/security/authentication/anonymousAuthentication" -Name Enabled -Value False -PSPath IIS:\ -Location "Default Web Site/$iisAppName"

Write-Host Enable windows authentication
Set-WebConfigurationProperty -Filter "/system.webServer/security/authentication/windowsAuthentication" -Name Enabled -Value True -PSPath IIS:\ -Location "Default Web Site/$iisAppName"