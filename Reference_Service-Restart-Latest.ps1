<#
.SYNOPSIS

    File Name:      HPE-GMS_Service-Restart.ps1
    Description:    Service Restart
    Script Owner:   ITOM Team, Tools Engineering
    Created By :    Anirudha Bagchi
    Version:        V.1.0
    Created Date:   30/07/2020
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

#.$function_file;

Function Start-WinService
{
    [cmdletbinding()]
    Param
    (
        [Parameter(Position=0,Mandatory=$True)]
        [String]$ServerName,

        [Parameter(Position=1,Mandatory=$True)]
        [String]$SrvsName
    )

    Try
    {
        $ErrSrvStr = @();
        $SrvStrData = @();
        $SrvStrResult = @();

        #$SrvStrData = Get-Service -ComputerName $ServerName -Name $SrvsName -ErrorAction Stop| Start-Service -Confirm:$false -ErrorAction Stop -ErrorVariable ErrSrvStr|Out-Null;
        $SrvStrData = Invoke-Command -ComputerName $ServerName -Credential $cred -ScriptBlock {
            
            $StartServiceErrOutput = "";
            Try
            {
                Start-Service -DisplayName $args[0] -ErrorAction Stop|Out-Null;
            }
            Catch [System.Exception]
            {
                $StartServiceErrOutput = $($_);
            }

            Write-Output $StartServiceErrOutput;
        
        } -Args $SrvsName -ErrorAction Stop -ErrorVariable ErrSrvStr;

        if($SrvStrData -eq @() -or $SrvStrData -eq $null -or $SrvStrData -eq "")
        {
            if($ErrSrvStr.Count -gt 0)
            {

                $SrvStrResult = New-Object psobject -Property @{
                        Result = "FAILURE"
                        Msg = "$ErrSrvStr"
                        ServiceName = "$SrvsName"
                        ServerName = "$ServerName"
                }
            }

            Else
            {
                $SrvStrResult = New-Object psobject -Property @{
                        Result = "SUCCESS"
                        Msg = "Successfully Started $ServiceName on $ServerName"
                        ServiceName = "$SrvsName"
                        ServerName = "$ServerName"
                }
            }
        }
        Else
        { 
            $SrvStrResult = New-Object psobject -Property @{
                        Result = "FAILURE"
                        Msg = "$SrvStrData"
                        ServiceName = "$SrvsName"
                        ServerName = "$ServerName"
                }
        }
    }

    Catch [System.Exception]
    {
        $SrvStrResult = New-Object psobject -Property @{
                Result = "FAILURE"
                Msg = "$($_)"
                ServiceName = "$SrvsName"
                ServerName = "$ServerName"
        }
    }

    Return $SrvStrResult;
}

Function Get-ServData
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$True)]
        [String]$Service,

        [Parameter(Mandatory=$True)]
        [String]$Server
    )
        
    Try
    {
        $ErrSrv = @();
        $SrvData = @();
        $SrvResult = @();

        #$SrvData = Get-Service -ComputerName $Server -Name $Service -ErrorAction Stop -ErrorVariable ErrSrv|Select-Object *;
        $SrvData = Get-WmiObject -Class Win32_Service -ComputerName $Server -Filter "DisplayName = '$Service'" -Credential $cred -ErrorAction Stop -ErrorVariable ErrSrv|Select-Object *;
            
        if($ErrSrv.Count -gt 0 -or $SrvData -eq $null -or $SrvData.Count -eq 0)
        {
            if($SrvData -eq $null) {$MSG = "Service Not Found with DisplayName $ServiceName"}
            else {$MSG = "$ErrSrv"}

            $SrvResult = New-Object psobject -Property @{
                    Result = "FAILURE"
                    Msg = "$MSG"
                    Name = "$Service"
                    SrvDisplayName = ""
                    SrvStatus = ""
                    StartupType = ""
                    ProcID = ""
            }
        }
        elseif ($SrvData.Count -gt 1)
        {
            $SrvResult = New-Object psobject -Property @{
                Result = "FAILURE"
                Msg = "More than 1 Service Found With Same DisplayName"
                Name = "$Service"
                SrvDisplayName = ""
                SrvStatus = ""
                StartupType = ""
                ProcID = ""
            }
        }
        Else
        {
            $SrvResult = New-Object PSObject -Property @{
                    Result = "SUCCESS"
                    Msg = "Successfully Recieved Service Data"
                    Name = $($SrvData|Select-Object -ExpandProperty Name)
                    SrvDisplayName = $($SrvData|Select-Object -ExpandProperty DisplayName)
                    SrvStatus = $($SrvData|Select-Object -ExpandProperty State)
                    StartupType = $($SrvData|Select-Object -ExpandProperty StartMode)
                    ProcID = $($($SrvData|Select-Object -ExpandProperty ProcessId) -join ",")
            }
        }
    }
    Catch [System.Exception]
    {
        $SrvResult = New-Object psobject -Property @{
                Result = "FAILURE"
                Msg = "$($_)"
                Name = "$Service"
                SrvDisplayName = ""
                SrvStatus = ""
                StartupType = ""
                ProcID = ""
        }      
    }
        
    Return $SrvResult;

} # END Func GetServData()

