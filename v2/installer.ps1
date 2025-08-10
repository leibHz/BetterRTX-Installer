param (
    [string]$PackPath
)

#region Preamble and Global Setup
# [FIX?] Forca a codificacao de saída para UTF-8 para garantir que os caracteres especiais das traducoes sejam exibidos corretamente, nao funcionou, mas deixa ai, nn ajuda mas nao atrapalha
$OutputEncoding = [System.Text.Encoding]::UTF8

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$Global:BRTX_DIR = Join-Path -Path $env:LOCALAPPDATA -ChildPath "graphics.bedrock"
if (-not (Test-Path $Global:BRTX_DIR)) {
    try {
        New-Item -ItemType Directory -Path $Global:BRTX_DIR -Force -ErrorAction Stop | Out-Null
    }
    catch {
        $msg = "Falha crítica: Nao foi possível criar o diretório de dados em $($Global:BRTX_DIR). Verifique as permissoes da sua pasta."
        [System.Windows.Forms.MessageBox]::Show($msg, "Erro de Inicializacao", "OK", "Error")
        exit 1
    }
}

$Global:InstallerLogPath = Join-Path -Path $Global:BRTX_DIR -ChildPath "installer.log"
$Global:InstallerConfigPath = Join-Path -Path $Global:BRTX_DIR -ChildPath "installer_config.json"
#endregion

#region Logging
function Write-Log {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        [Parameter(Mandatory = $false)]
        [ValidateSet("INFO", "WARN", "ERROR", "SUCCESS", "DEBUG", "THEME", "UI_ACTION")]
        [string]$Level = "INFO",
        [Parameter(Mandatory = $false)]
        [switch]$NoNewLine
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "$timestamp [$Level] $Message"
    $color = switch ($Level) {
        "INFO"      { "Gray" }
        "WARN"      { "Yellow" }
        "ERROR"     { "Red" }
        "SUCCESS"   { "Green" }
        "DEBUG"     { "Cyan" }
        "THEME"     { "Magenta" }
        "UI_ACTION" { "DarkCyan" }
        default     { "White" }
    }
    
    $writeHostParams = @{
        Object          = $logEntry
        ForegroundColor = $color
    }
    if ($NoNewLine) {
        $writeHostParams.NoNewline = $true
    }
    Write-Host @writeHostParams

    try {
        Add-Content -Path $Global:InstallerLogPath -Value $logEntry
    } catch {
        Write-Host "[$timestamp] [ERROR] Failed to write to log file $Global:InstallerLogPath : $($_.Exception.Message)" -ForegroundColor Red
    }
}
#endregion

#region Localization
function Get-LocalizedStrings {
    $culture = (Get-Culture).Name.Split('-')[0]
    Write-Log -Level INFO -Message "System language culture detected: $culture"

    # Default Strings (English)
    $strings = @{
        package_name = "BetterRTX Installer"
        browse = "Browse..."
        install = "Install"
        install_instance = "Install to Instance(s)"
        install_all = "Install to all detected versions"
        install_pack = "Install Preset"
        install_custom = "Custom .rtpack File..."
        uninstall_betterrtx = "Revert to Original Shaders for Selected"
        uninstalled_success = "Successfully reverted shaders for"
        uninstalled_failed = "Failed to revert shaders for"
        uninstalled_nobackup = "No initial backup found for"
        copying = "Copying"
        downloading = "Downloading"
        deleting = "Deleting"
        expanding_pack = "Expanding pack, please wait..."
        success = "Success"
        error = "Error"
        error_invalid_file_type = "Invalid file type. Please select a .mcpack or .rtpack file."
        error_no_installations_selected = "Please select at least one Minecraft installation."
        error_copy_failed = "Unable to copy to Minecraft installation. Check logs."
        error_iobit_missing = "IObit Unlocker not found. It is recommended for modifying Store app files."
        error_config_corrupt = "Configuration file was corrupt and has been reset. Please re-add any custom paths."
        error_network = "Could not load pack list. Please check your internet connection."
        setup = "Setup"
        download = "Download"
        launchers = "Launchers"
        launch = "Launch Minecraft"
        help = "Help"
        backup = "Backup Current Shaders"
        backup_instance_location = "Select backup location for instance"
        create_initial_backup = "Creating initial backup of shaders"
        register_rtpack = "Register .rtpack Extension"
        advanced = "Advanced"
        update_dlss = "Update DLSS"
        dlss_downloading = "Downloading DLSS"
        dlss_updating = "Updating DLSS for"
        dlss_success = "Successfully updated DLSS."
        add_ms_store = "Microsoft Store Version"
        add_bedrock_launcher = "Bedrock Launcher Version"
        add_custom_path = "Custom Installation Path"
        manage_installations = "Manage Installations"
        add_bl_versions_folder = "Add Bedrock Launcher Versions Folder"
        add_custom_install_folder = "Add Custom Game Installation Folder"
        edit_display_name = "Edit Display Name"
        remove_selected_path = "Remove Selected Path"
        confirm_remove_path = "Are you sure you want to remove this installation path? This does not delete game files."
        path_not_found = "Path not found"
        installation_type = "Type"
        installation_path = "Path"
        display_name = "Display Name"
        save_config = "Save Configuration"
        config_saved = "Configuration saved."
        config_loaded = "Configuration loaded."
        config_load_error = "Error loading configuration. Check logs."
        verify_paths = "Verifying installation paths..."
        path_verified = "Path verified"
        path_verification_failed = "Path verification failed"
        file_copied_verify = "File copied. New timestamp"
        custom_install_root_warning = "For Custom Installations, select the ROOT folder of Minecraft (e.g., C:\\Games\\MinecraftBedrock). BetterRTX files will be placed in 'data\\renderer\\materials' relative to this root."
        bedrock_launcher_versions_info = "Select the 'versions' folder for Bedrock Launcher (e.g., %APPDATA%\\.minecraft_bedrock\\versions)."
        theme_detection_failed = "Could not detect system theme. Defaulting to light."
        theme_applied_light = "Light theme applied."
        theme_applied_dark = "Dark theme applied."
        reverting_shaders = "Reverting shaders for"
    }

    switch ($culture) {
        'pt' {
            Write-Log -Level INFO -Message "Applying Portuguese translations."
            $strings.package_name = "Instalador BetterRTX"
            $strings.browse = "Procurar..."
            $strings.install = "Instalar"
            $strings.install_instance = "Instalar na(s) Instancia(s)"
            $strings.install_all = "Instalar em todas as versoes detetadas"
            $strings.install_pack = "Instalar Predefinicao"
            $strings.install_custom = "Ficheiro .rtpack Personalizado..."
            $strings.uninstall_betterrtx = "Reverter Shaders Originais para Selecionados"
            $strings.uninstalled_success = "Shaders revertidos com sucesso para"
            $strings.uninstalled_failed = "Falha ao reverter shaders para"
            $strings.uninstalled_nobackup = "Nenhum backup inicial encontrado para"
            $strings.copying = "A copiar"
            $strings.downloading = "A descarregar"
            $strings.deleting = "A apagar"
            $strings.expanding_pack = "A extrair o pacote, por favor aguarde..."
            $strings.success = "Sucesso"
            $strings.error = "Erro"
            $strings.error_invalid_file_type = "Tipo de ficheiro invalido. Por favor, selecione um ficheiro .mcpack ou .rtpack."
            $strings.error_no_installations_selected = "Por favor, selecione pelo menos uma instalacao do Minecraft."
            $strings.error_copy_failed = "Nao foi possível copiar para a instalacao do Minecraft. Verifique os logs."
            $strings.error_iobit_missing = "IObit Unlocker nao encontrado. É recomendado para modificar ficheiros de apps da Store."
            $strings.error_config_corrupt = "O ficheiro de configuracao estava corrompido e foi reiniciado. Por favor, adicione novamente os caminhos personalizados."
            $strings.error_network = "Nao foi possível carregar a lista de pacotes. Verifique a sua ligacao a internet."
            $strings.setup = "Configuracao"
            $strings.download = "Descarregar"
            $strings.launchers = "Lancadores"
            $strings.launch = "Iniciar Minecraft"
            $strings.help = "Ajuda"
            $strings.backup = "Fazer Backup dos Shaders Atuais"
            $strings.backup_instance_location = "Selecione o local do backup para a instancia"
            $strings.create_initial_backup = "A criar backup inicial dos shaders"
            $strings.register_rtpack = "Registar Extensao .rtpack"
            $strings.advanced = "Avancado"
            $strings.update_dlss = "Atualizar DLSS"
            $strings.dlss_downloading = "A descarregar DLSS"
            $strings.dlss_updating = "A atualizar DLSS para"
            $strings.dlss_success = "DLSS atualizado com sucesso."
            $strings.manage_installations = "Gerir Instalacoes"
            $strings.add_bl_versions_folder = "Adicionar Pasta de Versoes (Bedrock Launcher)"
            $strings.add_custom_install_folder = "Adicionar Pasta de Instalacao Personalizada"
            $strings.edit_display_name = "Editar Nome de Exibicao"
            $strings.remove_selected_path = "Remover Caminho Selecionado"
            $strings.confirm_remove_path = "Tem a certeza que quer remover este caminho de instalacao? Isto nao apaga os ficheiros do jogo."
            $strings.path_not_found = "Caminho nao encontrado"
            $strings.save_config = "Guardar Configuracao"
            $strings.config_saved = "Configuracao guardada."
            $strings.config_loaded = "Configuracao carregada."
            $strings.config_load_error = "Erro ao carregar a configuracao. Verifique os logs."
            $strings.reverting_shaders = "A reverter shaders para"
        }
        'de' {
            Write-Log -Level INFO -Message "Applying German translations."
            $strings.package_name = "BetterRTX-Installationsprogramm"
            $strings.install_instance = "In Instanz(en) installieren"
            $strings.install_all = "In allen erkannten Versionen installieren"
            $strings.install_pack = "Voreinstellung installieren"
            $strings.install_custom = "Benutzerdefinierte .rtpack-Datei..."
            $strings.uninstall_betterrtx = "Original-Shader für Auswahl wiederherstellen"
            $strings.copying = "Kopieren"
            $strings.downloading = "Herunterladen"
            $strings.deleting = "Löschen"
            $strings.expanding_pack = "Paket wird erweitert, bitte warten..."
            $strings.success = "Erfolg"
            $strings.error = "Fehler"
            $strings.error_no_installations_selected = "Bitte wählen Sie mindestens eine Minecraft-Installation aus."
            $strings.error_network = "Paketliste konnte nicht geladen werden. Bitte überprüfen Sie Ihre Internetverbindung."
            $strings.setup = "Einstellungen"
            $strings.launch = "Minecraft starten"
            $strings.help = "Hilfe"
            $strings.backup = "Aktuelle Shader sichern"
            $strings.register_rtpack = ".rtpack-Erweiterung registrieren"
            $strings.advanced = "Erweitert"
            $strings.update_dlss = "DLSS aktualisieren"
            $strings.manage_installations = "Installationen verwalten"
            $strings.add_bl_versions_folder = "Bedrock Launcher-Versionsordner hinzufügen"
            $strings.add_custom_install_folder = "Benutzerdefinierten Spielinstallationsordner hinzufügen"
            $strings.edit_display_name = "Anzeigenamen bearbeiten"
            $strings.remove_selected_path = "Ausgewählten Pfad entfernen"
        }
        # Adicione outras traducoes parciais aqui, se necessario
    }
    return $strings
}
#endregion

#region Environment and Dependency Detection
function Find-IObitUnlocker {
    Write-Log -Level DEBUG -Message "Attempting to find IObit Unlocker."
    $potentialPaths = @(
        Join-Path -Path ([Environment]::GetFolderPath("ProgramFilesX86")) -ChildPath "IObit\IObit Unlocker\IObitUnlocker.exe"
        Join-Path -Path ([Environment]::GetFolderPath("ProgramFiles")) -ChildPath "IObit\IObit Unlocker\IObitUnlocker.exe"
    )

    foreach ($path in $potentialPaths) {
        if (Test-Path $path) {
            Write-Log -Level SUCCESS -Message "IObit Unlocker found at $path"
            return $path
        }
    }

    $iobitPathViaPath = Get-Command IObitUnlocker.exe -ErrorAction SilentlyContinue
    if ($iobitPathViaPath) {
        Write-Log -Level SUCCESS -Message "IObit Unlocker found via PATH at $($iobitPathViaPath.Source)"
        return $iobitPathViaPath.Source
    }
    
    Write-Log -Level WARN -Message "$($Global:T.error_iobit_missing) (Not found in common paths or PATH)."
    return $null
}

