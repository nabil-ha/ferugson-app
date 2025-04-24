from flask import Flask, request, jsonify
import torch
import joblib
from torch import nn

app = Flask(__name__)

# -------------------------
# Injury Prediction Model
# -------------------------
class InjuryClassifier(nn.Module):
    def __init__(self, input_size=3):
        super(InjuryClassifier, self).__init__()
        self.fc1 = nn.Linear(input_size, 64)
        self.fc2 = nn.Linear(64, 32)
        self.fc3 = nn.Linear(32, 3)

    def forward(self, x):
        x = torch.relu(self.fc1(x))
        x = torch.relu(self.fc2(x))
        return self.fc3(x)  # logits (no softmax here)

injury_model = InjuryClassifier(input_size=3)
injury_model.load_state_dict(torch.load('injury_model.pth', weights_only=True))
injury_model.eval()
injury_scaler = joblib.load('injury_scalar.pkl')  # rename accordingly

injury_labels = {0: "Low Risk", 1: "Medium Risk", 2: "High Risk"}

# -------------------------
# Fatigue Prediction Model
# -------------------------
class FatigueRegressor(nn.Module):
    def __init__(self, input_size=3):
        super(FatigueRegressor, self).__init__()
        self.fc1 = nn.Linear(input_size, 64)
        self.fc2 = nn.Linear(64, 32)
        self.fc3 = nn.Linear(32, 1)

    def forward(self, x):
        x = torch.relu(self.fc1(x))
        x = torch.relu(self.fc2(x))
        x = torch.sigmoid(self.fc3(x))  # outputs value in [0, 1]
        return x

fatigue_model = FatigueRegressor(input_size=3)
fatigue_model.load_state_dict(torch.load('fatigue_model.pth'))
fatigue_model.eval()
fatigue_scaler = joblib.load('fatigue_scalar.pkl')

# -------------------------
# Injury Prediction Endpoint
# -------------------------
@app.route('/predict-injury', methods=['POST'])
def predict_injury():
    data = request.json
    features = [
        data['Previous_Injuries'],
        data['Training_Intensity'],
        data['BMI']
    ]
    X_scaled = injury_scaler.transform([features])
    input_tensor = torch.tensor(X_scaled, dtype=torch.float32)

    with torch.no_grad():
        output = injury_model(input_tensor)
        prediction = torch.argmax(output, dim=1).item()

    return jsonify({
        'class': int(prediction),
        'label': injury_labels[prediction]
    })

# -------------------------
# Fatigue Prediction Endpoint
# -------------------------
@app.route('/predict-fatigue', methods=['POST'])
def predict_fatigue():
    data = request.json
    features = [
        data['Speed'],
        data['Strength'],
        data['Stamina']
    ]
    X_scaled = fatigue_scaler.transform([features])
    input_tensor = torch.tensor(X_scaled, dtype=torch.float32)

    with torch.no_grad():
        output = fatigue_model(input_tensor)
        fatigue_percent = float(output.item() * 100)

    return jsonify({
        'fatigue_percent': round(fatigue_percent, 2)
    })

# -------------------------
# Run the API
# -------------------------
if __name__ == '__main__':
    app.run(debug=True)
