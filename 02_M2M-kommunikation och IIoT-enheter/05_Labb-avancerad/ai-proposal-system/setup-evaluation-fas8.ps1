# setup-evaluation-fas8.ps1
# Bygger utvärderingssystem för offerter (fungerar i demo-läge)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Fas 8: Bygg Utvärderingssystem" -ForegroundColor Cyan
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
Write-Host "[1/5] VAD HÄNDER I FAS 8?" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "📌 Vi bygger ett system som POÄNGSÄTTER offerten i 4 dimensioner:"
Write-Host ""
Write-Host "   ┌─────────────────────────────────────────────────────────────┐"
Write-Host "   │  DIMENSION          POÄNG   METOD                            │"
Write-Host "   ├─────────────────────────────────────────────────────────────┤"
Write-Host "   │  Completeness       70      AI-utvärdering                   │"
Write-Host "   │  Product Relevance  80      AI-utvärdering                   │"
Write-Host "   │  Pricing Accuracy   100     Heuristik (budget)               │"
Write-Host "   │  Requirement Cov.   75      AI + heuristik (datum, gäster)   │"
Write-Host "   ├─────────────────────────────────────────────────────────────┤"
Write-Host "   │  TOTAL POÄNG: (70+80+100+75)/4 = 81/100                      │"
Write-Host "   └─────────────────────────────────────────────────────────────┘"
Write-Host ""
Write-Host "✅ Detta ger detaljerad feedback på vad som är bra/dåligt!"
Write-Host ""

Read-Host "Tryck ENTER för att fortsätta"

# Steg 2: Fråga om användaren vill använda Proposales API
Write-Host ""
Write-Host "[2/5] VILL DU ANVÄNDA PROPOSALES API (online) FÖR ATT HÄMTA RIKTIGA OFFERTER?" -ForegroundColor Yellow
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
Write-Host "[3/5] Skapar API route för utvärdering..." -ForegroundColor Yellow

New-Item -ItemType Directory -Force -Path "app/api/evaluate" | Out-Null

