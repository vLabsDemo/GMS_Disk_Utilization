<#
.SYNOPSIS
This file serves the purpose of keeping all the general utility functions that can used in any of the operation.
Script Owner: ITOM Team, Tools Engineering
Created By : Anirudha Bagchi
Version:V.1.0
Created Date: 23/01/2020
Updated Date:
#>


function output-format($scriptname,$curr_time,$target_host,$conn_type,$output,$exec_status) 
{
        $global:jsonRequest = @"
        {

                "Script": "$scriptname",
                "Time": "$curr_time",
                "TargetHost": "$target_host",
                "ConnectionType": "$conn_type",
                "Output": $output,
                "Excecution_Status": "$exec_status"
       }
"@

}


function timestamp ()
{
       $global:time = get-date #-format yyyyMMddhhmmss
}


function get-directory
{
        $global:path = Split-Path $script:MyInvocation.MyCommand.Path
        $global:script = $script:MyInvocation.MyCommand.name
        
}

function LogMessage ($path,$message,$error1,$info)
{
		if($error1){
        		Add-Content -Path $Path -Value ("[PowerShell] [Error] {0} {1}" -f $(Get-Date -Format "MM-dd-yyyy hh:mm:ss"), $message) -ErrorAction Stop 
				Write-Host $message -ForegroundColor red
		}
		elseif($INFO){
				Add-Content -Path $Path -Value ("[PowerShell] [Information] {0} {1}" -f $(Get-Date -Format "MM-dd-yyyy hh:mm:ss"), $message) -ErrorAction Stop 
				Write-Host $message -ForegroundColor Green
		}
		else{
				Add-Content -Path $Path -Value ("[PowerShell] [Information] {0} {1}" -f $(Get-Date -Format "MM-dd-yyyy hh:mm:ss"), $message) -ErrorAction Stop 
				Write-Host $message -ForegroundColor Cyan
			}
}

function targethostname()
{
        $targethostname=Get-WmiObject Win32_Computersystem
        $Global:targethostnamefqdn = $targethostname.name + "." + $targethostname.domain
}


