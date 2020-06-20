function New-OTRebootTask 
{
    Param (
    [datetime]$Date = (Get-Date -Second 0 -Minute 0 -Hour 0).addDays(1),
        
    [String[]]$ComputerName = "localhost"
    )

    $Date = $Date | Get-Date

    $Action = New-ScheduledTaskAction -Execute "shutdown.exe" -Argument "/r /t 0"
    $Trigger = New-ScheduledTaskTrigger -Once -At $Date
    $Trigger.EndBoundary = $Date.AddMinutes(1).ToString('s')
    $Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM"
    $Settings = New-ScheduledTaskSettingsSet -DeleteExpiredTaskAfter (New-TimeSpan -Minutes 1) -Compatibility Win7 -AllowStartIfOnBatteries

    $Task = New-ScheduledTask -Action $Action -Principal $Principal -Trigger $Trigger -Settings $Settings
    $Task.Author = "PSRebootTask"

    Invoke-Command -ComputerName $ComputerName -ArgumentList $Task -ScriptBlock { 
        try
        {
            Register-ScheduledTask -TaskName "RebootTask" -InputObject $args[0] -ErrorAction Stop > $null
            Write-Output "[$env:COMPUTERNAME] RebootTask registered."
        }
        catch
        {
            $message = $_.Exception.Message.Trim()
            if ("$message" -eq "Cannot create a file when that file already exists.")
            {
                Write-Warning "[$env:COMPUTERNAME] RebootTask already exists."
            }
            else
            {
                $_
            }
        }
    }
}

function Remove-OTRebootTask
{
    Param (  
    [String[]]$ComputerName = "localhost"
    )

    Invoke-Command -ComputerName $ComputerName -ScriptBlock { 
        try
        {
            Unregister-ScheduledTask -TaskName "RebootTask" -Confirm:$false -ErrorAction Stop > $null
            Write-Output "[$env:COMPUTERNAME] RebootTask removed."
        }
        catch
        {
            $message = $_.Exception.Message.Trim()
            if ("$message" -like "No MSFT_ScheduledTask objects found with property*")
            {
                Write-Warning "[$env:COMPUTERNAME] No RebootTask found."
            }
            else
            {
                $_
            }
        }
    }
}

function Get-OTRebootTask 
{
    Param (
    [Parameter(ParameterSetName="ComputerName")]
    [String[]]$ComputerName = "localhost",

    [Parameter(ParameterSetName="AllAD")]
    [switch]$AllAD = $false
    )

    if ($AllAD)
    {
        Write-Error "[-AllAD] This feature is not yet ready."
        return

        #$ComputerName = Get-ADComputer -Filter 'OperatingSystem -like "Windows*"'
    }

    Invoke-Command -ComputerName $ComputerName -ScriptBlock {
        try
        {
            $Task = (Get-ScheduledTask -TaskName "RebootTask" -ErrorAction Stop)
            $TaskTime = $Task.Triggers.StartBoundary | Get-Date
            Write-Output "[$env:COMPUTERNAME] RebootTask scheduled: $TaskTime"
        }
        catch
        {
            $message = $_.Exception.Message.Trim()
            if ("$message" -like "No MSFT_ScheduledTask objects found with property*")
            {
                Write-Warning "[$env:COMPUTERNAME] No RebootTask found."
            }
            else
            {
                $_
            }
        }
    }    
}
