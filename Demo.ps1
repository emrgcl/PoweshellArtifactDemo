$NugetFolder = 'C:\Temp'
$LocalRepo = 'C:\Repos\PSModulesv2'
$patToken = 'izltzcaslejgm3wt272c4ijztr2dpeyokocpfbthehofb2dkuxjq'
$FeedName = 'PowerShellModules1'
$FeedLocation = "https://pkgs.dev.azure.com/emrgcl/PSModulesv2/_packaging/$FeedName/nuget"
$ModuleName = 'ArtifactDemo'


# Prepare AzureDevops
# 1) Create a PAT in org settings / Dont Forget to copy the token you will need to regenerate if not copied - jhklevglah36diivtwshbxwd2cq3wnvhmktyltahocolcthzvcbq / https://dev.azure.com/emrgcl/PSModulesv2/
# 2) Create a Artifact Feed 

# Prepare the Nuget Package

# 1) Download Nuget nuget exe from https://www.nuget.org/downloads to c:\temp

$sourceNugetExe = "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe"
$targetNugetExe = "$NugetFolder\nuget.exe"
Invoke-WebRequest $sourceNugetExe -OutFile $targetNugetExe

# 2) Set the version in Get-help.psd1  ModuleVersion to 1.0.x (3 digits) to be used in nuget package
psedit "$LocalRepo\$ModuleName\$ModuleName.psd1"

# 3) CD into working folder which is the module folder
Cd "$LocalRepo\$ModuleName"
gci 


# 4) Create the nuspec file
invoke-expression "$NugetFolder\nuget.exe spec $ModuleName -Force"
gci 

# 5) Edit the nuspec file, a) Version should match with the one in psd1 file, b) remove the sample dependency within <Dependencies>
psedit "$LocalRepo\$ModuleName\$ModuleName.nuspec"

# 6) pack the files using nuget file Get-Hello.nuspec
invoke-expression "$NugetFolder\nuget.exe pack $ModuleName.nuspec"

# 7) Move the Package to Packages folder (lets be tidy!)
Move-Item -Path "$LocalRepo\$ModuleName\*.nupkg" -Destination "$LocalRepo\packages"
Get-ChildItem -Path "$LocalRepo\Packages"

# 8) add the Azure Devops Services Repo as a source for Nuget
c:\temp\nuget.exe sources Add -Name $FeedName -Source "$($FeedLocation)/v3/index.json" -username "emreg@microsoft.com" -password $patToken
invoke-expression "$NugetFolder\nuget.exe push -Source $FeedName -ApiKey AZ $LocalRepo\Packages\$ModuleName.1.0.5.nupkg"


# Register to Repository

# 1) Create Credential
$patTokenCred = $patToken | ConvertTo-SecureString -AsPlainText -Force 
$credsAzureDevopsServices = New-Object System.Management.Automation.PSCredential("emreg@microsoft.com", $patTokenCred)

# 2) Register to repository
Get-PSRepository | ft -AutoSize
Register-PSRepository -Name "PowershellAzureDevopsServices" -SourceLocation "$($FeedLocation)/v2"  -PublishLocation "$($FeedLocation)/v2" -InstallationPolicy Trusted -Credential $credsAzureDevopsServices

# 3) Verify the repository
Get-PSRepository | ft -AutoSize

# 4) lets see powershell modules folder

gci -path (($Env:PSModulePath -split ';')[1]) | ? Name -eq $ModuleName

# 5) LEts see if the module sits in our repo :) 
Find-Module -Repository PowershellAzureDevopsServices -Credential $credsAzureDevopsServices

# Install Module  and use
# 1) Install Module
Install-Module -Name $ModuleName -Repository PowershellAzureDevopsServices -Credential $credsAzureDevopsServices

# 2) lets see powershell modules folder

gci -path (($Env:PSModulePath -split ';')[1]) | ? Name -eq $ModuleName

# 3) ImportModule and run

Import-Module ArtifactDemo
Get-Hello
