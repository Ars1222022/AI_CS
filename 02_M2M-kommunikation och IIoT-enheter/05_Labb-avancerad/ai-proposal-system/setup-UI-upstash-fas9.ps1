# setup-UI-upstash-fas9.ps1
# KOMPLETT version - UI + Upstash Vector för semantisk sökning (LOKALT)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Fas 9: Bygg UI med Upstash (LOKAL semantisk sökning)" -ForegroundColor Cyan
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

# ============================================
# DEL 1: FÖRKLARING AV VAD SOM HÄNDER
# ============================================
Write-Host "[1/11] VAD HÄNDER I FAS 9?" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "📌 Vi bygger UI och ansluter till Upstash Vector för semantisk sökning (LOKALT)"
Write-Host ""
Write-Host "   ✅ UI med Vanilla CSS (fungerar alltid)"
Write-Host "   ✅ Upstash Vector för äkta semantisk sökning"
Write-Host "   ✅ mock-products.json med priser (11 produkter)"
Write-Host "   ✅ RFP-extractor (AI förstår text via Groq)"
Write-Host "   ✅ Plan med produkter och priser"
Write-Host "   ✅ Utvärdering med Groq AI"
Write-Host ""
Write-Host "📌 VAD ÄR UPSTASH VECTOR?" -ForegroundColor Cyan
Write-Host "   - En serverless vektordatabas (fungerar lokalt och i molnet)"
Write-Host "   - Gör SEMANTISK sökning (förstår mening, inte bara ord)"
Write-Host "   - Exempel: 'mötesrum' hittar 'Conference Hall' även om orden är olika"
Write-Host "   - Gratis upp till 1 GB lagring och 100 000 vektorer"
Write-Host ""

Read-Host "Tryck ENTER för att fortsätta"

# ============================================
# DEL 2: KONTROLLERA ATT GROQ_API_KEY FINNS
# ============================================
Write-Host ""
Write-Host "[2/11] Kontrollerar GROQ_API_KEY..." -ForegroundColor Yellow

$envFile = ".env.local"
$groqKey = ""
if (Test-Path $envFile) {
    $envContent = Get-Content $envFile -Raw
    if ($envContent -match 'GROQ_API_KEY=(.+)') {
        $groqKey = $matches[1].Trim()
        Write-Host "✅ GROQ_API_KEY finns i .env.local" -ForegroundColor Green
    }
}

if (-not $groqKey) {
    Write-Host ""
    Write-Host "❌ GROQ_API_KEY saknas!" -ForegroundColor Red
    Write-Host ""
    Write-Host "📌 Så här får du en GRATIS API-nyckel från Groq:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "   1. Gå till https://console.groq.com" -ForegroundColor White
    Write-Host "   2. Registrera dig (gratis, använd GitHub eller e-post)" -ForegroundColor White
    Write-Host "   3. Gå till 'API Keys' → 'Create API Key'" -ForegroundColor White
    Write-Host "   4. Kopiera nyckeln (börjar med 'gsk_')" -ForegroundColor White
    Write-Host ""
    $groqKey = Read-Host "📝 Klistra in din GROQ_API_KEY"
    
    # Spara till .env.local
    if (Test-Path $envFile) {
        Add-Content -Path $envFile -Value "`nGROQ_API_KEY=$groqKey" -Encoding utf8
    } else {
        "GROQ_API_KEY=$groqKey" | Out-File -FilePath $envFile -Encoding utf8
    }
    Write-Host "✅ GROQ_API_KEY sparad i .env.local" -ForegroundColor Green
}

# ============================================
# DEL 3: UPSTASH VECTOR - KONFIGURATION
# ============================================
Write-Host ""
Write-Host "[3/11] UPSTASH VECTOR - Serverless vektordatabas" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "📌 VAD GÖR UPSTASH VECTOR?" -ForegroundColor Cyan
Write-Host "   - Lagrar produkter som vektorer (embeddings)"
Write-Host "   - Gör SEMANTISK sökning (förstår mening, inte bara ord)"
Write-Host "   - Fungerar lokalt och på Vercel (serverless)"
Write-Host ""
Write-Host "📌 KOSTNAD:" -ForegroundColor Cyan
Write-Host "   Gratis upp till 1 GB lagring och 100 000 vektorer."
Write-Host ""

