Instructions for VS kode terminal:
Step 1: Completely Reset Your Environment
# Remove all containers
docker rm -f $(docker ps -aq)

# Remove all images
docker rmi -f $(docker images -q)

# Verify clean state
docker ps -a
docker images

Step 2: Create a Clean Project Structure
# Create fresh directory structure
mkdir app, app/static, app/templates -Force

# Create PROPER requirements.txt (this is critical)
@"
fastapi==0.68.1
uvicorn==0.15.0
scikit-learn==0.24.2
numpy==1.21.2
jinja2==3.0.1
python-multipart==0.0.5
aiofiles==22.1.0
"@ | Out-File requirements.txt -Encoding utf8

# Verify the file contains exactly these 7 lines with no extra characters
Get-Content requirements.txt

Step 3: Create Dockerfile
@"
FROM python:3.9-slim
WORKDIR /app
COPY . .
RUN pip install --no-cache-dir -r requirements.txt
EXPOSE 8000
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
"@ | Out-File Dockerfile -Encoding utf8


Step 4: Create Application Files
# main.py
@"
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
"@ | Out-File app/main.py -Encoding utf8

# model.py
@"
from sklearn.linear_model import LinearRegression
import numpy as np

class HousePriceModel:
    def __init__(self):
        sizes = np.array([750, 800, 850, 900, 950, 1000, 1100, 1200, 1300, 1400]).reshape(-1, 1)
        prices = np.array([150, 160, 165, 170, 180, 190, 210, 230, 245, 260])
        self.model = LinearRegression()
        self.model.fit(sizes, prices)
    
    def predict(self, size):
        return self.model.predict([[size]])[0]
"@ | Out-File app/model.py -Encoding utf8

# index.html
@"
<!DOCTYPE html>
<html>
<head>
    <title>House Price Predictor</title>
    <link rel="stylesheet" href="/static/style.css">
</head>
<body>
    <div class="container">
        <h1>House Price Predictor</h1>
        <form id="prediction-form" method="post" action="/predict">
            <input type="number" id="size" name="size" placeholder="Square feet" required>
            <button type="submit">Predict Price</button>
        </form>
        <div id="result"></div>
    </div>
    <script>
        document.getElementById('prediction-form').addEventListener('submit', async (e) => {
            e.preventDefault();
            const formData = new FormData(e.target);
            const response = await fetch('/predict', {
                method: 'POST',
                body: new URLSearchParams(formData)
            });
            const data = await response.json();
            document.getElementById('result').innerHTML = `Estimated price: $${data.price}K`;
        });
    </script>
</body>
</html>
"@ | Out-File app/templates/index.html -Encoding utf8

# style.css
@"
body {
    font-family: Arial, sans-serif;
    max-width: 600px;
    margin: 0 auto;
    padding: 20px;
}
.container {
    background: #f9f9f9;
    padding: 20px;
    border-radius: 8px;
}
input, button {
    padding: 8px;
    margin: 5px 0;
}
button {
    background: #007bff;
    color: white;
    border: none;
    cursor: pointer;
}
#result {
    margin-top: 20px;
    font-weight: bold;
}
"@ | Out-File app/static/style.css -Encoding utf8


Step 5: Build and Run
# Build with no cache
docker build --no-cache -t house-price-predictor .

# Run with proper port mapping
docker run -d -p 8000:8000 --name house-app house-price-predictor

# Check logs
docker logs house-app

# Verify running
docker ps









Proper requirements.txt format: No PowerShell artifacts, just pure text

Complete fresh build: Using --no-cache to avoid any cached errors

Simplified application code: Removed unnecessary complexity

Proper file encoding: Using UTF8 consistently

Verification:
After running, check http://localhost:8000 in your browser

You should see the house price predictor form

Enter a value (e.g., 1200) and click "Predict Price"

You should get back a price prediction
