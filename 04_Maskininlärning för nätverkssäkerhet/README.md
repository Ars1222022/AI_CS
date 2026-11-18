# Maskininlärning för nätverkssäkerhet

**Schemalagd:** 2027-05-10 · 09:00–16:00 · **Nivå:** nybörjare · **Interaktivitet:** 5/5 · **Avancerad (Kurs-PM):** ML för nätverkssäkerhet – analys av stora datamängder

## Tid och arbetsform

| | |
|---|---|
| På passet | 360 min, varav **290 min egen aktivitet (81 %)** |
| Hemma före | PowerPoint, ca 1,5 h |
| Hemma efter | Gör klart notebooksen, ca 3 h |
| Avancerad uppgift | SQL2025-labbet, 8–10 h (görs hemma, krävs inte för G) |

Teori ses hemma så att passet kan användas till eget arbete. Hela tidsbudgeten finns i
`00_Kursplan/Tidsplan och arbetsfördelning.md`.


## Vad du gör

Att hitta attacker i nätverkstrafik med maskininlärning: rena data, välja modell, mäta rätt och visa resultatet.

## Varför

Det här är kursens tyngsta tekniska moment och det som ger flest mätbara resultat till projektuppgiften.

## Så jobbar du

1. Läs föreläsningen. Det avancerade 4.2-blocket är för dig som vill gå djupare.
2. Kör `ML_modeller_för_Anomalidetektering.ipynb` och jämför modellerna.
3. Kör `NetworkSecurity_Training.ipynb` om du vill träna modellen från början.
4. Gör labben i `05_Labb-avancerad`: databas, träning, analys och Power BI (12 steg i README).
5. Svara på quizet.

## Filer i mappen

**01 Multimedia** (`01_Multimedia/`)

| Fil | Storlek | Typ |
|---|---|---|
| `4.2 ML för stora datamängder/` | – | Mapp |
| `Maskininlärning_som_nätverkets_nya_försvarslinje.m4a` | 28.2 MB | Ljud |
| `ML_i_nätverkssäkerhet.mp4` | 50.1 MB | Video |

**02 PowerPoint och quiz** (`02_PowerPoint-och-quiz/`)

| Fil | Storlek | Typ |
|---|---|---|
| `4.2 ML för stora datamängder/` | – | Mapp |
| `4. Maskininlärning för nätverkssäkerhet analys av stora datamängder för att - Google Forms.pdf` | 149 kB | PDF |
| `4. Maskininlärning för nätverkssäkerhet analys av stora datamängder för att .pdf` | 671 kB | PDF |
| `4. Maskininlärning för nätverkssäkerhet analys av stora datamängder för att .pptx` | 1.6 MB | PowerPoint |

**03 Workshop** (`03_Workshop/`)

| Fil | Storlek | Typ |
|---|---|---|
| `workshop-04-ml-natverkssakerhet.html` | 80 kB | Workshop |

**04 Labb grund** (`04_Labb-grund/`)

| Fil | Storlek | Typ |
|---|---|---|
| `Customer Call List.xlsx` | 12 kB | Fil |
| `Data Cleaning Customer Call List.ipynb` | 173 kB | Notebook |
| `KDDTest+.txt` | 3.3 MB | Data |
| `ML_modeller_för_Anomalidetektering.ipynb` | 315 kB | Notebook |
| `ML_modeller_för_Anomalidetektering_i_Nätverkssäkerhet.ipynb` | 26 kB | Notebook |
| `network_data.csv` | 55 kB | Data |
| `NetworkSecurity_Training.ipynb` | 155 kB | Notebook |
| `NUSW-NB15_features.csv` | 4 kB | Data |

**05 Labb avancerad** (`05_Labb-avancerad/`)

| Fil | Storlek | Typ |
|---|---|---|
| `SQL2025/` | – | Mapp |
| `Maskininlärning för nätverkssäkerhet analys av stora datamängder.pdf` | 902 kB | PDF |
| `Maskininlärning för nätverkssäkerhet analys av stora datamängder.pptx` | 875 kB | PowerPoint |
| `README.md` | 13 kB | Fil |

## I Colab

`NetworkSecurity_Training.ipynb` tränar modellen i Colab och sparar `.pkl`. Ändra sparsökvägen till `/content/` när du kör i Colab.

1. Gå till [colab.research.google.com](https://colab.research.google.com) och välj *Upload notebook*.
2. Ladda upp datafilerna från `04_Labb-grund` till samma session.
3. Kör *Runtime → Run all* och läs igenom resultaten.

## Koppling till kursplanen

Kursplanen: maskininlärningens förmåga att analysera stora datamängder, upptäcka mönster och exponera nätverkssårbarheter.

## Om något går fel

- Fel `numpy`-version ger `ModuleNotFoundError: No module named 'numpy._core'`. Lösningen står i labbens README: uppgradera enligt `requirements.txt`, nedgradera inte.
- `KDDTest+.txt` är stor – räkna med några sekunder per inläsning.
- `Customer Call List.xlsx` och städnotebooken hör inte till nätverkssäkerheten. Använd dem inte i undervisningen: innehållet kan innehålla personuppgifter och är inte granskat.

Fler fel och lösningar finns i labbens README.
