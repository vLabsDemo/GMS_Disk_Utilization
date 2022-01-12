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
    [String]$DriveVal=$env:SNC_DriveName,

    [Parameter()]
    [String]$DiskThreshold=$env:SNC_DiskThreshold
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

$WNOutput = "";
$Action = "";

Try
{
    $WNOutput += "Checking Pre Disk Utilization for $DriveVal Drive on $env:computername`n";

    Try
    {
        $PreviousData = Get-WmiObject -class Win32_LogicalDisk -ErrorAction Stop|?{($_.DeviceID -eq $DriveVal) -and ($_.DriveType -eq 3)};

        $deviceID = $PreviousData.DeviceID;
        [float]$size = $PreviousData.Size;
        [float]$freespace = $PreviousData.FreeSpace; 
        $percentFree = ($freespace / $size) * 100;
        $percentFree1 = [math]::Round($percentFree,2);

        $sizeGB = ($size / 1073741824);
        $sizeGB1 = [math]::Truncate($sizeGB);

        $freeSpaceGB = ($freespace / 1073741824);
        $freeSpaceGB1 = [math]::Round($freeSpaceGB);

        $usedSpaceGB = $sizeGB1 - $freeSpaceGB1;	
        $percentUsed = 100 - $percentFree1;

        $WNOutput += "Disk Size: $sizeGB1 GB`nFree Space: $freeSpaceGB1 GB`nUsed Space: $usedSpaceGB GB`nCurrent Utilization: $percentUsed %`n";
    }

    Catch [Syste.Exception]
    {
        $WNOutput += "FAILED: Some Unexpected Error Has Occoured while Fetching initial Disk Utilization details`nERROR: $($_)`n";
    }

    if($DriveVal -eq "C:")
    {
        #C:\Windows\Temp
        Try
        {
            if(Test-Path C:\Windows\Temp)
            {
                $WNOutput += "Getting Temp Files at C:\Windows\Temp whcih are not touched for more than 7 days:`n";
                $WinTemp = Get-ChildItem C:\Windows\Temp -Recurse -File -ErrorAction Stop|Where-Object {$_.LastAccessTime -lt $(Get-Date).AddDays(-7)}|Out-String;
                $WNOutput += "$WinTemp`n";
            }
            Else
            {
                $WNOutput += "INFO: C:\Windows\Temp Directory doesn't exists`n";
            }
        }
        Catch [System.Exception]
        {
            $WNOutput += "FAILED: Some Unexpected Error Has Occoured while Fetching Files at C:\Windows\Temp directory`nERROR: $($_)`n";
        }

        #C:\inetpub\logs\LogFiles
        Try
        {
            if(Test-Path C:\inetpub\logs\LogFiles)
            {
                $WNOutput += "Getting Temp Files at C:\inetpub\logs\LogFiles whcih are not touched for more than 7 days:`n";
                $InetLog = Get-ChildItem C:\inetpub\logs\LogFiles -Recurse -File -ErrorAction Stop|Where-Object {$_.LastAccessTime -lt $(Get-Date).AddDays(-7)}|Out-String;
                $WNOutput += "$InetLog`n";
            }
            Else
            {
                $WNOutput += "INFO: C:\inetpub\logs\LogFiles Directory doesn't exists`n";
            }
        }
        Catch [System.Exception]
        {
            $WNOutput += "FAILED: Some Unexpected Error Has Occoured while Fetching Files at C:\inetpub\logs\LogFiles directory`nERROR: $($_)`n";
        }

        
        # List User Profiles
        Try
        {
            $WNOutput += "Getting List of All User Profiles on System:`n";
            $Profs = Get-WmiObject -ClassName Win32_UserProfile -ErrorAction Stop|?{$_.LocalPath -like "C:\Users*"}|Select-Object LocalPath,SID;
            $WNOutput += "$($Profs|Out-String)`n";
        }
        Catch [System.Exception]
        {
            $WNOutput += "FAILED: Some Unexpected Error Has Occoured while Fetching User Profiles`nERROR: $($_)`n";
        }

        # Delete User Profile Data
        Try
        {
            foreach ($Prof in $Profs)
            {
                $ProfilePath = $($Prof|Select-Object -ExpandProperty LocalPath);

                ########################################
                #\AppData\Local\Temp
                if(Test-Path $($ProfilePath + "\AppData\Local\Temp"))
                {
                    Try
                    {
                        $WNOutput += "Getting 7 Days Old \AppData\Local\Temp File for User Profile $ProfilePath on System:`n";
                        $LocTemps = Get-ChildItem "$($ProfilePath + "\AppData\Local\Temp")" -Recurse -File -ErrorAction Stop|Where-Object {$_.LastAccessTime -lt $(Get-Date).AddDays(-7)};
                        $WNOutput += "$($LocTemps|Out-String)`n";

                        $WNOutput += "\AppData\Local\Temp Cleanup Process started for User Profile $ProfilePath`n";

                        foreach($LocTemp in $LocTemps)
                        {
                            Try
                            {
                                #Remove-Item -Path "$($LocTemp|Select-Object -ExpandProperty FullName)" -Force -Confirm:$false -ErrorAction Stop;
                            }
                            Catch [System.Exception]
                            {
                                #$WNOutput += " FAILED: Unable to Delete $($LocTemp|Select-Object -ExpandProperty FullName)`nERROR: $($_)`n";
                            }
                        }
                        $WNOutput += "Above Files Deleted Successfully for User Profile $ProfilePath`n";

                    }
                    Catch [System.Exception]
                    {
                        $WNOutput += "FAILED: Some Unexpected Error Has Occoured while Fetching Files from $ProfilePath\AppData\Local\Temp`nERROR: $($_)`n";
                    }
                } # END: Local\Temp

                ##############################################
                #\AppData\Local\Microsoft\Windows\Temporary Internet Files
                if(Test-Path $($ProfilePath + "\AppData\Local\Microsoft\Windows\Temporary Internet Files"))
                {
                    Try
                    {
                        $WNOutput += "Getting 7 Days Old \AppData\Local\Microsoft\Windows\Temporary Internet Files for User Profile $ProfilePath on System:`n";
                        $TempInts = Get-ChildItem "$($ProfilePath + "\AppData\Local\Microsoft\Windows\Temporary Internet Files")" -Recurse -File -ErrorAction Stop|Where-Object {$_.LastAccessTime -lt $(Get-Date).AddDays(-7)};
                        $WNOutput += "$($TempInts|Out-String)`n";

                        $WNOutput += "\AppData\Local\Microsoft\Windows\Temporary Internet Files Cleanup Process started for User Profile $ProfilePath`n";

                        foreach($TempInt in $TempInts)
                        {
                            Try
                            {
                                #Remove-Item -Path "$($TempInt|Select-Object -ExpandProperty FullName)" -Force -Confirm:$false -ErrorAction Stop;
                            }
                            Catch [System.Exception]
                            {
                                #$WNOutput += " FAILED: Unable to Delete $($TempInt|Select-Object -ExpandProperty FullName)`nERROR: $($_)`n";
                                #$fso = New-Object -ComObject Scripting.FileSystemObject
                                #$fso.DeleteFile("$($TempInt|Select-Object -ExpandProperty FullName)",$true);
                            }
                        }
                        $WNOutput += "Above Files Deleted Successfully for User Profile $ProfilePath`n";

                    }
                    Catch [System.Exception]
                    {
                        $WNOutput += "FAILED: Some Unexpected Error Has Occoured while Fetching Files from $ProfilePath\AppData\Local\Microsoft\Windows\Temporary Internet Files`nERROR: $($_)`n";
                    }
                } # END: Temporary Internet Files

                ##############################################
                #*vhd, *iso
                Try
                {
                    $WNOutput += "Getting *iso, *vhd Files for User Profile $ProfilePath on System:`n";
                    $LargeFile = Get-ChildItem -Path "$ProfilePath\*" -Recurse -Include @("*.iso","*.vhd") -ErrorAction Stop;
                    $WNOutput += "$($LargeFile|Out-String)`n";
                }
                Catch [System.Exception]
                {
                    $WNOutput += "FAILED: Some Unexpected Error Has Occoured while Fetching Files from $ProfilePath\AppData\Local\Microsoft\Windows\Temporary Internet Files`nERROR: $($_)`n";
                }
                # END: *vhd, *iso

            } # For Each User Profiles    
        }
        Catch [System.Exception]
        {
            $WNOutput += "FAILED: Some Unexpected Error Has Occoured While Clening Up Profile Data`nERROR: $($_)`n";
        }

        #C:\Windows\SoftwareDistribution
        Try
        {
            if(Test-Path C:\Windows\SoftwareDistribution)
            {
                $WNOutput += "Getting *.log, *.jrs, *.edb, *.jfm, *.cab Files from at C:\Windows\SoftwareDistribution:`n";
                $SwDis = Get-ChildItem -Path C:\Windows\SoftwareDistribution\* -Recurse -Include @("*.log", "*.jrs", "*.edb", "*.jfm", "*.cab") -ErrorAction Stop;
                $WNOutput += "$($SwDis|Out-String)`n";
            }
            Else
            {
                $WNOutput += "INFO: C:\Windows\SoftwareDistribution doesn't exists`n";
            }
        }
        Catch [System.Exception]
        {
            $WNOutput += "FAILED: Some Unexpected Error Has Occoured while Fetching Files at C:\Windows\SoftwareDistribution`nERROR: $($_)`n";
        }

        $WNOutput += "Checking Post Disk Utilization for $DriveVal Drive on $env:computername`n";

        Try
        {
            $PostData = Get-WmiObject -class Win32_LogicalDisk -ErrorAction Stop|?{($_.DeviceID -eq $DriveVal) -and ($_.DriveType -eq 3)};

            $deviceIDP = $PostData.DeviceID;
            [float]$sizeP = $PostData.Size;
            [float]$freespaceP = $PostData.FreeSpace; 
            $percentFreeP = ($freespaceP / $sizeP) * 100;
            $percentFree1P = [math]::Round($percentFreeP,2);

            $sizeGBP = ($sizeP / 1073741824);
            $sizeGB1P = [math]::Truncate($sizeGBP);

            $freeSpaceGBP = ($freespaceP / 1073741824);
            $freeSpaceGB1P = [math]::Round($freeSpaceGBP);

            $usedSpaceGBP = $sizeGB1P - $freeSpaceGB1P;	
            $percentUsedP = 100 - $percentFree1P;

            $WNOutput += "Disk Size: $sizeGB1P GB`nFree Space: $freeSpaceGB1P GB`nUsed Space: $usedSpaceGBP GB`nCurrent Utilization: $percentUsedP %`n";
        }

        Catch [Syste.Exception]
        {
            $WNOutput += "FAILED: Some Unexpected Error Has Occoured while Fetching Post Disk Utilization details`nERROR: $($_)`n";
        }

        if($percentUsedP -lt $DiskThreshold)
        {


            $WNOutput += "After Cleanup Process, Disk Utilization is now Normal`n Hence resolving the Incident";
            $Action = "Resolve the Ticket"
            $overall_status = "Success";
        }
        Else
        {
            $WNOutput += "Post Cleanup Process, Disk Utilization is still higher than Threshold $DiskThreshold`nReassign the Incident to Next Manual Queue";
            $Action = "Reassign to Next Manual Queue";
            $overall_status = "Success";
        }
    }
    Else
    {
        $WNOutput += "Drive is Other than C:, Needs to be checked manually by Support Engineer`nReassign the Incident to Next Manual Queue"
        $Action = "Reassign to Next Manual Queue";
        $overall_status = "Success";
    }

}
Catch [System.Exception]
{
    $WNOutput += "FAILED: Some Unexpected Error Has Occoured`nERROR: $($_)`n";
    $Action = "Reassign to Next Manual Queue";
    $overall_status = "Failure";
}

#Write-Output $WNOutput
#Write-Output $Action


$Obj_Output = @();

$Obj_Output += New-Object psobject -Property @{
    WorkNoteValue = "$WNOutput"
    Action = "$Action"
}

$Json_Output = $($Obj_Output|ConvertTo-Json);

output-format $FileName_WithoutExtension $global:time $ServerName $conn_type $Json_Output $overall_status
$global:jsonRequest|Out-File -FilePath .\JsonOutput.txt