# setup-fas4-complete.ps1
# Komplett installation av RFP-extractor (Fas 4)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Fas 4: Bygg RFP-extractor (AI som laser forfragningar)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Steg 0: Kontrollera att vi ar i ratt mapp
Write-Host "[0/6] Kontrollerar projektmapp..." -ForegroundColor Yellow

if (-not (Test-Path "package.json")) {
    Write-Host "[FEL] Ingen package.json hittades!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Ga till ratt mapp och kor igen:" -ForegroundColor Yellow
    Write-Host "   cd D:\ai-proposal-system\proposales-ai" -ForegroundColor White
    exit 1
}

Write-Host "[OK] Ratt mapp: $(Get-Location)" -ForegroundColor Green
Write-Host ""

# Steg 1: Forklara vad som ska handa
Write-Host "[1/6] VAD HANDER I FAS 4?" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Vi bygger en AI som kan lasa en forfragran (RFP) och extrahera:"
Write-Host ""
Write-Host "   Exempel pa RFP:"
Write-Host "   'We need a meeting room for 12 people on May 15th. Budget 2000 EUR.'"
Write-Host ""
Write-Host "   AI:n extraherar:"
Write-Host "   Datum: May 15th"
Write-Host "   Antal gaster: 12"
Write-Host "   Budget: 2000 EUR"
Write-Host "   Eventtyp: meeting"
Write-Host ""
Write-Host "[OK] Detta gor att vi automatiskt kan forsta vad kunden vill ha!"
Write-Host ""

Read-Host "Tryck ENTER for att fortsatta"

# Steg 2: Kontrollera GROQ_API_KEY
Write-Host ""
Write-Host "[2/6] Kontrollerar GROQ_API_KEY..." -ForegroundColor Yellow

$envFile = ".env.local"
$groqKey = ""
if (Test-Path $envFile) {
    $envContent = Get-Content $envFile -Raw
    if ($envContent -match 'GROQ_API_KEY=(.+)') {
        $groqKey = $matches[1].Trim()
        Write-Host "[OK] GROQ_API_KEY finns i .env.local" -ForegroundColor Green
    }
}

if (-not $groqKey) {
    Write-Host ""
    Write-Host "[FEL] GROQ_API_KEY saknas!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Sa har du far en GRATIS API-nyckel:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "   1. Oppna webblasaren och ga till: https://console.groq.com" -ForegroundColor White
    Write-Host "   2. Klicka pa 'Sign up' (registrera dig gratis)" -ForegroundColor White
    Write-Host "   3. Valj 'Continue with Google' eller anvand e-post" -ForegroundColor White
    Write-Host "   4. Efter inloggning, klicka pa 'API Keys' i menyn" -ForegroundColor White
    Write-Host "   5. Klicka pa 'Create API Key'" -ForegroundColor White
    Write-Host "   6. Ge nyckeln ett namn (t.ex. 'proposales-ai')" -ForegroundColor White
    Write-Host "   7. Kopiera nyckeln (borjar med 'gsk_')" -ForegroundColor White
    Write-Host ""
    Write-Host "Klistra in din GROQ_API_KEY nedan:" -ForegroundColor Cyan
    $groqKey = Read-Host "GROQ_API_KEY"
    
    # Spara till .env.local
    if (Test-Path $envFile) {
        Add-Content -Path $envFile -Value "`nGROQ_API_KEY=$groqKey" -Encoding utf8
    } else {
        "GROQ_API_KEY=$groqKey" | Out-File -FilePath $envFile -Encoding utf8
    }
    Write-Host "[OK] GROQ_API_KEY sparad i .env.local" -ForegroundColor Green
}

# Steg 3: Installera Groq SDK
Write-Host ""
Write-Host "[3/6] Installerar Groq SDK..." -ForegroundColor Yellow
npm install groq-sdk
Write-Host "[OK] Groq SDK installerat!" -ForegroundColor Green

# Steg 4: Skapa API route for extract
Write-Host ""
Write-Host "[4/6] Skapar API route for RFP-extraction..." -ForegroundColor Yellow

New-Item -ItemType Directory -Force -Path "app/api/extract" | Out-Null

$extractContent = @'
import { NextRequest, NextResponse } from 'next/server';
import Groq from 'groq-sdk';

const groq = new Groq({
  apiKey: process.env.GROQ_API_KEY || '',
});

