# AI för säkerhetsincidenter

**Schemalagd:** 2027-05-11 · 09:00–16:00 · **Nivå:** nybörjare · **Interaktivitet:** 5/5 · **Avancerad (Kurs-PM):** EndpointSecurityML

## Tid och arbetsform

| | |
|---|---|
| På passet | 360 min, varav **290 min egen aktivitet (81 %)** |
| Hemma före | PowerPoint, ca 1,5 h |
| Hemma efter | Gör klart notebooksen, ca 3 h |
| Avancerad uppgift | EndpointSecurityML med Docker, 8–10 h (görs hemma, krävs inte för G) |

Teori ses hemma så att passet kan användas till eget arbete. Hela tidsbudgeten finns i
`00_Kursplan/Tidsplan och arbetsfördelning.md`.


## Vad du gör

Hur AI används för att upptäcka, förebygga och svara på incidenter – och hur ett MLOps-flöde håller modellen spårbar när den väl är i drift.

## Varför

En modell som inte går att reproducera eller övervaka är värdelös i en incident. Här får du hela kedjan.

## Så jobbar du

1. Läs föreläsningen. 5.2 är den avancerade versionen.
2. Kör de fyra notebooksen: loggparser, phishing-URL med RAG, BERT-identifiering och självlärande databas.
3. Starta MLOps-labben: `docker compose up --build -d api`, öppna <http://localhost:8000/docs>.
4. Öppna kontrollpanelen (`python control-center/server.py` → <http://127.0.0.1:8765>) och kör stegen: ladda data, träna, versionera, prediktera.
5. Svara på quizet.

## Filer i mappen

**01 Multimedia** (`01_Multimedia/`)

| Fil | Storlek | Typ |
|---|---|---|
| `AI-drivet_cybersäkerhetssystem.mp4` | 40.2 MB | Video |
| `AI_som_både_försvar_och_säkerhetsrisk.m4a` | 45.6 MB | Ljud |
| `Bygg_en_robust_MLOps-fästning_mot_ransomware.m4a` | 53.0 MB | Ljud |

**02 PowerPoint och quiz** (`02_PowerPoint-och-quiz/`)

| Fil | Storlek | Typ |
|---|---|---|
| `5. Användning av AI för detektering och respons på säkerhetsincidente - Google Forms.pdf` | 144 kB | PDF |
| `5. Användning av AI för detektering och respons på säkerhetsincidenter.pdf` | 1.8 MB | PDF |
| `5. Användning av AI för detektering och respons på säkerhetsincidenter.pptx` | 11.3 MB | PowerPoint |
| `5.2. AI för detektering, förebyggande åtgärder och respons på säkerhetsincidenter (avancerad).pdf` | 7.9 MB | PDF |
| `5.2. AI för detektering, förebyggande åtgärder och respons på säkerhetsincidenter (avancerad).pptx` | 27.6 MB | PowerPoint |

**03 Workshop** (`03_Workshop/`)

| Fil | Storlek | Typ |
|---|---|---|
| `workshop-05-ai-incidenter.html` | 78 kB | Workshop |

**04 Labb grund** (`04_Labb-grund/`)

| Fil | Storlek | Typ |
|---|---|---|
| `AI_baserad_Loggparser_med_Flan_T5_och_Finjustering.ipynb` | 17 kB | Notebook |
| `AI_baserad_Phishing_URL_Detektor_med_NLP_samt_RAG_(Retrieval_Augmented_Generation)_princip.ipynb` | 104 kB | Notebook |
| `Identifiering_av_Phishing_e_postmeddelanden_med_BERT.ipynb` | 29 kB | Notebook |
| `login_attempts_dataset.csv` | 4.3 MB | Data |
| `Self_Adaptive_AI_database_for_Cybersecurity.ipynb` | 1.5 MB | Notebook |

**05 Labb avancerad** (`05_Labb-avancerad/`)

| Fil | Storlek | Typ |
|---|---|---|
| `MLOps-Docker/` | – | Mapp |

## I Colab

Notebooksen har all data i mappen. `login_attempts_dataset.csv` ligger bredvid och ska laddas upp om notebooken frågar efter den.

1. Gå till [colab.research.google.com](https://colab.research.google.com) och välj *Upload notebook*.
2. Ladda upp datafilerna från `04_Labb-grund` till samma session.
3. Kör *Runtime → Run all* och läs igenom resultaten.

## Koppling till kursplanen

Kursplanen: AI för detektering, förebyggande åtgärder och respons, samt att se mönster och övervaka system.

## Om något går fel

- Första `--build` laddar ner images: 5–15 minuter och några GB.
- Portarna 8000, 5000, 8080, 9090 och 3000 måste vara lediga.
- Inloggning `admin`/`admin` gäller bara lokalt – exponera aldrig tjänsterna.

Fler fel och lösningar finns i labbens README.
