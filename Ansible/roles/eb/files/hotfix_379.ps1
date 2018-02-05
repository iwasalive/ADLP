$ebSharedPath = "C:\Program Files\Bentley\eB\Shared"
$ebServerPath = "C:\Program Files\Bentley\eB\Server"
$gacPath = "%windir%\Microsoft.NET\assembly"

# Get all apps
function Get-ComServices() {
    $comAdmin = New-Object -com ("COMAdmin.COMAdminCatalog.1")
    $applications = $comAdmin.GetCollection("Applications") 
    $applications.Populate() 
}

# Shut down and disable
function Stop-EbService() {
    Get-ComServices

    # Stop eb 
    Stop-Service "eB Service Manager"

    # Stop
    $ebInsightApp = $applications | ? {$_.name -eq "eB Insight"}
    $comAdmin.ShutdownApplication("eB Insight")
    $ebInsightApp.Value("IsEnabled") = $false
    $applications.SaveChanges()
}

# Enable application and start
function Start-EbService() {
    Get-ComServices 

    # Start eb service
    Start-Service "eB Service Manager"

    # Start COM eb service
    $ebInsightApp.Value("IsEnabled") = $true
    $comAdmin.StartApplication("eB Insight")
    $applications.SaveChanges()
}


# Copy to Shared Folder 
cd "c:\temp\hotfixes\hotix_379\v15.6.1-HF00379"

# Extract hotfix 
Expand-Archive c:\temp\hotfix_379.zip -Destination c:\temp\hotfixes\hotix_379

function Copy-Files() {   
    [cmdletbinding()]
    param(
        [Parameter(Mandatory = $true)][string] $files,
        [Parameter(Mandatory = $true)][string] $destination,
        [Parameter(Mandatory = $false)] [switch] $recurse
    )

    foreach ($file in $files) {
        try {
            Copy-Item $file -Destination $destination $isRecursive -Recurse:$recurse
        }
        catch {
            Write-Host "Failed to copy $file" -ForegroundColor Red
        }
    }
}

### Update Instructions: Application/ Print/Index Server ###

Stop-EbService

$updateSharedDLLs = "eB.Common.dll", "eB.Service.Index.dll", "eB.Service.Proxy.dll"

Copy-Files($updateSharedDLLs, $ebSharedPath)
Copy-Files($updateSharedDLLs, $gacPath)

Copy-Files($abdobeResourceFolderPath, "$ebSharedPath\Adobe", $true)

Copy-Files("eB.Service.Storage.exe", $ebServerPath)
Copy-Files("eB.Driver.ProjectWise.dll", "$ebServerPath\Drivers")


$engineFiles = "ClosedXML.dll", "DocumentFormat.OpenXml.dll", "Engine.ActiveDirectory.dll", "Engine.BulkTransaction.dll", "Engine.ECEngine.dll", "Engine.ExecuteSSISPackage.dll", "Engine.InterPlotEngine.dll", "Engine.ProjectWise.dll", "Engine.SnapshotCapture.dll"

Copy-Files($engineFiles, "$ebServerPath\Engines")

$dataParserPaths = "C:\Program Files\Common Files\Bentley Shared\eB SSIS\DataParser", "C:\Program Files (x86)\Common Files\Bentley Shared\eB SSIS\DataParser"

Copy-Files("Bentley.DataParser.dll", $dataParserPaths[0])
Copy-Files("Bentley.DataParser.dll", $dataParserPaths[1])

# Restart eB Service Manager 
Start-EbService


### Update Instructions: Database ###

$ebDatabasePath = "C:\Program Files\Bentley\eB\Server\Database"

Copy-Files("Core.15.6.1.Mssql.zip", $ebDatabasePath)
Copy-Files("Nuclear.5.4.2.Mssql.zip", $ebDatabasePath)
Copy-Files("ETM.2.2.2.Mssql.zip", $ebDatabasePath)
Copy-Files("ProjectWise.2.2.2.Mssql.zip", $ebDatabasePath)
Copy-Files("StagedImport.15.6.1.Mssql.zip", $ebDatabasePath)

### Update Instructions: Web Server ###

# run msi 
function Run-MSI($path) {
    $errorFile = $path.split("\")[-1]
    try {
        msiexec.exe /log "c:\logs\$errorFile" /i $path /qn /passive
    } catch {
        Write-Host "failed to run msi"
    }
}

# Update binaries (uninstall install but this is first run so just install)
Run-MSI("..\eB Web Applications (x86).msi")
Run-MSI("..\eB Change Package Plug-In (x86).msi")
Run-MSI("..\eB Engineering Designer Web Plug-Ins (x86).msi")
Run-MSI("..\eB ETM (x64).msi")
Run-MSI("..\eB Bulk Transfer Configuration Tool (x86)")
Run-MSI("..\eB CAD Connect (x86)")
Run-MSI("..\eB Director (x86)")
Run-MSI("..\eB Engineering Designer (x86)")

