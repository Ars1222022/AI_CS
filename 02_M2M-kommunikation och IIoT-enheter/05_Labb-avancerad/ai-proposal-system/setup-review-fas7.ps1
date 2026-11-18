# setup-review-fas7.ps1
# Bygger self-review system (fungerar i både online och demo-läge)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Fas 7: Bygg Self-Review" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Kontrollera att vi är i rätt mapp
if (-not (Test-Path "package.json")) {
    Write-Host "❌ Kör skriptet i mappen där package.json finns!" -ForegroundColor Red
    Write-Host ""
    Write-Host "📁 Gå till rätt mapp: cd D:\ai-proposal-system\proposales-ai" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Rätt mapp: $(Get-Location)" -ForegroundColor Green
Write-Host ""

# Steg 1: Förklara vad som händer
Write-Host "[1/5] VAD HÄNDER I FAS 7?" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "📌 Vi bygger ett system som GRANSKAR offerten och FLAGGAR brister:"
Write-Host ""
Write-Host "   ┌─────────────────────────────────────────────────────────┐"
Write-Host "   │  RFP: 'Meeting room for 12 people. Need projector.'     │"
Write-Host "   └─────────────────────────────────────────────────────────┘"
Write-Host "                              ↓"
Write-Host "   ┌─────────────────────────────────────────────────────────┐"
Write-Host "   │  OFFERT: 'Standard Meeting Room + Lunch Buffet'         │"
Write-Host "   │  Pris: 1500 EUR                                         │"
Write-Host "   └─────────────────────────────────────────────────────────┘"
Write-Host "                              ↓"
Write-Host "   ┌─────────────────────────────────────────────────────────┐"
Write-Host "   │  GRANSKNING:                                            │"
Write-Host "   │  ❌ Projektor saknas (HOG allvarlighetsgrad)             │"
Write-Host "   │  ✅ Budget 1500 ≤ 2000                                  │"
Write-Host "   │  ⚠️  Kaffe saknas (MEDEL)                                │"
Write-Host "   │  📊 Kvalitetspoäng: 65/100                              │"
Write-Host "   └─────────────────────────────────────────────────────────┘"
Write-Host ""
Write-Host "✅ Detta hjälper dig att automatiskt kvalitetssäkra offerter!"
Write-Host ""

Read-Host "Tryck ENTER för att fortsätta"

# Steg 2: Fråga om användaren har Proposales API
Write-Host ""
Write-Host "[2/5] VILL DU ANVÄNDA PROPOSALES API (online) FÖR ATT HÄMTA RIktiga OFFERTER?" -ForegroundColor Yellow
Write-Host "   J = Hämta riktiga offerter från Proposales (kräver API-nyckel)" -ForegroundColor White
Write-Host "   N = Demo-läge (simulerar offerter för testning)" -ForegroundColor White
Write-Host ""
$useProposales = Read-Host "Använd Proposales API? (J/N)"

# Steg 3: Kontrollera API-nyckel om J valdes
$proposalesKey = ""
if ($useProposales -eq "J") {
    $envFile = ".env.local"
    if (Test-Path $envFile) {
        $envContent = Get-Content $envFile -Raw
        if ($envContent -match 'PROPOSALES_API_KEY=(.+)') {
            $proposalesKey = $matches[1].Trim()
            Write-Host "✅ PROPOSALES_API_KEY laddad från .env.local" -ForegroundColor Green
        } else {
            Write-Host "❌ PROPOSALES_API_KEY saknas i .env.local" -ForegroundColor Red
            Write-Host "   Använder demo-läge istället..." -ForegroundColor Yellow
            $useProposales = "N"
        }
    } else {
        Write-Host "❌ .env.local hittades inte!" -ForegroundColor Red
        $useProposales = "N"
    }
}

# Steg 4: Skapa API route
Write-Host ""
Write-Host "[3/5] Skapar API route för self-review..." -ForegroundColor Yellow

New-Item -ItemType Directory -Force -Path "app/api/review" | Out-Null

if ($useProposales -eq "J") {
    # ONLINE-LÄGE: Hämtar riktiga offerter från Proposales
    $reviewContent = @'
import { NextRequest, NextResponse } from 'next/server';
import Groq from 'groq-sdk';

const groq = new Groq({
  apiKey: process.env.GROQ_API_KEY || '',
});

const PROPOSALES_API_KEY = process.env.PROPOSALES_API_KEY || '';

async function getProposal(uuid: string) {
  const response = await fetch(`https://api.proposales.com/v3/proposals/${uuid}`, {
    headers: { "Authorization": `Bearer ${PROPOSALES_API_KEY}` }
  });
  const data = await response.json();
  return data.data;
}

async function extractRFP(rfpText: string) {
  const response = await fetch("http://localhost:3000/api/extract", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ rfpText })
  });
  return await response.json();
}

