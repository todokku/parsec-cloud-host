Configuration ParsecSystem
{
    Param()

    Import-DscResource -ModuleName 'ComputerManagementDsc'
    Import-DscResource -ModuleName 'PSDscResources'

    # Power plan
    PowerPlan 'HighPerformancePowerPlan'
    {
        IsSingleInstance = 'Yes'
        Name = 'High performance'
    }

    # Prioritise programs
    Registry 'PrioritisePrograms'
    {
        Ensure = 'Present'
        Key = 'HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl'
        ValueName = 'Win32PrioritySeparation'
        ValueData = 38
        ValueType = 'Dword'
        Force = $true
    }

    # Disable crash dump
    Registry 'CrashDumpDisabled'
    {
        Ensure = 'Present'
        Key = 'HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl'
        ValueName = 'CrashDumpEnabled'
        ValueData = 0
        ValueType = 'Dword'
        Force = $true
    }

    # Harden RDP
    RemoteDesktopAdmin RemoteDesktopSettings
    {
        IsSingleInstance = 'Yes'
        Ensure = 'Present'
        UserAuthentication = 'Secure'
    }

    # Required features built-in to Windows
    WindowsFeatureSet "WindowsFeatures"
    {
        Ensure = 'Present'
        Name = 'NET-Framework-Core','NET-Framework-45-Core','Direct-Play'
    }

    # Disable Internet Explorer Enhanced Security Configuration
    Registry "IE-ESC-Admin-Disabled"
    {
        Ensure = 'Present'
        Key = 'HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}'
        ValueName = 'IsInstalled'
        ValueData = 0
        ValueType = 'Dword'
        Force = $true
    }
    Registry "IE-ESC-User-Disabled"
    {
        Ensure = 'Present'
        Key = 'HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}'
        ValueName = 'IsInstalled'
        ValueData = 0
        ValueType = 'Dword'
        Force = $true
    }
    Registry "IE-First-Run-Disabled"
    {
        Ensure = 'Present'
        Key = 'HKLM:\Software\Policies\Microsoft\Internet Explorer\Main'
        ValueName = 'DisableFirstRunCustomize'
        ValueData = 1
        ValueType = 'Dword'
        Force = $true
    }

    # # Disable Windows Automatic Updates
    Registry "AutomaticUpdates-Disabled"
    {
        Ensure = 'Present'
        Key = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU'
        ValueName = 'NoAutoUpdate'
        ValueData = 1
        ValueType = 'Dword'
        Force = $true
    }

    # # Configure NTP
    Registry "NTP-Internet-Enabled"
    {
        Ensure = 'Present'
        Key = 'HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Parameters'
        ValueName = 'Type'
        ValueData = 'NTP'
        ValueType = 'String'
        Force = $true
    }
    Registry "TimeZoneAutomaticUpdate-Service-Enabled"
    {
        Ensure = 'Present'
        Key = 'HKLM:\SYSTEM\CurrentControlSet\Services\tzautoupdate'
        ValueName = 'Start'
        ValueData = 3
        ValueType = 'Dword'
        Force = $true
    }
    
    # # Disable New Network UI
    Registry "NewNetworkWindow-Disabled"
    {
        Ensure = 'Present'
        Key = 'HKLM:\SYSTEM\CurrentControlSet\Control\Network\NewNetworkWindowOff'
        ValueName = ''
        Force = $true
    }
    
    # # Disable Server Manager at login
    Registry "ServerManager-Startup-Disabled"
    {
        Ensure = 'Present'
        Key = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Server\ServerManager'
        ValueName = 'DoNotOpenAtLogon'
        ValueData = 1
        ValueType = 'Dword'
        Force = $true
    }

    # # Disable lockscreen
    Registry "Lockscreen-Disabled"
    {
        Ensure = 'Present'
        Key = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'
        ValueName = 'DisableLockWorkstation'
        ValueData = 1
        ValueType = 'Dword'
        Force = $true
    }

    # Disable recently installed items in start menu
    Registry "StartMenu-RecentlyInstalled-Disabled"
    {
        Ensure = 'Present'
        Key = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer'
        ValueName = 'HideRecentlyAddedApps'
        ValueData = 1
        ValueType = 'Dword'
        Force = $true
    }

    # Disable telemetry
    Registry "Telemetry-Disabled"
    {
        Ensure = 'Present'
        Key = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection'
        ValueName = 'AllowTelemetry'
        ValueData = 0
        ValueType = 'Dword'
        Force = $true
    }

    # Disable Scheduled tasks
    $tasksToDisable =
    @(
        @{ TaskName = 'ScheduledDefrag' ; TaskPath = '\Microsoft\Windows\Defrag\' }
        @{ TaskName = 'ProactiveScan' ; TaskPath = '\Microsoft\Windows\Chkdsk\' }
        @{ TaskName = 'Scheduled' ; TaskPath = '\Microsoft\Windows\Diagnosis\' }
        @{ TaskName = 'WinSAT' ; TaskPath = '\Microsoft\Windows\Maintenance\' }
        @{ TaskName = 'StartComponentCleanup' ; TaskPath = '\Microsoft\Windows\Servicing\' }
    )
    $validTasks = $tasksToDisable | % { Get-ScheduledTask @PSitem -EA 'SilentlyContinue' }
    If ($validTasks)
    {
        ForEach ($task in $validTasks) {
            ScheduledTask "$($task.TaskName)Disabled"
            {
                TaskName = $task.TaskName
                TaskPath = $task.TaskPath
                Enable = $false
            }
        }
    }

    # Disable services
    $servicesToDisable =
    @(
        "diagnosticshub.standardcollector.service"
        "DiagTrack"
        "dmwappushservice"
        "gupdate"
        "lfsvc"
        "MapsBroker"
        "RemoteAccess"
        "SharedAccess"
        "Spooler"
        "TrkWks"
        "WbioSrvc"
        "XblAuthManager"
        "XblGameSave"
    )
    $validServices = $servicesToDisable | Get-Service -EA 'SilentlyContinue'
    ServiceSet "DisabledServices"
    {
        Name = $validServices.Name
        StartupType = 'Disabled'
        State = 'Stopped'
    }
}
