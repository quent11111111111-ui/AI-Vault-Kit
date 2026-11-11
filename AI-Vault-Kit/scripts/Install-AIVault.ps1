<#
.SYNOPSIS
  Déploie AI-Vault (mémoire IA centralisée Obsidian + MCP) sur Windows, sans rien supprimer.

.DESCRIPTION
  Étapes (toutes non destructives) :
    1. Analyse de l'environnement (OS, Obsidian, coffres existants, Node/npm, Antigravity, config MCP).
    2. Installation d'Obsidian via winget (source officielle) si absent — avec confirmation.
    3. Copie du coffre vers -VaultPath (fichiers manquants uniquement ; refuse un coffre personnel non-AI-Vault).
    4. Pré-installation du plugin "Local REST API with MCP" depuis la release GitHub officielle (id vérifié).
    5. Ouverture du coffre dans Obsidian (vous validez la confiance dans le plugin).
    6. (Option -TrustCertificate) Ajout de la CA locale du plugin au magasin racine de l'UTILISATEUR, après explication et accord.
    7. Saisie masquée de la clé API, sauvegarde horodatée puis FUSION de %USERPROFILE%\.gemini\config\mcp_config.json.
    8. (Option) Copie globale des agents/skills/règle dans %USERPROFILE%\.gemini\config\ (sans écraser).
    9. Lancement de Test-AIVault.ps1.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File .\scripts\Install-AIVault.ps1
  powershell -ExecutionPolicy Bypass -File .\scripts\Install-AIVault.ps1 -TrustCertificate
#>
[CmdletBinding()]
param(
    [string]$VaultPath,
    [switch]$TrustCertificate,
    [switch]$SkipObsidianInstall,
    [switch]$SkipPlugin,
    [switch]$SkipMcpConfig,
    [switch]$NoGlobalCustomizations,
    [switch]$SkipTests
)

