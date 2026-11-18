# setup-proposal-generator-fas6.ps1
# Bygger proposal-generatorn med stöd för online (Proposales API) eller lokal demo

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Fas 6: Bygg Proposal-generator" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Kontrollera att vi är i rätt mapp
if (-not (Test-Path "package.json")) {
    Write-Host "❌ Kör skriptet i mappen där package.json finns!" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Rätt mapp: $(Get-Location)" -ForegroundColor Green
Write-Host ""

# Steg 1: Fråga om användaren har Proposales API
Write-Host "[1/5] VILL DU ANVÄNDA PROPOSALES API (online)?" -ForegroundColor Yellow
Write-Host "   J = Skapa riktiga offerter online (kräver API-nyckel)" -ForegroundColor White
Write-Host "   N = Demo-läge (visar bara plan, skapar ingen riktig offert)" -ForegroundColor White
Write-Host ""
$useProposales = Read-Host "Använd Proposales API? (J/N)"

# Steg 2: Kontrollera API-nyckel om J valdes
$proposalesKey = ""
$companyId = ""
if ($useProposales -eq "J") {
    $envFile = ".env.local"
    if (Test-Path $envFile) {
        $envContent = Get-Content $envFile -Raw
        if ($envContent -match 'PROPOSALES_API_KEY=(.+)') {
            $proposalesKey = $matches[1].Trim()
            Write-Host "✅ PROPOSALES_API_KEY laddad från .env.local" -ForegroundColor Green
        } else {
            Write-Host "❌ PROPOSALES_API_KEY saknas i .env.local" -ForegroundColor Red
            Write-Host ""
            Write-Host "📌 Lägg till i .env.local eller välj N för demo-läge." -ForegroundColor Yellow
            $useProposales = "N"
        }
        if ($envContent -match 'PROPOSALES_COMPANY_ID=(.+)') {
            $companyId = $matches[1].Trim()
            Write-Host "✅ PROPOSALES_COMPANY_ID laddad från .env.local" -ForegroundColor Green
        } else {
            Write-Host "⚠️ PROPOSALES_COMPANY_ID saknas - använder 5262" -ForegroundColor Yellow
            $companyId = "5262"
        }
    } else {
        Write-Host "❌ .env.local hittades inte!" -ForegroundColor Red
        $useProposales = "N"
    }
}

# Steg 3: Förklara vad som händer
Write-Host ""
Write-Host "[2/5] VAD HÄNDER I FAS 6?" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
if ($useProposales -eq "J") {
    Write-Host "📌 ONLINE-LÄGE: Skapar riktiga offerter i Proposales"
    Write-Host ""
    Write-Host "   1. Hämta planen från Fas 5"
    Write-Host "   2. Hitta produkt-ID för varje produkt"
    Write-Host "   3. Bygg proposal-struktur"
    Write-Host "   4. Anropa Proposales API"
    Write-Host "   5. Få tillbaka en länk till offerten"
    Write-Host ""
    Write-Host "✅ Resultatet är en RIKTIG offert som kunden kan se!"
} else {
    Write-Host "📌 DEMO-LÄGE: Visar planen utan att skapa riktig offert"
    Write-Host ""
    Write-Host "   1. Hämta planen från Fas 5"
    Write-Host "   2. Visa planen i konsolen"
    Write-Host "   3. Ingen API-anrop till Proposales görs"
    Write-Host ""
    Write-Host "✅ Bra för att testa utan Proposales-konto!"
}

Read-Host "Tryck ENTER för att fortsätta"

# Steg 4: Skapa API route
Write-Host ""
Write-Host "[3/5] Skapar API route för proposal-generator..." -ForegroundColor Yellow

New-Item -ItemType Directory -Force -Path "app/api/generate-proposal" | Out-Null

if ($useProposales -eq "J") {
    # ONLINE-LÄGE: Skapar riktiga offerter
    $generateContent = @'
import { NextRequest, NextResponse } from 'next/server';

const PROPOSALES_API_KEY = process.env.PROPOSALES_API_KEY || '';
const COMPANY_ID = parseInt(process.env.PROPOSALES_COMPANY_ID || '5262');

async function callPlan(rfpText: string) {
  const res = await fetch(`${process.env.NEXT_PUBLIC_APP_URL || 'http://localhost:3000'}/api/plan`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ rfpText })
  });
  return res.json();
}

async function getAllProducts() {
  const res = await fetch(`${process.env.NEXT_PUBLIC_APP_URL || 'http://localhost:3000'}/api/products`);
  const data = await res.json();
  return data;
}