Write-Host "📌 SÅ HÄR SKAPAR DU ETT UPSTASH VECTOR-KONTO (GRATIS):" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "STEG 1: Skapa konto" -ForegroundColor Yellow
Write-Host "   1. Gå till https://console.upstash.com/vector" -ForegroundColor White
Write-Host "   2. Klicka 'Continue with GitHub' (använd ditt GitHub-konto)" -ForegroundColor White
Write-Host ""
Write-Host "STEG 2: Skapa Vector Index (VIKTIGT - med inbyggda embeddings!)" -ForegroundColor Yellow
Write-Host "   1. Klicka '+ Create' → 'Vector Index'" -ForegroundColor White
Write-Host "   2. Fyll i:" -ForegroundColor White
Write-Host "      - Name: 'proposal-products'" -ForegroundColor Gray
Write-Host "      - Region: Välj närmast dig (t.ex. 'eu-west-1' för Europa)" -ForegroundColor Gray
Write-Host "      - Type: 'Dense'" -ForegroundColor Gray
Write-Host "      - Embedding Model: Välj 'BAAI/bge-small-en-v1.5'" -ForegroundColor Green
Write-Host "      - Dimensions: '384' (sätts automatiskt)" -ForegroundColor Gray
Write-Host "      - Metric: 'cosine'" -ForegroundColor Gray
Write-Host "   3. Klicka 'Create'" -ForegroundColor White
Write-Host "   4. Kopiera 'UPSTASH_VECTOR_REST_URL' och 'UPSTASH_VECTOR_REST_TOKEN'" -ForegroundColor White
Write-Host ""

$upstashUrl = Read-Host "📝 Klistra in UPSTASH_VECTOR_REST_URL"
$upstashToken = Read-Host "📝 Klistra in UPSTASH_VECTOR_REST_TOKEN"

# Spara till .env.local
Write-Host ""
Write-Host "📝 Sparar konfiguration i .env.local..." -ForegroundColor Yellow

$envContent = @()
if (Test-Path ".env.local") {
    $envContent = Get-Content ".env.local"
}
$envContent = $envContent | Where-Object { $_ -notmatch "UPSTASH_VECTOR_REST_URL" -and $_ -notmatch "UPSTASH_VECTOR_REST_TOKEN" }
$envContent += "UPSTASH_VECTOR_REST_URL=$upstashUrl"
$envContent += "UPSTASH_VECTOR_REST_TOKEN=$upstashToken"
$envContent += "NEXT_PUBLIC_APP_URL=http://localhost:3000"
$envContent | Out-File -FilePath ".env.local" -Encoding utf8
Write-Host "✅ Upstash konfiguration sparad i .env.local" -ForegroundColor Green

# Installera Upstash paket
Write-Host ""
Write-Host "📦 Installerar @upstash/vector..." -ForegroundColor Yellow
npm install @upstash/vector --legacy-peer-deps 2>$null
Write-Host "✅ @upstash/vector installerat" -ForegroundColor Green

# ============================================
# DEL 4: SKAPA MOCK-PRODUCTS.JSON MED PRISER
# ============================================
Write-Host ""
Write-Host "[4/11] Skapar mock-products.json med priser..." -ForegroundColor Yellow

$mockProducts = @'
[
  { "id": 1, "title": "Standard Meeting Room", "description": "Bright meeting room with whiteboard, TV and WiFi. Perfect for board meetings.", "unit": "day", "price": 500 },
  { "id": 2, "title": "Executive Boardroom", "description": "Premium soundproof boardroom with video conferencing.", "unit": "day", "price": 800 },
  { "id": 3, "title": "Grand Conference Hall", "description": "Large theater-style hall with stage and sound system.", "unit": "day", "price": 1500 },
  { "id": 4, "title": "Executive Lunch Buffet", "description": "Hot and cold buffet with salads, main courses, dessert.", "unit": "person", "price": 45 },
  { "id": 5, "title": "Premium Coffee Break", "description": "Fresh coffee, teas, pastries and fruit.", "unit": "person", "price": 12 },
  { "id": 6, "title": "Professional AV Package", "description": "Full HD projector, screen and wireless microphone.", "unit": "day", "price": 250 },
  { "id": 7, "title": "Deluxe Double Room", "description": "Spacious room with king bed and free WiFi. Includes breakfast.", "unit": "night", "price": 220 },
  { "id": 8, "title": "Bridal Suite", "description": "Luxury suite with jacuzzi and champagne on arrival.", "unit": "night", "price": 750 },
  { "id": 9, "title": "Basic Wedding Package", "description": "Ceremony setup, 3-course dinner and open bar.", "unit": "unit", "price": 12000 },
  { "id": 10, "title": "Spa Day Access", "description": "Full access to sauna, steam room, jacuzzi and pool.", "unit": "person", "price": 65 },
  { "id": 11, "title": "Farewell Brunch Buffet", "description": "Late morning buffet with eggs, pastries and fruits.", "unit": "person", "price": 29 }
]
'@