export async function POST(request: NextRequest) {
  try {
    const { proposalUuid, rfpText } = await request.json();

    if (!proposalUuid || !rfpText) {
      return NextResponse.json({ error: "proposalUuid and rfpText are required" }, { status: 400 });
    }

    console.log("📦 Hämtar proposal från Proposales...");
    const proposal = await getProposal(proposalUuid);
    
    console.log("📋 Extraherar RFP-information...");
    const rfpStructure = await extractRFP(rfpText);

    const prompt = `
Du är en kvalitetsgranskare för event-proposals.

**Original RFP:**
${rfpText}

**Extraherad RFP-struktur:**
${JSON.stringify(rfpStructure, null, 2)}

**Skapad proposal:**
Titel: ${proposal.title || 'N/A'}
Beskrivning: ${proposal.description_md || 'N/A'}
Antal blocks: ${proposal.blocks?.length || 0}
Total värde: ${proposal.value_with_tax || 0} EUR

**Uppgift:** Jämför proposal med RFP och flagga brister.

Returnera ENDAST JSON:
{
  "gaps": [
    { "type": "missing_requirement | price_mismatch | missing_product", "description": "...", "severity": "high|medium|low" }
  ],
  "summary": "Kort sammanfattning",
  "overallScore": 75
}
`;

    const completion = await groq.chat.completions.create({
      messages: [{ role: "user", content: prompt }],
      model: "llama-3.3-70b-versatile",
      temperature: 0.2,
    });

    const responseText = completion.choices[0]?.message?.content || "{}";
    let cleanJson = responseText.replace(/```json\n?/g, '').replace(/```\n?/g, '');
    const jsonMatch = cleanJson.match(/\{[\s\S]*\}/);
    const review = jsonMatch ? JSON.parse(jsonMatch[0]) : JSON.parse(cleanJson);

    return NextResponse.json({
      proposalUuid,
      rfpExtracted: rfpStructure,
      review,
      mode: "online"
    });

  } catch (error) {
    console.error("Review error:", error);
    return NextResponse.json({ error: "Review failed" }, { status: 500 });
  }
}
'@
    Write-Host "  ✅ ONLINE-läge (hämtar riktiga offerter)" -ForegroundColor Green
} else {
    # DEMO-LÄGE: Simulerar offerter
    $reviewContent = @'
import { NextRequest, NextResponse } from 'next/server';
import Groq from 'groq-sdk';

const groq = new Groq({
  apiKey: process.env.GROQ_API_KEY || '',
});

async function extractRFP(rfpText: string) {
  const response = await fetch("http://localhost:3000/api/extract", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ rfpText })
  });
  return await response.json();
}

async function getMockProposal() {
  // Simulerad offert för demo
  return {
    title: "Demo Proposal",
    description_md: "This is a demo proposal for testing the review system",
    blocks: [
      { title: "Standard Meeting Room" },
      { title: "Executive Lunch Buffet" }
    ],
    value_with_tax: 1500
  };
}

export async function POST(request: NextRequest) {
  try {
    const { proposalUuid, rfpText } = await request.json();

    if (!proposalUuid || !rfpText) {
      return NextResponse.json({ error: "proposalUuid and rfpText are required" }, { status: 400 });
    }

    console.log("📋 Extraherar RFP-information...");
    const rfpStructure = await extractRFP(rfpText);
    
    console.log("📦 DEMO-LÄGE: Använder simulerad offert");
    const proposal = await getMockProposal();

    const prompt = `
Du är en kvalitetsgranskare för event-proposals.

**Original RFP:**
${rfpText}

**Extraherad RFP-struktur:**
${JSON.stringify(rfpStructure, null, 2)}

**Skapad proposal (DEMO):**
Titel: ${proposal.title}
Beskrivning: ${proposal.description_md}
Antal blocks: ${proposal.blocks.length}
Total värde: ${proposal.value_with_tax} EUR

**Uppgift:** Jämför proposal med RFP och flagga brister.

Returnera ENDAST JSON:
{
  "gaps": [
    { "type": "missing_requirement | price_mismatch | missing_product", "description": "...", "severity": "high|medium|low" }
  ],
  "summary": "Kort sammanfattning",
  "overallScore": 75
}
`;

    const completion = await groq.chat.completions.create({
      messages: [{ role: "user", content: prompt }],
      model: "llama-3.3-70b-versatile",
      temperature: 0.2,
    });

    const responseText = completion.choices[0]?.message?.content || "{}";
    let cleanJson = responseText.replace(/```json\n?/g, '').replace(/```\n?/g, '');
    const jsonMatch = cleanJson.match(/\{[\s\S]*\}/);
    const review = jsonMatch ? JSON.parse(jsonMatch[0]) : JSON.parse(cleanJson);

    return NextResponse.json({
      proposalUuid,
      rfpExtracted: rfpStructure,
      review,
      mode: "demo"
    });

  } catch (error) {
    console.error("Review error:", error);
    return NextResponse.json({ error: "Review failed" }, { status: 500 });
  }
}
'@
    Write-Host "  ✅ DEMO-läge (simulerar offerter för testning)" -ForegroundColor Green
}

