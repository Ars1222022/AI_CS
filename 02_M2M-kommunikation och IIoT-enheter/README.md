# M2M-kommunikation och IIoT-enheter

**Schemalagd:** 2027-05-04 · 09:00–16:00 · **Nivå:** nybörjare · **Interaktivitet:** 4/5 · **Avancerad (Kurs-PM):** AI-proposal-system

## Tid och arbetsform

| | |
|---|---|
| På passet | 360 min, varav **285 min egen aktivitet (79 %)** |
| Hemma före | PowerPoint + video, ca 2 h |
| Hemma efter | Gör klart notebooksen, ca 2 h |
| Avancerad uppgift | AI-proposal-system, 6–8 h (görs hemma, krävs inte för G) |

Teori ses hemma så att passet kan användas till eget arbete. Hela tidsbudgeten finns i
`00_Kursplan/Tidsplan och arbetsfördelning.md`.


## Vad du gör

Hur maskiner pratar med varandra och hur sensordata från en fabrik samlas in, tolkas och används för automation.

## Varför

IIoT är där AI möter den fysiska världen. Samma data används sedan i lektion 3 och 4.

## Så jobbar du

1. Läs föreläsningen och titta på videon om M2M och IIoT.
2. Kör `IIoT_sensorer.ipynb`, sedan `Analysera_och_tolka_filens_innehåll...ipynb` i Colab.
3. Starta `klient.py` och `server.py` i två terminaler (valfritt) för att se ett enkelt utbyte.
4. Gör quizet. Vill du gå vidare: bygg AI Proposal System i `05_Labb-avancerad` (nio PowerShell-faser, kräver Node.js och API-nycklar).

## Filer i mappen

**01 Multimedia** (`01_Multimedia/`)

| Fil | Storlek | Typ |
|---|---|---|
| `M2M och IIoT Integration_ Automatisering och Kommunikation.wav` | 33.4 MB | Ljud |
| `M2M_&_IIoT__Teori_till_Praktik.mp4` | 42.4 MB | Video |

**02 PowerPoint och quiz** (`02_PowerPoint-och-quiz/`)

| Fil | Storlek | Typ |
|---|---|---|
| `2. M2M-kommunikation och IIoT-enheter integration för ökad automatisering och förbättrad k - Google Forms.pdf` | 141 kB | PDF |
| `2. M2M-kommunikation och IIoT-enheter integration för ökad automatisering och förbättrad k.pdf` | 1.2 MB | PDF |
| `2. M2M-kommunikation och IIoT-enheter integration för ökad automatisering och förbättrad k.pptx` | 7.7 MB | PowerPoint |

**03 Workshop** (`03_Workshop/`)

| Fil | Storlek | Typ |
|---|---|---|
| `workshop-02-m2m-iiot.html` | 72 kB | Workshop |

**04 Labb grund** (`04_Labb-grund/`)

| Fil | Storlek | Typ |
|---|---|---|
| `Analysera_och_tolka_filens_innehåll_i_GOOGLE_COLAB.ipynb` | 24 kB | Notebook |
| `data-20221207.csv` | 19.7 MB | Data |
| `iiot_factory_data.csv` | 3.6 MB | Data |
| `iiot_factory_data.pbix` | 288 kB | Power BI |
| `IIoT_sensorer.ipynb` | 15 kB | Notebook |
| `klient.py` | 1 kB | Kod |
| `server.py` | 1 kB | Kod |

**05 Labb avancerad** (`05_Labb-avancerad/`)

| Fil | Storlek | Typ |
|---|---|---|
| `ai-proposal-system/` | – | Mapp |

## I Colab

`data-20221207.csv` (20 MB) måste laddas upp till Colab innan cellen som läser den. Ladda upp hela mappen `04_Labb-grund`.

1. Gå till [colab.research.google.com](https://colab.research.google.com) och välj *Upload notebook*.
2. Ladda upp datafilerna från `04_Labb-grund` till samma session.
3. Kör *Runtime → Run all* och läs igenom resultaten.

## Koppling till kursplanen

Kursplanen: M2M och IIoT-enheter samt hur integrering ger ökad automatisering och bättre kontroll.

## Om något går fel

- Stor CSV ger långsam uppladdning – vänta tills filen syns i filpanelen.
- AI Proposal System kräver Node.js och API-nycklar; README i labbmappen visar fasordningen.
- `ai-proposal-system` är ett PowerShell-labb i nio faser. Kör skripten i nummerordning:
  `setup-fas1.ps1`, `setup-products-fas2.ps1`, … `setup-UI-upstash-fas9.ps1`.

Fler fel och lösningar finns i labbens README.
