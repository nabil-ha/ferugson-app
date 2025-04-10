from flask import Flask, request, jsonify
import joblib
import pandas as pd

app = Flask(__name__)

# Load models
fatigue_model = joblib.load("fatigue_model.pkl")
injury_model = joblib.load("injury_model.pkl")
scaler = joblib.load("scaler.pkl")

@app.route("/predict_fatigue", methods=["POST"])
def predict_fatigue():
    data = request.json
    df = pd.DataFrame([data])  # Expect unscaled inputs
    fatigue_prediction = fatigue_model.predict(df)[0]
    return jsonify({"fatigue": int(fatigue_prediction)})

@app.route("/predict_injury", methods=["POST"])
def predict_injury():
    data = request.json

    try:
        # Required inputs from frontend
        age = data["Player_Age"]
        weight = data["Player_Weight"]
        height = data["Player_Height"]
        previous_injuries = data["Previous_Injuries"]

        # Calculate features on the backend
        bmi = weight / ((height / 100) ** 2)
        bmi_age_ratio = bmi / age
        prev_injury_age = previous_injuries / age

        # Format input for model
        df = pd.DataFrame([{
            "Player_Age": age,
            "Player_Weight": weight,
            "Player_Height": height,
            "Previous_Injuries": previous_injuries,
            "BMI": bmi,
            "BMI_Age_Ratio": bmi_age_ratio,
            "Prev_Injury_Age": prev_injury_age
        }])

        # Scale and predict
        scaled_input = scaler.transform(df)
        prediction = injury_model.predict(scaled_input)[0]

        return jsonify({"injury": int(prediction)})

    except KeyError as e:
        return jsonify({"error": f"Missing required field: {str(e)}"}), 400
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=3000, debug=True)