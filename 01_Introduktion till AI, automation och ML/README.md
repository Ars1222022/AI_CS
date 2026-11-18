# Introduktion till AI, automation och ML

**Schemalagd:** 2027-05-03 · 09:00–16:00 · **Nivå:** nybörjare · **Interaktivitet:** 4/5

## Tid och arbetsform

| | |
|---|---|
| På passet | 360 min, varav **285 min egen aktivitet (79 %)** |
| Hemma före | PowerPoint + podd, ca 1,5 h |
| Hemma efter | Gör klart båda notebooksen, ca 2 h |

Teori ses hemma så att passet kan användas till eget arbete. Hela tidsbudgeten finns i
`00_Kursplan/Tidsplan och arbetsfördelning.md`.


## Vad du gör

Du får begreppen AI, automation och maskininlärning, ser skillnaden mellan regelstyrda system och system som lär sig av data, och kör dina två första modeller.

## Varför

Utan vokabulären går resten av kursen inte att följa. Här byggs också vanan att köra en notebook från början till slut.

## Så jobbar du

1. Läs föreläsningen och notera tre begrepp du inte känner igen.
2. Öppna `Klassificera_blommor_(Iris_dataset).ipynb` i Colab och kör alla celler. Byt ut ett värde i datat och se om träffsäkerheten ändras.
3. Kör `Detektera_anomalier_i_nätverkstrafik_(synthetic_dataset).ipynb`. Fundera på varför modellen flaggar vissa rader.
4. Svara på quizet i `02_PowerPoint-och-quiz` innan du går vidare.

## Filer i mappen

**01 Multimedia** (`01_Multimedia/`)

| Fil | Storlek | Typ |
|---|---|---|
| `AI Automation and Machine Learning Concepts.wav` | 34.3 MB | Ljud |

**02 PowerPoint och quiz** (`02_PowerPoint-och-quiz/`)

| Fil | Storlek | Typ |
|---|---|---|
| `1. Introduktion till AI, automation och maskininlärning definitioner och verkliga tillämpningar - Google Forms.pdf` | 143 kB | PDF |
| `1. Introduktion till AI, automation och maskininlärning definitioner och verkliga tillämpningar.pdf` | 1.8 MB | PDF |
| `1. Introduktion till AI, automation och maskininlärning definitioner och verkliga tillämpningar.pptx` | 1.6 MB | PowerPoint |
| `ENISA Threat Landscape 2023.pdf` | 7.9 MB | PDF |

**03 Workshop** (`03_Workshop/`)

| Fil | Storlek | Typ |
|---|---|---|
| `workshop-01-introduktion-ai.html` | 86 kB | Workshop |

**04 Labb grund** (`04_Labb-grund/`)

| Fil | Storlek | Typ |
|---|---|---|
| `Bot/` | – | Mapp |
| `Detektera_anomalier_i_nätverkstrafik_(synthetic_dataset).ipynb` | 280 kB | Notebook |
| `Klassificera_blommor_(Iris_dataset).ipynb` | 361 kB | Notebook |


**05 Labb avancerad** (`05_Labb-avancerad/`)

| Fil | Storlek | Typ |
|---|---|---|
| `README.md` | 1 kB | Dokument |

## I Colab

Båda notebooksen har all data inbyggd eller genererad i koden – inget behöver laddas upp.

1. Gå till [colab.research.google.com](https://colab.research.google.com) och välj *Upload notebook*.
2. Ladda upp datafilerna från `04_Labb-grund` till samma session.
3. Kör *Runtime → Run all* och läs igenom resultaten.

## Koppling till kursplanen

Kursplanens första läranderesultat: redogöra för begrepp inom AI, automation och machine learning.

## Om något går fel

- Colab har redan `pandas` och `scikit-learn`; kör du lokalt behöver du installera dem.
- `04_Labb-grund/Bot/` är ett exempel på kunskapsbas för en enkel bot – den innehåller ingen färdig app.

Fler fel och lösningar finns i labbens README.
