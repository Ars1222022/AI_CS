# AI-verktyg i cybersäkerhet

**Schemalagd:** 2027-05-17 · 09:00–16:00 · **Nivå:** nybörjare · **Interaktivitet:** 5/5 · **Avancerad (Kurs-PM):** Insider Threat Detection

## Tid och arbetsform

| | |
|---|---|
| På passet | 360 min, varav **290 min egen aktivitet (81 %)** |
| Hemma före | PowerPoint + podd, ca 1,5 h |
| Hemma efter | Gör klart notebooksen, ca 3 h |
| Avancerad uppgift | Insider Threat Detection, 8–10 h (görs hemma, krävs inte för G) |

Teori ses hemma så att passet kan användas till eget arbete. Hela tidsbudgeten finns i
`00_Kursplan/Tidsplan och arbetsfördelning.md`.


## Vad du gör

AI-verktyg i praktiskt säkerhetsarbete: intrångsdetektering på exempeldata, skadliga dokument, insiderhot och två mindre AI-tjänster i Docker.

## Varför

Här omsätts hela kursen i verktyg du faktiskt kan använda – och i en projektuppgift som examineras.

## Så jobbar du

1. Kör IDPS-notebooken på exempelfilerna i mappen. Använd inte din egen webbläsarhistorik – den kan innehålla personuppgifter.
2. Kör `Malicious_Document_Detection.ipynb`.
3. Gör Insider Threat-labben i 14 steg enligt `HANDLEDNING.md` (kräver Snowflake, dbt Cloud och Databricks – alla gratisnivåer).
4. Kör `house_price_predictor` med Docker om du vill se hur en modell blir en tjänst.
5. Svara på quizet och påbörja projektuppgiften.

## Filer i mappen

**01 Multimedia** (`01_Multimedia/`)

| Fil | Storlek | Typ |
|---|---|---|
| `Gemini AI for Security Operations_ Use Cases and Insights.wav` | 62.9 MB | Ljud |

**02 PowerPoint och quiz** (`02_PowerPoint-och-quiz/`)

| Fil | Storlek | Typ |
|---|---|---|
| `7. Praktisk tillämpning av AI-verktyg inom cybersäkerhet - Google Forms.pdf` | 141 kB | PDF |
| `7. Praktisk tillämpning av AI-verktyg inom cybersäkerhet.pdf` | 12.3 MB | PDF |
| `7. Praktisk tillämpning av AI-verktyg inom cybersäkerhet.pptx` | 15.2 MB | PowerPoint |

**03 Workshop** (`03_Workshop/`)

| Fil | Storlek | Typ |
|---|---|---|
| `workshop-07-ai-cybersakerhetsverktyg.html` | 78 kB | Workshop |

**04 Labb grund** (`04_Labb-grund/`)

| Fil | Storlek | Typ |
|---|---|---|
| `Intrusion_Detection_System_(IDPS)_test_med_hjälp_av_egen_webbhistorik.ipynb` | 817 kB | Notebook |
| `Malicious_Document_Detection.ipynb` | 29 kB | Notebook |
| `web history (1 month).csv` | 75 kB | Data |
| `web history (forever).csv` | 271 kB | Data |

**05 Labb avancerad** (`05_Labb-avancerad/`)

| Fil | Storlek | Typ |
|---|---|---|
| `house_price_predictor/` | – | Mapp |
| `Insider-Threat-Detection/` | – | Mapp |

## I Colab

IDPS-notebooken behöver `web history (1 month).csv` eller `(forever).csv` uppladdad. Insider Threat körs i Databricks, inte Colab.

1. Gå till [colab.research.google.com](https://colab.research.google.com) och välj *Upload notebook*.
2. Ladda upp datafilerna från `04_Labb-grund` till samma session.
3. Kör *Runtime → Run all* och läs igenom resultaten.

## Koppling till kursplanen

Kursplanen: använda AI för detektering och respons, se mönster, övervaka system och stärka kontrollsystem. Underlag för projektuppgiften (IG/G/VG).

## Om något går fel

- Insider-labben kräver konton hos tre tjänster – gör steg 1–7 i god tid.
- `house_price_predictor` är en liten demo, inte ett produktionssystem.

Fler fel och lösningar finns i labbens README.
