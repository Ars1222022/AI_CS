# setup-retrieval-fas3.ps1
# Bygger retrieval-lager med stod for ONLINE (Proposales API) eller LOKALT (mock-products.json)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Fas 3: Bygg retrieval-lager (semantisk sokning)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Hitta projektmappen (dar package.json finns)
$projectPath = $null
$currentPath = Get-Location

# Kolla om vi redan ar i ratt mapp
if (Test-Path "package.json") {
    $projectPath = $currentPath
    Write-Host "[OK] Redan i projektmapp: $projectPath" -ForegroundColor Green
} else {
    # Kolla om proposales-ai mappen finns i nuvarande mapp
    if (Test-Path "proposales-ai/package.json") {
        $projectPath = Join-Path $currentPath "proposales-ai"
        Write-Host "[OK] Hittade projektmapp: $projectPath" -ForegroundColor Green
        Set-Location $projectPath
    } 
    # Kolla om vi ar i en foralder mapp (upp en niva)
    elseif (Test-Path "../package.json") {
        $projectPath = Resolve-Path ".."
        Write-Host "[OK] Hittade projektmapp en niva upp: $projectPath" -ForegroundColor Green
        Set-Location $projectPath
    }
    # Kolla om proposales-ai finns i foralder mappen
    elseif (Test-Path "../proposales-ai/package.json") {
        $projectPath = Resolve-Path "../proposales-ai"
        Write-Host "[OK] Hittade proposales-ai en niva upp: $projectPath" -ForegroundColor Green
        Set-Location $projectPath
    }
    else {
        Write-Host "[FEL] Kan inte hitta package.json!" -ForegroundColor Red
        Write-Host ""
        Write-Host "Forsokte soka pa:" -ForegroundColor Yellow
        Write-Host "   - Nuvarande mapp: $currentPath" -ForegroundColor White
        Write-Host "   - ./proposales-ai/" -ForegroundColor White
        Write-Host "   - ../ (en niva upp)" -ForegroundColor White
        Write-Host "   - ../proposales-ai/" -ForegroundColor White
        Write-Host ""
        Write-Host "Var god ga manuellt till projektmappen och kor skriptet igen." -ForegroundColor Yellow
        exit 1
    }
}

Write-Host "[OK] Arbetar i: $(Get-Location)" -ForegroundColor Green
Write-Host ""

# Steg 1: Fraga om datakalla
Write-Host "[1/5] Valj datakalla for produkter:" -ForegroundColor Yellow
Write-Host "   J = Anvand Proposales API (online) - kraver API-nyckel" -ForegroundColor White
Write-Host "   N = Anvand mock-products.json (lokalt demo-lage)" -ForegroundColor White
Write-Host ""
$useProposales = Read-Host "Anvand Proposales API? (J/N)"

# Steg 2: Kontrollera API-nyckel om J valdes
$apiKey = ""
$companyId = ""
if ($useProposales -eq "J") {
    $envFile = ".env.local"
    if (Test-Path $envFile) {
        $envContent = Get-Content $envFile -Raw
        if ($envContent -match 'PROPOSALES_API_KEY=(.+)') {
            $apiKey = $matches[1].Trim()
            Write-Host "[OK] PROPOSALES_API_KEY laddad fran .env.local" -ForegroundColor Green
        } else {
            Write-Host "[FEL] PROPOSALES_API_KEY saknas i .env.local" -ForegroundColor Red
            Write-Host ""
            Write-Host "Lagg till i .env.local:" -ForegroundColor Yellow
            Write-Host "   PROPOSALES_API_KEY=ps.din_nyckel" -ForegroundColor Cyan
            Write-Host "   PROPOSALES_COMPANY_ID=din_siffra" -ForegroundColor Cyan
            Write-Host ""
            exit 1
        }
        if ($envContent -match 'PROPOSALES_COMPANY_ID=(.+)') {
            $companyId = $matches[1].Trim()
            Write-Host "[OK] PROPOSALES_COMPANY_ID laddad fran .env.local" -ForegroundColor Green
        } else {
            Write-Host "[FEL] PROPOSALES_COMPANY_ID saknas i .env.local" -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host "[FEL] .env.local hittades inte!" -ForegroundColor Red
        exit 1
    }
}

# Steg 3: Installera nodvandiga paket
Write-Host ""
Write-Host "[2/5] Installerar nodvandiga paket..." -ForegroundColor Yellow

Write-Host "   Installerar vectra, transformers, localforage..." -ForegroundColor White
npm install vectra @huggingface/transformers localforage --legacy-peer-deps

Write-Host "[OK] Paket installerade!" -ForegroundColor Green

# Steg 4: Skapa alla API-filer
Write-Host ""
Write-Host "[3/5] Skapar API routes..." -ForegroundColor Yellow

# Skapa mappar
New-Item -ItemType Directory -Force -Path "app/api/products" | Out-Null
New-Item -ItemType Directory -Force -Path "app/api/build-index" | Out-Null
New-Item -ItemType Directory -Force -Path "app/api/search" | Out-Null
New-Item -ItemType Directory -Force -Path "app/lib" | Out-Null

# Skapa app/api/products/route.ts
if ($useProposales -eq "J") {
    $productsRouteContent = @'
import { NextResponse } from 'next/server';

const API_KEY = "PROPOSALES_API_KEY_PLACEHOLDER";

export async function GET() {
  try {
    const response = await fetch("https://api.proposales.com/v3/content", {
      headers: {
        "Authorization": `Bearer ${API_KEY}`,
        "Content-Type": "application/json"
      }
    });
    const data = await response.json();
    return NextResponse.json(data);
  } catch (error) {
    return NextResponse.json({ error: "Failed to fetch products" }, { status: 500 });
  }
}
'@
    $productsRouteContent = $productsRouteContent -replace "PROPOSALES_API_KEY_PLACEHOLDER", $apiKey
} else {
    $productsRouteContent = @'
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
    return NextResponse.json({ data: [] });
  } catch (error) {
    return NextResponse.json({ error: "Failed to fetch products" }, { status: 500 });
  }
}
'@
}
$productsRouteContent | Out-File -FilePath "app/api/products/route.ts" -Encoding utf8
Write-Host "  [OK] app/api/products/route.ts" -ForegroundColor Green