function Get-SystemTheme {
    Write-Log -Level DEBUG -Message "Get-SystemTheme: Function entry."
    try {
        $themeValue = Get-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "AppsUseLightTheme" -ErrorAction SilentlyContinue
        if ($null -ne $themeValue) {
            if ($themeValue.AppsUseLightTheme -eq 0) {
                $theme = "Dark"
            } else {
                $theme = "Light"
            }
            Write-Log -Level THEME -Message "System theme detected: $theme"
            return $theme
        } else {
            Write-Log -Level WARN -Message "Get-SystemTheme: AppsUseLightTheme registry value not found. Defaulting to Light."
            return "Light" 
        }
    } catch {
        Write-Log -Level WARN -Message "Get-SystemTheme: Error reading system theme: $($_.Exception.Message). Defaulting to Light."
        return "Light"
    }
}
#endregion

#region Configuration Management
$Global:dataSrc = [System.Collections.Generic.List[PSCustomObject]]::new()

function Load-Configuration {
    Write-Log -Level INFO -Message "Load-Configuration: Attempting to load from $Global:InstallerConfigPath"
    if (Test-Path $Global:InstallerConfigPath) {
        try {
            $configContentText = Get-Content -Path $Global:InstallerConfigPath -Raw
            if (-not [string]::IsNullOrWhiteSpace($configContentText)) {
                $configContent = $configContentText | ConvertFrom-Json -ErrorAction Stop
                if ($configContent) {
                    $Global:dataSrc.Clear()
                    foreach ($item in $configContent) { $Global:dataSrc.Add([PSCustomObject]$item) }
                    Write-Log -Level SUCCESS -Message "Load-Configuration: $($Global:T.config_loaded) ($($Global:dataSrc.Count) entries)"
                } else {
                     Write-Log -Level WARN -Message "Load-Configuration: Configuration file was empty or invalid after JSON conversion. Resetting."
                     $Global:dataSrc.Clear()
                }
            } else {
                 Write-Log -Level INFO -Message "Load-Configuration: Configuration file is empty. No entries loaded."
                 $Global:dataSrc.Clear()
            }
        } catch {
            Write-Log -Level ERROR -Message "Load-Configuration: $($Global:T.config_load_error): $($_.Exception.Message)"
            Write-Log -Level DEBUG -Message "Load-Configuration: Corrupted config content: $configContentText. Resetting dataSrc."
            $Global:dataSrc.Clear()
            [System.Windows.Forms.MessageBox]::Show($Global:T.error_config_corrupt, "Configuration Error", "OK", "Warning") | Out-Null
        }
    } else {
        Write-Log -Level INFO -Message "Load-Configuration: No configuration file found at $Global:InstallerConfigPath. Starting with default detection."
    }
}

function Save-Configuration {
    Write-Log -Level INFO -Message "Save-Configuration: Attempting to save $($Global:dataSrc.Count) entries to $Global:InstallerConfigPath"
    try {
        $outFileParams = @{
            FilePath = $Global:InstallerConfigPath
            Encoding = 'UTF8'
            Force    = $true
        }
        $Global:dataSrc | ConvertTo-Json -Depth 5 | Out-File @outFileParams
        Write-Log -Level SUCCESS -Message "Save-Configuration: $($Global:T.config_saved)"
    } catch {
        Write-Log -Level ERROR -Message "Save-Configuration: Error saving configuration: $($_.Exception.Message)"
    }
}
#endregion

#region Installation Path Management
function Verify-InstallationPaths {
    Write-Log -Level INFO -Message "Verify-InstallationPaths: Starting verification. Current count: $($Global:dataSrc.Count)"
    $validEntries = [System.Collections.Generic.List[PSCustomObject]]::new()
    $changed = $false
    foreach ($entry in $Global:dataSrc) {
        Write-Log -Level DEBUG -Message "Verify-InstallationPaths: Checking '$($entry.DisplayName)' (Type: $($entry.Type), Path: $($entry.InstallLocation))"
        $pathStillValid = $false
        switch ($entry.Type) {
            "MSStore" {
                $appx = Get-AppxPackage -Name "Microsoft.Minecraft*" | Where-Object {$_.InstallLocation -eq $entry.InstallLocation}
                if ($appx) { $pathStillValid = $true }
            }
            "BedrockLauncherVersion" {
                if (Test-Path (Join-Path -Path $entry.InstallLocation -ChildPath "data\renderer\materials") -PathType Container) {
                    $pathStillValid = $true
                }
            }
            "Custom" {
                 if (Test-Path (Join-Path -Path $entry.InstallLocation -ChildPath "data\renderer\materials") -PathType Container) {
                    $pathStillValid = $true
                }
            }
            default { Write-Log -Level WARN -Message "Verify-InstallationPaths: Unknown entry type '$($entry.Type)' for '$($entry.DisplayName)'" }
        }

        if ($pathStillValid) {
            Write-Log -Level DEBUG -Message "Verify-InstallationPaths: $($Global:T.path_verified): $($entry.DisplayName)"
            $validEntries.Add($entry)
        } else {
            Write-Log -Level WARN -Message "Verify-InstallationPaths: $($Global:T.path_verification_failed) for $($entry.DisplayName) at $($entry.InstallLocation). It might have been moved or deleted."
            $changed = $true
        }
    }
    if ($changed) {
        Write-Log -Level INFO -Message "Verify-InstallationPaths: Path list changed. Old count: $($Global:dataSrc.Count), New count: $($validEntries.Count)."
        $Global:dataSrc = $validEntries
        Save-Configuration 
    } else {
        Write-Log -Level INFO -Message "Verify-InstallationPaths: All paths verified. No changes to configuration."
    }
}

function Add-MSStoreInstallations {
    Write-Log -Level INFO -Message "Add-MSStoreInstallations: Detecting Microsoft Store Minecraft installations..."
    $mcPackages = Get-AppxPackage -Name "Microsoft.Minecraft*" | Where-Object { $_.InstallLocation -notlike "*Java*" }
    foreach ($mc in $mcPackages) {
        $displayName = $mc.Name
        try {
            $manifest = Get-AppxPackageManifest -Package $mc -ErrorAction Stop
            if ($manifest -and $manifest.Package -and $manifest.Package.Properties -and -not [string]::IsNullOrWhiteSpace($manifest.Package.Properties.DisplayName)) {
                $displayName = $manifest.Package.Properties.DisplayName
            }
        } catch {
            Write-Log -Level WARN -Message "Could not read manifest for package $($mc.Name). Using package name as display name."
        }

        $installLocation = $mc.InstallLocation
        
        if (-not ($Global:dataSrc | Where-Object { $_.InstallLocation -eq $installLocation -and $_.Type -eq "MSStore" })) {
            $newEntry = [PSCustomObject]@{
                DisplayName     = $displayName
                InstallLocation = $installLocation
                Type            = "MSStore"
                Preview         = ($mc.InstallLocation -like "*Beta*" -or $displayName -like "*Preview*")
                Id              = [System.Guid]::NewGuid().ToString()
            }
            $Global:dataSrc.Add($newEntry)
            Write-Log -Level DEBUG -Message "Add-MSStoreInstallations: Added MSStore: $displayName (ID: $($newEntry.Id))"
            Backup-InitialShaderFiles -InstallEntry $newEntry
        }
    }
}