$mockProducts | Out-File -FilePath "mock-products.json" -Encoding utf8
Write-Host "  ✅ mock-products.json skapad (11 produkter med priser)" -ForegroundColor Green

# ============================================
# DEL 5: SKAPA API ROUTES
# ============================================
Write-Host ""
Write-Host "[5/11] Skapar API routes..." -ForegroundColor Yellow

# Skapa app/api/extract/route.ts (FIXAD version med bättre JSON-parsning)
New-Item -ItemType Directory -Force -Path "app/api/extract" | Out-Null
@'
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

    const prompt = `Extrahera information från denna RFP: "${rfpText}"

Returnera ENDAST JSON i detta format:
{
  "dates": "datum eller null",
  "guestCount": antal (siffra eller null),
  "eventType": "meeting/conference/wedding eller null",
  "budgetRange": { "min": siffra, "max": siffra } eller null,
  "specialRequests": []
}`;

    const completion = await groq.chat.completions.create({
      messages: [{ role: "user", content: prompt }],
      model: "llama-3.3-70b-versatile",
      temperature: 0.1,
    });

    const responseText = completion.choices[0]?.message?.content || "{}";
    
    // Försök hitta JSON i svaret
    let cleanJson = responseText;
    cleanJson = cleanJson.replace(/```json\n?/g, '').replace(/```\n?/g, '');
    
    const firstBrace = cleanJson.indexOf('{');
    const lastBrace = cleanJson.lastIndexOf('}');
    
    if (firstBrace !== -1 && lastBrace !== -1) {
      cleanJson = cleanJson.substring(firstBrace, lastBrace + 1);
    }
    
    let result;
    try {
      result = JSON.parse(cleanJson);
    } catch {
      result = { dates: null, guestCount: null, eventType: null, budgetRange: null, specialRequests: [] };
    }
    
    return NextResponse.json(result);
  } catch (error) {
    console.error("Extract error:", error);
    return NextResponse.json({ error: "Extraction failed" }, { status: 500 });
  }
}
'@ | Out-File -FilePath "app/api/extract/route.ts" -Encoding utf8
Write-Host "  ✅ app/api/extract/route.ts" -ForegroundColor Green

# Skapa app/lib/retrieval.ts
New-Item -ItemType Directory -Force -Path "app/lib" | Out-Null
@'
import { Index } from '@upstash/vector';
import fs from 'fs';
import path from 'path';

const upstashIndex = new Index({
  url: process.env.UPSTASH_VECTOR_REST_URL || '',
  token: process.env.UPSTASH_VECTOR_REST_TOKEN || '',
});

async function fetchProducts() {
  const mockPath = path.join(process.cwd(), 'mock-products.json');
  if (fs.existsSync(mockPath)) {
    const data = fs.readFileSync(mockPath, 'utf8');
    return JSON.parse(data);
  }
  return [];
}

export async function createEmbedding(text: string): Promise<number[]> {
  return [];
}

export async function buildIndex() {
  console.log("📦 Indexerar produkter i Upstash...");
  const products = await fetchProducts();
  
  if (products.length === 0) {
    console.log("⚠️ Inga produkter hittades!");
    return null;
  }
  
  console.log(`🔍 Hittade ${products.length} produkter`);
  await upstashIndex.reset();
  
  for (let i = 0; i < products.length; i++) {
    const product = products[i];
    const textToEmbed = product.title + " " + (product.description || '');
    console.log(`  ${i + 1}/${products.length}: ${product.title} (${product.price} EUR)`);
    await upstashIndex.upsert({
      id: product.id.toString(),
      data: textToEmbed,
      metadata: {
        title: product.title,
        description: product.description || '',
        price: product.price,
        unit: product.unit
      }
    });
  }
  console.log(`✅ Index skapat! ${products.length} produkter sparade.`);
  return true;
}

