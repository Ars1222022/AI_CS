# house_price_predictor – modell som HTTP-tjänst

**Vad:** en liten webbtjänst som gissar bostadspris utifrån storlek. Modellen är en linjär
regression tränad på tio påhittade punkter i `model.py` – den är en demonstration, inte ett
riktigt verktyg.

**Varför:** visa hela kedjan från modell till tjänst: Python-modell → FastAPI → webbsida →
container. Samma mönster används i MLOps-labben i lektion 5, men där med en riktig modell
och databas.

**Hur:**

```sh
cd "07_AI-verktyg i cybersäkerhet/05_Labb-avancerad/house_price_predictor"
docker build -t house-price .
docker run --rm -p 8000:8000 house-price
```

Öppna <http://localhost:8000>, skriv en storlek (kvadratfot) och läs av priset.

**Filer:**

| Fil | Vad den gör |
|---|---|
| `main.py` | FastAPI-app: `/` visar formuläret, `/predict` räknar ut priset |
| `model.py` | Modellen: linjär regression på inbyggd exempeldata |
| `templates/index.html`, `static/style.css` | Sidan och stilen |
| `Dockerfile` | Python 3.9, uvicorn på port 8000 |
| `requirements.txt` | Pinnade versioner som passar Python 3.9 |
| `ReadMe.txt` | Originalets instruktion (PowerShell-version) |

**Fallgropar:**

- `requirements.txt` pinnar gamla versioner (`fastapi==0.68.1`, `numpy==1.21.2`). Byter du
  basimage till nyare Python måste versionerna uppdateras, annars går bygget inte igenom.
- Tjänsten är avsiktligt enkel: ingen autentisering, ingen validering av extremvärden.
  Kör den bara lokalt.