function Add-BedrockLauncherVersions {
    param([string]$VersionsFolderPath)
    Write-Log -Level INFO -Message "Add-BedrockLauncherVersions: Looking for versions in: $VersionsFolderPath"
    if (-not (Test-Path $VersionsFolderPath -PathType Container)) {
        Write-Log -Level WARN -Message "Add-BedrockLauncherVersions: Folder not found: $VersionsFolderPath"
        [System.Windows.Forms.MessageBox]::Show($Global:T.path_not_found + ": $VersionsFolderPath", $Global:T.error, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
        return
    }

    Get-ChildItem -Path $VersionsFolderPath -Directory | ForEach-Object {
        $versionPath = $_.FullName
        $versionName = $_.Name
        if (-not (Test-Path (Join-Path -Path $versionPath -ChildPath "data\renderer\materials") -PathType Container)) {
            Write-Log -Level DEBUG -Message "Add-BedrockLauncherVersions: Skipping '$versionName' as it does not appear to be a valid version."
            return 
        }

        if (-not ($Global:dataSrc | Where-Object { $_.InstallLocation -eq $versionPath -and $_.Type -eq "BedrockLauncherVersion" })) {
            $newEntry = [PSCustomObject]@{
                DisplayName     = "Bedrock Launcher - $versionName"
                InstallLocation = $versionPath 
                Type            = "BedrockLauncherVersion"
                Preview         = $false 
                Id              = [System.Guid]::NewGuid().ToString()
                ParentVersionsFolder = $VersionsFolderPath 
            }
            $Global:dataSrc.Add($newEntry)
            Write-Log -Level DEBUG -Message "Add-BedrockLauncherVersions: Added Version: $versionName (ID: $($newEntry.Id))"
            Backup-InitialShaderFiles -InstallEntry $newEntry
        } else {
            Write-Log -Level DEBUG -Message "Add-BedrockLauncherVersions: Version '$versionName' already exists in configuration."
        }
    }
}

function Add-CustomInstallation {
    param([string]$CustomPath)
    Write-Log -Level INFO -Message "Add-CustomInstallation: Adding path: $CustomPath"
    if (-not (Test-Path $CustomPath -PathType Container)) {
        Write-Log -Level WARN -Message "Add-CustomInstallation: Path not found: $CustomPath"
        [System.Windows.Forms.MessageBox]::Show($Global:T.path_not_found + ": $CustomPath", $Global:T.error, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
        return
    }
     if (-not (Test-Path (Join-Path -Path $CustomPath -ChildPath "data\renderer\materials") -PathType Container)) {
        Write-Log -Level WARN -Message "Add-CustomInstallation: The path '$CustomPath' does not appear to be a valid Minecraft Bedrock root."
        [System.Windows.Forms.MessageBox]::Show($Global:T.custom_install_root_warning, "Aviso", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning) | Out-Null
    }

    if (-not ($Global:dataSrc | Where-Object { $_.InstallLocation -eq $CustomPath -and $_.Type -eq "Custom" })) {
        $newEntry = [PSCustomObject]@{
            DisplayName     = "Custom - $(Split-Path $CustomPath -Leaf)"
            InstallLocation = $CustomPath 
            Type            = "Custom"
            Preview         = $false
            Id              = [System.Guid]::NewGuid().ToString()
        }
        $Global:dataSrc.Add($newEntry)
        Write-Log -Level DEBUG -Message "Add-CustomInstallation: Added Custom Installation: $CustomPath (ID: $($newEntry.Id))"
        Backup-InitialShaderFiles -InstallEntry $newEntry
    } else {
        Write-Log -Level DEBUG -Message "Add-CustomInstallation: Custom path '$CustomPath' already exists in configuration."
    }
}
#endregion

#region Core File Operations
function Get-EffectiveInstallPath {
    param ([PSCustomObject]$InstallEntry)
    return $InstallEntry.InstallLocation
}
function Get-MaterialsPath {
    param ([PSCustomObject]$InstallEntry)
    $base = Get-EffectiveInstallPath -InstallEntry $InstallEntry
    if ($base) {
        return (Join-Path -Path $base -ChildPath "data\renderer\materials")
    }
    return $null
}
function Get-DlssPath {
    param ([PSCustomObject]$InstallEntry)
    $base = Get-EffectiveInstallPath -InstallEntry $InstallEntry
    if ($base) {
        return (Join-Path -Path $base -ChildPath "nvngx_dlss.dll")
    }
    return $null
}

function IoBitDelete {
    param([string[]]$FilePathsToDelete)
    if (-not $Global:ioBitExe) { Write-Log -Level WARN -Message "IoBitDelete: IObit Unlocker not available."; return $false }
    Write-Log -Level DEBUG -Message "IoBitDelete: Attempting to delete: $($FilePathsToDelete -join ', ')"
    $existingFiles = $FilePathsToDelete | Where-Object { Test-Path $_ }
    if ($existingFiles.Count -eq 0) { Write-Log -Level INFO -Message "IoBitDelete: No files to delete (all paths non-existent)."; return $true }
    
    $arguments = "/Delete " + (($existingFiles | ForEach-Object { "`"$_`"" }) -join ",")
    Write-Log -Level DEBUG -Message "IoBitDelete: Arguments: $arguments"
    $processOptions = @{ FilePath = $Global:ioBitExe; ArgumentList = $arguments.TrimEnd(","); Wait = $true; PassThru = $true; WindowStyle = "Hidden" }
    try {
        $deleteProc = Start-Process @processOptions -ErrorAction Stop
        Write-Log -Level DEBUG -Message "IoBitDelete: Process exit code: $($deleteProc.ExitCode)"
        if ($deleteProc.ExitCode -ne 0) {
            Write-Log -Level WARN -Message "IoBitDelete: IObit process exited with non-zero code: $($deleteProc.ExitCode)."
            return $false
        }
        $stillExist = $existingFiles | Where-Object { Test-Path $_ }
        if ($stillExist.Count -gt 0) { Write-Log -Level WARN -Message "IoBitDelete: Some files may still exist: $($stillExist -join ', ')"; return $false }
        return $true
    } catch { Write-Log -Level ERROR -Message "IoBitDelete: Failed to start IObit process: $($_.Exception.Message)"; return $false }
}

function IoBitCopy {
    param([string[]]$SourceMaterialFiles, [string]$DestinationMaterialFolder)
    if (-not $Global:ioBitExe) { Write-Log -Level WARN -Message "IoBitCopy: IObit Unlocker not available."; return $false }
    Write-Log -Level DEBUG -Message "IoBitCopy: Attempting to copy to $DestinationMaterialFolder"
    $allCopied = $true
    foreach ($sourceFile in $SourceMaterialFiles) {
        if (-not (Test-Path $sourceFile)) { Write-Log -Level WARN -Message "IoBitCopy: Source file not found: $sourceFile"; $allCopied = $false; continue }
        $fileName = Split-Path -Path $sourceFile -Leaf
        $destinationFilePath = Join-Path -Path $DestinationMaterialFolder -ChildPath $fileName
        Write-Log -Level DEBUG -Message "IoBitCopy: Copying `"$sourceFile`" to `"$DestinationMaterialFolder`""
        $arguments = "/Copy `"$sourceFile`" `"$DestinationMaterialFolder`""
        Write-Log -Level DEBUG -Message "IoBitCopy: Arguments: $arguments"
        $processOptions = @{ FilePath = $Global:ioBitExe; ArgumentList = $arguments; Wait = $true; PassThru = $true; WindowStyle = "Hidden" }
        try {
            $copyProc = Start-Process @processOptions -ErrorAction Stop
            Write-Log -Level DEBUG -Message "IoBitCopy: Process for $fileName exit code: $($copyProc.ExitCode)"
            if ($copyProc.ExitCode -ne 0 -or -not (Test-Path $destinationFilePath)) { 
                Write-Log -Level WARN -Message "IoBitCopy: File copy failed for $fileName. ExitCode: $($copyProc.ExitCode)"; $allCopied = $false 
            }
            else { 
                $destTimestamp = (Get-Item $destinationFilePath).LastWriteTime
                Write-Log -Level INFO -Message ("IoBitCopy: {0} for {1}: {2}" -f $Global:T.file_copied_verify, $fileName, $destTimestamp) 
            }
        } catch { Write-Log -Level ERROR -Message ("IoBitCopy: Failed to start IObit process for {0}: {1}" -f $sourceFile, $_.Exception.Message); $allCopied = $false }
    }
    return $allCopied
}

function StandardDelete {
    param([string[]]$FilePathsToDelete)
    Write-Log -Level DEBUG -Message "StandardDelete: Attempting to delete: $($FilePathsToDelete -join ', ')"
    $allDeleted = $true
    foreach ($filePath in $FilePathsToDelete) {
        if (Test-Path $filePath) {
            try { Remove-Item -Path $filePath -Force -ErrorAction Stop; Write-Log -Level DEBUG -Message "StandardDelete: Successful for $filePath" }
            catch { Write-Log -Level WARN -Message ("StandardDelete: Failed for {0}: {1}" -f $filePath, $_.Exception.Message); $allDeleted = $false }
        } else { Write-Log -Level DEBUG -Message "StandardDelete: File not found, skipping: $filePath" }
    }
    return $allDeleted
}

function StandardCopy {
    param([string[]]$SourceMaterialFiles, [string]$DestinationMaterialFolder)
    Write-Log -Level DEBUG -Message "StandardCopy: Attempting to copy to $DestinationMaterialFolder"
    if (-not (Test-Path $DestinationMaterialFolder)) {
        try { New-Item -ItemType Directory -Path $DestinationMaterialFolder -Force -ErrorAction Stop | Out-Null }
        catch { Write-Log -Level ERROR -Message ("StandardCopy: Failed to create destination directory {0}: {1}" -f $DestinationMaterialFolder, $_.Exception.Message); return $false }
    }
    $allCopied = $true
    foreach ($sourceFile in $SourceMaterialFiles) {
        if (-not (Test-Path $sourceFile)) { Write-Log -Level WARN -Message "StandardCopy: Source file not found: $sourceFile"; $allCopied = $false; continue }
        $fileName = Split-Path -Path $sourceFile -Leaf
        $destinationFilePath = Join-Path -Path $DestinationMaterialFolder -ChildPath $fileName
        try { 
            Copy-Item -Path $sourceFile -Destination $destinationFilePath -Force -ErrorAction Stop
            $destTimestamp = (Get-Item $destinationFilePath).LastWriteTime
            Write-Log -Level INFO -Message ("StandardCopy: {0} for {1}: {2}" -f $Global:T.file_copied_verify, $fileName, $destTimestamp) 
        }
        catch { Write-Log -Level WARN -Message ("StandardCopy: Failed for {0} to {1}: {2}" -f $sourceFile, $destinationFilePath, $_.Exception.Message); $allCopied = $false }
    }
    return $allCopied
}

function Copy-ShaderFilesInternal {
    param([PSCustomObject]$InstallEntry, [string[]]$SourceMaterialFullPaths)
    Write-Log -Level INFO -Message "Copy-ShaderFilesInternal: For '$($InstallEntry.DisplayName)', Type: '$($InstallEntry.Type)'"
    $materialsDestFolder = Get-MaterialsPath -InstallEntry $InstallEntry
    if (-not $materialsDestFolder) { Write-Log -Level ERROR -Message "Copy-ShaderFilesInternal: Could not determine materials path for $($InstallEntry.DisplayName)."; return $false }
    
    Write-Log -Level INFO -Message "Copy-ShaderFilesInternal: Preparing to copy shaders to $materialsDestFolder"
    $isStoreApp = $InstallEntry.Type -eq "MSStore"; $useIoBit = $isStoreApp -and $Global:ioBitExe
    Write-Log -Level DEBUG -Message "Copy-ShaderFilesInternal: isStoreApp=$isStoreApp, useIoBit=$useIoBit"
    
    $existingMaterialFilesToDelete = @()
    foreach ($srcFile in $SourceMaterialFullPaths) { $existingMaterialFilesToDelete += Join-Path -Path $materialsDestFolder -ChildPath (Split-Path -Path $srcFile -Leaf) }
    
    Write-Log -Level INFO -Message "Copy-ShaderFilesInternal: Attempting to delete existing files..."
    $deleteSuccess = if ($useIoBit) { IoBitDelete -FilePathsToDelete $existingMaterialFilesToDelete } else { StandardDelete -FilePathsToDelete $existingMaterialFilesToDelete }
    if (-not $deleteSuccess) { Write-Log -Level WARN -Message "Copy-ShaderFilesInternal: Failed to delete one or more existing files in $materialsDestFolder." }
    else { Write-Log -Level INFO -Message "Copy-ShaderFilesInternal: Successfully deleted existing files (or they didn't exist)." }
    
    Start-Sleep -Milliseconds 200
    
    Write-Log -Level INFO -Message "Copy-ShaderFilesInternal: Attempting to copy new materials..."
    $copySuccess = if ($useIoBit) { IoBitCopy -SourceMaterialFiles $SourceMaterialFullPaths -DestinationMaterialFolder $materialsDestFolder } else { StandardCopy -SourceMaterialFiles $SourceMaterialFullPaths -DestinationMaterialFolder $materialsDestFolder }
    if (-not $copySuccess) { Write-Log -Level ERROR -Message "Copy-ShaderFilesInternal: $($Global:T.error_copy_failed) for $($InstallEntry.DisplayName)."; return $false }
    
    Write-Log -Level SUCCESS -Message "Copy-ShaderFilesInternal: Successfully copied shader files for $($InstallEntry.DisplayName)."; return $true
}
#endregion

#region Backup and Restore
function Backup-InitialShaderFiles {
    param(
        [PSCustomObject]$InstallEntry, 
        [string[]]$MaterialsToBackup = @("RTXStub.material.bin", "RTXPostFX.Tonemapping.material.bin", "RTXPostFX.Bloom.material.bin"), 
        [string]$DLSSdllName = "nvngx_dlss.dll"
    )
    $backupInstanceDir = Join-Path -Path $Global:BRTX_DIR -ChildPath "initial_backup\$($InstallEntry.Id)"
    if (Test-Path $backupInstanceDir) {
        Write-Log -Level DEBUG -Message "Backup-InitialShaderFiles: Backup already exists for '$($InstallEntry.DisplayName)' (ID: $($InstallEntry.Id)). Skipping."
        return $true
    }
    Write-Log -Level INFO -Message "Backup-InitialShaderFiles: For '$($InstallEntry.DisplayName)' (ID: $($InstallEntry.Id)) to $backupInstanceDir"
    try {
        New-Item -ItemType Directory -Path $backupInstanceDir -Force -ErrorAction Stop | Out-Null
        $materialsSourceFolder = Get-MaterialsPath -InstallEntry $InstallEntry
        if ($materialsSourceFolder -and (Test-Path $materialsSourceFolder)) {
            foreach ($file in $MaterialsToBackup) {
                $srcMaterialPath = Join-Path -Path $materialsSourceFolder -ChildPath $file
                if (Test-Path $srcMaterialPath) { Copy-Item -Path $srcMaterialPath -Destination $backupInstanceDir -Force -ErrorAction Stop; Write-Log -Level DEBUG -Message "Backup-InitialShaderFiles: Backed up $file" }
                else { Write-Log -Level WARN -Message "Backup-InitialShaderFiles: Source material not found $srcMaterialPath" }
            }
        } else { Write-Log -Level WARN -Message "Backup-InitialShaderFiles: Materials source folder not found or invalid: $materialsSourceFolder" }
        
        $dlssSourcePath = Get-DlssPath -InstallEntry $InstallEntry
        if ($dlssSourcePath -and (Test-Path $dlssSourcePath)) { Copy-Item -Path $dlssSourcePath -Destination (Join-Path -Path $backupInstanceDir -ChildPath $DLSSdllName) -Force -ErrorAction Stop; Write-Log -Level DEBUG -Message "Backup-InitialShaderFiles: Backed up $DLSSdllName" }
        else { Write-Log -Level WARN -Message "Backup-InitialShaderFiles: DLSS source file not found $dlssSourcePath" }
        return $true
    } catch { Write-Log -Level ERROR -Message "Backup-InitialShaderFiles: Failed for $($InstallEntry.DisplayName): $($_.Exception.Message)"; return $false }
}

function Backup-ShaderFilesToUserLocation {
    param([PSCustomObject]$InstallEntry)
    Write-Log -Level INFO -Message "Backup-ShaderFilesToUserLocation: For '$($InstallEntry.DisplayName)'"
    $tempBackupDir = Join-Path -Path $Global:BRTX_DIR -ChildPath "temp_user_backup\$($InstallEntry.Id)"
    if (Test-Path $tempBackupDir) { Remove-Item -Path $tempBackupDir -Recurse -Force }
    New-Item -ItemType Directory -Path $tempBackupDir -Force | Out-Null
    
    $materialsSourceFolder = Get-MaterialsPath -InstallEntry $InstallEntry
    if ($materialsSourceFolder -and (Test-Path $materialsSourceFolder)) {
        Get-ChildItem -Path $materialsSourceFolder -Filter "*.material.bin" | ForEach-Object { Copy-Item -Path $_.FullName -Destination $tempBackupDir -Force }
        Write-Log -Level DEBUG -Message "Backup-ShaderFilesToUserLocation: Copied .material.bin files from $materialsSourceFolder"
    } else { Write-Log -Level WARN -Message "Backup-ShaderFilesToUserLocation: No materials source folder found for $($InstallEntry.DisplayName)"}
    
    $dlssSourcePath = Get-DlssPath -InstallEntry $InstallEntry
    if ($dlssSourcePath -and (Test-Path $dlssSourcePath)) { Copy-Item -Path $dlssSourcePath -Destination (Join-Path $tempBackupDir (Split-Path $dlssSourcePath -Leaf)) -Force; Write-Log -Level DEBUG -Message "Backup-ShaderFilesToUserLocation: Copied DLSS from $dlssSourcePath" }
    else {Write-Log -Level WARN -Message "Backup-ShaderFilesToUserLocation: No DLSS file found for $($InstallEntry.DisplayName)"}
    
    if((Get-ChildItem $tempBackupDir).Count -eq 0) {
        Write-Log -Level WARN -Message "Backup-ShaderFilesToUserLocation: No files found to backup for $($InstallEntry.DisplayName)"
        [System.Windows.Forms.MessageBox]::Show("No shader or DLSS files found in the current installation of '$($InstallEntry.DisplayName)' to backup.", "Backup Warning", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning) | Out-Null
        Remove-Item -Path $tempBackupDir -Recurse -Force
        return $false
    }

    $safeDisplayName = $InstallEntry.DisplayName -replace '[^a-zA-Z0-9_-]', '_'
    $zipFilename = "betterrtx_current_backup_$($safeDisplayName)_$(Get-Date -Format "yyyyMMdd_HHmmss").zip"
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog; $dialog.Description = "$($Global:T.backup_instance_location) `"$($InstallEntry.DisplayName)`""
    if ($dialog.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { Write-Log -Level INFO -Message "Backup-ShaderFilesToUserLocation: User cancelled."; Remove-Item -Path $tempBackupDir -Recurse -Force; return $false }
    
    $zipOutputPath = Join-Path -Path $dialog.SelectedPath -ChildPath $zipFilename
    try {
        Compress-Archive -Path "$tempBackupDir\*" -DestinationPath $zipOutputPath -Force
        Write-Log -Level SUCCESS -Message "Backup-ShaderFilesToUserLocation: Backup created: $zipOutputPath"
        Rename-Item -Path $zipOutputPath -NewName ($zipOutputPath -replace '\.zip$', '.rtpack') -Force
        Write-Log -Level INFO -Message "Backup-ShaderFilesToUserLocation: Backup renamed to .rtpack"
    } catch { Write-Log -Level ERROR -Message "Backup-ShaderFilesToUserLocation: Failed to create/rename archive: $($_.Exception.Message)"; return $false }
    finally { if (Test-Path $tempBackupDir) {Remove-Item -Path $tempBackupDir -Recurse -Force} }
    return $true
}

function Uninstall-BetterRTXFromInstance {
    param([PSCustomObject]$InstallEntry)
    Write-Log -Level INFO -Message "Uninstall-BetterRTXFromInstance: For '$($InstallEntry.DisplayName)'"
    $StatusLabel.Text = "$($Global:T.reverting_shaders) $($InstallEntry.DisplayName)..."; $StatusLabel.ForeColor = [System.Drawing.Color]::Blue; $StatusLabel.Visible = $true; $form.Refresh()
    $initialBackupInstanceDir = Join-Path -Path $Global:BRTX_DIR -ChildPath "initial_backup\$($InstallEntry.Id)"
    if (-not (Test-Path $initialBackupInstanceDir)) {
        Write-Log -Level WARN -Message "Uninstall-BetterRTXFromInstance: $($Global:T.uninstalled_nobackup) '$($InstallEntry.DisplayName)'"
        $StatusLabel.Text = "$($Global:T.uninstalled_nobackup) '$($InstallEntry.DisplayName)'"; $StatusLabel.ForeColor = [System.Drawing.Color]::Orange
        return $false
    }
    $backedUpMaterials = Get-ChildItem -Path $initialBackupInstanceDir -Filter "*.material.bin" -File | Select-Object -ExpandProperty FullName
    $backedUpDlss = Get-ChildItem -Path $initialBackupInstanceDir -Filter "nvngx_dlss.dll" -File | Select-Object -ExpandProperty FullName
    
    $revertSuccess = $true
    if ($backedUpMaterials.Count -gt 0) {
        Write-Log -Level DEBUG -Message "Uninstall-BetterRTXFromInstance: Reverting materials..."
        if (-not (Copy-ShaderFilesInternal -InstallEntry $InstallEntry -SourceMaterialFullPaths $backedUpMaterials)) {
            $revertSuccess = $false
            Write-Log -Level ERROR -Message "Uninstall-BetterRTXFromInstance: Failed to revert materials for '$($InstallEntry.DisplayName)'."
        }
    } else { Write-Log -Level INFO -Message "Uninstall-BetterRTXFromInstance: No backed up .material.bin files found." }

    if ($backedUpDlss) {
        Write-Log -Level DEBUG -Message "Uninstall-BetterRTXFromInstance: Reverting DLSS..."
        $targetDlssPath = Get-DlssPath -InstallEntry $InstallEntry
        $targetDlssDir = Split-Path $targetDlssPath
        $isStoreApp = $InstallEntry.Type -eq "MSStore"; $useIoBit = $isStoreApp -and $Global:ioBitExe
        try {
            if (Test-Path $targetDlssPath) {
                $deleteSuccess = if ($useIoBit) { IoBitDelete -FilePathsToDelete @($targetDlssPath) } else { StandardDelete -FilePathsToDelete @($targetDlssPath) }
                if (-not $deleteSuccess) { throw "Failed to delete existing DLSS before revert." }
            }
            if ($useIoBit) {
                 $arguments = "/Copy `"$backedUpDlss`" `"$targetDlssDir`""
                 $proc = Start-Process $Global:ioBitExe -ArgumentList $arguments -Wait -PassThru -WindowStyle Hidden -ErrorAction Stop
                 if ($proc.ExitCode -ne 0 -or -not (Test-Path $targetDlssPath)) { throw "IObit copy failed for DLSS revert (ExitCode: $($proc.ExitCode))." }
            } else {
                if (-not (Test-Path $targetDlssDir)) { New-Item -ItemType Directory -Path $targetDlssDir -Force | Out-Null }
                Copy-Item -Path $backedUpDlss -Destination $targetDlssPath -Force -ErrorAction Stop
            }
            Write-Log -Level INFO -Message "Uninstall-BetterRTXFromInstance: DLSS reverted for '$($InstallEntry.DisplayName)'."
        } catch {
            Write-Log -Level ERROR -Message "Uninstall-BetterRTXFromInstance: Failed to revert DLSS for '$($InstallEntry.DisplayName)': $($_.Exception.Message)"
            $revertSuccess = $false
        }
    } else { Write-Log -Level INFO -Message "Uninstall-BetterRTXFromInstance: No backed up DLSS file found." }
    
    if ($revertSuccess) { Write-Log -Level SUCCESS -Message "Uninstall-BetterRTXFromInstance: $($Global:T.uninstalled_success) '$($InstallEntry.DisplayName)'." }
    else { Write-Log -Level ERROR -Message "Uninstall-BetterRTXFromInstance: $($Global:T.uninstalled_failed) '$($InstallEntry.DisplayName)'." }
    return $revertSuccess
}
#endregion

#region Pack and DLSS Handling
function Expand-Pack {
    param([string]$PackPath)
    $PackName = [System.IO.Path]::GetFileNameWithoutExtension($PackPath)
    $PackDirName = Join-Path -Path $Global:BRTX_DIR -ChildPath "packs\$PackName"
    Write-Log -Level DEBUG -Message "Expand-Pack: Expanding '$PackName' from '$PackPath' to '$PackDirName'"
    if (Test-Path $PackDirName) { Remove-Item -Path $PackDirName -Recurse -Force }
    New-Item -ItemType Directory -Path $PackDirName -Force | Out-Null
    $tempZipPath = Join-Path -Path $PackDirName -ChildPath "$PackName.zip"
    Copy-Item -Path $PackPath -Destination $tempZipPath -Force
    Expand-Archive -Path $tempZipPath -DestinationPath $PackDirName -Force
    Remove-Item -Path $tempZipPath -Force
    Write-Log -Level DEBUG -Message "Expand-Pack: Pack expanded."; return $PackDirName
}

function Install-DLSSInternal {
    param([PSCustomObject]$InstallEntry)
    Write-Log -Level INFO -Message "Install-DLSSInternal: For '$($InstallEntry.DisplayName)'"
    $dlssCacheDir = Join-Path -Path $Global:BRTX_DIR -ChildPath "dlss_cache"
    $downloadedDlssDll = Join-Path -Path $dlssCacheDir -ChildPath "nvngx_dlss.dll"
    $StatusLabel.Text = "$($Global:T.dlss_updating) $($InstallEntry.DisplayName)..."; $StatusLabel.ForeColor = [System.Drawing.Color]::Blue; $StatusLabel.Visible = $true; $form.Refresh()
    
    if (-not (Test-Path $downloadedDlssDll)) {
        Write-Log -Level INFO -Message "Install-DLSSInternal: DLSS not found in cache. Downloading..."; $StatusLabel.Text = $Global:T.dlss_downloading; $form.Refresh()
        New-Item -ItemType Directory -Path $dlssCacheDir -Force -ErrorAction SilentlyContinue | Out-Null
        try {
            $response = Invoke-WebRequest -Uri "https://bedrock.graphics/api/dlss" -ContentType "application/json" -UseBasicParsing -ErrorAction Stop
            $versions = $response.Content | ConvertFrom-Json -ErrorAction Stop
            Invoke-WebRequest -Uri $versions.latest -OutFile (Join-Path $dlssCacheDir "nvngx_dlss.zip") -UseBasicParsing -ErrorAction Stop
            Expand-Archive -Path (Join-Path $dlssCacheDir "nvngx_dlss.zip") -DestinationPath $dlssCacheDir -Force -ErrorAction Stop
            Remove-Item -Path (Join-Path $dlssCacheDir "nvngx_dlss.zip") -Force
            if (-not (Test-Path $downloadedDlssDll)) { throw "DLSS DLL not found after download and extraction."}
            Write-Log -Level SUCCESS -Message "Install-DLSSInternal: DLSS downloaded and extracted to cache."
        } catch { Write-Log -Level ERROR -Message "Install-DLSSInternal: Failed to download/extract DLSS: $($_.Exception.Message)"; $StatusLabel.Text = "$($Global:T.error): DLSS download failed."; $StatusLabel.ForeColor = [System.Drawing.Color]::Red; return $false }
    }
    
    $targetDlssPath = Get-DlssPath -InstallEntry $InstallEntry
    if (-not $targetDlssPath) { Write-Log -Level ERROR -Message "Install-DLSSInternal: Could not determine DLSS path for $($InstallEntry.DisplayName)."; $StatusLabel.Text = "$($Global:T.error): Invalid DLSS path."; $StatusLabel.ForeColor = [System.Drawing.Color]::Red; return $false }
    
    $targetDlssDir = Split-Path $targetDlssPath
    $isStoreApp = $InstallEntry.Type -eq "MSStore"; $useIoBit = $isStoreApp -and $Global:ioBitExe
    Write-Log -Level DEBUG -Message "Install-DLSSInternal: Target DLSS path: $targetDlssPath. Use IObit: $useIoBit"
    try {
        if (Test-Path $targetDlssPath) {
            Write-Log -Level INFO -Message "Install-DLSSInternal: Existing DLSS file found. Attempting to delete..."
            $deleteSuccess = if ($useIoBit) { IoBitDelete -FilePathsToDelete @($targetDlssPath) } else { StandardDelete -FilePathsToDelete @($targetDlssPath) }
            if (-not $deleteSuccess) { throw "Failed to delete existing DLSS file: $targetDlssPath" }
            Write-Log -Level INFO -Message "Install-DLSSInternal: Old DLSS file deleted."; Start-Sleep -Milliseconds 200
        }
        
        Write-Log -Level INFO -Message "Install-DLSSInternal: Copying new DLSS to $targetDlssDir"
        if ($useIoBit) {
            $arguments = "/Copy `"$downloadedDlssDll`" `"$targetDlssDir`""
            $proc = Start-Process $Global:ioBitExe -ArgumentList $arguments -Wait -PassThru -WindowStyle Hidden -ErrorAction Stop
            if ($proc.ExitCode -ne 0 -or -not (Test-Path $targetDlssPath)) { throw "IObit copy failed for DLSS (ExitCode: $($proc.ExitCode))." }
        } else {
            if (-not (Test-Path $targetDlssDir)) { New-Item -ItemType Directory -Path $targetDlssDir -Force | Out-Null }
            Copy-Item -Path $downloadedDlssDll -Destination $targetDlssPath -Force -ErrorAction Stop
        }
        
        if (Test-Path $targetDlssPath) { $newTimestamp = (Get-Item $targetDlssPath).LastWriteTime; Write-Log -Level SUCCESS -Message "Install-DLSSInternal: DLSS successfully updated for $($InstallEntry.DisplayName). New timestamp: $newTimestamp"; return $true }
        else { throw "DLSS file not found at target after copy: $targetDlssPath" }
    } catch { Write-Log -Level ERROR -Message "Install-DLSSInternal: Error updating DLSS for $($InstallEntry.DisplayName): $($_.Exception.Message)"; $StatusLabel.Text = "$($Global:T.error): DLSS update failed."; $StatusLabel.ForeColor = [System.Drawing.Color]::Red; return $false }
}
#endregion

#region System Integration
function Register-RtpackExtension {
    param([string]$InstallerPath)
    Write-Log -Level INFO -Message "Register-RtpackExtension: Registering with installer path $InstallerPath"
    $rtpackKey = "Registry::HKEY_CURRENT_USER\Software\Classes\.rtpack"
    $rtpackAppKey = "Registry::HKEY_CURRENT_USER\Software\Classes\BetterRTX.PackageFile"
    try {
        if (Test-Path $rtpackKey) { Remove-Item -Path $rtpackKey -Recurse -Force }
        if (Test-Path $rtpackAppKey) { Remove-Item -Path $rtpackAppKey -Recurse -Force }
        
        New-Item -Path $rtpackKey -Force | Out-Null; Set-ItemProperty -Path $rtpackKey -Name "(Default)" -Value "BetterRTX.PackageFile" -Force
        New-Item -Path $rtpackAppKey -Force | Out-Null; Set-ItemProperty -Path $rtpackAppKey -Name "(Default)" -Value "BetterRTX Preset" -Force
        
        $batPath = Join-Path -Path $Global:BRTX_DIR -ChildPath "install_rtpack.bat"
        $batContent = "@echo off`r`npowershell.exe -ExecutionPolicy Bypass -File `"$InstallerPath`" `"%1`""
        Set-Content -Path $batPath -Value $batContent -Encoding ASCII -Force
        
        New-Item -Path "$rtpackAppKey\shell\open\command" -Force | Out-Null
        Set-ItemProperty -Path "$rtpackAppKey\shell\open\command" -Name "(Default)" -Value "`"$batPath`" `"%1`"" -Force
        
        $iconPath = Join-Path -Path $Global:BRTX_DIR -ChildPath "rtpack.ico"
        if (-not (Test-Path $iconPath)) {
            $iconUrl = "https://bedrock.graphics/favicon.ico"; Write-Log -Level DEBUG -Message "Register-RtpackExtension: Downloading icon from $iconUrl"
            Invoke-WebRequest -Uri $iconUrl -OutFile $iconPath -UseBasicParsing -ErrorAction Stop
        }
        New-Item -Path "$rtpackAppKey\DefaultIcon" -Force -ErrorAction SilentlyContinue | Out-Null
        Set-ItemProperty -Path "$rtpackAppKey\DefaultIcon" -Name "(Default)" -Value "$iconPath,0" -Force
        
        try {
            $signature = '[System.Runtime.InteropServices.DllImport("shell32.dll", CharSet = System.Runtime.InteropServices.CharSet.Auto, SetLastError = true)] public static extern void SHChangeNotify(long wEventId, uint uFlags, System.IntPtr dwItem1, System.IntPtr dwItem2);'
            Add-Type -MemberDefinition $signature -Namespace WinAPI -Name ShellUtils -UsingNamespace System.Text -ErrorAction SilentlyContinue
            [WinAPI.ShellUtils]::SHChangeNotify(0x08000000, 0x0000, [System.IntPtr]::Zero, [System.IntPtr]::Zero)
            Write-Log -Level INFO -Message "Register-RtpackExtension: Shell notified of association change."
        } catch {
            Write-Log -Level WARN -Message "Register-RtpackExtension: Could not notify shell of association change. A restart might be needed to see the new icon."
        }
        Write-Log -Level SUCCESS -Message "Register-RtpackExtension: Successfully registered .rtpack extension."
    } catch { Write-Log -Level ERROR -Message "Register-RtpackExtension: Failed: $($_.Exception.Message)" }
}
#endregion

#region Main Application Logic and GUI
function Show-CliInstallDialog {
    param([string]$PackToInstallPath)
    
    if (-not (Test-Path $PackToInstallPath)) {
        Write-Log -Level ERROR -Message "CLI Mode: Pack file specified in argument not found: $PackToInstallPath"
        [System.Windows.Forms.MessageBox]::Show($Global:T.path_not_found + ": $PackToInstallPath", $Global:T.error, "OK", "Error") | Out-Null; return
    }
    
    $formArgInstall = New-Object System.Windows.Forms.Form; $formArgInstall.Text = "Install Pack: $(Split-Path $PackToInstallPath -Leaf)"; $formArgInstall.Size = New-Object System.Drawing.Size(450, 400); $formArgInstall.StartPosition = "CenterScreen"
    $labelArg = New-Object System.Windows.Forms.Label; $labelArg.Text = "Select installations to apply this pack to:"; $labelArg.AutoSize = $true; $labelArg.Location = New-Object System.Drawing.Point(10, 10); $formArgInstall.Controls.Add($labelArg)
    $listBoxArg = New-Object System.Windows.Forms.ListBox; $listBoxArg.Location = New-Object System.Drawing.Point(10, 40); $listBoxArg.Size = New-Object System.Drawing.Size(410, 250); $listBoxArg.SelectionMode = "MultiExtended"; $Global:dataSrc | ForEach-Object { $listBoxArg.Items.Add($_.DisplayName) | Out-Null }; $formArgInstall.Controls.Add($listBoxArg)
    $buttonArgInstall = New-Object System.Windows.Forms.Button; $buttonArgInstall.Text = "Install"; $buttonArgInstall.Location = New-Object System.Drawing.Point(170, 300); $buttonArgInstall.Size = New-Object System.Drawing.Size(100, 30); $formArgInstall.Controls.Add($buttonArgInstall)
    
    $buttonArgInstall.Add_Click({
        $selectedInstallationsDisplayNames = $listBoxArg.SelectedItems
        if ($selectedInstallationsDisplayNames.Count -eq 0) { [System.Windows.Forms.MessageBox]::Show($Global:T.error_no_installations_selected, $Global:T.error, "OK", "Error") | Out-Null; return }
        
        Write-Log -Level INFO -Message "CLI Install: User selected $($selectedInstallationsDisplayNames.Count) installations."
        $packDir = $null; 
        try { $packDir = Expand-Pack -PackPath $PackToInstallPath } catch { Write-Log -Level ERROR -Message "CLI Install: Failed to expand pack: $($_.Exception.Message)"; [System.Windows.Forms.MessageBox]::Show("Failed to expand pack.", $Global:T.error, "OK", "Error") | Out-Null; return }
        
        $materialsToInstall = Get-ChildItem -Path $packDir -Recurse -Filter "*.material.bin" -File | Select-Object -ExpandProperty FullName
        if ($materialsToInstall.Count -eq 0) { Write-Log -Level WARN -Message "CLI Install: No .material.bin files found in pack."; [System.Windows.Forms.MessageBox]::Show("No .material.bin files found in the pack.", "Aviso", "OK", "Warning") | Out-Null; if ($packDir) { Remove-Item -Path $packDir -Recurse -Force }; return }
        
        $overallSuccess = $true
        foreach ($displayName in $selectedInstallationsDisplayNames) {
            $installEntry = $Global:dataSrc | Where-Object { $_.DisplayName -eq $displayName } | Select-Object -First 1
            if ($installEntry) { 
                Write-Log -Level INFO -Message "CLI Install: Installing to $($installEntry.DisplayName)"
                if (-not (Copy-ShaderFilesInternal -InstallEntry $installEntry -SourceMaterialFullPaths $materialsToInstall)) { $overallSuccess = $false; Write-Log -Level ERROR -Message "CLI Install: Failed for $($installEntry.DisplayName)." }
            }
        }
        if ($packDir) { Remove-Item -Path $packDir -Recurse -Force }
        
        if ($overallSuccess) { [System.Windows.Forms.MessageBox]::Show("Pack installed successfully!", $Global:T.success, "OK", "Information") | Out-Null }
        else { [System.Windows.Forms.MessageBox]::Show("Pack installation completed with one or more errors. Check logs.", "Aviso", "OK", "Warning") | Out-Null }
        $formArgInstall.Close()
    })
    
    Write-Log -Level INFO -Message "CLI Mode: Showing install dialog."; [void]$formArgInstall.ShowDialog(); Write-Log -Level INFO -Message "CLI Mode: Dialog closed. Exiting script."; exit 0
}

function Show-MainForm {
    # GUI Construction
    $lineHeight = 25; $padding = 10; $screenHeight = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Height
    $formHeight = [math]::Min($screenHeight * 0.85, 780); $formWidth = 600; $containerWidth = $formWidth - ($padding * 2)

    $form = New-Object System.Windows.Forms.Form; $form.Text = $Global:T.package_name; $form.Size = New-Object System.Drawing.Size($formWidth, $formHeight); $form.StartPosition = 'CenterScreen'; $form.Padding = New-Object System.Windows.Forms.Padding($padding); $form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle; $form.MaximizeBox = $false; $form.MinimizeBox = $true; $form.ShowInTaskbar = $true; $form.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::Font; $form.Font = New-Object System.Drawing.Font("Segoe UI", 9)

    $flowPanel = New-Object System.Windows.Forms.FlowLayoutPanel; $flowPanel.Dock = [System.Windows.Forms.DockStyle]::Fill; $flowPanel.FlowDirection = [System.Windows.Forms.FlowDirection]::TopDown; $flowPanel.WrapContents = $false; $flowPanel.AutoScroll = $true

    $ListLabel = New-Object System.Windows.Forms.Label; $ListLabel.Text = $Global:T.install_instance; $ListLabel.Font = New-Object System.Drawing.Font($form.Font.FontFamily, 11, [System.Drawing.FontStyle]::Bold); $ListLabel.AutoSize = $true; $ListLabel.Margin = New-Object System.Windows.Forms.Padding(0, $padding, 0, 5); $flowPanel.Controls.Add($ListLabel)
    $ListBox = New-Object System.Windows.Forms.ListBox; $ListBox.SelectionMode = [System.Windows.Forms.SelectionMode]::MultiExtended; $ListBox.Height = 180; $ListBox.Width = $containerWidth - 20; $ListBox.Margin = New-Object System.Windows.Forms.Padding(0,0,0, $padding); $Global:dataSrc | ForEach-Object { $ListBox.Items.Add($_.DisplayName) | Out-Null }; $flowPanel.Controls.Add($ListBox)

    $selectAllCheckbox = New-Object System.Windows.Forms.CheckBox; $selectAllCheckbox.Text = $Global:T.install_all; $selectAllCheckbox.AutoSize = $true; $selectAllCheckbox.Margin = New-Object System.Windows.Forms.Padding(0, 0, 0, $padding); $flowPanel.Controls.Add($selectAllCheckbox)

    $ManageButtonsPanel = New-Object System.Windows.Forms.FlowLayoutPanel; $ManageButtonsPanel.FlowDirection = [System.Windows.Forms.FlowDirection]::LeftToRight; $ManageButtonsPanel.AutoSize = $true; $ManageButtonsPanel.WrapContents = $true; $ManageButtonsPanel.Width = $containerWidth; $ManageButtonsPanel.Margin = New-Object System.Windows.Forms.Padding(0,0,0, $padding)
    $ButtonAddBedrockLauncher = New-Object System.Windows.Forms.Button; $ButtonAddBedrockLauncher.Text = $Global:T.add_bl_versions_folder; $ButtonAddBedrockLauncher.AutoSize = $true; $ButtonAddBedrockLauncher.Padding = New-Object System.Windows.Forms.Padding(5); $ButtonAddBedrockLauncher.Margin = New-Object System.Windows.Forms.Padding(3); $ManageButtonsPanel.Controls.Add($ButtonAddBedrockLauncher)
    $ButtonAddCustomPath = New-Object System.Windows.Forms.Button; $ButtonAddCustomPath.Text = $Global:T.add_custom_install_folder; $ButtonAddCustomPath.AutoSize = $true; $ButtonAddCustomPath.Padding = New-Object System.Windows.Forms.Padding(5); $ButtonAddCustomPath.Margin = New-Object System.Windows.Forms.Padding(3); $ManageButtonsPanel.Controls.Add($ButtonAddCustomPath)
    $ButtonEditName = New-Object System.Windows.Forms.Button; $ButtonEditName.Text = $Global:T.edit_display_name; $ButtonEditName.AutoSize = $true; $ButtonEditName.Enabled = $false; $ButtonEditName.Padding = New-Object System.Windows.Forms.Padding(5); $ButtonEditName.Margin = New-Object System.Windows.Forms.Padding(3); $ManageButtonsPanel.Controls.Add($ButtonEditName)
    $ButtonRemovePath = New-Object System.Windows.Forms.Button; $ButtonRemovePath.Text = $Global:T.remove_selected_path; $ButtonRemovePath.AutoSize = $true; $ButtonRemovePath.Enabled = $false; $ButtonRemovePath.Padding = New-Object System.Windows.Forms.Padding(5); $ButtonRemovePath.Margin = New-Object System.Windows.Forms.Padding(3); $ManageButtonsPanel.Controls.Add($ButtonRemovePath)
    $flowPanel.Controls.Add($ManageButtonsPanel)

    $PackListLabel = New-Object System.Windows.Forms.Label; $PackListLabel.Text = $Global:T.install_pack; $PackListLabel.Font = New-Object System.Drawing.Font($form.Font.FontFamily, 11, [System.Drawing.FontStyle]::Bold); $PackListLabel.AutoSize = $true; $PackListLabel.Margin = New-Object System.Windows.Forms.Padding(0, $padding, 0, 5); $flowPanel.Controls.Add($PackListLabel)
    $PackSelectList = New-Object System.Windows.Forms.ComboBox; $PackSelectList.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList; $PackSelectList.Width = $containerWidth - 20; $PackSelectList.Margin = New-Object System.Windows.Forms.Padding(0,0,0, $padding); $flowPanel.Controls.Add($PackSelectList)

    $InstallButton = New-Object System.Windows.Forms.Button; $InstallButton.Text = $Global:T.install; $InstallButton.Font = New-Object System.Drawing.Font($form.Font.FontFamily, 10, [System.Drawing.FontStyle]::Bold); $InstallButton.Width = $containerWidth - 20; $InstallButton.Height = $lineHeight * 1.5; $InstallButton.Enabled = $false; $InstallButton.Margin = New-Object System.Windows.Forms.Padding(0, $padding, 0, $padding); $flowPanel.Controls.Add($InstallButton)
    $StatusLabel = New-Object System.Windows.Forms.Label; $StatusLabel.Font = New-Object System.Drawing.Font($form.Font.FontFamily, 9); $StatusLabel.Width = $containerWidth - 20; $StatusLabel.Height = $lineHeight * 2; $StatusLabel.Visible = $false; $StatusLabel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle; $StatusLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter; $StatusLabel.Margin = New-Object System.Windows.Forms.Padding(0,0,0, $padding); $flowPanel.Controls.Add($StatusLabel)
    $LaunchButton = New-Object System.Windows.Forms.Button; $LaunchButton.Text = $Global:T.launch; $LaunchButton.Font = New-Object System.Drawing.Font($form.Font.FontFamily, 10, [System.Drawing.FontStyle]::Bold); $LaunchButton.Width = $containerWidth - 20; $LaunchButton.Height = $lineHeight * 1.5; $LaunchButton.Enabled = $false; $LaunchButton.Visible = $false; $LaunchButton.Margin = New-Object System.Windows.Forms.Padding(0,0,0, $padding); $flowPanel.Controls.Add($LaunchButton)
    $form.Controls.Add($flowPanel)

    # GUI Helper Functions
    function Update-ListBox { 
        Write-Log -Level DEBUG -Message "Update-ListBox: Refreshing ListBox."
        $ListBox.BeginUpdate()
        $ListBox.Items.Clear()
        $Global:dataSrc | ForEach-Object { $ListBox.Items.Add($_.DisplayName) | Out-Null }
        $ListBox.EndUpdate()
        Toggle-GuiElementState
        Save-Configuration 
    }
    
    function Toggle-GuiElementState {
        Write-Log -Level DEBUG -Message "Toggle-GuiElementState: Updating UI element states."
        $anyPackSel = ($PackSelectList.SelectedItem -ne $null -and $PackSelectList.SelectedItem -ne "")
        $anyInstSel = ($ListBox.SelectedItems.Count -gt 0)
        $oneInstSel = ($ListBox.SelectedItems.Count -eq 1)
        
        $InstallButton.Enabled = ($anyPackSel -and $anyInstSel)
        $LaunchButton.Enabled = $oneInstSel 
        $ButtonEditName.Enabled = $oneInstSel
        $ButtonRemovePath.Enabled = $anyInstSel
        
        $dlssMenu = $advancedMenu.MenuItems | Where-Object { $_.Text -eq $Global:T.update_dlss }; if($dlssMenu) { $dlssMenu.Enabled = $anyInstSel }
        $backupMenu = $fileMenu.MenuItems | Where-Object { $_.Text -eq $Global:T.backup }; if($backupMenu) { $backupMenu.Enabled = $anyInstSel }
        $uninstallMenu = $fileMenu.MenuItems | Where-Object { $_.Text -eq $Global:T.uninstall_betterrtx }; if($uninstallMenu) { $uninstallMenu.Enabled = $anyInstSel }
    }

    function Refresh-PackList {
        Write-Log -Level DEBUG -Message "Refresh-PackList: Starting."
        $PackSelectList.Items.Clear()
        $apiPacks = @()
        try {
            $apiJsonPath = Join-Path -Path $Global:BRTX_DIR -ChildPath "packs_api.json"
            $needsUpdate = $true
            if (Test-Path $apiJsonPath) { if (((Get-Item $apiJsonPath).LastWriteTime) -gt (Get-Date).AddHours(-1)) { $needsUpdate = $false } }
            
            if ($needsUpdate) { 
                Write-Log -Level INFO -Message "Refresh-PackList: Fetching latest pack list from API."
                $response = Invoke-WebRequest -Uri "https://bedrock.graphics/api" -ContentType "application/json" -UseBasicParsing -ErrorAction Stop
                $response.Content | Out-File $apiJsonPath -Encoding UTF8
            }
            else { Write-Log -Level DEBUG -Message "Refresh-PackList: Using cached API pack list."}
            
            $apiPacks = Get-Content $apiJsonPath -Raw | ConvertFrom-Json -ErrorAction Stop
        } catch { 
            Write-Log -Level WARN -Message "Refresh-PackList: Failed to get/parse API packs: $($_.Exception.Message)."
            $StatusLabel.Text = $Global:T.error_network; $StatusLabel.ForeColor = [System.Drawing.Color]::Orange; $StatusLabel.Visible = $true 
        }
        if ($apiPacks) { foreach ($pack in $apiPacks) { $PackSelectList.Items.Add($pack.name) | Out-Null } }
        $PackSelectList.Items.Add($Global:T.install_custom) | Out-Null
        Write-Log -Level DEBUG -Message "Refresh-PackList: Finished. Count: $($PackSelectList.Items.Count)"
    }
    
    function Style-InstallerButton {
        param(
            [Parameter(Mandatory=$true)] [System.Windows.Forms.Button]$Button,
            [Parameter(Mandatory=$true)] [string]$Theme
        )
        $Button.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
        $Button.FlatAppearance.BorderSize = 1
        $Button.Font = New-Object System.Drawing.Font("Segoe UI", 8.5, [System.Drawing.FontStyle]::Bold)
        
        # Armazena as cores no objeto do botao para evitar problemas de escopo
        $Button.Tag = @{
            NormalColor = if ($Theme -eq "Dark") { [System.Drawing.Color]::FromArgb(60, 60, 60) } else { [System.Drawing.Color]::FromArgb(225, 225, 225) }
            HoverColor  = if ($Theme -eq "Dark") { [System.Drawing.Color]::FromArgb(85, 85, 85) } else { [System.Drawing.Color]::FromArgb(200, 200, 200) }
        }
        $borderColor = if ($Theme -eq "Dark") { [System.Drawing.Color]::FromArgb(100, 100, 100) } else { [System.Drawing.Color]::FromArgb(180, 180, 180) }
        
        $Button.BackColor = $Button.Tag.NormalColor
        $Button.FlatAppearance.BorderColor = $borderColor
        
        $Button.Add_MouseHover({
            param($sender, $e)
            if (-not $sender.IsDisposed) {
                $sender.BackColor = $sender.Tag.HoverColor
            }
        })
        $Button.Add_MouseLeave({
            param($sender, $e)
            if (-not $sender.IsDisposed) {
                $sender.BackColor = $sender.Tag.NormalColor
            }
        })
    }

    function Apply-ThemeRecursively {
        param(
            [Parameter(Mandatory=$true)] [System.Windows.Forms.Control]$Control,
            [Parameter(Mandatory=$true)] [string]$Theme
        )
        
        $backColor = if ($Theme -eq 'Dark') { [System.Drawing.Color]::FromArgb(45, 45, 48) } else { [System.Drawing.SystemColors]::Control }
        $foreColor = if ($Theme -eq 'Dark') { [System.Drawing.Color]::White } else { [System.Drawing.Color]::Black }

        $Control.BackColor = $backColor
        $Control.ForeColor = $foreColor

        if ($Control.HasChildren) {
            foreach ($childControl in $Control.Controls) {
                Apply-ThemeRecursively -Control $childControl -Theme $Theme
            }
        }
    }

    # GUI Event Handlers
    $ListBox.Add_SelectedIndexChanged({ Write-Log -Level UI_ACTION -Message "ListBox SelectedIndexChanged event."; Toggle-GuiElementState })
    $PackSelectList.Add_SelectedIndexChanged({ Write-Log -Level UI_ACTION -Message "PackSelectList SelectedIndexChanged event."; Toggle-GuiElementState })

    $selectAllCheckbox.Add_CheckedChanged({
        if ($selectAllCheckbox.Checked) {
            $ListBox.Enabled = $false
            for ($i = 0; $i -lt $ListBox.Items.Count; $i++) {
                $ListBox.SetSelected($i, $true)
            }
        } else {
            $ListBox.Enabled = $true
            $ListBox.ClearSelected()
        }
        Toggle-GuiElementState
    })

    $ButtonAddBedrockLauncher.Add_Click({ 
        Write-Log -Level UI_ACTION -Message "ButtonAddBedrockLauncher clicked."
        $folderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
        $folderDialog.Description = $Global:T.bedrock_launcher_versions_info
        $folderDialog.SelectedPath = "$env:APPDATA\.minecraft_bedrock\versions"
        if ($folderDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { Add-BedrockLauncherVersions -VersionsFolderPath $folderDialog.SelectedPath; Update-ListBox }
    })
    $ButtonAddCustomPath.Add_Click({ 
        Write-Log -Level UI_ACTION -Message "ButtonAddCustomPath clicked."
        $folderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
        $folderDialog.Description = $Global:T.custom_install_root_warning
        if ($folderDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { Add-CustomInstallation -CustomPath $folderDialog.SelectedPath; Update-ListBox }
    })
    $ButtonEditName.Add_Click({ 
        Write-Log -Level UI_ACTION -Message "ButtonEditName clicked."
        if ($ListBox.SelectedItems.Count -ne 1) { return }
        $selDispName = $ListBox.SelectedItem
        $entry = $Global:dataSrc | Where-Object { $_.DisplayName -eq $selDispName } | Select-Object -First 1
        if ($entry) { 
            Add-Type -AssemblyName Microsoft.VisualBasic
            $newName = [Microsoft.VisualBasic.Interaction]::InputBox("Enter new display name for '$($entry.DisplayName)':", $Global:T.edit_display_name, $entry.DisplayName)
            if (-not [string]::IsNullOrWhiteSpace($newName) -and $newName -ne $entry.DisplayName) { 
                Write-Log -Level INFO -Message "Renaming '$($entry.DisplayName)' to '$newName'"
                $entry.DisplayName = $newName
                Update-ListBox 
            }
        }
    })
    $ButtonRemovePath.Add_Click({ 
        Write-Log -Level UI_ACTION -Message "ButtonRemovePath clicked."
        if ($ListBox.SelectedItems.Count -eq 0) { return }
        $confirm = [System.Windows.Forms.MessageBox]::Show($Global:T.confirm_remove_path, "Confirm Removal", "YesNo", "Warning")
        if ($confirm -eq "Yes") { 
            $selDispNames = @($ListBox.SelectedItems)
            foreach($name in $selDispNames){ 
                $entry = $Global:dataSrc | Where-Object {$_.DisplayName -eq $name} | Select-Object -First 1
                if($entry){ Write-Log -Level INFO -Message "Removing path: $($entry.DisplayName)"; $Global:dataSrc.Remove($entry) }
            }
            Update-ListBox 
        }
    })
    
    $InstallButton.Add_Click({
        Write-Log -Level UI_ACTION -Message "InstallButton clicked."
        $StatusLabel.Visible = $false
        if ($ListBox.SelectedItems.Count -eq 0) { $StatusLabel.Text = $Global:T.error_no_installations_selected; $StatusLabel.ForeColor = [System.Drawing.Color]::Red; $StatusLabel.Visible = $true; return }
        
        $selPackName = $PackSelectList.SelectedItem
        if (-not $selPackName) { $StatusLabel.Text = "Please select a preset or custom file."; $StatusLabel.ForeColor = [System.Drawing.Color]::Red; $StatusLabel.Visible = $true; return }
        
        $InstallButton.Enabled = $false; $overallSuccess = $true; $anySuccess = $false; $srcMaterials = @(); $tempPackDir = $null
        try {
            if ($selPackName -eq $Global:T.install_custom) {
                $fileDialog = New-Object System.Windows.Forms.OpenFileDialog; $fileDialog.Filter = "BetterRTX Preset (*.rtpack;*.mcpack)|*.rtpack;*.mcpack|All files (*.*)|*.*"; $fileDialog.Title = "Select Custom Pack File"
                if ($fileDialog.ShowDialog() -eq "OK") { 
                    Write-Log -Level INFO -Message "InstallButton: User selected custom pack: $($fileDialog.FileName)"
                    $StatusLabel.Text = $Global:T.expanding_pack; $StatusLabel.ForeColor = [System.Drawing.Color]::Blue; $StatusLabel.Visible = $true; $form.Refresh()
                    $tempPackDir = Expand-Pack -PackPath $fileDialog.FileName
                    $srcMaterials = Get-ChildItem -Path $tempPackDir -Recurse -Filter "*.material.bin" -File | Select-Object -ExpandProperty FullName 
                }
                else { Write-Log -Level INFO -Message "InstallButton: Custom pack selection cancelled."; $InstallButton.Enabled = $true; return }
            } else {
                Write-Log -Level INFO -Message "InstallButton: User selected API pack: $selPackName"
                $StatusLabel.Text = "$($Global:T.downloading) $selPackName..."; $StatusLabel.ForeColor = [System.Drawing.Color]::Blue; $StatusLabel.Visible = $true; $form.Refresh()
                $apiPacksLocal = Get-Content (Join-Path -Path $Global:BRTX_DIR -ChildPath "packs_api.json") -Raw | ConvertFrom-Json
                $selApiPack = $apiPacksLocal | Where-Object { $_.name -eq $selPackName } | Select-Object -First 1
                if (-not $selApiPack) { throw "Selected API pack '$selPackName' not found in cached API data." }
                
                $packDlDir = Join-Path -Path $Global:BRTX_DIR -ChildPath "packs\$($selApiPack.uuid)"
                if (Test-Path $packDlDir) { Remove-Item $packDlDir -Recurse -Force } New-Item -ItemType Directory -Path $packDlDir -Force | Out-Null
                
                $packInfoResp = Invoke-WebRequest -Uri "https://bedrock.graphics/api/presets/$($selApiPack.uuid)" -ContentType "application/json" -UseBasicParsing -ErrorAction Stop
                $packContents = $packInfoResp.Content | ConvertFrom-Json -ErrorAction Stop
                
                Invoke-WebRequest -Uri $packContents.stub -OutFile (Join-Path $packDlDir "RTXStub.material.bin") -UseBasicParsing -ErrorAction Stop; $srcMaterials += (Join-Path $packDlDir "RTXStub.material.bin")
                Invoke-WebRequest -Uri $packContents.tonemapping -OutFile (Join-Path $packDlDir "RTXPostFX.Tonemapping.material.bin") -UseBasicParsing -ErrorAction Stop; $srcMaterials += (Join-Path $packDlDir "RTXPostFX.Tonemapping.material.bin")
                Invoke-WebRequest -Uri $packContents.bloom -OutFile (Join-Path $packDlDir "RTXPostFX.Bloom.material.bin") -UseBasicParsing -ErrorAction Stop; $srcMaterials += (Join-Path $packDlDir "RTXPostFX.Bloom.material.bin")
            }
            
            if ($srcMaterials.Count -eq 0) { Write-Log -Level WARN -Message "InstallButton: No .material.bin files found to install."; $StatusLabel.Text = "$($Global:T.error): No material files in pack."; $StatusLabel.ForeColor = [System.Drawing.Color]::Red; $StatusLabel.Visible = $true; $InstallButton.Enabled = $true; return }
            
            foreach ($selDispName in $ListBox.SelectedItems) {
                $instEntry = $Global:dataSrc | Where-Object { $_.DisplayName -eq $selDispName } | Select-Object -First 1
                if ($instEntry) { 
                    $StatusLabel.Text = "$($Global:T.copying) to $($instEntry.DisplayName)..."; $StatusLabel.ForeColor = [System.Drawing.Color]::Blue; $StatusLabel.Visible = $true; $form.Refresh()
                    if (Copy-ShaderFilesInternal -InstallEntry $instEntry -SourceMaterialFullPaths $srcMaterials) { $anySuccess = $true } else { $overallSuccess = $false }
                }
            }
        } catch { Write-Log -Level ERROR -Message "InstallButton: Error during installation: $($_.Exception.Message)"; $StatusLabel.Text = "$($Global:T.error): Installation failed."; $StatusLabel.ForeColor = [System.Drawing.Color]::Red; $StatusLabel.Visible = $true; $overallSuccess = $false }
        finally { if ($tempPackDir -and (Test-Path $tempPackDir)) { Remove-Item -Path $tempPackDir -Recurse -Force }}
        
        if ($overallSuccess -and $anySuccess) { $StatusLabel.Text = "$($Global:T.success) Pack installed."; $StatusLabel.ForeColor = [System.Drawing.Color]::Green; $LaunchButton.Visible = $true }
        elseif ($anySuccess) { $StatusLabel.Text = "Warning: Pack installed with some errors."; $StatusLabel.ForeColor = [System.Drawing.Color]::Orange; $LaunchButton.Visible = $true }
        else { $StatusLabel.Text = "$($Global:T.error): Pack installation failed."; $StatusLabel.ForeColor = [System.Drawing.Color]::Red }
        $StatusLabel.Visible = $true; $InstallButton.Enabled = $true; Toggle-GuiElementState
    })

    $LaunchButton.Add_Click({
        Write-Log -Level UI_ACTION -Message "LaunchButton clicked."
        if ($ListBox.SelectedItems.Count -ne 1) { $StatusLabel.Text="Select one instance to launch."; $StatusLabel.ForeColor=[System.Drawing.Color]::Orange; $StatusLabel.Visible=$true; return }
        $selDispName = $ListBox.SelectedItem; $instEntry = $Global:dataSrc | Where-Object { $_.DisplayName -eq $selDispName } | Select-Object -First 1
        if ($instEntry) {
            Write-Log -Level INFO -Message "LaunchButton: Attempting to launch: $($instEntry.DisplayName) (Type: $($instEntry.Type))"
            try {
                switch ($instEntry.Type) {
                    "MSStore" { if ($instEntry.Preview) { Start-Process "minecraft-preview:" } else { Start-Process "minecraft:" }}
                    "BedrockLauncherVersion" { $blPath = Join-Path $env:LOCALAPPDATA "Programs\BedrockLauncher\BedrockLauncher.exe"; if (Test-Path $blPath) { Start-Process -FilePath $blPath } else { [System.Windows.Forms.MessageBox]::Show("Could not find Bedrock Launcher at $blPath.", "Info", "OK", "Information") | Out-Null }}
                    "Custom" { $exePath = Get-ChildItem -Path $instEntry.InstallLocation -Recurse -Filter "Minecraft.Windows.exe" -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName; if ($exePath) { Start-Process -FilePath $exePath } else { [System.Windows.Forms.MessageBox]::Show("Could not find Minecraft.Windows.exe in '$($instEntry.InstallLocation)'.", "Info", "OK", "Information") | Out-Null }}
                    default { Write-Log -Level WARN -Message "LaunchButton: Unsupported type for launch: $($instEntry.Type)" }
                }
            } catch { Write-Log -Level ERROR -Message "LaunchButton: Failed to launch: $($_.Exception.Message)"; $StatusLabel.Text = "$($Global:T.error): Failed to launch."; $StatusLabel.ForeColor = [System.Drawing.Color]::Red; $StatusLabel.Visible = $true }
        }
    })

    # Menu Setup
    $mainMenu = New-Object System.Windows.Forms.MainMenu; $form.Menu = $mainMenu
    $fileMenu = New-Object System.Windows.Forms.MenuItem($Global:T.setup); $mainMenu.MenuItems.Add($fileMenu) | Out-Null
    $manageInstallationsMenuItem = New-Object System.Windows.Forms.MenuItem($Global:T.manage_installations); $fileMenu.MenuItems.Add($manageInstallationsMenuItem) | Out-Null
    $addBLMenuItem = New-Object System.Windows.Forms.MenuItem($Global:T.add_bl_versions_folder); $addBLMenuItem.Add_Click({ $ButtonAddBedrockLauncher.PerformClick() }); $manageInstallationsMenuItem.MenuItems.Add($addBLMenuItem) | Out-Null
    $addCustomMenuItem = New-Object System.Windows.Forms.MenuItem($Global:T.add_custom_install_folder); $addCustomMenuItem.Add_Click({ $ButtonAddCustomPath.PerformClick() }); $manageInstallationsMenuItem.MenuItems.Add($addCustomMenuItem) | Out-Null
    $manageInstallationsMenuItem.MenuItems.Add("-") | Out-Null
    $saveConfigMenuItem = New-Object System.Windows.Forms.MenuItem($Global:T.save_config); $saveConfigMenuItem.Add_Click({ Write-Log -Level UI_ACTION -Message "Menu: Save Configuration clicked."; Save-Configuration; $StatusLabel.Text = $Global:T.config_saved; $StatusLabel.ForeColor=[System.Drawing.Color]::DarkGreen; $StatusLabel.Visible=$true }); $manageInstallationsMenuItem.MenuItems.Add($saveConfigMenuItem) | Out-Null
    $fileMenu.MenuItems.Add("-") | Out-Null
    $backupMenuItem = New-Object System.Windows.Forms.MenuItem($Global:T.backup); $backupMenuItem.Enabled = $false
    $backupMenuItem.Add_Click({
        Write-Log -Level UI_ACTION -Message "Menu: Backup Shaders clicked."
        if ($ListBox.SelectedItems.Count > 0) {
            $successCount = 0; foreach($selDispName in $ListBox.SelectedItems){ $instEntry = $Global:dataSrc | Where-Object {$_.DisplayName -eq $selDispName} | Select-Object -First 1; if($instEntry){ if(Backup-ShaderFilesToUserLocation -InstallEntry $instEntry){ $successCount++ }}};
            if($successCount -gt 0){ $StatusLabel.Text = "Backup successful for $successCount instance(s)."; $StatusLabel.ForeColor = [System.Drawing.Color]::Green }
            else { $StatusLabel.Text = "Backup failed or cancelled."; $StatusLabel.ForeColor = [System.Drawing.Color]::Red }
        } else { $StatusLabel.Text = $Global:T.error_no_installations_selected; $StatusLabel.ForeColor = [System.Drawing.Color]::Red }
        $StatusLabel.Visible = $true
    })
    $fileMenu.MenuItems.Add($backupMenuItem) | Out-Null

    $uninstallShadersMenuItem = New-Object System.Windows.Forms.MenuItem($Global:T.uninstall_betterrtx); $uninstallShadersMenuItem.Enabled = $false
    $uninstallShadersMenuItem.Add_Click({
        Write-Log -Level UI_ACTION -Message "Menu: Uninstall BetterRTX (Revert) clicked."
        if ($ListBox.SelectedItems.Count > 0) {
            $confirmUninstall = [System.Windows.Forms.MessageBox]::Show($Global:T.confirm_remove_path, "Confirm Revert", "YesNo", "Warning")
            if ($confirmUninstall -eq "Yes") {
                $revertedCount = 0; $failedCount = 0;
                foreach($selDispName in $ListBox.SelectedItems){
                    $instEntry = $Global:dataSrc | Where-Object {$_.DisplayName -eq $selDispName} | Select-Object -First 1
                    if($instEntry){ if(Uninstall-BetterRTXFromInstance -InstallEntry $instEntry){ $revertedCount++ } else { $failedCount++} }
                }
                if ($revertedCount -gt 0 -and $failedCount -eq 0) { $StatusLabel.Text = "Successfully reverted shaders for $revertedCount instance(s)."; $StatusLabel.ForeColor = [System.Drawing.Color]::Green }
                elseif ($revertedCount -gt 0 -and $failedCount -gt 0) { $StatusLabel.Text = "Reverted $revertedCount, failed $failedCount."; $StatusLabel.ForeColor = [System.Drawing.Color]::Orange }
                else { $StatusLabel.Text = "Failed to revert shaders for $failedCount instance(s)."; $StatusLabel.ForeColor = [System.Drawing.Color]::Red }
            } else { $StatusLabel.Text = "Revert cancelled."; $StatusLabel.ForeColor = [System.Drawing.Color]::Gray }
        } else { $StatusLabel.Text = $Global:T.error_no_installations_selected; $StatusLabel.ForeColor = [System.Drawing.Color]::Red }
        $StatusLabel.Visible = $true
    })
    $fileMenu.MenuItems.Add($uninstallShadersMenuItem) | Out-Null

    $rtpackRegisterMenuItem = New-Object System.Windows.Forms.MenuItem($Global:T.register_rtpack)
    $rtpackRegisterMenuItem.Add_Click({ 
        Write-Log -Level UI_ACTION -Message "Menu: Register .rtpack clicked."
        $thisScriptPath = $MyInvocation.MyCommand.Path
        if (-not $thisScriptPath) { 
            Write-Log -Level WARN -Message "Could not determine script path for .rtpack registration."
            $StatusLabel.Text = "Error: Script path unknown."; $StatusLabel.ForeColor = [System.Drawing.Color]::Red; $StatusLabel.Visible = $true; return 
        }
        Register-RtpackExtension -InstallerPath $thisScriptPath
        $StatusLabel.Text = ".rtpack extension registration attempted."; $StatusLabel.ForeColor = [System.Drawing.Color]::Blue; $StatusLabel.Visible = $true 
    })
    $fileMenu.MenuItems.Add($rtpackRegisterMenuItem) | Out-Null
    if (-not $Global:ioBitExe) { $downloadIoBitMenuItem = New-Object System.Windows.Forms.MenuItem($Global:T.download + " IObit Unlocker"); $downloadIoBitMenuItem.Add_Click({ Start-Process -FilePath "https://www.iobit.com/en/iobit-unlocker.php" }); $fileMenu.MenuItems.Add($downloadIoBitMenuItem) | Out-Null }
    $fileMenu.MenuItems.Add("-") | Out-Null; $exitMenuItem = New-Object System.Windows.Forms.MenuItem("E&xit"); $exitMenuItem.Add_Click({ Write-Log -Level UI_ACTION -Message "Menu: Exit clicked."; $form.Close() }); $fileMenu.MenuItems.Add($exitMenuItem) | Out-Null

    $advancedMenu = New-Object System.Windows.Forms.MenuItem($Global:T.advanced); $mainMenu.MenuItems.Add($advancedMenu) | Out-Null
    $dlssUpdateMenuItem = New-Object System.Windows.Forms.MenuItem($Global:T.update_dlss); $dlssUpdateMenuItem.Enabled = $false
    $dlssUpdateMenuItem.Add_Click({
        Write-Log -Level UI_ACTION -Message "Menu: Update DLSS clicked."
        if ($ListBox.SelectedItems.Count > 0) {
            $anyDlssSuccess = $false; $allDlssSuccess = $true;
            foreach($selDispName in $ListBox.SelectedItems){ $instEntry = $Global:dataSrc | Where-Object {$_.DisplayName -eq $selDispName} | Select-Object -First 1; if($instEntry){ if(Install-DLSSInternal -InstallEntry $instEntry){ $anyDlssSuccess = $true } else { $allDlssSuccess = $false }}}
            if ($allDlssSuccess -and $anyDlssSuccess) { $StatusLabel.Text = $Global:T.dlss_success; $StatusLabel.ForeColor = [System.Drawing.Color]::Green }
            elseif ($anyDlssSuccess) { $StatusLabel.Text = "DLSS updated for some, errors on others."; $StatusLabel.ForeColor = [System.Drawing.Color]::Orange }
            else { $StatusLabel.Text = "DLSS update failed for all selected."; $StatusLabel.ForeColor = [System.Drawing.Color]::Red }
        } else { $StatusLabel.Text = $Global:T.error_no_installations_selected; $StatusLabel.ForeColor = [System.Drawing.Color]::Red }
        $StatusLabel.Visible = $true; Toggle-GuiElementState
    })
    $advancedMenu.MenuItems.Add($dlssUpdateMenuItem) | Out-Null

    $helpMenu = New-Object System.Windows.Forms.MenuItem($Global:T.help); $mainMenu.MenuItems.Add($helpMenu) | Out-Null
    $discordMenuItem = New-Object System.Windows.Forms.MenuItem("&Discord"); $discordMenuItem.Add_Click({ Start-Process -FilePath "https://discord.com/invite/minecraft-rtx-691547840463241267" }); $helpMenu.MenuItems.Add($discordMenuItem) | Out-Null
    $gitHubMenuItem = New-Object System.Windows.Forms.MenuItem("&GitHub (Installer)"); $gitHubMenuItem.Add_Click({ Start-Process -FilePath "https://github.com/BetterRTX/BetterRTX-Installer" }); $helpMenu.MenuItems.Add($gitHubMenuItem) | Out-Null
    $openLogFileMenuItem = New-Object System.Windows.Forms.MenuItem("Open Log File"); $openLogFileMenuItem.Add_Click({ Write-Log -Level UI_ACTION -Message "Menu: Open Log File clicked."; if (Test-Path $Global:InstallerLogPath) { Invoke-Item $Global:InstallerLogPath } else { $StatusLabel.Text = "Log file not found yet."; $StatusLabel.ForeColor = [System.Drawing.Color]::Orange; $StatusLabel.Visible = $true }}); $helpMenu.MenuItems.Add($openLogFileMenuItem) | Out-Null

    # Form Events
    $form.Add_Shown({
        Write-Log -Level INFO -Message "Main form shown. Applying theme and updating UI states."
        
        Apply-ThemeRecursively -Control $form -Theme $Global:CurrentTheme
        
        if ($Global:CurrentTheme -eq "Dark") {
            $ListBox.BackColor = [System.Drawing.Color]::FromArgb(60,60,60)
            $ListBox.ForeColor = [System.Drawing.Color]::White
            $PackSelectList.BackColor = [System.Drawing.Color]::FromArgb(60,60,60)
            $PackSelectList.ForeColor = [System.Drawing.Color]::White
            $PackSelectList.FlatStyle = "Flat"
            Write-Log -Level THEME -Message $Global:T.theme_applied_dark
        } else {
            $ListBox.BackColor = [System.Drawing.SystemColors]::Window
            $ListBox.ForeColor = [System.Drawing.SystemColors]::WindowText
            $PackSelectList.BackColor = [System.Drawing.SystemColors]::Window
            $PackSelectList.ForeColor = [System.Drawing.SystemColors]::WindowText
            $PackSelectList.FlatStyle = "Standard"
            Write-Log -Level THEME -Message $Global:T.theme_applied_light
        }
        
        Style-InstallerButton -Button $ButtonAddBedrockLauncher -Theme $Global:CurrentTheme
        Style-InstallerButton -Button $ButtonAddCustomPath -Theme $Global:CurrentTheme
        Style-InstallerButton -Button $ButtonEditName -Theme $Global:CurrentTheme
        Style-InstallerButton -Button $ButtonRemovePath -Theme $Global:CurrentTheme
        
        Toggle-GuiElementState 
        Refresh-PackList
        if (-not $Global:ioBitExe) { $StatusLabel.Text = $Global:T.error_iobit_missing + " Some operations might fail."; $StatusLabel.ForeColor = [System.Drawing.Color]::OrangeRed; $StatusLabel.Visible = $true }
    })
    $form.Add_FormClosing({ Write-Log -Level INFO -Message "Main form closing. Saving configuration."; Save-Configuration })

    # Show Form
    Write-Log -Level INFO -Message "Showing main dialog. Theme: $Global:CurrentTheme"
    [void]$form.ShowDialog()
    Write-Log -Level INFO -Message "Main dialog closed. Script exiting."
}
#endregion

#region Main Execution
try {
    $Global:T = Get-LocalizedStrings
    $Global:ioBitExe = Find-IObitUnlocker
    $Global:CurrentTheme = Get-SystemTheme
    
    Load-Configuration
    Add-MSStoreInstallations 
    Verify-InstallationPaths 

    if ($PSBoundParameters.ContainsKey('PackPath') -and $PackPath) {
        Show-CliInstallDialog -PackToInstallPath $PackPath
    } else {
        Show-MainForm
    }
}
catch {
    $errorMessage = "A critical error occurred: $($_.Exception.Message)"
    Write-Log -Level ERROR -Message $errorMessage
    [System.Windows.Forms.MessageBox]::Show($errorMessage, "Critical Error", "OK", "Error") | Out-Null
}
finally {
    Write-Log -Level INFO -Message "Script execution finished."
}
#endregion