# Skapa app/lib/retrieval.ts
$retrievalContent = @'
import { LocalIndex } from 'vectra';
import { pipeline } from '@huggingface/transformers';
import path from 'path';

let embeddingModel: any = null;
let index: LocalIndex | null = null;

async function getEmbeddingModel() {
  if (!embeddingModel) {
    console.log("Laddar embeddings-modell (forsta gangen tar ~15 sek)...");
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
  
  if (products.length === 0) {
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
    
    console.log("  " + (i + 1) + "/" + products.length + ": " + title);
    const embedding = await createEmbedding(textToEmbed);
    
    await idx.insertItem({
      id: (product.product_id || product.id).toString(),
      vector: embedding,
      metadata: {
        title: title,
        description: description,
        product_id: product.product_id || product.id
      }
    });
  }
  
  console.log("Index skapat! " + products.length + " produkter sparade.");
  return true;
}

export async function searchProducts(query: string, topK: number = 5) {
  const idx = await getIndex();
  const queryEmbedding = await createEmbedding(query);
  const results = await idx.queryItems(queryEmbedding, topK);
  
  return results.map(r => ({
    title: r.item.metadata?.title,
    description: r.item.metadata?.description,
    score: r.score
  }));
}
'@
$retrievalContent | Out-File -FilePath "app/lib/retrieval.ts" -Encoding utf8
Write-Host "  [OK] app/lib/retrieval.ts" -ForegroundColor Green

# Skapa app/api/build-index/route.ts
$buildIndexContent = @'
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
'@
$buildIndexContent | Out-File -FilePath "app/api/build-index/route.ts" -Encoding utf8
Write-Host "  [OK] app/api/build-index/route.ts" -ForegroundColor Green

# Skapa app/api/search/route.ts
$searchRouteContent = @'
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
    console.error(error);
    return NextResponse.json({ error: "Search failed" }, { status: 500 });
  }
}
'@
$searchRouteContent | Out-File -FilePath "app/api/search/route.ts" -Encoding utf8
Write-Host "  [OK] app/api/search/route.ts" -ForegroundColor Green

# Steg 5: Skapa mock-products.json (om demo-lage)
if ($useProposales -ne "J") {
    Write-Host ""
    Write-Host "[4/5] Skapar mock-products.json (demo-lage)..." -ForegroundColor Yellow
    
    if (-not (Test-Path "mock-products.json")) {
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
        $mockJson = $mockProducts | ConvertTo-Json -Depth 10
        $mockJson | Out-File -FilePath "mock-products.json" -Encoding utf8
        Write-Host "  [OK] mock-products.json skapad (11 produkter)" -ForegroundColor Green
    } else {
        Write-Host "  [OK] mock-products.json finns redan" -ForegroundColor Green
    }
}

# Steg 6: Bygg index
Write-Host ""
Write-Host "[5/5] Bygger sokindex..." -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "[VARNING] Detta tar ca 1-2 minuter forsta gangen!" -ForegroundColor Yellow
Write-Host ""

# Bygg index via API
Write-Host ""
Write-Host "[INFO] Starta servern i en NY terminal:" -ForegroundColor Yellow
Write-Host "   cd $(Get-Location)" -ForegroundColor White
Write-Host "   npm run dev" -ForegroundColor White
Write-Host ""
Write-Host "[INFO] I den HAR terminalen, bygg index nar servern ar uppe:" -ForegroundColor Yellow
Write-Host "   curl -X POST http://localhost:3000/api/build-index" -ForegroundColor White
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Fas 3 ar klar!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Testa sokning (nar servern kor):" -ForegroundColor Yellow
Write-Host "   curl -X POST http://localhost:3000/api/search -H 'Content-Type: application/json' -d '{\"query\":\"meeting room\"}'" -ForegroundColor White
Write-Host ""
Write-Host "Nasta steg: Fas 4 - Bygg RFP-extractor" -ForegroundColor Cyan