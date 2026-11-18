# IT och OT - zonindelning och datadiod

**Schemalagd:** 2027-05-05 · 09:00–12:00 · **Nivå:** nybörjare · **Interaktivitet:** 3/5

## Tid och arbetsform

| | |
|---|---|
| På passet | 180 min, varav **140 min egen aktivitet (78 %)** |
| Hemma före | PowerPoint + podd, ca 1,5 h |
| Hemma efter | Skriv egen slutsats om datadioden, ca 1 h |

Teori ses hemma så att passet kan användas till eget arbete. Hela tidsbudgeten finns i
`00_Kursplan/Tidsplan och arbetsfördelning.md`.


## Vad du gör

Varför industriella nät separeras från kontorsnät, vad en zonindelning gör och hur en datadiod släpper ut data men inte in attacker.

## Varför

De flesta allvarliga incidenterna i OT-miljöer börjar med att gränsen mellan IT och OT är otydlig.

## Så jobbar du

1. Läs föreläsningen och lyssna på podden om mejlklicket som stoppade fabriken.
2. Kör `it_ot_security_data.ipynb` och läs tabellerna den skriver ut.
3. Avgör själv: vilka flöden i datat skulle en datadiod blockera?
4. Svara på quizet.

## Filer i mappen

**01 Multimedia** (`01_Multimedia/`)

| Fil | Storlek | Typ |
|---|---|---|
| `När_ett_mejlklick_stoppar_hela_fabriken.m4a` | 31.6 MB | Ljud |
| `Säkra_vår_Fysiska_Värld.mp4` | 19.8 MB | Video |

**02 PowerPoint och quiz** (`02_PowerPoint-och-quiz/`)

| Fil | Storlek | Typ |
|---|---|---|
| `3. Säkerhet genom separation av IT och OT zonindelningar och användning av datadioder - Google Forms.pdf` | 143 kB | PDF |
| `3. Säkerhet genom separation av IT och OT zonindelningar och användning av datadioder.pdf` | 1.1 MB | PDF |
| `3. Säkerhet genom separation av IT och OT zonindelningar och användning av datadioder.pptx` | 1.4 MB | PowerPoint |

**03 Workshop** (`03_Workshop/`)

| Fil | Storlek | Typ |
|---|---|---|
| `workshop-03-it-ot.html` | 73 kB | Workshop |

**04 Labb grund** (`04_Labb-grund/`)

| Fil | Storlek | Typ |
|---|---|---|
| `it_ot_security_data.csv` | 686 kB | Data |
| `it_ot_security_data.ipynb` | 273 kB | Notebook |
| `it_ot_security_data.pbix` | 276 kB | Power BI |


**05 Labb avancerad** (`05_Labb-avancerad/`)

| Fil | Storlek | Typ |
|---|---|---|
| `README.md` | 1 kB | Dokument |

## I Colab

Notebooken installerar sina paket själv i första cellen. Inga externa filer behövs utöver CSV:n i mappen.

1. Gå till [colab.research.google.com](https://colab.research.google.com) och välj *Upload notebook*.
2. Ladda upp datafilerna från `04_Labb-grund` till samma session.
3. Kör *Runtime → Run all* och läs igenom resultaten.

## Koppling till kursplanen

Kursplanen: IT/OT-separation med zonindelningar, datadiod i zongränser och allowlisting.

## Om något går fel

- Notebooken innehåller mest markdown och en kodcell – lägg tid på att läsa slutsatserna, inte bara på att köra.

Fler fel och lösningar finns i labbens README.
