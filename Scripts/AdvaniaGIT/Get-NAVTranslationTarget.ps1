﻿function Get-NAVTranslationTarget
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$True, ValueFromPipelineByPropertyname=$true)]
        [PSObject]$SetupParameters,
        [Parameter(Mandatory=$True, ValueFromPipelineByPropertyname=$true)]
        [PSObject]$BranchSettings
    )
    if ($BranchSettings.dockerContainerId -eq "") {
        $Languages = Get-ChildItem -Path $SetupParameters.navServicePath -Filter '??-??'
    } else {
        $Session = New-DockerSession -DockerContainerId $BranchSettings.dockerContainerId
        $Languages = Invoke-Command -Session $Session -ScriptBlock {
            $navServicePath = (Get-Item -Path 'C:\Program Files\Microsoft Dynamics NAV\*\Service').FullName
            return Get-ChildItem -Path $navServicePath -Filter '??-??'
        }
        Remove-PSSession $Session
    }
    if ($Languages.Count -eq 1) { return ($Languages | Select-Object -First 1).Name }
    $LanguageNo = 1
    $menuItems = @()
    foreach ($Language in $Languages) {
        $menuItem = New-Object -TypeName PSObject
        $menuItem | Add-Member -MemberType NoteProperty -Name No -Value $LanguageNo
        $menuItem = Combine-Settings $menuItem $Language
        $menuItems += $menuItem
        $LanguageNo ++
    }

    do {
        # Start Menu
        Clear-Host
        Add-BlankLines
        $menuItems | Format-Table -Property No, Name -AutoSize | Out-Host
        $input = Read-Host "Please select Language file number (0 = exit)"
        switch ($input) {
            '0' { break }
            default {
                $selectedLanguage = $menuItems | Where-Object -Property No -EQ $input
                if ($selectedLanguage) { return $selectedLanguage.Name }
            }
        }
    }
    until ($input -ieq '0')

}