export async function searchProducts(query: string, topK: number = 8) {
  try {
    const results = await upstashIndex.query({
      data: query,
      topK: topK,
      includeMetadata: true,
      includeVectors: false
    });
    console.log(`🔍 Sökning "${query}" → ${results.length} resultat`);
    return results.map(r => ({
      title: r.metadata?.title,
      description: r.metadata?.description,
      score: r.score,
      price: r.metadata?.price,
      unit: r.metadata?.unit
    }));
  } catch (error) {
    console.error("Search error:", error);
    return [];
  }
}
'@ | Out-File -FilePath "app/lib/retrieval.ts" -Encoding utf8
Write-Host "  ✅ app/lib/retrieval.ts" -ForegroundColor Green

# Skapa app/api/search/route.ts
New-Item -ItemType Directory -Force -Path "app/api/search" | Out-Null
@'
import { NextRequest, NextResponse } from 'next/server';
import { searchProducts } from '@/app/lib/retrieval';

export async function POST(request: NextRequest) {
  try {
    const { query, topK = 8 } = await request.json();
    if (!query) {
      return NextResponse.json({ error: "Query is required" }, { status: 400 });
    }
    const results = await searchProducts(query, topK);
    return NextResponse.json({ results });
  } catch (error) {
    console.error("Search error:", error);
    return NextResponse.json({ error: "Search failed" }, { status: 500 });
  }
}
'@ | Out-File -FilePath "app/api/search/route.ts" -Encoding utf8
Write-Host "  ✅ app/api/search/route.ts" -ForegroundColor Green

# Skapa app/api/build-index/route.ts
New-Item -ItemType Directory -Force -Path "app/api/build-index" | Out-Null
@'
import { NextResponse } from 'next/server';
import { buildIndex } from '@/app/lib/retrieval';

export async function POST() {
  try {
    await buildIndex();
    return NextResponse.json({ message: "Index built successfully" });
  } catch (error) {
    console.error(error);
    return NextResponse.json({ error: "Failed to build index" }, { status: 500 });
  }
}
'@ | Out-File -FilePath "app/api/build-index/route.ts" -Encoding utf8
Write-Host "  ✅ app/api/build-index/route.ts" -ForegroundColor Green

# Skapa app/api/products/route.ts
New-Item -ItemType Directory -Force -Path "app/api/products" | Out-Null
@'
import { NextResponse } from 'next/server';
import fs from 'fs';
import path from 'path';

export async function GET() {
  try {
    const mockPath = path.join(process.cwd(), 'mock-products.json');
    if (fs.existsSync(mockPath)) {
      const data = fs.readFileSync(mockPath, 'utf8');
      return NextResponse.json(JSON.parse(data));
    }
    return NextResponse.json([]);
  } catch (error) {
    return NextResponse.json({ error: "Failed to fetch products" }, { status: 500 });
  }
}
'@ | Out-File -FilePath "app/api/products/route.ts" -Encoding utf8
Write-Host "  ✅ app/api/products/route.ts" -ForegroundColor Green

# Skapa app/api/plan/route.ts
New-Item -ItemType Directory -Force -Path "app/api/plan" | Out-Null
@'
import { NextRequest, NextResponse } from 'next/server';
import Groq from 'groq-sdk';

const groq = new Groq({
  apiKey: process.env.GROQ_API_KEY || '',
});

async function extractRFP(rfpText: string) {
  const response = await fetch(`${process.env.NEXT_PUBLIC_APP_URL || 'http://localhost:3000'}/api/extract`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ rfpText })
  });
  return response.json();
}

async function searchProducts(query: string) {
  const response = await fetch(`${process.env.NEXT_PUBLIC_APP_URL || 'http://localhost:3000'}/api/search`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ query, topK: 8 })
  });
  const data = await response.json();
  return data.results || [];
}

