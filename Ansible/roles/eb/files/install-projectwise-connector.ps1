# run msi 
Run-MSI("...\Server Installation\eB ProjectWise Connector")

# stop services 
Stop-EbService

# Apply hotfix 
Copy-Files("ProjectWise.2.2.2.Mssql.zip", $ebDatabasePath)

# restart service 
Start-EbService

# Update data source using bently management console 
Call SikuliX method to accomplish this


# Install ProjectWise Gateway Service
Run-MSI("...\ProjectWise-Gateway")
Run-MSI("...\ProjectWise-Prerequisites")

# Deploy dmskrnl.cfg
# Doing this through Ansible with tokens would be nice 

# Restart PW Gateway service 
Restart-Service PWConSrv

# Install ProjectWise Explorer
Run-MSI("...\ProjectWise-Prerequisites")

# Config PW intergration settings 
# sikuliX 