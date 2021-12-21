<#
.SYNOPSIS

    File Name:      HPE-GMS_Utilities_Disk_Utilization_Check_Cleaup.ps1
    Description:    Disk Utilization
    Script Owner:   ITOM Team, Tools Engineering
    Created By :    Anirudha Bagchi
    Version:        V.1.0
    Created Date:   21/12/2021
    Updated Date:   08/10/2020

    Requires powershell -Version 3.0
#>

[cmdletbinding()]
Param
(
    [Parameter()]
    [String]$ServerName=$env:SNC_TargetHostName,

    [Parameter()]
    [String]$ServiceName=$env:SNC_CheckServiceName
)

$ErrorActionPreference = "SilentlyContinue";
    
$ScriptPath = Split-Path $MyInvocation.MyCommand.Path;
$ScriptFile_Name = $script:MyInvocation.MyCommand.Name;
$ScriptFile_FullName = $script:MyInvocation.MyCommand.Path;
    
$FileName_WithoutExtension = [io.path]::GetFileNameWithoutExtension($ScriptFile_FullName);
$function_file = $ScriptPath + "\" + "HPE-AMS_GeneralFunction.ps1";

. "$PSScriptRoot\HPE-AMS_GeneralFunction.ps1";

timestamp

$conn_type = "WMI";