$reviewContent | Out-File -FilePath "app/api/review/route.ts" -Encoding utf8
Write-Host "  ✅ app/api/review/route.ts skapad" -ForegroundColor Green

# Steg 5: Testinstruktioner
Write-Host ""
Write-Host "[4/5] TESTNING - Så här testar du self-review" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "📋 Steg för att testa:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1️⃣  Starta om servern (i Terminal 2):" -ForegroundColor White
Write-Host "    npm run dev" -ForegroundColor Gray
Write-Host ""
Write-Host "2️⃣  I Terminal 1, kör detta kommando:" -ForegroundColor White
Write-Host '    $body = @{ proposalUuid = "demo-123"; rfpText = "Meeting room for 12 people. Need projector and lunch. Budget 2000 EUR." } | ConvertTo-Json' -ForegroundColor Gray
Write-Host '    Invoke-RestMethod -Uri "http://localhost:3000/api/review" -Method POST -Body $body -ContentType "application/json"' -ForegroundColor Gray
Write-Host ""
Write-Host "3️⃣  Förväntat svar (DEMO-läge):" -ForegroundColor White
Write-Host '    {' -ForegroundColor Gray
Write-Host '      "proposalUuid": "demo-123",' -ForegroundColor Gray
Write-Host '      "rfpExtracted": { "guestCount": 12, "budgetRange": { "max": 2000 } },' -ForegroundColor Gray
Write-Host '      "review": {' -ForegroundColor Gray
Write-Host '        "gaps": [ { "type": "missing_product", "description": "Projektor saknas", "severity": "high" } ],' -ForegroundColor Gray
Write-Host '        "summary": "Saknar AV-utrustning",' -ForegroundColor Gray
Write-Host '        "overallScore": 65' -ForegroundColor Gray
Write-Host '      },' -ForegroundColor Gray
Write-Host '      "mode": "demo"' -ForegroundColor Gray
Write-Host '    }' -ForegroundColor Gray
Write-Host ""

Read-Host "Tryck ENTER när du har läst instruktionerna"

# Steg 6: Starta om servern
Write-Host ""
Write-Host "[5/5] Startar om servern..." -ForegroundColor Yellow
Get-Process node -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "✅ Fas 7 är KLAR!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "📋 Starta servern i en NY terminal:" -ForegroundColor Yellow
Write-Host "   cd D:\ai-proposal-system\proposales-ai" -ForegroundColor White
Write-Host "   npm run dev" -ForegroundColor White
Write-Host ""
Write-Host "📋 I DEN HÄR terminalen, testa self-review:" -ForegroundColor Yellow
Write-Host '   $body = @{ proposalUuid = "demo-123"; rfpText = "Meeting room for 12 people. Need projector and lunch. Budget 2000 EUR." } | ConvertTo-Json' -ForegroundColor White
Write-Host '   Invoke-RestMethod -Uri "http://localhost:3000/api/review" -Method POST -Body $body -ContentType "application/json"' -ForegroundColor White
Write-Host ""
Write-Host "📊 Vad du ser i svaret:" -ForegroundColor Cyan
Write-Host "   • gaps = lista över vad som saknas eller är fel" -ForegroundColor White
Write-Host "   • overallScore = kvalitetspoäng (0-100)" -ForegroundColor White
Write-Host "   • severity = high/medium/low (hur allvarligt)" -ForegroundColor White
Write-Host ""
Write-Host "Nästa steg: Fas 8 - Bygg Utvärderingssystem" -ForegroundColor Cyan