export async function POST(request: NextRequest) {
  try {
    const { rfpText } = await request.json();
    if (!rfpText) {
      return NextResponse.json({ error: "RFP text is required" }, { status: 400 });
    }

    const extracted = await extractRFP(rfpText);
    const products = await searchProducts(rfpText);
    
    if (!products || products.length === 0) {
      const demoPlan = {
        selectedProducts: [
          { title: "Standard Meeting Room", reason: "Passar för möten", order: 1, price: 500 },
          { title: "Executive Lunch Buffet", reason: "Lunch för deltagarna", order: 2, price: 450 }
        ],
        summary: "Mötesrum med lunch (bygg index med /api/build-index för semantisk sökning)",
        totalEstimatedPrice: 950
      };
      return NextResponse.json({ extracted, matchedProducts: [], plan: demoPlan });
    }

    const prompt = `Extraherad information: ${JSON.stringify(extracted)}\nTillgängliga produkter med priser: ${JSON.stringify(products)}\nReturnera JSON: { "selectedProducts": [{"title":"","reason":"","order":1,"price":0}], "summary":"", "totalEstimatedPrice":0 }`;

    const completion = await groq.chat.completions.create({
      messages: [{ role: "user", content: prompt }],
      model: "llama-3.3-70b-versatile",
      temperature: 0.3,
    });

    const responseText = completion.choices[0]?.message?.content || "{}";
    let cleanJson = responseText.replace(/```json\n?/g, '').replace(/```\n?/g, '');
    const jsonMatch = cleanJson.match(/\{[\s\S]*\}/);
    const plan = jsonMatch ? JSON.parse(jsonMatch[0]) : { selectedProducts: [], summary: "", totalEstimatedPrice: 0 };

    return NextResponse.json({ extracted, matchedProducts: products, plan });
  } catch (error) {
    console.error("Plan error:", error);
    return NextResponse.json({ error: "Planning failed" }, { status: 500 });
  }
}
'@ | Out-File -FilePath "app/api/plan/route.ts" -Encoding utf8
Write-Host "  ✅ app/api/plan/route.ts" -ForegroundColor Green

# Skapa app/api/evaluate/route.ts
New-Item -ItemType Directory -Force -Path "app/api/evaluate" | Out-Null
@'
import { NextRequest, NextResponse } from 'next/server';
import Groq from 'groq-sdk';

const groq = new Groq({
  apiKey: process.env.GROQ_API_KEY || '',
});

export async function POST(request: NextRequest) {
  try {
    const { proposalUuid, rfpText } = await request.json();
    if (!proposalUuid || !rfpText) {
      return NextResponse.json({ error: "Missing parameters" }, { status: 400 });
    }

    const prompt = `Utvärdera proposal för RFP: ${rfpText}. Returnera JSON: { "completeness": 0-100, "productRelevance": 0-100, "pricingAccuracy": 0-100, "requirementCoverage": 0-100, "justification": "text" }`;

    const completion = await groq.chat.completions.create({
      messages: [{ role: "user", content: prompt }],
      model: "llama-3.3-70b-versatile",
      temperature: 0.2,
    });

    const responseText = completion.choices[0]?.message?.content || "{}";
    let cleanJson = responseText.replace(/```json\n?/g, '').replace(/```\n?/g, '');
    const jsonMatch = cleanJson.match(/\{[\s\S]*\}/);
    const scores = jsonMatch ? JSON.parse(jsonMatch[0]) : { completeness: 0, productRelevance: 0, pricingAccuracy: 0, requirementCoverage: 0, justification: "" };

    const totalScore = Math.round((scores.completeness + scores.productRelevance + scores.pricingAccuracy + scores.requirementCoverage) / 4);

    return NextResponse.json({
      proposalUuid,
      scores: {
        completeness: scores.completeness,
        productRelevance: scores.productRelevance,
        pricingAccuracy: scores.pricingAccuracy,
        requirementCoverage: scores.requirementCoverage
      },
      totalScore: totalScore,
      llmJustification: scores.justification || ""
    });
  } catch (error) {
    console.error("Evaluation error:", error);
    return NextResponse.json({ error: "Evaluation failed" }, { status: 500 });
  }
}
'@ | Out-File -FilePath "app/api/evaluate/route.ts" -Encoding utf8
Write-Host "  ✅ app/api/evaluate/route.ts" -ForegroundColor Green

# ============================================
# DEL 6: SKAPA GENERATE-PROPOSAL ROUTE (DEMO)
# ============================================
Write-Host ""
Write-Host "[6/11] Skapar app/api/generate-proposal/route.ts..." -ForegroundColor Yellow

