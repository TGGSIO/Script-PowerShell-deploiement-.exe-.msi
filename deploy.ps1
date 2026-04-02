Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Dossier contenant les installateurs
$installerFolder = "C:\test"

# Dossier pour logs (créé s'il n'existe pas)
$logFolder = Join-Path $PSScriptRoot "Logs"
if (-not (Test-Path $logFolder)) {
    New-Item -ItemType Directory -Path $logFolder | Out-Null
}

# Fichier log avec horodatage
$logFile = Join-Path $logFolder ("InstallLog_" + (Get-Date -Format "yyyyMMdd_HHmmss") + ".txt")

function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logLine = "[$timestamp][$Level] $Message"
    Add-Content -Path $logFile -Value $logLine

    switch ($Level) {
        "INFO"    { Write-Host $Message -ForegroundColor Green }
        "WARNING" { Write-Warning $Message }
        "ERROR"   { Write-Error $Message }
        default   { Write-Host $Message }
    }
}

function IsAppInstalled {
    param ([string[]]$appNames)

    $appNames = $appNames | ForEach-Object { $_.ToLower().Trim() }

    $registryPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )

    foreach ($path in $registryPaths) {
        try {
            $apps = Get-ItemProperty -Path $path -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName }
            foreach ($app in $apps) {
                $displayName = $app.DisplayName.ToLower().Trim()
                foreach ($name in $appNames) {
                    if ($displayName -like "*$name*") {
                        return $true
                    }
                }
            }
        } catch { }
    }

    # Verifications par chemin
    foreach ($name in $appNames) {
        if ($name -like "*chrome*") {
            $paths = @(
                "$env:ProgramFiles(x86)\Google\Chrome\Application\chrome.exe",
                "$env:ProgramFiles\Google\Chrome\Application\chrome.exe"
            )
            foreach ($path in $paths) {
                if (Test-Path $path) { return $true }
            }
        }
        elseif ($name -like "*firefox*") {
            $paths = @(
                "$env:ProgramFiles\Mozilla Firefox\firefox.exe",
                "$env:ProgramFiles(x86)\Mozilla Firefox\firefox.exe"
            )
            foreach ($path in $paths) {
                if (Test-Path $path) { return $true }
            }
            if (Get-Process -Name firefox -ErrorAction SilentlyContinue) {
                return $true
            }
        }
        elseif ($name -like "*steam*") {
            $paths = @(
                "$env:ProgramFiles(x86)\Steam\Steam.exe",
                "$env:ProgramFiles\Steam\Steam.exe"
            )
            foreach ($path in $paths) {
                if (Test-Path $path) { return $true }
            }
        }
        elseif ($name -like "*vlc*") {
            $paths = @(
                "$env:ProgramFiles\VideoLAN\VLC\vlc.exe",
                "$env:ProgramFiles(x86)\VideoLAN\VLC\vlc.exe"
            )
            foreach ($path in $paths) {
                if (Test-Path $path) { return $true }
            }
        }
    }

    return $false
}

# Liste des installateurs connus
$installersKnown = @(
    @{ Path = Join-Path $installerFolder "Chrome.exe"; Type = "exe"; Args = "/silent /install"; Names = @("Google Chrome", "chrome") },
    @{ Path = Join-Path $installerFolder "Firefox.exe"; Type = "exe"; Args = "/S"; Names = @("Mozilla Firefox", "firefox") },
    @{ Path = Join-Path $installerFolder "7Zip.msi"; Type = "msi"; Names = @("7-Zip", "7zip") },
    @{ Path = Join-Path $installerFolder "Reader.exe"; Type = "exe"; Args = "/sAll /rs /rps /msi EULA_ACCEPT=YES"; Names = @("Adobe Acrobat Reader", "acrobat reader") }
)

# Cles generiques de detection
$genericAppNames = @{
    "SteamSetup" = @("Steam")
    "vlc" = @("VLC media player", "vlc")
    "Firefox Installer" = @("Mozilla Firefox", "firefox")
    "chrome" = @("Google Chrome", "chrome")
    "7z" = @("7-Zip", "7zip")
}

# Recuperer tous les installateurs (connus + inconnus)
$allInstallers = @()

# Ajout des installateurs connus
foreach ($app in $installersKnown) {
    if (Test-Path $app.Path) {
        $installed = IsAppInstalled -appNames $app.Names
        $allInstallers += [PSCustomObject]@{
            Name = ([IO.Path]::GetFileName($app.Path))
            Path = $app.Path
            Type = $app.Type
            Args = $app.Args
            Installed = $installed
            Names = $app.Names
        }
    }
}

