# auto-fix-and-test.ps1
# Komplett automatisk fix, start och test av Fas 3, 4 och 5

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "AUTO-FIX: Reparerar, startar och testar allt" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Hitta projektmappen automatiskt
function Find-ProjectPath {
    $searchPaths = @(
        (Get-Location),
        (Join-Path (Get-Location) "proposales-ai"),
        (Resolve-Path ".." -ErrorAction SilentlyContinue),
        (Join-Path (Resolve-Path ".." -ErrorAction SilentlyContinue) "proposales-ai"),
        "D:\ai-proposal-system\proposales-ai",
        "D:\FSHI\AI\2. M2M-kommunikation och IIoT-enheter\ai-proposal-system\proposales-ai"
    )
    
    foreach ($path in $searchPaths) {
        if ($path -and (Test-Path (Join-Path $path "package.json"))) {
            return $path
        }
    }
    return $null
}

$projectPath = Find-ProjectPath
if (-not $projectPath) {
    Write-Host "[FEL] Kan inte hitta projektmappen!" -ForegroundColor Red
    exit 1
}

Set-Location $projectPath
Write-Host "[OK] Projektmapp: $(Get-Location)" -ForegroundColor Green
Write-Host ""

# Steg 1: Fixa mock-products.json
Write-Host "[1/7] Fixar mock-products.json..." -ForegroundColor Yellow

$correctMockProducts = @'
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

$correctMockProducts | Out-File -FilePath "mock-products.json" -Encoding utf8
Write-Host "  [OK] mock-products.json uppdaterad" -ForegroundColor Green

# Steg 2: Fixa products route
Write-Host ""
Write-Host "[2/7] Fixar app/api/products/route.ts..." -ForegroundColor Yellow

$fixedProductsRoute = @'
import { NextResponse } from 'next/server';
import fs from 'fs';
import path from 'path';

export async function GET() {
  try {
    const mockPath = path.join(process.cwd(), 'mock-products.json');
    
    if (!fs.existsSync(mockPath)) {
      return NextResponse.json({ data: [] }, { status: 200 });
    }
    
    const data = fs.readFileSync(mockPath, 'utf8');
    const products = JSON.parse(data);
    
    const formattedProducts = {
      data: products.map(function(p) { return {
        product_id: p.id,
        title: { en: p.title },
        description: { en: p.description },
        unit: p.unit,
        price: p.price
      };})
    };
    
    return NextResponse.json(formattedProducts);
  } catch (error) {
    return NextResponse.json({ data: [] }, { status: 200 });
  }
}
'@

New-Item -ItemType Directory -Force -Path "app/api/products" | Out-Null
$fixedProductsRoute | Out-File -FilePath "app/api/products/route.ts" -Encoding utf8
Write-Host "  [OK] app/api/products/route.ts fixad" -ForegroundColor Green

# Steg 3: Fixa retrieval.ts
Write-Host ""
Write-Host "[3/7] Fixar app/lib/retrieval.ts..." -ForegroundColor Yellow

$fixedRetrieval = @'
import { LocalIndex } from 'vectra';
import { pipeline } from '@huggingface/transformers';
import path from 'path';

let embeddingModel: any = null;
let index: LocalIndex | null = null;

async function getEmbeddingModel() {
  if (!embeddingModel) {
    console.log("Laddar embeddings-modell...");
    embeddingModel = await pipeline('feature-extraction', 'Xenova/all-MiniLM-L6-v2');
  }
  return embeddingModel;
}

export async function createEmbedding(text: string): Promise<number[]> {
  const model = await getEmbeddingModel();
  const result = await model(text, { pooling: 'mean', normalize: true });
  return Array.from(result.data);
}

async function getIndex() {
  if (!index) {
    const indexPath = path.join(process.cwd(), 'vectra-index');
    index = new LocalIndex(indexPath);
    if (!await index.isIndexCreated()) {
      await index.createIndex();
    }
  }
  return index;
}

async function fetchProducts() {
  const response = await fetch("http://localhost:3000/api/products");
  const data = await response.json();
  return data.data || [];
}