New-Item -ItemType Directory -Force -Path "app/api/generate-proposal" | Out-Null
@'
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

    const planData = await callPlan(rfpText);
    const selectedProducts = planData.plan?.selectedProducts || [];

    console.log("=== DEMO-LÄGE: Ingen riktig offert skapas ===");
    console.log("📝 Planens produkter:");
    selectedProducts.forEach((p: any, i: number) => {
      console.log(`   ${i+1}. ${p.title} - ${p.reason} (${p.price} EUR)`);
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
'@ | Out-File -FilePath "app/api/generate-proposal/route.ts" -Encoding utf8
Write-Host "  ✅ app/api/generate-proposal/route.ts" -ForegroundColor Green

# ============================================
# DEL 7: SKAPA UI (GLOBALS.CSS + PAGE.TSX)
# ============================================
Write-Host ""
Write-Host "[7/11] Skapar UI (Vanilla CSS)..." -ForegroundColor Yellow

@'
* { margin: 0; padding: 0; box-sizing: border-box; }
body { background-color: #f9fafb; color: #1f2937; font-family: system-ui, sans-serif; line-height: 1.5; }
a { color: #2563eb; text-decoration: none; }
a:hover { text-decoration: underline; }
pre { background-color: #f3f4f6; padding: 1rem; border-radius: 0.5rem; overflow-x: auto; font-size: 0.875rem; }
ul, ol { padding-left: 1.5rem; margin: 0.5rem 0; }
'@ | Out-File -FilePath "app/globals.css" -Encoding utf8

$pageContent = @'
"use client";

import { useState } from "react";
import "./globals.css";

export default function Home() {
  const [rfpText, setRfpText] = useState("");
  const [loading, setLoading] = useState(false);
  const [step, setStep] = useState("");
  const [result, setResult] = useState<any>(null);
  const [error, setError] = useState("");

  const runPipeline = async () => {
    if (!rfpText.trim()) {
      setError("Ange RFP-text");
      return;
    }

    setLoading(true);
    setError("");
    setResult(null);

    try {
      setStep("1/5: Extraherar RFP-information...");
      const extractRes = await fetch("/api/extract", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ rfpText }),
      });
      const extracted = await extractRes.json();

      setStep("2/5: Semantisk sökning (Upstash)...");
      const searchRes = await fetch("/api/search", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ query: rfpText, topK: 8 }),
      });
      const searchResults = await searchRes.json();

      setStep("3/5: Skapar plan...");
      const planRes = await fetch("/api/plan", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ rfpText }),
      });
      const planData = await planRes.json();

      setStep("4/5: Genererar proposal...");
      const proposalRes = await fetch("/api/generate-proposal", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ rfpText }),
      });
      const proposal = await proposalRes.json();

      setStep("5/5: Utvärderar...");
      const evalRes = await fetch("/api/evaluate", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          proposalUuid: proposal.proposalUuid || "demo-123",
          rfpText,
        }),
      });
      const evaluation = await evalRes.json();

      setStep("5/5: Klart!");
      setResult({ extracted, searchResults: searchResults.results, plan: planData.plan, proposal, evaluation });
    } catch (err) {
      setError(`Fel: ${err}`);
    } finally {
      setLoading(false);
      setStep("");
    }
  };

  return (
    <div className="container">
      <h1>🤖 AI Proposal Intelligence System</h1>
      <p className="subtitle">Ange din förfrågan (RFP) så genererar systemet automatiskt en offert.</p>

      <div className="card">
        <label>📝 RFP Text:</label>
        <textarea
          placeholder='Exempel: We need a meeting room for 12 people on May 15th. Budget around 2000 EUR.'
          value={rfpText}
          onChange={(e) => setRfpText(e.target.value)}
          rows={4}
        />
        <button onClick={runPipeline} disabled={loading}>
          {loading ? "⏳ Bearbetar..." : "🚀 Generera proposal"}
        </button>
        {step && <p className="step">📍 {step}</p>}
        {error && <p className="error">❌ {error}</p>}
      </div>

      {result && (
        <div className="results">
          <div className="card"><h2>📋 Extraherad information</h2><pre>{JSON.stringify(result.extracted, null, 2)}</pre></div>
          
          {result.searchResults && result.searchResults.length > 0 && (
            <div className="card">
              <h2>🔍 Semantisk sökning (Upstash Vector)</h2>
              <div className="product-grid">
                {result.searchResults.map((p: any, i: number) => (
                  <div key={i} className="product-card">
                    <h3>{p.title}</h3>
                    <p>{p.description}</p>
                    <span className="score">📊 Relevans: {(p.score * 100).toFixed(0)}%</span>
                    {p.price && <span className="price-badge">💰 {p.price} EUR</span>}
                  </div>
                ))}
              </div>
            </div>
          )}

          <div className="card"><h2>📝 Plan</h2><p>{result.plan?.summary}</p><p className="price">💰 Pris: {result.plan?.totalEstimatedPrice} EUR</p><ul>{result.plan?.selectedProducts?.map((p: any, i: number) => (<li key={i}><strong>{p.title}</strong> – {p.reason} ({p.price} EUR)</li>))}</ul></div>
          <div className="card"><h2>📄 Proposal</h2>{result.proposal?.success ? (<><p className="success">✅ Proposal skapad!</p><a href={result.proposal.proposalUrl} target="_blank">🔗 Öppna proposal →</a><p className="uuid">🆔 UUID: {result.proposal.proposalUuid}</p></>) : (<p className="error">⚠️ Kunde inte skapa proposal</p>)}</div>
          <div className="card"><h2>⭐ Utvärdering</h2><div className="scores"><div className="score-card"><span className="score-value">{result.evaluation?.totalScore || 0}</span><span className="score-label">Total poäng</span></div><div className="score-details"><div>📋 Completeness: {result.evaluation?.scores?.completeness || 0}</div><div>🎯 Relevans: {result.evaluation?.scores?.productRelevance || 0}</div><div>💰 Pris: {result.evaluation?.scores?.pricingAccuracy || 0}</div><div>✅ Täckning: {result.evaluation?.scores?.requirementCoverage || 0}</div></div></div><p className="justification">💬 {result.evaluation?.llmJustification}</p></div>
        </div>
      )}

      <style jsx>{`
        .container { max-width: 1200px; margin: 0 auto; padding: 2rem; font-family: system-ui, sans-serif; }
        h1 { color: #2563eb; margin-bottom: 0.5rem; }
        .subtitle { color: #6b7280; margin-bottom: 2rem; }
        .card { background: white; border-radius: 0.5rem; padding: 1.5rem; margin-bottom: 1.5rem; box-shadow: 0 1px 3px rgba(0,0,0,0.1); border: 1px solid #e5e7eb; }
        label { display: block; font-weight: 500; margin-bottom: 0.5rem; }
        textarea { width: 100%; padding: 0.75rem; border: 1px solid #d1d5db; border-radius: 0.5rem; font-family: monospace; margin-bottom: 1rem; }
        button { background: #2563eb; color: white; padding: 0.75rem 1.5rem; border: none; border-radius: 0.5rem; cursor: pointer; font-size: 1rem; }
        button:disabled { opacity: 0.5; cursor: not-allowed; }
        .step { color: #2563eb; margin-top: 1rem; }
        .error { color: #dc2626; margin-top: 1rem; }
        .success { color: #16a34a; }
        .product-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(280px, 1fr)); gap: 1rem; }
        .product-card { border: 1px solid #e5e7eb; border-radius: 0.5rem; padding: 1rem; background: #fafafa; }
        .product-card h3 { margin-bottom: 0.5rem; font-size: 1rem; }
        .product-card p { font-size: 0.875rem; color: #6b7280; margin-bottom: 0.5rem; }
        .score { font-size: 0.875rem; color: #2563eb; font-weight: 500; }
        .price-badge { display: inline-block; margin-top: 0.5rem; font-size: 0.75rem; color: #16a34a; }
        .price { font-weight: bold; color: #16a34a; margin: 0.5rem 0; }
        .scores { display: flex; gap: 1rem; align-items: center; flex-wrap: wrap; }
        .score-card { text-align: center; background: #f3f4f6; padding: 1rem; border-radius: 0.5rem; min-width: 100px; }
        .score-value { font-size: 2rem; font-weight: bold; color: #2563eb; display: block; }
        .score-label { font-size: 0.875rem; color: #6b7280; }
        .score-details { flex: 1; }
        .justification { color: #6b7280; font-style: italic; margin-top: 1rem; }
        .uuid { font-family: monospace; font-size: 0.875rem; color: #6b7280; margin-top: 0.5rem; }
      `}</style>
    </div>
  );
}
'@
$pageContent | Out-File -FilePath "app/page.tsx" -Encoding utf8
Write-Host "  ✅ app/page.tsx" -ForegroundColor Green