# Autres fichiers du dossier
if (Test-Path $installerFolder) {
    $files = Get-ChildItem -Path $installerFolder -Include *.exe, *.msi -File -Recurse
    $knownPaths = $installersKnown.Path
    foreach ($file in $files) {
        if ($knownPaths -contains $file.FullName) { continue }
        $baseName = [IO.Path]::GetFileNameWithoutExtension($file.Name).ToLower()
        $matchedNames = @()
        foreach ($key in $genericAppNames.Keys) {
            if ($baseName -like "*$key*") {
                $matchedNames = $genericAppNames[$key]
                break
            }
        }
        if ($matchedNames.Count -eq 0) { $matchedNames = @($baseName) }
        $installed = IsAppInstalled -appNames $matchedNames
        $allInstallers += [PSCustomObject]@{
            Name = $file.Name
            Path = $file.FullName
            Type = $file.Extension.TrimStart('.')
            Args = $null
            Installed = $installed
            Names = $matchedNames
        }
    }
} else {
    Write-Log "Le dossier d'installation $installerFolder est introuvable." "ERROR"
    exit
}

# Interface
$form = New-Object System.Windows.Forms.Form
$form.Text = "Installateur d'applications"
$form.Size = New-Object System.Drawing.Size(600, 500)
$form.StartPosition = "CenterScreen"

$listView = New-Object System.Windows.Forms.ListView
$listView.Size = New-Object System.Drawing.Size(560, 330)
$listView.Location = New-Object System.Drawing.Point(10, 10)
$listView.CheckBoxes = $true
$listView.View = 'List'
$form.Controls.Add($listView)

foreach ($installer in $allInstallers) {
    $item = New-Object System.Windows.Forms.ListViewItem($installer.Name)
    $item.Checked = $true
    if ($installer.Installed) {
        $item.ForeColor = [System.Drawing.Color]::Green
        $item.Text += " (Deja installe)"
    }
    $item.Tag = $installer
    $listView.Items.Add($item) | Out-Null
}

# Bouton Selectionner tout
$btnSelectAll = New-Object System.Windows.Forms.Button
$btnSelectAll.Text = "Tout selectionner"
$btnSelectAll.Size = New-Object System.Drawing.Size(170, 30)
$btnSelectAll.Location = New-Object System.Drawing.Point(10, 350)
$btnSelectAll.Add_Click({
    foreach ($item in $listView.Items) { $item.Checked = $true }
})
$form.Controls.Add($btnSelectAll)

# Bouton Inverser selection
$btnInvert = New-Object System.Windows.Forms.Button
$btnInvert.Text = "Inverser la selection"
$btnInvert.Size = New-Object System.Drawing.Size(180, 30)
$btnInvert.Location = New-Object System.Drawing.Point(200, 350)
$btnInvert.Add_Click({
    foreach ($item in $listView.Items) { $item.Checked = -not $item.Checked }
})
$form.Controls.Add($btnInvert)

# Bouton Quitter
$btnQuit = New-Object System.Windows.Forms.Button
$btnQuit.Text = "Quitter"
$btnQuit.Size = New-Object System.Drawing.Size(100, 30)
$btnQuit.Location = New-Object System.Drawing.Point(400, 350)
$btnQuit.Add_Click({ $form.Close() })
$form.Controls.Add($btnQuit)

# Bouton Installer
$buttonInstall = New-Object System.Windows.Forms.Button
$buttonInstall.Text = "Installer les applications selectionnees"
$buttonInstall.Size = New-Object System.Drawing.Size(560, 40)
$buttonInstall.Location = New-Object System.Drawing.Point(10, 390)
$form.Controls.Add($buttonInstall)

$buttonInstall.Add_Click({
    $checkedItems = $listView.CheckedItems
    if ($checkedItems.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("Veuillez selectionner au moins une application.", "Information", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        return
    }
    foreach ($item in $checkedItems) {
        $installer = $item.Tag
        Write-Log "Installation de : $($installer.Name)"
        try {
            if ($installer.Type -eq "exe") {
                if ($installer.Args) {
                    Start-Process -FilePath $installer.Path -ArgumentList $installer.Args -Wait -NoNewWindow
                } else {
                    Start-Process -FilePath $installer.Path -Wait -NoNewWindow
                }
            } elseif ($installer.Type -eq "msi") {
                $arguments = "/i `"$($installer.Path)`" /quiet /norestart"
                Start-Process -FilePath "msiexec.exe" -ArgumentList $arguments -Wait -NoNewWindow
            } else {
                Start-Process -FilePath $installer.Path -Wait -NoNewWindow
            }
            Write-Log "Installation reussie pour : $($installer.Name)"
        }
        catch {
            Write-Log "Erreur lors de l'installation de : $($installer.Name). Details: $_" "ERROR"
        }
    }
    [System.Windows.Forms.MessageBox]::Show("Installation(s) terminee(s).", "Information", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
})

# Affiche la fenetre
[void]$form.ShowDialog()