$ErrorActionPreference = 'Stop'
try { [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12 } catch {}

# ---------------------------------------------------------------- helpers
$UserHome = if ($env:USERPROFILE) { $env:USERPROFILE } else { $HOME }
if (-not $VaultPath) {
    $docs = [Environment]::GetFolderPath('MyDocuments')
    if (-not $docs) { $docs = Join-Path $UserHome 'Documents' }
    $VaultPath = Join-Path $docs 'AI-Vault'
}
$KitRoot      = Split-Path -Parent $PSScriptRoot
$SourceVault  = Join-Path $KitRoot 'AI-Vault'
$GeminiConfig = Join-Path (Join-Path $UserHome '.gemini') 'config'
$McpConfig    = Join-Path $GeminiConfig 'mcp_config.json'
$Stamp        = Get-Date -Format 'yyyyMMdd-HHmmss'
$BackupDir    = Join-Path (Join-Path $UserHome '.ai-vault-backups') $Stamp
$PluginId     = 'obsidian-local-rest-api'
$BaseUrl      = 'https://127.0.0.1:27124'
$Placeholder  = 'REPLACE_WITH_OBSIDIAN_API_KEY'
$EnabledTools = @('vault_list','vault_read','vault_read_binary','vault_get_document_map','search_query',
                  'search_simple','tag_list','active_file_get_path','vault_write','vault_append','vault_patch','open_file')
$BlockedTools = @('vault_delete','vault_move','vault_copy','command_execute','command_list',
                  'vault_get_download_url','vault_get_upload_url','events_get_listener_url')

function Step($t)  { Write-Host "`n=== $t ===" -ForegroundColor Cyan }
function Ok($t)    { Write-Host "  [OK]   $t" -ForegroundColor Green }
function Warn($t)  { Write-Host "  [WARN] $t" -ForegroundColor Yellow }
function Info($t)  { Write-Host "  [..]   $t" }
function Confirm-Yes($q) { $a = Read-Host "$q [o/N]"; return ($a -match '^(o|oui|y|yes)$') }
function Write-Utf8NoBom($path, $text) { [IO.File]::WriteAllText($path, $text, (New-Object Text.UTF8Encoding($false))) }
function Backup-File($path) {
    if (Test-Path -LiteralPath $path) {
        New-Item -ItemType Directory -Force -Path $BackupDir | Out-Null
        $dest = Join-Path $BackupDir ((Split-Path -Leaf $path) + '.bak')
        Copy-Item -LiteralPath $path -Destination $dest -Force
        Ok "Sauvegarde : $dest"
    }
}
function Copy-MissingTree($src, $dst) {
    # Copie uniquement les fichiers absents de la destination. Ne remplace et ne supprime jamais rien.
    $created = 0; $skipped = 0
    $srcFull = (Resolve-Path -LiteralPath $src).Path
    Get-ChildItem -LiteralPath $srcFull -Recurse -Force -File | ForEach-Object {
        $rel = $_.FullName.Substring($srcFull.Length).TrimStart('\','/')
        $target = Join-Path $dst $rel
        if (Test-Path -LiteralPath $target) { $skipped++ }
        else {
            New-Item -ItemType Directory -Force -Path (Split-Path -Parent $target) | Out-Null
            Copy-Item -LiteralPath $_.FullName -Destination $target
            $created++
        }
    }
    return @{ Created = $created; Skipped = $skipped }
}
function Get-ObsidianExe {
    $c = @("$env:LOCALAPPDATA\Programs\Obsidian\Obsidian.exe", "$env:ProgramFiles\Obsidian\Obsidian.exe")
    foreach ($p in $c) { if ($p -and (Test-Path $p)) { return $p } }
    return $null
}

if (-not (Test-Path (Join-Path $SourceVault '00_SYSTEM\AI-INDEX.md'))) {
    throw "Kit introuvable : $SourceVault doit contenir 00_SYSTEM\AI-INDEX.md. Lancez le script depuis le dossier du kit."
}

# ---------------------------------------------------------------- 1. analyse
Step '1. Analyse de l''environnement'
$isWin = ($env:OS -eq 'Windows_NT')
if ($isWin) {
    $os = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
    if ($os) { Ok "Système : $($os.Caption) $($os.Version) ($($os.OSArchitecture))" }
} else { Warn "Ce script est prévu pour Windows (système détecté : $([Environment]::OSVersion.VersionString))." }
Ok "PowerShell : $($PSVersionTable.PSVersion)"
Ok "Dossier utilisateur : $UserHome"
Info "Coffre cible : $VaultPath"

$obsExe = Get-ObsidianExe
if ($obsExe) { Ok "Obsidian installé : $obsExe ($((Get-Item $obsExe).VersionInfo.ProductVersion))" } else { Warn 'Obsidian non détecté.' }

$obsJson = Join-Path $env:APPDATA 'obsidian\obsidian.json'
if ($env:APPDATA -and (Test-Path $obsJson)) {
    $vaults = (Get-Content $obsJson -Raw | ConvertFrom-Json).vaults
    $vaultPaths = @($vaults.PSObject.Properties | ForEach-Object { $_.Value.path })
    Ok "Coffres Obsidian enregistrés : $($vaultPaths.Count)"
    $vaultPaths | ForEach-Object { Info "  - $_" }
} else { Info 'Aucun registre de coffres Obsidian trouvé.' }

foreach ($cmd in 'node','npm','winget','agy') {
    $g = Get-Command $cmd -ErrorAction SilentlyContinue
    if ($g) {
        $v = try { (& $cmd --version 2>$null | Select-Object -First 1) } catch { '?' }
        Ok "$cmd : $v"
    } else { Info "$cmd : non trouvé dans le PATH" }
}
if (Test-Path (Join-Path $UserHome '.gemini')) { Ok "Configuration Antigravity : $(Join-Path $UserHome '.gemini')" } else { Warn 'Dossier ~/.gemini absent (Antigravity jamais lancé ?).' }
if (Test-Path $McpConfig) { Ok "mcp_config.json existant : $McpConfig" } else { Info "mcp_config.json absent (il sera créé)." }
foreach ($sub in 'agents','skills','rules') {
    $d = Join-Path $GeminiConfig $sub
    if (Test-Path $d) { Info "Personnalisations globales $sub : $((Get-ChildItem $d -Force | Measure-Object).Count) élément(s)" }
}

# ---------------------------------------------------------------- 2. Obsidian
Step '2. Obsidian'
if (-not $obsExe -and -not $SkipObsidianInstall) {
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        if (Confirm-Yes 'Installer Obsidian (paquet officiel winget Obsidian.Obsidian) ?') {
            winget install --id Obsidian.Obsidian --exact --source winget --accept-package-agreements --accept-source-agreements
            Start-Sleep -Seconds 3
            $obsExe = Get-ObsidianExe
            if ($obsExe) { Ok "Obsidian installé : $obsExe" } else { Warn 'Installation terminée mais exécutable non trouvé ; vérifiez le menu Démarrer.' }
        }
    } else {
        Warn 'winget indisponible. Téléchargez Obsidian depuis https://obsidian.md/download puis relancez ce script.'
    }
} elseif ($obsExe) { Ok 'Déjà installé, rien à faire.' }

# ---------------------------------------------------------------- 3. coffre
Step '3. Déploiement du coffre AI-Vault'
if (Test-Path -LiteralPath $VaultPath) {
    $isAiVault = Test-Path (Join-Path $VaultPath '00_SYSTEM\AI-INDEX.md')
    $nonEmpty  = (Get-ChildItem -LiteralPath $VaultPath -Force | Measure-Object).Count -gt 0
    if ($nonEmpty -and -not $isAiVault) {
        throw "Le dossier $VaultPath existe, n'est pas vide et n'est pas un AI-Vault. Par sécurité rien n'a été modifié. Relancez avec -VaultPath <autre dossier>."
    }
    if ($isAiVault) { Info 'AI-Vault existant détecté : seuls les fichiers manquants seront ajoutés (aucun remplacement).' }
}
New-Item -ItemType Directory -Force -Path $VaultPath | Out-Null
$r = Copy-MissingTree $SourceVault $VaultPath
Ok "Fichiers créés : $($r.Created) ; déjà présents (conservés) : $($r.Skipped)"

# ---------------------------------------------------------------- 4. plugin
Step '4. Plugin Local REST API with MCP'
$pluginDir = Join-Path $VaultPath ".obsidian\plugins\$PluginId"
if ($SkipPlugin) { Info 'Ignoré (-SkipPlugin).' }
elseif (Test-Path (Join-Path $pluginDir 'manifest.json')) {
    $m = Get-Content (Join-Path $pluginDir 'manifest.json') -Raw | ConvertFrom-Json
    Ok "Déjà présent : $($m.name) v$($m.version)"
} else {
    Info 'Téléchargement depuis la release officielle GitHub coddingtonbear/obsidian-local-rest-api…'
    $rel = Invoke-RestMethod -UseBasicParsing -Uri "https://api.github.com/repos/coddingtonbear/$PluginId/releases/latest" -Headers @{ 'User-Agent' = 'AI-Vault-Installer' }
    $tmp = Join-Path ([IO.Path]::GetTempPath()) "ai-vault-plugin-$Stamp"
    New-Item -ItemType Directory -Force -Path $tmp | Out-Null
    foreach ($f in 'manifest.json','main.js','styles.css') {
        $asset = $rel.assets | Where-Object { $_.name -eq $f }
        if ($asset) { Invoke-WebRequest -UseBasicParsing -Uri $asset.browser_download_url -OutFile (Join-Path $tmp $f) }
    }
    $m = Get-Content (Join-Path $tmp 'manifest.json') -Raw | ConvertFrom-Json
    if ($m.id -ne $PluginId -or $m.author -ne 'Adam Coddington') { throw "Manifest inattendu (id=$($m.id), auteur=$($m.author)). Arrêt par sécurité." }
    New-Item -ItemType Directory -Force -Path $pluginDir | Out-Null
    Copy-Item (Join-Path $tmp '*') $pluginDir
    Ok "Plugin $($m.name) v$($m.version) (id $($m.id), auteur $($m.author)) copié dans le coffre."

    $cp = Join-Path $VaultPath '.obsidian\community-plugins.json'
    $list = @()
    if (Test-Path $cp) { Backup-File $cp; $list = @((Get-Content $cp -Raw | ConvertFrom-Json) | ForEach-Object { $_ }) }
    if ($list -notcontains $PluginId) { $list += $PluginId }
    Write-Utf8NoBom $cp (ConvertTo-Json -InputObject @($list))
    Ok 'Plugin déclaré dans .obsidian\community-plugins.json'
}

# ---------------------------------------------------------------- 5. ouverture
Step '5. Ouverture du coffre dans Obsidian'
$uri = 'obsidian://open?path=' + [Uri]::EscapeDataString($VaultPath)
try { Start-Process $uri; Ok 'Obsidian lancé sur le coffre.' } catch { Warn "Ouvrez manuellement Obsidian > « Ouvrir un dossier comme coffre » > $VaultPath" }
Write-Host @"

  ACTION MANUELLE dans Obsidian :
   a) Si Obsidian demande « Faire confiance à l'auteur et activer les plugins ? » -> Faire confiance.
      (Sinon : Paramètres > Plugins communautaires > désactiver le mode restreint, puis activer
       « Local REST API with MCP ». Vous pouvez aussi l'installer depuis Parcourir : même plugin, même id.)
   b) Paramètres > Local REST API : vérifiez que le serveur HTTPS (27124) et le serveur MCP sont actifs,
      que « Enable HTTP server » (27123) reste DÉSACTIVÉ, et que l'adresse d'écoute est 127.0.0.1.
   c) Copiez la clé API (elle ne sera saisie qu'ici, de façon masquée, jamais dans le coffre).
"@ -ForegroundColor Yellow
Read-Host '  Appuyez sur Entrée lorsque c''est fait'

# ---------------------------------------------------------------- 6. certificat
Step '6. Confiance TLS dans l''autorité locale du plugin'
function Test-Tls {
    try { $null = Invoke-WebRequest -UseBasicParsing -Uri "$BaseUrl/" -TimeoutSec 5; return $true } catch { return $false }
}
if (Test-Tls) { Ok 'Le certificat du serveur est déjà approuvé par Windows.' }
elseif (-not $TrustCertificate) {
    Warn 'Le certificat local n''est pas (encore) approuvé ou le serveur ne répond pas.'
    Info 'Relancez avec -TrustCertificate pour l''ajouter après explication et accord (voir README).'
} else {
    Write-Host @"

  EXPLICATION :
   Le plugin a généré sa propre autorité de certification (CA). Pour que Antigravity et les autres
   clients se connectent en HTTPS SANS désactiver la vérification TLS, Windows doit faire confiance
   à cette CA. Elle sera ajoutée au magasin « Autorités de certification racines de confiance »
   de VOTRE COMPTE uniquement (Cert:\CurrentUser\Root), pas de la machine.
   Cette CA est restreinte par contraintes de nom : elle ne peut certifier que 127.0.0.1, localhost
   et les noms que vous avez configurés dans le plugin. Elle ne peut pas usurper d'autres sites.
   Pour récupérer son certificat PUBLIC, la vérification TLS est contournée pour CETTE SEULE requête
   vers 127.0.0.1 (la CA n'étant pas encore approuvée) ; son empreinte vous est affichée avant tout ajout.
   Retrait ultérieur : certmgr.msc > Racines de confiance > Certificats > supprimer l'entrée.
"@ -ForegroundColor Yellow
    $crtPath = Join-Path $VaultPath '.obsidian\obsidian-local-rest-api-ca.crt'
    Add-Type -TypeDefinition @"
using System; using System.IO; using System.Net;
public static class AiVaultLocalCa {
    public static byte[] Download(string url) {
        var u = new Uri(url);
        if (u.Host != "127.0.0.1" && u.Host != "localhost") throw new Exception("Refus : hôte non local");
        var req = (HttpWebRequest)WebRequest.Create(u);
        req.ServerCertificateValidationCallback = delegate { return true; };
        req.Timeout = 10000;
        using (var resp = req.GetResponse()) using (var s = resp.GetResponseStream()) using (var ms = new MemoryStream()) { s.CopyTo(ms); return ms.ToArray(); }
    }
}
"@ -ErrorAction SilentlyContinue
    $bytes = [AiVaultLocalCa]::Download("$BaseUrl/obsidian-local-rest-api.crt")
    [IO.File]::WriteAllBytes($crtPath, $bytes)
    $cert = New-Object Security.Cryptography.X509Certificates.X509Certificate2(,$bytes)
    $nc = $cert.Extensions | Where-Object { $_.Oid.Value -eq '2.5.29.30' }
    Info "Sujet       : $($cert.Subject)"
    Info "Empreinte   : $($cert.Thumbprint)"
    Info "Valide      : $($cert.NotBefore) -> $($cert.NotAfter)"
    Info ("Contraintes de nom : " + $(if ($nc) { 'présentes' } else { 'ABSENTES (attention)' }))
    if (Confirm-Yes 'Ajouter cette CA aux racines de confiance de votre compte Windows ?') {
        $store = New-Object Security.Cryptography.X509Certificates.X509Store('Root','CurrentUser')
        $store.Open('ReadWrite'); $store.Add($cert); $store.Close()   # Windows affiche sa propre confirmation
        if (Test-Tls) { Ok 'CA approuvée : HTTPS vérifié avec succès.' } else { Warn 'CA ajoutée mais la connexion HTTPS échoue encore (Obsidian ouvert ? plugin actif ?).' }
    } else { Warn 'CA non ajoutée. Les clients MCP risquent de refuser la connexion.' }
}

# ---------------------------------------------------------------- 7. MCP config
Step '7. Configuration MCP d''Antigravity'
if ($SkipMcpConfig) { Info 'Ignoré (-SkipMcpConfig).' }
else {
    $sec = Read-Host '  Collez la clé API Obsidian (saisie masquée ; Entrée vide = espace réservé)' -AsSecureString
    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec)
    $apiKey = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
    $hasKey = -not [string]::IsNullOrWhiteSpace($apiKey)
    if ($hasKey) {
        try {
            $st = Invoke-RestMethod -UseBasicParsing -Uri "$BaseUrl/" -Headers @{ Authorization = "Bearer $apiKey" } -TimeoutSec 5
            if ($st.authenticated) { Ok 'Clé API validée par le serveur (authenticated = true).' } else { Warn 'Le serveur répond mais la clé est refusée (authenticated = false). Vérifiez-la.' }
        } catch { Warn "Validation impossible maintenant ($($_.Exception.Message)). La clé est enregistrée quand même." }
    } else { $apiKey = $Placeholder; Warn "Aucune clé saisie : espace réservé écrit et serveur désactivé (disabled: true)." }

    New-Item -ItemType Directory -Force -Path $GeminiConfig | Out-Null
    $cfg = $null
    if (Test-Path $McpConfig) {
        Backup-File $McpConfig
        $raw = Get-Content $McpConfig -Raw
        if ([string]::IsNullOrWhiteSpace($raw)) { $cfg = [pscustomobject]@{} }
        else {
            try { $cfg = $raw | ConvertFrom-Json } catch { throw "mcp_config.json existant illisible (JSON invalide). Rien n'a été modifié. Corrigez-le puis relancez." }
        }
    } else { $cfg = [pscustomobject]@{} }
    if (-not $cfg.PSObject.Properties['mcpServers']) { $cfg | Add-Member -NotePropertyName mcpServers -NotePropertyValue ([pscustomobject]@{}) }
    $others = @($cfg.mcpServers.PSObject.Properties | Where-Object { $_.Name -ne 'obsidian' } | ForEach-Object { $_.Name })

    $entry = [ordered]@{
        serverUrl     = "$BaseUrl/mcp/"
        headers       = [ordered]@{ Authorization = "Bearer $apiKey" }
        enabledTools  = $EnabledTools
        disabledTools = $BlockedTools
    }
    if (-not $hasKey) { $entry['disabled'] = $true }

    $write = $true
    if ($cfg.mcpServers.PSObject.Properties['obsidian']) {
        $write = Confirm-Yes '  Une entrée "obsidian" existe déjà. La remplacer (sauvegarde faite) ?'
        if ($write) { $cfg.mcpServers.PSObject.Properties.Remove('obsidian') }
    }
    if ($write) {
        $cfg.mcpServers | Add-Member -NotePropertyName obsidian -NotePropertyValue ([pscustomobject]$entry)
        Write-Utf8NoBom $McpConfig ($cfg | ConvertTo-Json -Depth 20)
        Ok "Entrée obsidian écrite dans $McpConfig"
        if ($others.Count) { Ok "Serveurs existants conservés : $($others -join ', ')" }
        if (-not $hasKey) { Warn "Remplacez $Placeholder dans $McpConfig puis supprimez la ligne `"disabled`": true." }
    } else { Info 'Entrée existante conservée.' }
    $apiKey = $null
}

# ---------------------------------------------------------------- 8. global
Step '8. Agents, skills et règle Antigravity'
Ok "Disponibles dans le workspace : $(Join-Path $VaultPath '.agents') (si vous ouvrez le coffre comme workspace)."
if (-not $NoGlobalCustomizations) {
    $map = @{ 'agents' = 'agents'; 'skills' = 'skills'; 'rules' = 'rules' }
    foreach ($k in $map.Keys) {
        $src = Join-Path $SourceVault ".agents\$k"
        $dst = Join-Path $GeminiConfig $map[$k]
        New-Item -ItemType Directory -Force -Path $dst | Out-Null
        $res = Copy-MissingTree $src $dst
        Ok "Global $k -> $dst : $($res.Created) créé(s), $($res.Skipped) déjà présent(s) (non remplacés)"
    }
} else { Info 'Copie globale ignorée (-NoGlobalCustomizations).' }

# ---------------------------------------------------------------- 9. tests
if (-not $SkipTests) {
    Step '9. Tests'
    & (Join-Path $PSScriptRoot 'Test-AIVault.ps1') -VaultPath $VaultPath
}
Write-Host "`nTerminé. Redémarrez Antigravity puis vérifiez Customizations > Installed > MCP Servers > obsidian." -ForegroundColor Cyan
if (Test-Path $BackupDir) { Write-Host "Sauvegardes : $BackupDir" }