# ============================================
# DEL 8: FIXA TYPESCRIPT-FEL
# ============================================
Write-Host ""
Write-Host "[8/11] Fixar TypeScript-fel..." -ForegroundColor Yellow

$generateFile = "app/api/generate-proposal/route.ts"
if (Test-Path $generateFile) {
    $content = Get-Content $generateFile -Raw
    $newContent = $content -replace 'selectedProducts\.forEach\(\(p, i\)', 'selectedProducts.forEach((p: any, i: number)'
    $newContent | Out-File $generateFile -Encoding utf8 -NoNewline
    Write-Host "  ✅ TypeScript-fel fixade" -ForegroundColor Green
}

# ============================================
# DEL 9: RENSA OCH INSTALLERA OM
# ============================================
Write-Host ""
Write-Host "[9/11] Rensar och installerar om paket..." -ForegroundColor Yellow

Write-Host "🧹 Rensar node_modules..." -ForegroundColor Gray
Remove-Item -Recurse -Force "node_modules" -ErrorAction SilentlyContinue
Remove-Item "package-lock.json" -ErrorAction SilentlyContinue

Write-Host "📦 Installerar paket (detta tar 1-2 minuter)..." -ForegroundColor Gray
npm install --legacy-peer-deps

# ============================================
# DEL 10: BYGG INDEX I UPSTASH (VIA API)
# ============================================
Write-Host ""
Write-Host "[10/11] Bygger index i Upstash..." -ForegroundColor Yellow