export async function POST(request: NextRequest) {
  try {
    const { rfpText } = await request.json();

    if (!rfpText) {
      return NextResponse.json({ error: "RFP text is required" }, { status: 400 });
    }

    const prompt = `
Du ar en assistent som extraherar information fran forfragningar (RFP) for event.

Extrahera foljande fran texten:
1. dates: datum for eventet (skriv som "start - slut" eller "ett datum")
2. guestCount: antal gaster (siffra)
3. eventType: typ av event (meeting, conference, wedding, etc.)
4. budgetRange: min och max budget (om angivet)
5. specialRequests: lista med specialkrav (t.ex. lunch, projektor, WiFi)

Returnera ENDAST JSON i detta format:
{
  "dates": "strang eller null",
  "guestCount": siffra eller null,
  "eventType": "strang",
  "budgetRange": { "min": siffra, "max": siffra } eller null,
  "specialRequests": ["strang1", "strang2"]
}

RFP Text:
${rfpText}
`;

    const completion = await groq.chat.completions.create({
      messages: [{ role: "user", content: prompt }],
      model: "llama-3.3-70b-versatile",
      temperature: 0.1,
    });

    const responseText = completion.choices[0]?.message?.content || "{}";
    let cleanJson = responseText.replace(/```json\n?/g, '').replace(/```\n?/g, '');
    let result;
    try {
      result = JSON.parse(cleanJson);
    } catch {
      const jsonMatch = cleanJson.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        result = JSON.parse(jsonMatch[0]);
      } else {
        throw new Error("Kunde inte tolka JSON");
      }
    }

    return NextResponse.json(result);
  } catch (error) {
    console.error("Extract error:", error);
    return NextResponse.json({ error: "Extraction failed" }, { status: 500 });
  }
}
'@

$extractContent | Out-File -FilePath "app/api/extract/route.ts" -Encoding utf8
Write-Host "  [OK] app/api/extract/route.ts skapad" -ForegroundColor Green

# Steg 5: Forklara hur man testar
Write-Host ""
Write-Host "[5/6] TESTNING - Sa har testar du RFP-extractorn" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Steg for att testa:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Starta om servern (i Terminal 2):" -ForegroundColor White
Write-Host "    npm run dev" -ForegroundColor Gray
Write-Host ""
Write-Host "2. I Terminal 1, kor detta kommando:" -ForegroundColor White
Write-Host '    $body = @{ rfpText = "We need a meeting room for 12 people on May 15th. Budget 2000 EUR." } | ConvertTo-Json' -ForegroundColor Gray
Write-Host '    Invoke-RestMethod -Uri "http://localhost:3000/api/extract" -Method POST -Body $body -ContentType "application/json"' -ForegroundColor Gray
Write-Host ""
Write-Host "3. Forvantat svar:" -ForegroundColor White
Write-Host '    { "dates": "May 15th", "guestCount": 12, "eventType": "meeting", "budgetRange": { "min": 2000, "max": 2000 }, "specialRequests": [] }' -ForegroundColor Green
Write-Host ""

Read-Host "Tryck ENTER nar du har last instruktionerna"

# Steg 6: Starta om servern automatiskt (om mojligt)
Write-Host ""
Write-Host "[6/6] Startar om servern..." -ForegroundColor Yellow

# Forsok stoppa befintlig server
Get-Process node -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "[OK] Fas 4 ar KLAR!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Starta servern manuellt i en NY terminal:" -ForegroundColor Yellow
Write-Host "   cd $(Get-Location)" -ForegroundColor White
Write-Host "   npm run dev" -ForegroundColor White
Write-Host ""
Write-Host "I DEN HAR terminalen, testa RFP-extractorn:" -ForegroundColor Yellow
Write-Host '   $body = @{ rfpText = "We need a meeting room for 12 people on May 15th. Budget 2000 EUR." } | ConvertTo-Json' -ForegroundColor White
Write-Host '   Invoke-RestMethod -Uri "http://localhost:3000/api/extract" -Method POST -Body $body -ContentType "application/json"' -ForegroundColor White
Write-Host ""
Write-Host "Forvantat svar:" -ForegroundColor Green
Write-Host '   { "dates": "May 15th", "guestCount": 12, "eventType": "meeting", "budgetRange": { "min": 2000, "max": 2000 }, "specialRequests": [] }' -ForegroundColor White
Write-Host ""
Write-Host "Nasta steg: Fas 5 - Bygg Planeringsagenten" -ForegroundColor Cyan