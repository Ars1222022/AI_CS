# setup-products-fas2.ps1
# Skapar produkter i Proposales content library (online) eller lokalt for demo
# Uppdaterad: Kan kora flera ganger utan att skapa dubletter

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Fas 2: Skapar produkter" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Las API-nycklar fran .env.local
$envFile = ".env.local"
$apiKey = ""
$companyId = ""

if (Test-Path $envFile) {
    $envContent = Get-Content $envFile -Raw
    if ($envContent -match 'PROPOSALES_API_KEY=(.+)') {
        $apiKey = $matches[1].Trim()
    }
    if ($envContent -match 'PROPOSALES_COMPANY_ID=(.+)') {
        $companyId = $matches[1].Trim()
    }
}

# Fraga om anvandaren vill anvanda Proposales API
Write-Host "VILL DU ANVANDA PROPOSALES API (online)?" -ForegroundColor Yellow
Write-Host "   Om ja: Skapas produkter online i ditt Proposales-konto" -ForegroundColor White
Write-Host "   Om nej: Skapas lokala test-produkter (demo-lage)" -ForegroundColor White
Write-Host ""
$useProposales = Read-Host "Anvand Proposales API? (J/N)"

# Fraga om anvandaren vill ersatta befintlig databas
Write-Host ""
Write-Host "VILL DU ERSATTA BEFINTLIG DATABAS?" -ForegroundColor Yellow
Write-Host "   Om ja: Tar bort gamla produkter och skapar nya" -ForegroundColor White
Write-Host "   Om nej: Lagger till nya produkter (kan skapa dubletter)" -ForegroundColor White
Write-Host ""
$replaceDatabase = Read-Host "Ersatta befintlig databas? (J/N)"

