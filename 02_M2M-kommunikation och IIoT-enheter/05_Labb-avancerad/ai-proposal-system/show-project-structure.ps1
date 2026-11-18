# show-project-structure.ps1
# Visar komplett mappstruktur och filer (exkluderar stora/systemmappar)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "📁 PROJEKTSTRUKTUR - AI Proposal System" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Funktion för att visa trädstruktur
function Show-Tree {
    param(
        [string]$Path,
        [string]$Indent = "",
        [int]$Depth = 0,
        [int]$MaxDepth = 5
    )
    
    if ($Depth -gt $MaxDepth) { return }
    
    $items = Get-ChildItem -Path $Path -Force | Where-Object { 
        $_.Name -notin @(
            "node_modules", 
            ".next", 
            ".git", 
            "vectra-index", 
            ".vercel",
            "temp-build.js",
            "*.log",
            ".env.local.backup"
        ) 
    } | Sort-Object { $_.PSIsContainer } -Descending
    
    foreach ($item in $items) {
        if ($item.PSIsContainer) {
            # Räkna antal filer i mappen
            $fileCount = (Get-ChildItem -Path $item.FullName -Recurse -File -ErrorAction SilentlyContinue).Count
            $icon = if ($item.Name -eq "api") { "🔌" } elseif ($item.Name -eq "lib") { "📚" } else { "📁" }
            
            Write-Host "$Indent$icon $($item.Name)/ ($fileCount filer)" -ForegroundColor Cyan
            Show-Tree -Path $item.FullName -Indent "$Indent  " -Depth ($Depth + 1) -MaxDepth $MaxDepth
        } else {
            # Visa fil med storlek
            $size = "{0:N0}" -f ($item.Length / 1KB)
            $sizeUnit = "KB"
            if ($item.Length -gt 1MB) {
                $size = "{0:N2}" -f ($item.Length / 1MB)
                $sizeUnit = "MB"
            }
            
            # Välj ikon baserat på filtyp
            $icon = "📄"
            if ($item.Name -match "\.tsx?$") { $icon = "⚛️" }
            elseif ($item.Name -match "\.json$") { $icon = "📋" }
            elseif ($item.Name -match "\.ps1$") { $icon = "⚡" }
            elseif ($item.Name -match "\.css$") { $icon = "🎨" }
            elseif ($item.Name -match "\.env") { $icon = "🔐" }
            elseif ($item.Name -match "\.md$") { $icon = "📝" }
            
            Write-Host "$Indent$icon $($item.Name) ($size $sizeUnit)" -ForegroundColor Green
        }
    }
}

# Hitta projektmappen
$possiblePaths = @(
    "D:\ai-proposal-system\proposales-ai",
    "D:\ai-proposal-system",
    "C:\proposales-ai",
    (Get-Location).Path
)

$projectPath = $null
foreach ($path in $possiblePaths) {
    if (Test-Path "$path\package.json") {
        $projectPath = $path
        break
    }
}

if (-not $projectPath) {
    Write-Host "❌ Kunde inte hitta projektmappen!" -ForegroundColor Red
    Write-Host ""
    Write-Host "📁 Ange sökväg till din projektmapp (där package.json finns):" -ForegroundColor Yellow
    $projectPath = Read-Host "Sökväg"
    
    if (-not (Test-Path "$projectPath\package.json")) {
        Write-Host "❌ Ogiltig sökväg! Avbryter." -ForegroundColor Red
        exit 1
    }
}

Write-Host "📂 PROJEKTMAPP: $projectPath" -ForegroundColor Yellow
Write-Host ""

# Visa trädstruktur
Show-Tree -Path $projectPath -Depth 0 -MaxDepth 4

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "📊 SAMMANFATTNING" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan

# Räkna totalt antal filer
$allFiles = Get-ChildItem -Path $projectPath -Recurse -File -ErrorAction SilentlyContinue | Where-Object {
    $_.DirectoryName -notmatch "node_modules|\.next|\.git|vectra-index|\.vercel"
}
$totalFiles = $allFiles.Count
$totalSize = "{0:N2}" -f (($allFiles | Measure-Object -Property Length -Sum).Sum / 1MB)

Write-Host ""
Write-Host "📁 Totalt antal filer: $totalFiles" -ForegroundColor White
Write-Host "💾 Total storlek: $totalSize MB" -ForegroundColor White
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "📋 VIKTIGA FILER OCH DERAS SYFTE" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "📁 app/api/            - Alla API-routes (extract, search, plan, evaluate)" -ForegroundColor White
Write-Host "📁 app/lib/            - Retrieval.ts (semantisk sökning med Upstash)" -ForegroundColor White
Write-Host "📄 app/page.tsx        - Grafiskt gränssnitt (React-komponent)" -ForegroundColor White
Write-Host "📄 app/globals.css     - Stilar (Vanilla CSS)" -ForegroundColor White
Write-Host "📄 mock-products.json  - 11 produkter med priser" -ForegroundColor White
Write-Host "📄 .env.local          - API-nycklar (HEMLIGA! Ladda ALDRIG upp)" -ForegroundColor White
Write-Host "📄 package.json        - Lista över installerade bibliotek" -ForegroundColor White
Write-Host "📄 vercel.json         - Konfiguration för Vercel-deployment" -ForegroundColor White
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "🚀 FÖR ATT STARTA APPEN:" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "   npm run dev" -ForegroundColor Yellow
Write-Host "   Öppna http://localhost:3000" -ForegroundColor White
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "📦 FÖR ATT BYGGA UPSTASH INDEX (om det behövs):" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "   Invoke-RestMethod -Uri 'http://localhost:3000/api/build-index' -Method POST" -ForegroundColor Yellow
Write-Host ""