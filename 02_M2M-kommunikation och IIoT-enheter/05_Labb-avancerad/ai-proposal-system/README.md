# AI Proposal System

En demo i nio faser som bygger ett AI-baserat förslagsystem för hotell: RFP-extrahering,
produktdata, retrieval, planner, proposal-generator, granskning, utvärdering och ett gränssnitt.

## Förutsättningar

- Windows och PowerShell 7
- Node.js (fas 1 kan installera det)
- API-nycklar för de modelltjänster som efterfrågas

## Installation

Kör skripten i nummerordning från den här mappen:

```powershell
./setup-fas1.ps1
./setup-products-fas2.ps1
./setup-retrieval-fas3.ps1
./setup-rfp-extractor-fas4.ps1
./setup-planner-fas5.ps1
./setup-proposal-generator-fas6.ps1
./setup-review-fas7.ps1
./setup-evaluation-fas8.ps1
./setup-UI-upstash-fas9.ps1
```

Skripten skapar projektet steg för steg och frågar efter nycklar. Lägg aldrig nycklar i
README eller i versionshanterade filer; använd `.env.local` som skripten skapar.

## Användning

Starta det projekt som fas 1 skapade och följ instruktionerna i `AI Proposal System för hotell.pdf`.
Det här är en demonstration, inte ett produktionssystem. Den är inte testkörd i den här mappen.
