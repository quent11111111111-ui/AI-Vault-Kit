<#
.SYNOPSIS
  Vérifie l'installation AI-Vault (Obsidian, MCP, Antigravity, agents/skills, routage) sans rien modifier,
  sauf l'ajout d'un journal (sans secret) à 00_SYSTEM/SETUP-REPORT.md.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File .\scripts\Test-AIVault.ps1
#>
[CmdletBinding()]
param(
    [string]$VaultPath,
    [switch]$NoReport
)
$ErrorActionPreference = 'Continue'
try { [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12 } catch {}

$UserHome = if ($env:USERPROFILE) { $env:USERPROFILE } else { $HOME }
if (-not $VaultPath) {
    $docs = [Environment]::GetFolderPath('MyDocuments'); if (-not $docs) { $docs = Join-Path $UserHome 'Documents' }
    $VaultPath = Join-Path $docs 'AI-Vault'
}
$GeminiConfig = Join-Path (Join-Path $UserHome '.gemini') 'config'
$McpConfig    = Join-Path $GeminiConfig 'mcp_config.json'
$BaseUrl      = 'https://127.0.0.1:27124'
$Expected     = @('vault_list','vault_read','vault_read_binary','vault_get_document_map','search_query','search_simple',
                  'tag_list','active_file_get_path','vault_write','vault_append','vault_patch','open_file')
$Destructive  = @('vault_delete','vault_move','vault_copy','command_execute')

$Results = New-Object System.Collections.Generic.List[object]
function Rec($test, $name, $status, $detail = '') {
    $Results.Add([pscustomobject]@{ Test = $test; Check = $name; Status = $status; Detail = $detail })
    $color = @{ PASS = 'Green'; FAIL = 'Red'; WARN = 'Yellow'; SKIP = 'DarkGray'; INFO = 'Gray' }[$status]
    Write-Host ("  [{0}] {1} {2}" -f $status, $name, $(if ($detail) { "- $detail" })) -ForegroundColor $color
}
function Get-Frontmatter($path) {
    $t = Get-Content -LiteralPath $path -Raw -Encoding UTF8
    if ($t -match '(?s)^---\r?\n(.*?)\r?\n---') { return $Matches[1] } else { return $null }
}

# ------------------------------------------------------------------ Test 1
Write-Host "`n=== Test 1 : Obsidian et coffre ===" -ForegroundColor Cyan
$obsExe = @("$env:LOCALAPPDATA\Programs\Obsidian\Obsidian.exe", "$env:ProgramFiles\Obsidian\Obsidian.exe") | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1
if ($obsExe) { Rec 1 'Obsidian installé' PASS ((Get-Item $obsExe).VersionInfo.ProductVersion) } else { Rec 1 'Obsidian installé' FAIL 'exécutable introuvable' }
if (Get-Process -Name Obsidian -ErrorAction SilentlyContinue) { Rec 1 'Obsidian lancé' PASS } else { Rec 1 'Obsidian lancé' FAIL 'processus absent' }
if (Test-Path $VaultPath) { Rec 1 'Coffre existe' PASS $VaultPath } else { Rec 1 'Coffre existe' FAIL $VaultPath }
$dirs = '00_SYSTEM','01_PROFILE','02_PROJECTS','03_KNOWLEDGE','04_AGENTS','05_SKILLS','06_TEMPLATES','90_ARCHIVE','99_INBOX','.agents\rules','.agents\agents','.agents\skills'
$missing = $dirs | Where-Object { -not (Test-Path (Join-Path $VaultPath $_)) }
if (-not $missing) { Rec 1 'Arborescence' PASS "$($dirs.Count) dossiers" } else { Rec 1 'Arborescence' FAIL ("manquants : " + ($missing -join ', ')) }
$sys = 'AI-INDEX','PROFILE-INDEX','PROJECTS-INDEX','AGENTS-INDEX','SKILLS-INDEX','MEMORY-POLICY','SECURITY','SETUP-REPORT'
$ms = $sys | Where-Object { -not (Test-Path (Join-Path $VaultPath "00_SYSTEM\$_.md")) }
if (-not $ms) { Rec 1 'Notes système' PASS "$($sys.Count) fichiers" } else { Rec 1 'Notes système' FAIL ($ms -join ', ') }
$obsJson = if ($env:APPDATA) { Join-Path $env:APPDATA 'obsidian\obsidian.json' } else { $null }
if ($obsJson -and (Test-Path $obsJson)) {
    $paths = @((Get-Content $obsJson -Raw | ConvertFrom-Json).vaults.PSObject.Properties | ForEach-Object { $_.Value.path })
    if ($paths | Where-Object { $_ -and ((Resolve-Path $_ -ErrorAction SilentlyContinue).Path -eq (Resolve-Path $VaultPath).Path) }) { Rec 1 'Coffre enregistré dans Obsidian' PASS } else { Rec 1 'Coffre enregistré dans Obsidian' FAIL 'ouvrez le dossier comme coffre' }
} else { Rec 1 'Coffre enregistré dans Obsidian' SKIP 'obsidian.json introuvable' }

# ------------------------------------------------------------------ Test 2
Write-Host "`n=== Test 2 : serveur MCP local ===" -ForegroundColor Cyan
$apiKey = $null; $entry = $null
if (Test-Path $McpConfig) {
    try {
        $cfg = Get-Content $McpConfig -Raw | ConvertFrom-Json
        $entry = $cfg.mcpServers.obsidian
        if ($entry) { $apiKey = ($entry.headers.Authorization -replace '^Bearer\s+', '') }
    } catch { Rec 2 'Lecture mcp_config.json' FAIL $_.Exception.Message }
}
$tlsOk = $false
try {
    $st = Invoke-RestMethod -UseBasicParsing -Uri "$BaseUrl/" -TimeoutSec 5
    $tlsOk = $true
    Rec 2 'Serveur HTTPS 127.0.0.1:27124 (TLS vérifié)' PASS ("plugin v" + $st.versions.self + " / Obsidian " + $st.versions.obsidian)
} catch {
    Rec 2 'Serveur HTTPS 127.0.0.1:27124 (TLS vérifié)' FAIL ("$($_.Exception.Message) -> Obsidian ouvert ? plugin actif ? CA approuvée (Install-AIVault.ps1 -TrustCertificate) ?")
}
try { $null = Invoke-WebRequest -UseBasicParsing -Uri 'http://127.0.0.1:27123/' -TimeoutSec 3; Rec 2 'Serveur HTTP non chiffré 27123 désactivé' WARN 'il répond : désactivez « Enable HTTP server »' } catch { Rec 2 'Serveur HTTP non chiffré 27123 désactivé' PASS }

$useKey = $tlsOk -and $apiKey -and ($apiKey -ne 'REPLACE_WITH_OBSIDIAN_API_KEY')
if (-not $useKey) { Rec 2 'Authentification' SKIP 'serveur inaccessible ou clé absente de mcp_config.json' }
else {
    $auth = @{ Authorization = "Bearer $apiKey" }
    try { $s2 = Invoke-RestMethod -UseBasicParsing -Uri "$BaseUrl/" -Headers $auth -TimeoutSec 5
          if ($s2.authenticated) { Rec 2 'Authentification' PASS } else { Rec 2 'Authentification' FAIL 'clé refusée' ; $useKey = $false } }
    catch { Rec 2 'Authentification' FAIL $_.Exception.Message; $useKey = $false }
}

$script:McpSession = $null; $script:McpId = 0
function Invoke-Mcp($method, $params, [switch]$Notification) {
    $body = [ordered]@{ jsonrpc = '2.0'; method = $method }
    if ($null -ne $params) { $body.params = $params }
    if (-not $Notification) { $script:McpId++; $body.id = $script:McpId }
    $h = @{ Authorization = "Bearer $apiKey"; Accept = 'application/json, text/event-stream' }
    if ($script:McpSession) { $h['Mcp-Session-Id'] = $script:McpSession; $h['MCP-Protocol-Version'] = '2025-06-18' }
    $json = $body | ConvertTo-Json -Depth 20 -Compress
    $resp = Invoke-WebRequest -UseBasicParsing -Uri "$BaseUrl/mcp/" -Method Post -Headers $h -ContentType 'application/json' -Body ([Text.Encoding]::UTF8.GetBytes($json)) -TimeoutSec 20
    $sid = $resp.Headers['Mcp-Session-Id']; if ($sid) { $script:McpSession = ($sid -join '') }
    if ($Notification) { return $null }
    $raw = if ($resp.RawContentStream) { [Text.Encoding]::UTF8.GetString($resp.RawContentStream.ToArray()) } else { [string]$resp.Content }
    if ($raw -match '(?m)^data:') { $raw = (($raw -split "`n") | Where-Object { $_ -like 'data:*' } | ForEach-Object { $_.Substring(5).Trim() } | Select-Object -Last 1) }
    $obj = $raw | ConvertFrom-Json
    if ($obj.error) { throw "MCP $method : $($obj.error.message)" }
    return $obj.result
}
function First-Arg($tool, $fallback) {
    if ($tool -and $tool.inputSchema -and $tool.inputSchema.required) { return @($tool.inputSchema.required)[0] } else { return $fallback }
}
function Text-Of($result) { (@($result.content) | Where-Object { $_.type -eq 'text' } | ForEach-Object { $_.text }) -join "`n" }

$tools = @()
if ($useKey) {
    try {
        $init = Invoke-Mcp 'initialize' @{ protocolVersion = '2025-06-18'; capabilities = @{}; clientInfo = @{ name = 'ai-vault-test'; version = '1.0' } }
        Invoke-Mcp 'notifications/initialized' $null -Notification | Out-Null
        Rec 2 'Handshake MCP' PASS ("serveur " + $init.serverInfo.name + " " + $init.serverInfo.version + ", protocole " + $init.protocolVersion)
        $tools = @((Invoke-Mcp 'tools/list' @{}).tools)
        $names = $tools | ForEach-Object { $_.name }
        Rec 2 'Outils MCP détectés' PASS ("$($names.Count) : " + ($names -join ', '))
        $absent = $Expected | Where-Object { $names -notcontains $_ }
        if ($absent) { Rec 2 'Outils souhaités exposés' WARN ("absents côté serveur : " + ($absent -join ', ')) } else { Rec 2 'Outils souhaités exposés' PASS '12/12' }
        $extra = $names | Where-Object { ($Expected -notcontains $_) }
        if ($extra) { Rec 2 'Outils supplémentaires (filtrés côté client)' INFO ($extra -join ', ') }

        $tSearch = $tools | Where-Object { $_.name -eq 'search_simple' }
        $argS = First-Arg $tSearch 'query'
        $sr = Invoke-Mcp 'tools/call' @{ name = 'search_simple'; arguments = @{ $argS = 'AI-INDEX'; maxResults = 5 } }
        $txt = Text-Of $sr
        if ($txt -match 'AI-INDEX|00_SYSTEM') { Rec 2 'Recherche simple' PASS 'résultats trouvés' } else { Rec 2 'Recherche simple' WARN ("réponse : " + $txt.Substring(0, [Math]::Min(150, $txt.Length))) }

        $tRead = $tools | Where-Object { $_.name -eq 'vault_read' }
        $argR = First-Arg $tRead 'path'
        $rr = Invoke-Mcp 'tools/call' @{ name = 'vault_read'; arguments = @{ $argR = '00_SYSTEM/AI-INDEX.md' } }
        if ((Text-Of $rr) -match 'Routeur de contexte') { Rec 2 'Lecture de 00_SYSTEM/AI-INDEX.md' PASS } else { Rec 2 'Lecture de 00_SYSTEM/AI-INDEX.md' FAIL 'contenu inattendu' }

        $pr = Invoke-Mcp 'tools/call' @{ name = 'vault_read'; arguments = @{ $argR = '00_SYSTEM/PROJECTS-INDEX.md' } }
        $script:ProjectsIndex = Text-Of $pr
    } catch { Rec 2 'Dialogue MCP' FAIL $_.Exception.Message }
}

# ------------------------------------------------------------------ Test 3
Write-Host "`n=== Test 3 : Antigravity ===" -ForegroundColor Cyan
if (-not $entry) { Rec 3 'Entrée obsidian dans mcp_config.json' FAIL $McpConfig }
else {
    Rec 3 'Entrée obsidian dans mcp_config.json' PASS $McpConfig
    if ($entry.serverUrl -eq "$BaseUrl/mcp/") { Rec 3 'serverUrl localhost' PASS $entry.serverUrl } else { Rec 3 'serverUrl localhost' FAIL $entry.serverUrl }
    $en = @($entry.enabledTools)
    if (-not (Compare-Object $en $Expected)) { Rec 3 'enabledTools = liste prévue' PASS } else { Rec 3 'enabledTools = liste prévue' WARN ($en -join ', ') }
    $bad = $en | Where-Object { $Destructive -contains $_ }
    if ($bad) { Rec 3 'Aucun outil destructif autorisé' FAIL ($bad -join ', ') } else { Rec 3 'Aucun outil destructif autorisé' PASS }
    if ($entry.disabled) { Rec 3 'Serveur activé' FAIL '"disabled": true (clé non renseignée ?)' } else { Rec 3 'Serveur activé' PASS }
    $others = @($cfg.mcpServers.PSObject.Properties | Where-Object { $_.Name -ne 'obsidian' } | ForEach-Object { $_.Name })
    Rec 3 'Autres serveurs MCP préservés' INFO $(if ($others) { $others -join ', ' } else { 'aucun autre serveur' })
}
# Antigravity écrit le schéma de chaque outil sur disque lorsqu'il se connecte au serveur (lazy loading).
$cacheDirs = @((Join-Path $UserHome '.gemini\antigravity\mcp\obsidian'), (Join-Path $UserHome '.gemini\antigravity-cli\mcp\obsidian'))
$found = $false
foreach ($d in $cacheDirs) {
    if (Test-Path $d) {
        $found = $true
        $cached = @(Get-ChildItem $d -Filter *.json | ForEach-Object { $_.BaseName })
        $age = ((Get-Date) - (Get-Item $d).LastWriteTime).TotalHours
        Rec 3 "Antigravity connecté (cache $d)" PASS ("$($cached.Count) outil(s) : " + ($cached -join ', ') + (" ; mis à jour il y a {0:N1} h" -f $age))
        $leak = $cached | Where-Object { $Destructive -contains $_ }
        if ($leak) { Rec 3 'Outils visibles par l''agent' FAIL ("destructifs visibles : " + ($leak -join ', ')) } else { Rec 3 'Outils visibles par l''agent' PASS 'aucun outil destructif' }
    }
}
if (-not $found) { Rec 3 'Antigravity connecté' WARN 'aucun cache de schéma : redémarrez Antigravity, puis vérifiez Customizations > Installed > MCP Servers' }
if (Get-Command agy -ErrorAction SilentlyContinue) {
    $ag = (& agy agents 2>&1 | Out-String)
    foreach ($a in 'project-researcher','developer','reviewer') { if ($ag -match $a) { Rec 4 "agy agents liste $a" PASS } else { Rec 4 "agy agents liste $a" WARN 'non listé' } }
}

# ------------------------------------------------------------------ Test 4
Write-Host "`n=== Test 4 : agents, skills, règle ===" -ForegroundColor Cyan
$roots = @((Join-Path $VaultPath '.agents'))
if (Test-Path $GeminiConfig) { $roots += $GeminiConfig }
foreach ($root in $roots) {
    foreach ($a in 'project-researcher','developer','reviewer') {
        $f = Join-Path $root "agents\$a.md"
        if (Test-Path $f) {
            $fm = Get-Frontmatter $f
            if ($fm -match "(?m)^name:\s*$a\s*$" -and $fm -match '(?m)^description:\s*\S' -and $fm -match '(?m)^subagent:\s*true') { Rec 4 "Agent $a ($root)" PASS 'name/description/subagent:true' }
            else { Rec 4 "Agent $a ($root)" FAIL 'frontmatter incomplet' }
        } else { Rec 4 "Agent $a ($root)" $(if ($root -eq $GeminiConfig) { 'INFO' } else { 'FAIL' }) 'absent' }
    }
    foreach ($s in 'context-retrieval','project-management','knowledge-management','web-research','python-development','code-review') {
        $f = Join-Path $root "skills\$s\SKILL.md"
        if (Test-Path $f) {
            $fm = Get-Frontmatter $f
            $len = (Get-Item $f).Length
            if ($fm -match '(?m)^description:\s*\S') { Rec 4 "Skill $s ($root)" PASS ("description présente ; corps $len octets chargé à la demande") } else { Rec 4 "Skill $s ($root)" FAIL 'description manquante' }
        } else { Rec 4 "Skill $s ($root)" $(if ($root -eq $GeminiConfig) { 'INFO' } else { 'FAIL' }) 'absent' }
    }
    $rule = Join-Path $root 'rules\obsidian-context-router.md'
    if (Test-Path $rule) {
        $fm = Get-Frontmatter $rule
        if ($fm -match '(?m)^trigger:\s*model_decision\s*$' -and $fm -match '(?m)^description:') { Rec 4 "Règle obsidian-context-router ($root)" PASS 'trigger: model_decision' } else { Rec 4 "Règle obsidian-context-router ($root)" FAIL 'frontmatter invalide (règle ignorée par Antigravity)' }
    }
}
foreach ($big in (Join-Path $UserHome '.gemini\GEMINI.md'), (Join-Path $UserHome '.gemini\AGENTS.md'), (Join-Path $GeminiConfig 'GEMINI.md'), (Join-Path $GeminiConfig 'AGENTS.md')) {
    if (Test-Path $big) { $kb = [Math]::Round((Get-Item $big).Length / 1KB, 1); Rec 4 "Règle toujours active $big" $(if ($kb -gt 8) { 'WARN' } else { 'INFO' }) "$kb Ko chargés à chaque tour" }
}

# ------------------------------------------------------------------ Test 5
Write-Host "`n=== Test 5 : routage (simulation déterministe) ===" -ForegroundColor Cyan
$demande = 'Je veux reprendre mon projet de trading automatisé.'
$idx = if ($script:ProjectsIndex) { $script:ProjectsIndex } else { Get-Content (Join-Path $VaultPath '00_SYSTEM\PROJECTS-INDEX.md') -Raw -Encoding UTF8 }
$src = if ($script:ProjectsIndex) { 'via MCP' } else { 'via fichier local (MCP indisponible)' }
Rec 5 'Index des projets consulté' PASS $src
$section = ($idx -split '## Projets enregistrés')[1]
$rows = @(($section -split "`n") | Where-Object { $_ -match '^\|\s*[a-z0-9-]+\s*\|' -and $_ -notmatch '^\|\s*id\s*\|' })
$hit = $rows | Where-Object { $_ -match '(?i)trading' }
if ($hit) {
    $id = ($hit[0] -split '\|')[1].Trim()
    Rec 5 'Projet identifié' PASS $id
} else {
    Rec 5 'Projet Trading identifié' PASS 'aucun projet trading enregistré -> l''agent doit le signaler et proposer la création (catégorie Trading-Bot), sans inventer d''historique'
}
Rec 5 'Autres projets non lus' PASS ("seule la ligne correspondante est retenue parmi $($rows.Count) projet(s)")
Rec 5 'Spécialiste suggéré' PASS 'developer (code de bot) ; project-researcher si recherche de stratégie ; reviewer pour validation'
Rec 5 'Skills chargés' PASS 'context-retrieval (+ project-management si création) — 2/6'
Write-Host @"

  Test réel à faire dans Antigravity (nouvelle conversation) :
    "$demande"
  Attendu : lecture de 00_SYSTEM/AI-INDEX.md puis PROJECTS-INDEX.md via le serveur obsidian ;
  message « aucun projet de trading enregistré » + proposition de création ; aucune lecture
  des autres projets ; au plus 1–2 skills ouverts (context-retrieval, project-management).
"@ -ForegroundColor Yellow

# ------------------------------------------------------------------ résumé + rapport
$sum = $Results | Group-Object Status | ForEach-Object { "$($_.Name)=$($_.Count)" }
Write-Host "`nRésumé : $($sum -join '  ')" -ForegroundColor Cyan
if (-not $NoReport) {
    $rep = Join-Path $VaultPath '00_SYSTEM\SETUP-REPORT.md'
    if (Test-Path $rep) {
        $lines = @("", "### Tests du $(Get-Date -Format 'yyyy-MM-dd HH:mm') — $($sum -join ', ')", "", "| Test | Vérification | Statut | Détail |", "|---|---|---|---|")
        foreach ($r in $Results) { $lines += "| $($r.Test) | $($r.Check -replace '\|','/') | $($r.Status) | $(($r.Detail -replace '\|','/') -replace [regex]::Escape($UserHome),'%USERPROFILE%') |" }
        [IO.File]::AppendAllText($rep, ($lines -join "`r`n") + "`r`n", (New-Object Text.UTF8Encoding($false)))
        Write-Host "Journal ajouté à $rep (aucun secret)."
    }
}
$apiKey = $null