export async function POST(request: NextRequest) {
  try {
    const { rfpText } = await request.json();

    if (!rfpText) {
      return NextResponse.json({ error: "RFP text is required" }, { status: 400 });
    }

    console.log("📋 Hämtar plan...");
    const planData = await callPlan(rfpText);
    const selectedProducts = planData.plan?.selectedProducts || [];
    
    const allProducts = await getAllProducts();
    
    const blocks = [];
    for (const product of selectedProducts) {
      const found = allProducts.find((p: any) => p.title === product.title);
      if (found) {
        blocks.push({ content_id: found.id, type: "product-block" });
        console.log(`  ✅ ${product.title} (ID: ${found.id})`);
      } else {
        console.log(`  ❌ Hittade inte: ${product.title}`);
      }
    }

    if (blocks.length === 0) {
      return NextResponse.json({ error: "No valid products found" }, { status: 400 });
    }

    console.log("📝 Skapar proposal i Proposales...");
    
    const proposalBody = {
      company_id: COMPANY_ID,
      language: "en",
      title_md: `Proposal for: ${rfpText.substring(0, 50)}`,
      description_md: `## Event Proposal\n\n${planData.plan?.summary || ""}\n\n**Estimated total:** ${planData.plan?.totalEstimatedPrice || 0} EUR`,
      blocks: blocks,
      recipient: {
        email: "customer@example.com",
        company_name: "Event Customer"
      },
      invoicing_enabled: false
    };

    const proposalResponse = await fetch("https://api.proposales.com/v3/proposals", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${PROPOSALES_API_KEY}`,
        "Content-Type": "application/json"
      },
      body: JSON.stringify(proposalBody)
    });

    if (!proposalResponse.ok) {
      const error = await proposalResponse.text();
      console.error("Proposales error:", error);
      return NextResponse.json({ error: "Failed to create proposal" }, { status: 500 });
    }

    const proposalData = await proposalResponse.json();
    
    return NextResponse.json({
      success: true,
      proposalUrl: proposalData.proposal?.url,
      proposalUuid: proposalData.proposal?.uuid,
      plan: planData.plan,
      blocksUsed: blocks.length
    });

  } catch (error) {
    console.error("Generate error:", error);
    return NextResponse.json({ error: "Failed to generate proposal" }, { status: 500 });
  }
}
'@
    Write-Host "  ✅ ONLINE-läge (skapari riktiga offerter)" -ForegroundColor Green
} else {
    # DEMO-LÄGE: Visar bara planen
    $generateContent = @'
import { NextRequest, NextResponse } from 'next/server';

async function callPlan(rfpText: string) {
  const res = await fetch(`${process.env.NEXT_PUBLIC_APP_URL || 'http://localhost:3000'}/api/plan`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ rfpText })
  });
  return res.json();
}

export async function POST(request: NextRequest) {
  try {
    const { rfpText } = await request.json();

    if (!rfpText) {
      return NextResponse.json({ error: "RFP text is required" }, { status: 400 });
    }

    console.log("📋 Hämtar plan...");
    const planData = await callPlan(rfpText);
    const selectedProducts = planData.plan?.selectedProducts || [];

    console.log("=== DEMO-LÄGE: Ingen riktig offert skapas ===");
    console.log("📝 Planens produkter:");
    selectedProducts.forEach((p, i) => {
      console.log(`   ${i+1}. ${p.title} - ${p.reason}`);
    });
    console.log(`💰 Beräknat pris: ${planData.plan?.totalEstimatedPrice} EUR`);
    console.log(`📝 Sammanfattning: ${planData.plan?.summary}`);

    return NextResponse.json({
      success: true,
      demoMode: true,
      message: "Demo-läge - ingen riktig offert skapades",
      plan: planData.plan,
      blocksUsed: selectedProducts.length
    });

  } catch (error) {
    console.error("Generate error:", error);
    return NextResponse.json({ error: "Failed to generate proposal" }, { status: 500 });
  }
}
'@
    Write-Host "  ✅ DEMO-läge (visar bara planen)" -ForegroundColor Green
}

$generateContent | Out-File -FilePath "app/api/generate-proposal/route.ts" -Encoding utf8
Write-Host "  ✅ app/api/generate-proposal/route.ts skapad" -ForegroundColor Green

# Steg 5: Testinstruktioner
Write-Host ""
Write-Host "[4/5] TESTNING - Så här testar du proposal-generatorn" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "📋 Steg för att testa:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1️⃣  Starta om servern (i Terminal 2):" -ForegroundColor White
Write-Host "    npm run dev" -ForegroundColor Gray
Write-Host ""
Write-Host "2️⃣  I Terminal 1, kör detta kommando:" -ForegroundColor White
Write-Host '    $body = @{ rfpText = "Meeting room for 12 people. Budget 2000 EUR." } | ConvertTo-Json' -ForegroundColor Gray
Write-Host '    Invoke-RestMethod -Uri "http://localhost:3000/api/generate-proposal" -Method POST -Body $body -ContentType "application/json"' -ForegroundColor Gray
Write-Host ""

if ($useProposales -eq "J") {
    Write-Host "3️⃣  Förväntat svar (ONLINE):" -ForegroundColor White
    Write-Host '    { "success": true, "proposalUrl": "https://secure.proposales.com/proposals/...", "proposalUuid": "..." }' -ForegroundColor Green
} else {
    Write-Host "3️⃣  Förväntat svar (DEMO):" -ForegroundColor White
    Write-Host '    { "success": true, "demoMode": true, "message": "Demo-läge - ingen riktig offert skapades", "plan": {...} }' -ForegroundColor Green
}

Read-Host "Tryck ENTER när du har läst instruktionerna"

# Steg 6: Starta om servern
Write-Host ""
Write-Host "[5/5] Startar om servern..." -ForegroundColor Yellow
Get-Process node -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "✅ Fas 6 är KLAR!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "📋 Starta servern i en NY terminal:" -ForegroundColor Yellow
Write-Host "   cd D:\ai-proposal-system\proposales-ai" -ForegroundColor White
Write-Host "   npm run dev" -ForegroundColor White
Write-Host ""
Write-Host "📋 I DEN HÄR terminalen, testa proposal-generatorn:" -ForegroundColor Yellow
Write-Host '   $body = @{ rfpText = "Meeting room for 12 people. Budget 2000 EUR." } | ConvertTo-Json' -ForegroundColor White
Write-Host '   Invoke-RestMethod -Uri "http://localhost:3000/api/generate-proposal" -Method POST -Body $body -ContentType "application/json"' -ForegroundColor White
Write-Host ""
Write-Host "Nästa steg: Fas 7 - Bygg Self-Review" -ForegroundColor Cyan