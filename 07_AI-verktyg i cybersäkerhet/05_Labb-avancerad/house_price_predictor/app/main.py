from fastapi import FastAPI, Request, Form
from fastapi.responses import HTMLResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
from model import HousePriceModel
import uvicorn

app = FastAPI()
app.mount("/static", StaticFiles(directory="static"), name="static")
templates = Jinja2Templates(directory="templates")
model = HousePriceModel()

@app.get("/", response_class=HTMLResponse)
async def read_root(request: Request):
    return templates.TemplateResponse("index.html", {"request": request})

@app.post("/predict")
async def predict(size: float = Form(...)):
    prediction = model.predict(size)
    return {"price": round(prediction, 2)}

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