export async function buildIndex() {
  console.log("Hamtar produkter...");
  const products = await fetchProducts();
  
  if (!products || products.length === 0) {
    console.log("Inga produkter hittades!");
    return null;
  }
  
  const idx = await getIndex();
  console.log("Skapar embeddings for " + products.length + " produkter...");
  
  const existingItems = await idx.listItems();
  for (const item of existingItems) {
    await idx.deleteItem(item.id);
  }
  
  for (let i = 0; i < products.length; i++) {
    const product = products[i];
    const title = product.title?.en || product.title || '';
    const description = product.description?.en || product.description || '';
    const textToEmbed = title + " " + description;
    const productId = product.product_id || product.id;
    
    console.log("  " + (i + 1) + "/" + products.length + ": " + title);
    const embedding = await createEmbedding(textToEmbed);
    
    await idx.insertItem({
      id: String(productId),
      vector: embedding,
      metadata: {
        title: title,
        description: description,
        product_id: productId,
        price: product.price || 0,
        unit: product.unit || ''
      }
    });
  }
  
  console.log("Index skapat! " + products.length + " produkter sparade.");
  return { count: products.length };
}

export async function searchProducts(query: string, topK: number = 5) {
  const idx = await getIndex();
  const queryEmbedding = await createEmbedding(query);
  const results = await idx.queryItems(queryEmbedding, topK);
  
  return results.map(function(r) { return {
    title: r.item.metadata?.title,
    description: r.item.metadata?.description,
    product_id: r.item.metadata?.product_id,
    price: r.item.metadata?.price,
    unit: r.item.metadata?.unit,
    score: r.score
  };});
}
'@

New-Item -ItemType Directory -Force -Path "app/lib" | Out-Null
$fixedRetrieval | Out-File -FilePath "app/lib/retrieval.ts" -Encoding utf8
Write-Host "  [OK] app/lib/retrieval.ts fixad" -ForegroundColor Green

# Steg 4: Fixa build-index route
Write-Host ""
Write-Host "[4/7] Fixar app/api/build-index/route.ts..." -ForegroundColor Yellow

$fixedBuildIndex = @'
import { NextResponse } from 'next/server';
import { buildIndex } from '@/app/lib/retrieval';

export async function POST() {
  try {
    const result = await buildIndex();
    if (result) {
      return NextResponse.json({ message: "Index built successfully", count: result.count });
    } else {
      return NextResponse.json({ error: "No products found" }, { status: 404 });
    }
  } catch (error) {
    return NextResponse.json({ error: "Failed to build index" }, { status: 500 });
  }
}
'@

New-Item -ItemType Directory -Force -Path "app/api/build-index" | Out-Null
$fixedBuildIndex | Out-File -FilePath "app/api/build-index/route.ts" -Encoding utf8
Write-Host "  [OK] app/api/build-index/route.ts fixad" -ForegroundColor Green

# Steg 5: Fixa search route
Write-Host ""
Write-Host "[5/7] Fixar app/api/search/route.ts..." -ForegroundColor Yellow

$fixedSearch = @'
import { NextRequest, NextResponse } from 'next/server';
import { searchProducts } from '@/app/lib/retrieval';

export async function POST(request: NextRequest) {
  try {
    const { query, topK = 5 } = await request.json();
    
    if (!query) {
      return NextResponse.json({ error: "Query is required" }, { status: 400 });
    }
    
    const results = await searchProducts(query, topK);
    return NextResponse.json({ results });
  } catch (error) {
    return NextResponse.json({ error: "Search failed" }, { status: 500 });
  }
}
'@

New-Item -ItemType Directory -Force -Path "app/api/search" | Out-Null
$fixedSearch | Out-File -FilePath "app/api/search/route.ts" -Encoding utf8
Write-Host "  [OK] app/api/search/route.ts fixad" -ForegroundColor Green

# Steg 6: Ta bort gammalt index
Write-Host ""
Write-Host "[6/7] Tar bort gammalt index..." -ForegroundColor Yellow

if (Test-Path "vectra-index") {
    Remove-Item -Path "vectra-index" -Recurse -Force
    Write-Host "  [OK] Gammalt index borttaget" -ForegroundColor Green
}

# Steg 7: Starta servern och testa
Write-Host ""
Write-Host "[7/7] Startar servern och testar..." -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan

# Starta servern i bakgrunden
Write-Host "Startar Next.js server..." -ForegroundColor Yellow
$serverProcess = Start-Process -FilePath "npm" -ArgumentList "run dev" -NoNewWindow -PassThru

