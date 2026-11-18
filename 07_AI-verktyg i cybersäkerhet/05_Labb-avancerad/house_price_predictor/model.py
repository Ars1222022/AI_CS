from sklearn.linear_model import LinearRegression
import numpy as np

# Simple house price predictor based on size
class HousePriceModel:
    def __init__(self):
        # Sample data: house sizes (in sq ft) and prices (in $1000s)
        sizes = np.array([750, 800, 850, 900, 950, 1000, 1100, 1200, 1300, 1400]).reshape(-1, 1)
        prices = np.array([150, 160, 165, 170, 180, 190, 210, 230, 245, 260])
        
        self.model = LinearRegression()
        self.model.fit(sizes, prices)
    
    def predict(self, size):
        return self.model.predict([[size]])[0]