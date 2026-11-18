# Falsk information och deepfakes

**Schemalagd:** 2027-05-12 · 09:00–12:00 · **Nivå:** nybörjare · **Interaktivitet:** 4/5

## Tid och arbetsform

| | |
|---|---|
| På passet | 180 min, varav **140 min egen aktivitet (78 %)** |
| Hemma före | PowerPoint + deepfake-videor, ca 1,5 h |
| Hemma efter | Kort analys av en deepfake, ca 1 h |

Teori ses hemma så att passet kan användas till eget arbete. Hela tidsbudgeten finns i
`00_Kursplan/Tidsplan och arbetsfördelning.md`.


## Vad du gör

Hur falsk information produceras och upptäcks: deepfakes, manipulerade nyheter och textmodeller som skriver övertygande men fel.

## Varför

Kursplanen kräver att du kritiskt kan granska falsk information – både tekniskt och i ditt eget omdöme.

## Så jobbar du

1. Titta på de två deepfake-videorna och skriv ner tre tecken du reagerar på.
2. Titta på hur `Deepfake_detektering...ipynb` bygger modellen. Kör hela notebooken hemma om du har GPU – den hinner inte på en halvdag.
3. Kör `Phishing_detektering_med_hjälp_av_BERT_och_GPT_2.ipynb`.
4. Kör sentimentanalysen och fundera på vad den missar.
5. Svara på quizet.

## Filer i mappen

**01 Multimedia** (`01_Multimedia/`)

| Fil | Storlek | Typ |
|---|---|---|
| `Anderson Cooper, 4K Original_(Deep)Fake Example.mp4` | 1.2 MB | Video |
| `Detecting Fake News Campaigns via Graph Convolutional Networks.wav` | 63.1 MB | Ljud |
| `This is not Morgan Freeman  -  A Deepfake Singularity.mp4` | 2.0 MB | Video |

**02 PowerPoint och quiz** (`02_PowerPoint-och-quiz/`)

| Fil | Storlek | Typ |
|---|---|---|
| `6. Tekniker för att identifiera falsk information och stärka kontrollsystem - Google Forms.pdf` | 142 kB | PDF |
| `6. Tekniker för att identifiera falsk information och stärka kontrollsystem.pdf` | 1.5 MB | PDF |
| `6. Tekniker för att identifiera falsk information och stärka kontrollsystem.pptx` | 4.0 MB | PowerPoint |

**03 Workshop** (`03_Workshop/`)

| Fil | Storlek | Typ |
|---|---|---|
| `workshop-06-falsk-information.html` | 69 kB | Workshop |

**04 Labb grund** (`04_Labb-grund/`)

| Fil | Storlek | Typ |
|---|---|---|
| `Deepfake_detektering_med_enkelt_CNN,_MTCNN,_EfficientNetV2,_CNN_med_residualförbindelser_(ResNet).ipynb` | 893 kB | Notebook |
| `Phishing_detektering_med_hjälp_av_BERT_och_GPT_2.ipynb` | 135 kB | Notebook |
| `Sentiment_Analysis_Model_for_Cybersecurity_Applications.ipynb` | 55 kB | Notebook |


**05 Labb avancerad** (`05_Labb-avancerad/`)

| Fil | Storlek | Typ |
|---|---|---|
| `README.md` | 1 kB | Dokument |

## I Colab

Alla tre notebooksen installerar sina paket i första cellen. Deepfake-notebooken är tyngst – aktivera GPU under *Runtime → Change runtime type*.

1. Gå till [colab.research.google.com](https://colab.research.google.com) och välj *Upload notebook*.
2. Ladda upp datafilerna från `04_Labb-grund` till samma session.
3. Kör *Runtime → Run all* och läs igenom resultaten.

## Koppling till kursplanen

Kursplanen: identifiera och kritiskt granska falsk information som kan användas för att förstärka attacker.

## Om något går fel

- Utan GPU tar deepfake-notebooken lång tid.
- Videorna är exempel – de ska granskas, inte spridas vidare.

Fler fel och lösningar finns i labbens README.