if ($useProposales -eq "J") {
    # Kontrollera att API-nycklar finns
    if ([string]::IsNullOrEmpty($apiKey) -or [string]::IsNullOrEmpty($companyId)) {
        Write-Host ""
        Write-Host "[FEL] PROPOSALES_API_KEY eller PROPOSALES_COMPANY_ID saknas i .env.local" -ForegroundColor Red
        Write-Host ""
        Write-Host "Sa har du fixar:" -ForegroundColor Yellow
        Write-Host "   1. Oppna .env.local i VS Code" -ForegroundColor White
        Write-Host "   2. Lagg till dessa rader:" -ForegroundColor White
        Write-Host "      PROPOSALES_API_KEY=ps.din_nyckel" -ForegroundColor Cyan
        Write-Host "      PROPOSALES_COMPANY_ID=din_siffra" -ForegroundColor Cyan
        Write-Host "   3. Spara och kor skriptet igen" -ForegroundColor White
        Write-Host ""
        exit 1
    }
    
    Write-Host ""
    Write-Host "[OK] PROPOSALES_API_KEY laddad fran .env.local" -ForegroundColor Green
    Write-Host "[OK] PROPOSALES_COMPANY_ID laddad fran .env.local" -ForegroundColor Green
    
    # Om anvandaren vill ersatta, hamta och ta bort alla befintliga produkter
    if ($replaceDatabase -eq "J") {
        Write-Host ""
        Write-Host "Hamtar befintliga produkter fran Proposales..." -ForegroundColor Yellow
        
        try {
            $existingProducts = Invoke-RestMethod -Uri "https://api.proposales.com/v3/content" `
                -Method Get `
                -Headers @{
                    "Authorization" = "Bearer $apiKey"
                }
            
            $productCount = $existingProducts.data.Count
            Write-Host "   Hittade $productCount befintliga produkter" -ForegroundColor White
            
            if ($productCount -gt 0) {
                Write-Host "   Tar bort befintliga produkter..." -ForegroundColor Yellow
                
                # Ta bort varje produkt via DELETE /v3/content?product_id=xxx
                foreach ($product in $existingProducts.data) {
                    $productId = $product.product_id
                    try {
                        Invoke-RestMethod -Uri "https://api.proposales.com/v3/content?product_id=$productId" `
                            -Method Delete `
                            -Headers @{
                                "Authorization" = "Bearer $apiKey"
                            } | Out-Null
                        Write-Host "      [OK] Borttagen: $($product.title.en) (ID: $productId)" -ForegroundColor Green
                    }
                    catch {
                        Write-Host "      [VARNING] Kunde inte ta bort: $($product.title.en)" -ForegroundColor Yellow
                    }
                    Start-Sleep -Milliseconds 200
                }
                Write-Host "   [OK] Befintliga produkter borttagna!" -ForegroundColor Green
            }
        }
        catch {
            Write-Host "   [VARNING] Kunde inte hamta befintliga produkter" -ForegroundColor Yellow
        }
    }
    
    # Produkter att skapa online
    $products = @(
        "Standard Meeting Room|Bright meeting room with whiteboard, TV and WiFi. Perfect for board meetings.|day|50000"
        "Executive Boardroom|Premium soundproof boardroom with video conferencing.|day|80000"
        "Grand Conference Hall|Large theater-style hall with stage and sound system.|day|150000"
        "Executive Lunch Buffet|Hot and cold buffet with salads, main courses, dessert.|person|4500"
        "Premium Coffee Break|Fresh coffee, teas, pastries and fruit.|person|1200"
        "Professional AV Package|Full HD projector, screen and wireless microphone.|day|25000"
        "Deluxe Double Room|Spacious room with king bed and free WiFi. Includes breakfast.|night|22000"
        "Bridal Suite|Luxury suite with jacuzzi and champagne on arrival.|night|75000"
        "Basic Wedding Package|Ceremony setup, 3-course dinner and open bar.|unit|1200000"
        "Spa Day Access|Full access to sauna, steam room, jacuzzi and pool.|person|6500"
        "Farewell Brunch Buffet|Late morning buffet with eggs, pastries and fruits.|person|2900"
    )
    
    Write-Host ""
    Write-Host "Skapar $($products.Count) produkter ONLINE i Proposales..." -ForegroundColor Yellow
    Write-Host ""
    
    $successCount = 0
    $failCount = 0
    
    foreach ($product in $products) {
        $parts = $product -split "\|"
        $title = $parts[0]
        $description = $parts[1]
        
        Write-Host "Skapar: $title..." -ForegroundColor Yellow
        
        $body = @{
            company_id = [int]$companyId
            language = "en"
            title = $title
            description = $description
            images = @()
        }
        
        $jsonBody = $body | ConvertTo-Json
        
        try {
            $response = Invoke-RestMethod -Uri "https://api.proposales.com/v3/content" `
                -Method Post `
                -Headers @{
                    "Authorization" = "Bearer $apiKey"
                    "Content-Type" = "application/json"
                } `
                -Body $jsonBody
            
            Write-Host "  [OK] Skapad! (product_id: $($response.data.product_id))" -ForegroundColor Green
            $successCount++
            Start-Sleep -Milliseconds 500
        }
        catch {
            Write-Host "  [FEL] Fel: $($_.Exception.Message)" -ForegroundColor Red
            $failCount++
        }
    }
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Sammanfattning (ONLINE)" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "[OK] Lyckades: $successCount produkter" -ForegroundColor Green
    Write-Host "[FEL] Misslyckades: $failCount produkter" -ForegroundColor Red
    Write-Host ""
    
    # Fraga om anvandaren vill verifiera
    $verify = Read-Host "Vill du verifiera produkterna online? (J/N)"
    if ($verify -eq "J") {
        Write-Host ""
        Write-Host "Hamtar produkter fran Proposales..." -ForegroundColor Yellow
        try {
            $response = Invoke-RestMethod -Uri "https://api.proposales.com/v3/content" `
                -Method Get `
                -Headers @{
                    "Authorization" = "Bearer $apiKey"
                }
            Write-Host "[OK] Hittade $($response.data.Count) produkter:" -ForegroundColor Green
            foreach ($item in $response.data) {
                Write-Host "   - $($item.title.en)" -ForegroundColor White
            }
        }
        catch {
            Write-Host "[FEL] Kunde inte hamta produkter" -ForegroundColor Red
        }
    }
    
} else {
    # Demo-lage: Skapa lokal mock-data
    Write-Host ""
    Write-Host "DEMO-LAGE: Skapar lokala test-produkter" -ForegroundColor Yellow
    Write-Host ""
    
    # Om anvandaren vill ersatta, ta bort gammal mock-products.json
    if ($replaceDatabase -eq "J") {
        if (Test-Path "mock-products.json") {
            Remove-Item "mock-products.json" -Force
            Write-Host "[OK] Befintlig mock-products.json borttagen" -ForegroundColor Green
        }
    }
    
    Write-Host "[VARNING] OBS: Utan Proposales API kan du INTE:" -ForegroundColor Yellow
    Write-Host "   - Skapa riktiga proposal online" -ForegroundColor White
    Write-Host "   - Hamta produkter fran Proposales moln" -ForegroundColor White
    Write-Host ""
    Write-Host "[OK] Daremot KAN du:" -ForegroundColor Green
    Write-Host "   - Testa hela AI-pipelinen lokalt" -ForegroundColor White
    Write-Host "   - Semantisk sokning fungerar" -ForegroundColor White
    Write-Host "   - Planering och utvardering fungerar" -ForegroundColor White
    Write-Host ""
    
    # Skapa en lokal JSON-fil med mock-produkter
    $mockProducts = @(
        @{ id = 1; title = "Standard Meeting Room"; description = "Bright meeting room with whiteboard, TV and WiFi. Perfect for board meetings."; unit = "day"; price = 500 }
        @{ id = 2; title = "Executive Boardroom"; description = "Premium soundproof boardroom with video conferencing."; unit = "day"; price = 800 }
        @{ id = 3; title = "Grand Conference Hall"; description = "Large theater-style hall with stage and sound system."; unit = "day"; price = 1500 }
        @{ id = 4; title = "Executive Lunch Buffet"; description = "Hot and cold buffet with salads, main courses, dessert."; unit = "person"; price = 45 }
        @{ id = 5; title = "Premium Coffee Break"; description = "Fresh coffee, teas, pastries and fruit."; unit = "person"; price = 12 }
        @{ id = 6; title = "Professional AV Package"; description = "Full HD projector, screen and wireless microphone."; unit = "day"; price = 250 }
        @{ id = 7; title = "Deluxe Double Room"; description = "Spacious room with king bed and free WiFi. Includes breakfast."; unit = "night"; price = 220 }
        @{ id = 8; title = "Bridal Suite"; description = "Luxury suite with jacuzzi and champagne on arrival."; unit = "night"; price = 750 }
        @{ id = 9; title = "Basic Wedding Package"; description = "Ceremony setup, 3-course dinner and open bar."; unit = "unit"; price = 12000 }
        @{ id = 10; title = "Spa Day Access"; description = "Full access to sauna, steam room, jacuzzi and pool."; unit = "person"; price = 65 }
        @{ id = 11; title = "Farewell Brunch Buffet"; description = "Late morning buffet with eggs, pastries and fruits."; unit = "person"; price = 29 }
    )
    
    # Spara mock-produkter till JSON-fil
    $mockJson = $mockProducts | ConvertTo-Json -Depth 10
    $mockJson | Out-File -FilePath "mock-products.json" -Encoding utf8
    Write-Host "[OK] Sparade $($mockProducts.Count) test-produkter i mock-products.json" -ForegroundColor Green
    Write-Host ""
    
    # Visa produkterna i en fin tabell
    Write-Host "PRODUKTER:" -ForegroundColor Cyan
    Write-Host ("{0,-25} {1,-15} {2,-10}" -f "Titel", "Enhet", "Pris (EUR)") -ForegroundColor Yellow
    Write-Host ("{0,-25} {1,-15} {2,-10}" -f "-----", "-----", "---------") -ForegroundColor Gray
    foreach ($product in $mockProducts) {
        Write-Host ("{0,-25} {1,-15} {2,-10}" -f $product.title, $product.unit, $product.price) -ForegroundColor White
    }
    
    Write-Host ""
    Write-Host "[INFO] Filen sparas lokalt och anvands i Fas 3 (retrieval-lager)" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Fas 2 ar klar!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan