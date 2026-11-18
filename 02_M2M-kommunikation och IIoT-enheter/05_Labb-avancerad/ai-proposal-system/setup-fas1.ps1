# setup-fas1.ps1
# Automatisk installation och konfiguration for AI Proposal System - Fas 1

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "FAS 1: Automatisk installation" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Detta skript kommer att:" -ForegroundColor Yellow
Write-Host "  1. Kontrollera Node.js installation" -ForegroundColor White
Write-Host "  2. Installera Node.js om det saknas (automatiskt)" -ForegroundColor White
Write-Host "  3. Skapa Next.js-projekt" -ForegroundColor White
Write-Host "  4. Installera nodvandiga bibliotek" -ForegroundColor White
Write-Host "  5. Fraga efter API-nycklar" -ForegroundColor White
Write-Host "  6. Skapa .env.local med dina nycklar" -ForegroundColor White
Write-Host "  7. Starta servern" -ForegroundColor White
Write-Host ""

# Steg 1: Kontrollera och installera Node.js om det behovs
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "[1/7] Kontrollerar Node.js..." -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan

function Install-NodeJS {
    Write-Host "Node.js saknas! Installerar automatiskt..." -ForegroundColor Yellow
    
    # Hitta den senaste LTS-versionen av Node.js for Windows
    $nodeVersion = "22.14.0"  # Senaste LTS version (mars 2026)
    $installerUrl = "https://nodejs.org/dist/v$nodeVersion/node-v$nodeVersion-x64.msi"
    $installerPath = "$env:TEMP\node-installer.msi"
    
    Write-Host "Laddar ner Node.js v$nodeVersion från:" -ForegroundColor Cyan
    Write-Host $installerUrl -ForegroundColor White
    
    try {
        # Ladda ner installeraren
        Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath -UseBasicParsing
        Write-Host "[OK] Nedladdning klar!" -ForegroundColor Green
        
        # Installera Node.js (tyst installation)
        Write-Host "Installerar Node.js (detta kan ta nagra minuter)..." -ForegroundColor Yellow
        $installProcess = Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$installerPath`" /quiet /norestart" -Wait -PassThru
        
        if ($installProcess.ExitCode -eq 0) {
            Write-Host "[OK] Node.js installerat!" -ForegroundColor Green
            
            # Uppdatera PATH i nuvarande session
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
            
            # Ta bort installeraren
            Remove-Item $installerPath -ErrorAction SilentlyContinue
            
            # Vanta pa att installationen registreras
            Start-Sleep -Seconds 2
            return $true
        } else {
            Write-Host "[FEL] Installation misslyckades med kod: $($installProcess.ExitCode)" -ForegroundColor Red
            Write-Host "Forsok installera manuellt från: https://nodejs.org" -ForegroundColor Yellow
            return $false
        }
    } catch {
        Write-Host "[FEL] Kunde inte ladda ner Node.js: $_" -ForegroundColor Red
        Write-Host "Var god installera Node.js manuellt från: https://nodejs.org" -ForegroundColor Yellow
        return $false
    }
}

# Kontrollera om node finns, installera om inte
$nodeInstalled = $false
try {
    $nodeVersion = node -v 2>$null
    if ($nodeVersion) {
        Write-Host "[OK] Node.js ar installerat: $nodeVersion" -ForegroundColor Green
        $nodeInstalled = $true
    }
} catch {
    $nodeInstalled = $false
}

if (-not $nodeInstalled) {
    $installSuccess = Install-NodeJS
    
    if (-not $installSuccess) {
        Write-Host ""
        Write-Host "[FEL] Kunde inte installera Node.js automatiskt." -ForegroundColor Red
        Write-Host "Var god installera Node.js manuellt från: https://nodejs.org" -ForegroundColor Cyan
        Write-Host "Efter installation, starta om detta skript." -ForegroundColor Yellow
        exit 1
    }
    
    # Verifiera installationen
    try {
        $nodeVersion = node -v
        $npmVersion = npm -v
        Write-Host "[OK] Node.js installation verifierad: $nodeVersion" -ForegroundColor Green
        Write-Host "[OK] NPM version: $npmVersion" -ForegroundColor Green
    } catch {
        Write-Host "[VARNING] Starta om PowerShell for att anvanda Node.js" -ForegroundColor Yellow
        Write-Host "Kor sedan detta skript igen." -ForegroundColor Yellow
        exit 1
    }
}

# Steg 2: Skapa projekt (om det inte finns)
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "[2/7] Skapar Next.js-projekt..." -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan

$projectName = "proposales-ai"
if (Test-Path $projectName) {
    Write-Host "[VARNING] Projektmappen '$projectName' finns redan." -ForegroundColor Yellow
    $choice = Read-Host "Vill du anvanda befintlig mapp? (J/N)"
    if ($choice -ne "J") {
        Write-Host "Avbryter." -ForegroundColor Red
        exit 0
    }
} else {
    Write-Host "Skapar nytt Next.js-projekt: $projectName..." -ForegroundColor Yellow
    npx create-next-app@latest $projectName --typescript --tailwind --app --no-eslint --no-src-dir
    Write-Host "[OK] Projekt skapat!" -ForegroundColor Green
}

# Ga in i projektmappen
Set-Location $projectName
Write-Host "[OK] Gick in i mappen: $(Get-Location)" -ForegroundColor Green

# Steg 3: Installera bibliotek
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "[3/7] Installerar nodvandiga bibliotek..." -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan

$packages = @(
    "groq-sdk",
    "@huggingface/transformers",
    "vectra",
    "localforage",
    "dotenv"
)

foreach ($pkg in $packages) {
    Write-Host "Installerar $pkg..." -ForegroundColor Yellow
    npm install $pkg --silent
    Write-Host "   [OK] $pkg installerat" -ForegroundColor Green
}

Write-Host "[OK] Alla bibliotek installerade!" -ForegroundColor Green

# Steg 4: Fraga efter API-nycklar
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "[4/7] Ange API-nycklar" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Groq API-nyckel (gratis LLM)" -ForegroundColor Cyan
Write-Host "   Sa har du far en nyckel:" -ForegroundColor White
Write-Host "   1. Ga till https://console.groq.com" -ForegroundColor White
Write-Host "   2. Registrera dig (gratis)" -ForegroundColor White
Write-Host "   3. Ga till 'API Keys' -> 'Create API Key'" -ForegroundColor White
Write-Host "   4. Kopiera nyckeln (borjar med 'gsk_')" -ForegroundColor White
Write-Host ""
$groqKey = Read-Host "Klistra in din Groq API-nyckel"

Write-Host ""
Write-Host "Proposales API-nyckel (for offerter)" -ForegroundColor Cyan
Write-Host "   Sa har du far en nyckel (VALFRITT):" -ForegroundColor White
Write-Host "   1. Ga till https://proposales.com" -ForegroundColor White
Write-Host "   2. Registrera dig (gratis)" -ForegroundColor White
Write-Host "   3. Ga till Settings -> Profile -> langst ner" -ForegroundColor White
Write-Host "   4. Kopiera API-nyckeln (borjar med 'ps.')" -ForegroundColor White
Write-Host ""
$proposalesKey = Read-Host "Klistra in din Proposales API-nyckel (eller lamna tom for demo)"

Write-Host ""
Write-Host "Proposales Company ID" -ForegroundColor Cyan
Write-Host "   Sa har du hittar det:" -ForegroundColor White
Write-Host "   Kor i terminalen: curl -X GET 'https://api.proposales.com/v3/companies' -H 'Authorization: Bearer DIN_NYCKEL'" -ForegroundColor White
Write-Host "   Svaret innehaller 'id' (siffra)" -ForegroundColor White
Write-Host ""
$companyId = Read-Host "Ange ditt Company ID (siffra, eller lamna tom)"

# Steg 5: Skapa .env.local
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "[5/7] Skapar .env.local..." -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan

$envContent = @"
# API-nycklar for AI Proposal System
# Detta ar en lokal fil - ladda ALDRIG upp den till GitHub!

GROQ_API_KEY=$groqKey
"@

if ($proposalesKey) {
    $envContent = $envContent + "`nPROPOSALES_API_KEY=$proposalesKey"
}
if ($companyId) {
    $envContent = $envContent + "`nPROPOSALES_COMPANY_ID=$companyId"
}

$envContent = $envContent + @"

# For lokal utveckling
NEXT_PUBLIC_APP_URL=http://localhost:3000
"@

$envContent | Out-File -FilePath ".env.local" -Encoding utf8
Write-Host "[OK] .env.local skapad!" -ForegroundColor Green
Write-Host "[VARNING] Denna fil ar hemlig - ladda ALDRIG upp den till GitHub!" -ForegroundColor Yellow

# Steg 6: Skapa .gitignore
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "[6/7] Skapar .gitignore..." -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan

$gitignoreContent = @'
# Dependencies
node_modules/
.pnp/
.pnp.js

# Next.js
.next/
out/
build/
dist/

# Environment variables (HEMLIGA!)
.env
.env.local
.env.*.local
.env.production
.env.development

# IDE
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Logs
*.log
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# PowerShell scripts (installation only)
*.ps1

# Vector database (local only)
vectra-index/
lancedb/

# Build caches
.cache/
.parcel-cache/

# Misc
*.pem
*.cert
.vercel
README.md.backup
'@

$gitignoreContent | Out-File -FilePath ".gitignore" -Encoding utf8
Write-Host "[OK] .gitignore skapad!" -ForegroundColor Green
Write-Host "   (Skyddar dina hemligheter fran att pushas till GitHub)" -ForegroundColor Yellow

# Steg 7: Starta servern
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "[7/7] STARTA SERVERN..." -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Oppna din webblasare pa: http://localhost:3000" -ForegroundColor Yellow
Write-Host ""
Write-Host "Tryck CTRL+C for att stoppa servern nar du ar klar." -ForegroundColor White
Write-Host ""

npm run dev