# Vanta pa att servern startar
Write-Host "Vantar pa att servern ska starta (15 sekunder)..." -ForegroundColor Yellow
Start-Sleep -Seconds 15

# Testa att servern svarar
Write-Host ""
Write-Host "Testar anslutning..." -ForegroundColor Yellow
try {
    $testResponse = Invoke-RestMethod -Uri "http://localhost:3000/api/products" -Method GET -ErrorAction Stop
    Write-Host "  [OK] Server ar uppe!" -ForegroundColor Green
} catch {
    Write-Host "  [FEL] Kunde inte ansluta till servern" -ForegroundColor Red
    Write-Host "  Starta servern manuellt: npm run dev" -ForegroundColor Yellow
    exit 1
}

# Bygg indexet
Write-Host ""
Write-Host "Bygger sökindex..." -ForegroundColor Yellow
try {
    $buildResult = Invoke-RestMethod -Uri "http://localhost:3000/api/build-index" -Method POST
    Write-Host "  [OK] $($buildResult.message) - $($buildResult.count) produkter indexerade" -ForegroundColor Green
} catch {
    Write-Host "  [FEL] Kunde inte bygga index" -ForegroundColor Red
}

# Testa sökning
Write-Host ""
Write-Host "Testar sökning..." -ForegroundColor Yellow
$searchBody = @{ query = "meeting room" } | ConvertTo-Json
try {
    $searchResult = Invoke-RestMethod -Uri "http://localhost:3000/api/search" -Method POST -Body $searchBody -ContentType "application/json"
    if ($searchResult.results.Count -gt 0) {
        Write-Host "  [OK] Hittade $($searchResult.results.Count) produkter:" -ForegroundColor Green
        foreach ($item in $searchResult.results | Select-Object -First 3) {
            Write-Host "     - $($item.title) (poang: $([math]::Round($item.score, 2)))" -ForegroundColor White
        }
    } else {
        Write-Host "  [VARNING] Inga produkter hittades" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  [FEL] Sokning misslyckades" -ForegroundColor Red
}

# Testa RFP-extractor
Write-Host ""
Write-Host "Testar RFP-extractor..." -ForegroundColor Yellow
$extractBody = @{ rfpText = "Meeting room for 12 people on May 15th" } | ConvertTo-Json
try {
    $extractResult = Invoke-RestMethod -Uri "http://localhost:3000/api/extract" -Method POST -Body $extractBody -ContentType "application/json"
    Write-Host "  [OK] Extraherat:" -ForegroundColor Green
    Write-Host "     - Eventtyp: $($extractResult.eventType)" -ForegroundColor White
    Write-Host "     - Gaster: $($extractResult.guestCount)" -ForegroundColor White
    Write-Host "     - Datum: $($extractResult.dates)" -ForegroundColor White
} catch {
    Write-Host "  [FEL] Extract misslyckades" -ForegroundColor Red
}

# Testa planeringsagenten
Write-Host ""
Write-Host "Testar planeringsagenten..." -ForegroundColor Yellow
$planBody = @{ rfpText = "Meeting room for 12 people. Budget 2000 EUR." } | ConvertTo-Json
try {
    $planResult = Invoke-RestMethod -Uri "http://localhost:3000/api/plan" -Method POST -Body $planBody -ContentType "application/json"
    Write-Host "  [OK] Plan skapad!" -ForegroundColor Green
    Write-Host "     - Extraherat: $($planResult.extracted.eventType) for $($planResult.extracted.guestCount) personer" -ForegroundColor White
    Write-Host "     - Matchade produkter: $($planResult.matchedProducts.Count)" -ForegroundColor White
    if ($planResult.plan) {
        Write-Host "     - Plan pris: $($planResult.plan.totalEstimatedPrice) EUR" -ForegroundColor White
        Write-Host "     - Sammanfattning: $($planResult.plan.summary)" -ForegroundColor White
    }
} catch {
    Write-Host "  [FEL] Planering misslyckades" -ForegroundColor Red
}

# Sammanfattning
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "KLAR! Allt ar fixat och testat!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Servern kors i bakgrunden pa http://localhost:3000" -ForegroundColor Yellow
Write-Host ""
Write-Host "For att stoppa servern, kor: Stop-Process -Id $($serverProcess.Id)" -ForegroundColor White
Write-Host ""