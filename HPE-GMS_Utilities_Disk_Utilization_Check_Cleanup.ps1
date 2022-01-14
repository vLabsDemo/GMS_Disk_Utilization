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

    if($DriveVal -eq "C:")
    {

        $ErrCleanup = @();
        $CleanupData = @();

        Try
        {
            $cleanup_status = "";
            $CleanupData = Invoke-Command -ComputerName $ServerName -Credential $cred -ScriptBlock {

                $CleanUpLog = "";
                #C:\Windows\Temp
                Try
                {
                    if(Test-Path C:\Windows\Temp)
                    {
                        $CleanUpLog += "Getting Temp Files at C:\Windows\Temp whcih are not touched for more than 7 days:`n";
                        $WinTemp = Get-ChildItem C:\Windows\Temp -Recurse -File -ErrorAction Stop|Where-Object {$_.LastAccessTime -lt $(Get-Date).AddDays(-7)}|Out-String;
                        $CleanUpLog += "$WinTemp`n";
                    }
                    Else
                    {
                        $CleanUpLog += "INFO: C:\Windows\Temp Directory doesn't exists`n";
                    }
                }
                Catch [System.Exception]
                {
                    $CleanUpLog += "FAILED: Some Unexpected Error Has Occoured while Fetching Files at C:\Windows\Temp directory`nERROR: $($_)`n";
                }

                #C:\inetpub\logs\LogFiles
                Try
                {
                    if(Test-Path C:\inetpub\logs\LogFiles)
                    {
                        $CleanUpLog += "Getting Temp Files at C:\inetpub\logs\LogFiles whcih are not touched for more than 7 days:`n";
                        $InetLog = Get-ChildItem C:\inetpub\logs\LogFiles -Recurse -File -ErrorAction Stop|Where-Object {$_.LastAccessTime -lt $(Get-Date).AddDays(-7)}|Out-String;
                        $CleanUpLog += "$InetLog`n";
                    }
                    Else
                    {
                        $CleanUpLog += "INFO: C:\inetpub\logs\LogFiles Directory doesn't exists`n";
                    }
                }
                Catch [System.Exception]
                {
                    $CleanUpLog += "FAILED: Some Unexpected Error Has Occoured while Fetching Files at C:\inetpub\logs\LogFiles directory`nERROR: $($_)`n";
                }

        
                # List User Profiles
                Try
                {
                    $CleanUpLog += "Getting List of All User Profiles on System:`n";
                    $Profs = Get-WmiObject -ClassName Win32_UserProfile -ErrorAction Stop|?{$_.LocalPath -like "C:\Users*"}|Select-Object LocalPath,SID;
                    $CleanUpLog += "$($Profs|Out-String)`n";
                }
                Catch [System.Exception]
                {
                    $CleanUpLog += "FAILED: Some Unexpected Error Has Occoured while Fetching User Profiles`nERROR: $($_)`n";
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
                                $CleanUpLog += "Getting 7 Days Old \AppData\Local\Temp File for User Profile $ProfilePath on System:`n";
                                $LocTemps = Get-ChildItem "$($ProfilePath + "\AppData\Local\Temp")" -Recurse -File -ErrorAction Stop|Where-Object {$_.LastAccessTime -lt $(Get-Date).AddDays(-7)};
                                $CleanUpLog += "$($LocTemps|Out-String)`n";

                                $CleanUpLog += "\AppData\Local\Temp Cleanup Process started for User Profile $ProfilePath`n";

                                foreach($LocTemp in $LocTemps)
                                {
                                    Try
                                    {
                                        #Remove-Item -Path "$($LocTemp|Select-Object -ExpandProperty FullName)" -Force -Confirm:$false -ErrorAction Stop;
                                    }
                                    Catch [System.Exception]
                                    {
                                        #$CleanUpLog += " FAILED: Unable to Delete $($LocTemp|Select-Object -ExpandProperty FullName)`nERROR: $($_)`n";
                                    }
                                }
                                $CleanUpLog += "Above Files Deleted Successfully for User Profile $ProfilePath`n";

                            }
                            Catch [System.Exception]
                            {
                                $CleanUpLog += "FAILED: Some Unexpected Error Has Occoured while Fetching Files from $ProfilePath\AppData\Local\Temp`nERROR: $($_)`n";
                            }
                        } # END: Local\Temp

                        ##############################################
                        #\AppData\Local\Microsoft\Windows\Temporary Internet Files
                        if(Test-Path $($ProfilePath + "\AppData\Local\Microsoft\Windows\Temporary Internet Files"))
                        {
                            Try
                            {
                                $CleanUpLog += "Getting 7 Days Old \AppData\Local\Microsoft\Windows\Temporary Internet Files for User Profile $ProfilePath on System:`n";
                                $TempInts = Get-ChildItem "$($ProfilePath + "\AppData\Local\Microsoft\Windows\Temporary Internet Files")" -Recurse -File -ErrorAction Stop|Where-Object {$_.LastAccessTime -lt $(Get-Date).AddDays(-7)};
                                $CleanUpLog += "$($TempInts|Out-String)`n";

                                $CleanUpLog += "\AppData\Local\Microsoft\Windows\Temporary Internet Files Cleanup Process started for User Profile $ProfilePath`n";

                                foreach($TempInt in $TempInts)
                                {
                                    Try
                                    {
                                        #Remove-Item -Path "$($TempInt|Select-Object -ExpandProperty FullName)" -Force -Confirm:$false -ErrorAction Stop;
                                    }
                                    Catch [System.Exception]
                                    {
                                        #$CleanUpLog += " FAILED: Unable to Delete $($TempInt|Select-Object -ExpandProperty FullName)`nERROR: $($_)`n";
                                        #$fso = New-Object -ComObject Scripting.FileSystemObject
                                        #$fso.DeleteFile("$($TempInt|Select-Object -ExpandProperty FullName)",$true);
                                    }
                                }
                                $CleanUpLog += "Above Files Deleted Successfully for User Profile $ProfilePath`n";

                            }
                            Catch [System.Exception]
                            {
                                $CleanUpLog += "FAILED: Some Unexpected Error Has Occoured while Fetching Files from $ProfilePath\AppData\Local\Microsoft\Windows\Temporary Internet Files`nERROR: $($_)`n";
                            }
                        } # END: Temporary Internet Files

                        ##############################################
                        #*vhd, *iso
                        Try
                        {
                            $CleanUpLog += "Getting *iso, *vhd Files for User Profile $ProfilePath on System:`n";
                            $LargeFile = Get-ChildItem -Path "$ProfilePath\*" -Recurse -Include @("*.iso","*.vhd") -ErrorAction Stop;
                            $CleanUpLog += "$($LargeFile|Out-String)`n";
                        }
                        Catch [System.Exception]
                        {
                            $CleanUpLog += "FAILED: Some Unexpected Error Has Occoured while Fetching Files from $ProfilePath\AppData\Local\Microsoft\Windows\Temporary Internet Files`nERROR: $($_)`n";
                        }
                        # END: *vhd, *iso

                    } # For Each User Profiles    
                }
                Catch [System.Exception]
                {
                    $CleanUpLog += "FAILED: Some Unexpected Error Has Occoured While Clening Up Profile Data`nERROR: $($_)`n";
                }

                #C:\Windows\SoftwareDistribution
                Try
                {
                    if(Test-Path C:\Windows\SoftwareDistribution)
                    {
                        $CleanUpLog += "Getting *.log, *.jrs, *.edb, *.jfm, *.cab Files from at C:\Windows\SoftwareDistribution:`n";
                        $SwDis = Get-ChildItem -Path C:\Windows\SoftwareDistribution\* -Recurse -Include @("*.log", "*.jrs", "*.edb", "*.jfm", "*.cab") -ErrorAction Stop;
                        $CleanUpLog += "$($SwDis|Out-String)`n";
                    }
                    Else
                    {
                        $CleanUpLog += "INFO: C:\Windows\SoftwareDistribution doesn't exists`n";
                    }
                }
                Catch [System.Exception]
                {
                    $CleanUpLog += "FAILED: Some Unexpected Error Has Occoured while Fetching Files at C:\Windows\SoftwareDistribution`nERROR: $($_)`n";
                }

                Write-Output $CleanUpLog;

            } -ErrorAction Stop -ErrorVariable ErrCleanup;

            if($CleanupData -eq @() -or $CleanupData -eq $null -or $CleanupData -eq "")
            {
                $cleanup_status = "Failure";
                $WNOutput += "Unable to Perform Cleaup Task`n";
            }
            Else
            {
                if($ErrCleanup.Count -gt 0)
                {
                    $cleanup_status = "Success";
                    $WNOutput += $CleanupData;
                }
                Else
                {
                    $cleanup_status = "Failure";
                    $WNOutput += "$ErrCleanup`n";
                }
            }
        }
        Catch [System.Exception]
        {
            $cleanup_status = "Failure";
            $WNOutput += "FAILED: Some Unexpected Error Has Occoured while connecting $($env:computername) remotely`nERROR: $($_)`n";
        }

        if($cleanup_status -eq "Success")
        {
            $WNOutput += "Checking Post Disk Utilization for $DriveVal Drive on $env:computername`n";

            Try
            {
                $PostData = @();
                $PostData = Get-WmiObject -class Win32_LogicalDisk -ErrorAction Stop|?{($_.DeviceID -eq $DriveVal) -and ($_.DriveType -eq 3)};

                if($PostData)
                {
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
                    $WNOutput += "$DriveVal doesn't exists on $($env:computername)`n";
                    $Action = "Reassign to Next Manual Queue";
                    $overall_status = "Failure";
                }
            }

            Catch [Syste.Exception]
            {
                $WNOutput += "FAILED: Some Unexpected Error Has Occoured while Fetching Post Disk Utilization details`nERROR: $($_)`n";
                $Action = "Reassign to Next Manual Queue";
                $overall_status = "Failure";
            }
        }
        Else # Clenup Failed
        {
            $Action = "Reassign to Next Manual Queue";
            $overall_status = "Failure";
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
$global:jsonRequest