if ($useProposales -eq "J") {
    # ONLINE-LÄGE: Hämtar riktiga offerter
    $evaluationContent = @'
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

function checkDates(rfpDates: string, proposalText: string): number {
  if (!rfpDates) return 100;
  return proposalText.toLowerCase().includes(rfpDates.toLowerCase()) ? 100 : 0;
}

function checkGuestCount(rfpGuestCount: number, proposalText: string): number {
  if (!rfpGuestCount) return 100;
  return proposalText.includes(rfpGuestCount.toString()) ? 100 : 0;
}

function checkBudget(rfpBudget: any, proposalValue: number): number {
  if (!rfpBudget || !rfpBudget.min) return 100;
  if (proposalValue === 0) return 0;
  if (proposalValue >= rfpBudget.min && proposalValue <= rfpBudget.max) return 100;
  if (proposalValue < rfpBudget.min) return 50;
  return 25;
}

export async function POST(request: NextRequest) {
  try {
    const { proposalUuid, rfpText } = await request.json();

    if (!proposalUuid || !rfpText) {
      return NextResponse.json({ error: "proposalUuid and rfpText are required" }, { status: 400 });
    }

    console.log("📦 Hämtar proposal...");
    const proposal = await getProposal(proposalUuid);
    
    console.log("📋 Extraherar RFP...");
    const rfp = await extractRFP(rfpText);
    
    const proposalText = `${proposal?.title || ''} ${proposal?.description_md || ''}`;
    
    const dateScore = checkDates(rfp.dates, proposalText);
    const guestScore = checkGuestCount(rfp.guestCount, proposalText);
    const budgetScore = checkBudget(rfp.budgetRange, proposal?.value_with_tax || 0);
    
    const prompt = `
Du är en utvärderare av event-proposals.

**RFP:** ${rfpText}

**Proposal:**
Titel: ${proposal.title || 'N/A'}
Beskrivning: ${proposal.description_md || 'N/A'}
Produkter: ${proposal.blocks?.map((b: any) => b.title).join(', ') || 'Inga'}
Total värde: ${proposal.value_with_tax || 0} EUR

Returnera JSON:
{
  "completeness": 0-100,
  "productRelevance": 0-100,
  "requirementCoverage": 0-100,
  "justification": "text"
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
    const llmScores = jsonMatch ? JSON.parse(jsonMatch[0]) : { completeness: 0, productRelevance: 0, requirementCoverage: 0, justification: "" };

    const finalScores = {
      completeness: llmScores.completeness || 0,
      productRelevance: llmScores.productRelevance || 0,
      pricingAccuracy: budgetScore,
      requirementCoverage: Math.round((dateScore + guestScore + (llmScores.requirementCoverage || 0)) / 3)
    };
    
    const totalScore = Math.round(
      (finalScores.completeness + finalScores.productRelevance + finalScores.pricingAccuracy + finalScores.requirementCoverage) / 4
    );

    return NextResponse.json({
      proposalUuid,
      scores: finalScores,
      totalScore,
      heuristics: { dateScore, guestScore, budgetScore },
      llmJustification: llmScores.justification || ""
    });

  } catch (error) {
    console.error("Evaluation error:", error);
    return NextResponse.json({ error: "Evaluation failed" }, { status: 500 });
  }
}
'@
    Write-Host "  ✅ ONLINE-läge (hämtar riktiga offerter)" -ForegroundColor Green
} else {
    # DEMO-LÄGE: Simulerar offerter
    $evaluationContent = @'
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

function checkDates(rfpDates: string, proposalText: string): number {
  if (!rfpDates) return 100;
  return proposalText.toLowerCase().includes(rfpDates.toLowerCase()) ? 100 : 0;
}

function checkGuestCount(rfpGuestCount: number, proposalText: string): number {
  if (!rfpGuestCount) return 100;
  return proposalText.includes(rfpGuestCount.toString()) ? 100 : 0;
}

function checkBudget(rfpBudget: any, proposalValue: number): number {
  if (!rfpBudget || !rfpBudget.min) return 100;
  if (proposalValue === 0) return 0;
  if (proposalValue >= rfpBudget.min && proposalValue <= rfpBudget.max) return 100;
  if (proposalValue < rfpBudget.min) return 50;
  return 25;
}

export async function POST(request: NextRequest) {
  try {
    const { proposalUuid, rfpText } = await request.json();

    if (!proposalUuid || !rfpText) {
      return NextResponse.json({ error: "proposalUuid and rfpText are required" }, { status: 400 });
    }

    console.log("📋 Extraherar RFP...");
    const rfp = await extractRFP(rfpText);
    
    // DEMO-LÄGE: Simulera en proposal
    const mockProposal = {
      title: "Demo Proposal",
      description_md: "This is a demo proposal for testing evaluation",
      blocks: [{ title: "Standard Meeting Room" }, { title: "Executive Lunch Buffet" }],
      value_with_tax: 1500
    };
    
    const proposalText = `${mockProposal.title} ${mockProposal.description_md}`;
    
    const dateScore = checkDates(rfp.dates, proposalText);
    const guestScore = checkGuestCount(rfp.guestCount, proposalText);
    const budgetScore = checkBudget(rfp.budgetRange, mockProposal.value_with_tax);
    
    const prompt = `
Du är en utvärderare av event-proposals.

**RFP:** ${rfpText}

**Proposal (DEMO):**
Titel: ${mockProposal.title}
Beskrivning: ${mockProposal.description_md}
Produkter: ${mockProposal.blocks.map((b: any) => b.title).join(', ')}
Total värde: ${mockProposal.value_with_tax} EUR

Returnera JSON:
{
  "completeness": 0-100,
  "productRelevance": 0-100,
  "requirementCoverage": 0-100,
  "justification": "text"
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
    const llmScores = jsonMatch ? JSON.parse(jsonMatch[0]) : { completeness: 0, productRelevance: 0, requirementCoverage: 0, justification: "" };

    const finalScores = {
      completeness: llmScores.completeness || 0,
      productRelevance: llmScores.productRelevance || 0,
      pricingAccuracy: budgetScore,
      requirementCoverage: Math.round((dateScore + guestScore + (llmScores.requirementCoverage || 0)) / 3)
    };
    
    const totalScore = Math.round(
      (finalScores.completeness + finalScores.productRelevance + finalScores.pricingAccuracy + finalScores.requirementCoverage) / 4
    );

    return NextResponse.json({
      proposalUuid,
      scores: finalScores,
      totalScore,
      heuristics: { dateScore, guestScore, budgetScore },
      llmJustification: llmScores.justification || "",
      mode: "demo"
    });

  } catch (error) {
    console.error("Evaluation error:", error);
    return NextResponse.json({ error: "Evaluation failed" }, { status: 500 });
  }
}
'@
    Write-Host "  ✅ DEMO-läge (simulerar offerter för testning)" -ForegroundColor Green
}

$evaluationContent | Out-File -FilePath "app/api/evaluate/route.ts" -Encoding utf8
Write-Host "  ✅ app/api/evaluate/route.ts skapad" -ForegroundColor Green

# Steg 5: Testinstruktioner
Write-Host ""
Write-Host "[4/5] TESTNING - Så här testar du utvärderingssystemet" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "📋 Steg för att testa:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1️⃣  Starta om servern (i Terminal 2):" -ForegroundColor White
Write-Host "    npm run dev" -ForegroundColor Gray
Write-Host ""
Write-Host "2️⃣  I Terminal 1, kör detta kommando:" -ForegroundColor White
Write-Host '    $body = @{ proposalUuid = "demo-123"; rfpText = "Meeting room for 12 people. Budget 2000 EUR." } | ConvertTo-Json' -ForegroundColor Gray
Write-Host '    Invoke-RestMethod -Uri "http://localhost:3000/api/evaluate" -Method POST -Body $body -ContentType "application/json"' -ForegroundColor Gray
Write-Host ""
Write-Host "3️⃣  Förväntat svar (DEMO-läge):" -ForegroundColor White
Write-Host '    {' -ForegroundColor Gray
Write-Host '      "proposalUuid": "demo-123",' -ForegroundColor Gray
Write-Host '      "scores": { "completeness": 70, "productRelevance": 80, "pricingAccuracy": 100, "requirementCoverage": 75 },' -ForegroundColor Gray
Write-Host '      "totalScore": 81,' -ForegroundColor Gray
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
Write-Host "✅ Fas 8 är KLAR!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "📋 Starta servern i en NY terminal:" -ForegroundColor Yellow
Write-Host "   cd D:\ai-proposal-system\proposales-ai" -ForegroundColor White
Write-Host "   npm run dev" -ForegroundColor White
Write-Host ""
Write-Host "📋 I DEN HÄR terminalen, testa utvärderingssystemet:" -ForegroundColor Yellow
Write-Host '   $body = @{ proposalUuid = "demo-123"; rfpText = "Meeting room for 12 people. Budget 2000 EUR." } | ConvertTo-Json' -ForegroundColor White
Write-Host '   Invoke-RestMethod -Uri "http://localhost:3000/api/evaluate" -Method POST -Body $body -ContentType "application/json"' -ForegroundColor White
Write-Host ""
Write-Host "📊 Vad du ser i svaret:" -ForegroundColor Cyan
Write-Host "   • scores.completeness = hur komplett offerten är (0-100)" -ForegroundColor White
Write-Host "   • scores.productRelevance = hur relevanta produkterna är (0-100)" -ForegroundColor White
Write-Host "   • scores.pricingAccuracy = prissättning (0-100)" -ForegroundColor White
Write-Host "   • scores.requirementCoverage = täckning av krav (0-100)" -ForegroundColor White
Write-Host "   • totalScore = totalpoäng (0-100)" -ForegroundColor White
Write-Host ""
Write-Host "Nästa steg: Fas 9 - Bygg UI och förbered för Vercel" -ForegroundColor Cyan