Function Get-ProcData
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$True)]
        [String]$ProcessID,

        [Parameter(Mandatory=$True)]
        [String]$CompName
    )
        
    Try
    {
        $ErrProc = @();
        $ProcData = @();
        $ProcResult = @();

        $ProcData = Get-WmiObject Win32_Process -Filter "ProcessId = '$ProcessID'" -ComputerName $CompName -Credential $cred -ErrorAction Stop -ErrorVariable ErrProc;
        #$ProcData = Get-Process -ComputerName $CompName -Id $ProcessID -ErrorAction SilentlyContinue -ErrorVariable ErrProc|Select-Object *;

        if($ErrProc.Count -gt 0 -or $ProcData -eq $null)
        {
            if($ProcData -eq $null) {$MSG = "Process Details not found for PID $ProcessID"}
            Else {$MSG = "$ErrProc"}

            $ProcResult += New-Object psobject -Property @{
                Result = "FAILURE"
                Msg = $MSG
                ProcessId = $ProcessID
                ProcessData = ""
            }
        }
        Else
        {
            $ProcResult += New-Object psobject -Property @{
                Result = "SUCCESS"
                Msg = "Successfully Recieved Process Details"
                ProcessId = $ProcessID
                ProcessData = $($ProcData|Select-Object -ExpandProperty ProcessName)
            }
        }

    }

    Catch [System.Exception]
    {

        $ProcResult += New-Object psobject -Property @{
            Result = "FAILURE"
            Msg = "$($_)"
            ProcessId = $ProcessID
            ProcessData = ""
        }
    }
    Return $ProcResult;

} # END Func GetProcData()


$Obj_Output = @();

$SrvChk1 = Get-ServData -Server $ServerName -Service $ServiceName -ErrorAction SilentlyContinue;

if($SrvChk1.Result -eq "SUCCESS")
{       
    if($SrvChk1.SrvStatus -eq "Running")
    {
        # Get Process Details from Service PID
        $Proc = Get-ProcData -CompName $ServerName -ProcessID $($SrvChk1.ProcID) -ErrorAction SilentlyContinue;

        if($Proc.Result -eq "SUCCESS")
        { 
            $Obj_Output += New-Object psobject -Property @{
                ServiceName = "$($SrvChk1.Name)"
                InitialServiceStatus = "$($SrvChk1.SrvStatus)"
                ServiceStartupType = "$($SrvChk1.StartupType)"
                ProcessId = "$($Proc.ProcessId)"
                ProcessName = "$($Proc.ProcessData)"
                #ProcessWorkingSet = "$($($Proc.WorkingSet)/1024)"
                Message = "$($Proc.Msg)"
            }

            $overall_status = "Success";
        }
        Else
        {
            $Obj_Output += New-Object psobject -Property @{
                ServiceName = "$($SrvChk1.Name)"
                InitialServiceStatus = "$($SrvChk1.SrvStatus)"
                ServiceStartupType = "$($SrvChk1.StartupType)"
                ProcessId = "$($SrvChk1.ProcID)"
                #ProcessName = ""
                #ProcessWorkingSet = ""
                Message = "$($Proc.Msg)"
            }

            $overall_status = "Failure";
        }
    } # Initial Service Running
    Else
    {
        # Trying to Start the Service
        $StrStat = Start-WinService -ServerName $ServerName -SrvsName $ServiceName -ErrorAction SilentlyContinue;

        if($StrStat.Result -eq "SUCCESS")
        {   

            Start-Sleep -Seconds 10;
            # Check Service Status 2nd Time
            $SrvChk2 = Get-ServData -Server $ServerName -Service $ServiceName -ErrorAction SilentlyContinue;

            if($SrvChk2.Result -eq "SUCCESS")
            {
                $Obj_Output += New-Object psobject -Property @{
                    ServiceName = "$($SrvChk2.Name)"
                    InitialServiceStatus = "$($SrvChk1.SrvStatus)"
                    ServiceStartupType = "$($SrvChk2.StartupType)"
                    ActionTaken = "Started The Service"
                    StatusAfterAction = "$($SrvChk2.SrvStatus)"
                    Message = "$($SrvChk2.Msg)"
                }

                $overall_status = "Success";
                
            } # Got Service Data 2nd Time
            Else
            {
                $Obj_Output += New-Object psobject -Property @{
                    ServiceName = "$($SrvChk2.Name)"
                    InitialServiceStatus = "$($SrvChk1.SrvStatus)"
                    #ServiceStartupType = ""
                    ActionTaken = "Started The Service"
                    #StatusAfterAction = ""
                    Message = "$($SrvChk2.Msg)"
                }

                $overall_status = "Failure";
            } # Failed to get Service Data 2nd Time 
        } # Service Started Successfully
        Else
        {
            $Obj_Output += New-Object psobject -Property @{
                    ServiceName = "$($SrvChk1.Name)"
                    InitialServiceStatus = "$($SrvChk1.SrvStatus)"
                    ServiceStartupType = "$($SrvChk1.StartupType)"
                    ActionTaken = "Failed to Start Service"
                    #StatusAfterAction = ""
                    Message = "$($StrStat.Msg)"
                }

            $overall_status = "Failure";
        } # Failed To Start Service
    } #Initial Service Not Running
}
Else
{
    $Obj_Output += New-Object psobject -Property @{
        ServiceName = "$($SrvChk1.Name)"
        #InitialServiceStatus = ""
        #ServiceStartupType = ""
        #ProcessId = ""
        #ProcessName = ""
        #ProcessWorkingSet = ""
        Message = "$($SrvChk1.Msg)"
    }

    $overall_status = "Failure";
}

$Json_Output = $($Obj_Output|ConvertTo-Json);

output-format $FileName_WithoutExtension $global:time $ServerName $conn_type $Json_Output $overall_status
$global:jsonRequest