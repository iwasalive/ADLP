# Install carbon - management tool: http://get-carbon.org/
Install-Module Carbon -AllowClobber -Force
Import-Module Carbon

# Set account to login on as a service: https://stackoverflow.com/a/22155390/1297248
Grant-Priviledge -Identity $(whoami) "SeServiceLongonRight"