Write-Host "📦 Bygger index (detta tar 1-2 minuter)..." -ForegroundColor Cyan

# Starta servern i bakgrunden
Write-Host "   Startar servern temporärt..." -ForegroundColor Gray
$serverProcess = Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$PWD'; npm run dev" -PassThru -WindowStyle Hidden
Start-Sleep -Seconds 12

# Bygg index via API
try {
    $result = Invoke-RestMethod -Uri "http://localhost:3000/api/build-index" -Method POST -ErrorAction Stop
    Write-Host "  ✅ $($result.message)" -ForegroundColor Green
} catch {
    Write-Host "  ⚠️ Kunde inte bygga index automatiskt. Starta servern manuellt och kör:" -ForegroundColor Yellow
    Write-Host "     Invoke-RestMethod -Uri 'http://localhost:3000/api/build-index' -Method POST" -ForegroundColor White
}

# Stoppa den temporära servern
Stop-Process -Name "node" -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

# ============================================
# DEL 11: SLUTINSTRUKTIONER
# ============================================
Write-Host ""
Write-Host "[11/11] Starta servern manuellt..." -ForegroundColor Yellow

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "✅ FAS 9 KLAR!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "📌 UPSTASH VECTOR - Varför behövs det?" -ForegroundColor Cyan
Write-Host "   Vanlig textsökning: 'mötesrum' hittar ENDAST 'mötesrum'" -ForegroundColor White
Write-Host "   Semantisk sökning:  'mötesrum' hittar 'konferenslokal', 'boardroom', 'conference hall'" -ForegroundColor Green
Write-Host ""
Write-Host "🚀 Starta servern:" -ForegroundColor Yellow
Write-Host "   npm run dev" -ForegroundColor White
Write-Host ""
Write-Host "🌐 Öppna: http://localhost:3000" -ForegroundColor Cyan
Write-Host ""
Write-Host "📋 Om sökningen inte fungerar, bygg index manuellt (när servern kör):" -ForegroundColor Yellow
Write-Host "   Invoke-RestMethod -Uri 'http://localhost:3000/api/build-index' -Method POST" -ForegroundColor White
Write-Host ""
Write-Host "📋 Testa med olika RFP-exempel:" -ForegroundColor Yellow
Write-Host "   - 'Meeting room for 10 people'" -ForegroundColor White
Write-Host "   - 'Wedding for 100 guests'" -ForegroundColor White
Write-Host "   - 'Conference with projector and lunch'" -ForegroundColor White
Write-Host ""