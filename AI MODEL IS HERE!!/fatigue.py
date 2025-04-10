import pandas as pd

df = pd.read_csv("fatigue_data.csv")

df = df.drop(columns=["week", "player_id", "name", "session_type"])

# print(df.head())

def evaluate_fatigue(row):
    fatigue = row['fatigue_rating']
    stamina = row['stamina_rating']
    speed = row['speed_rating']
    strength = row['strength_rating']
    
    # Fatigue status
    if fatigue >= 8:
        fatigue_status = "High"
    elif fatigue >= 5:
        fatigue_status = "Medium"
    else:
        fatigue_status = "Low"

    return pd.Series([fatigue_status], index=['fatigue_status'])


df['fatigue_status'] = df.apply(evaluate_fatigue, axis = 1)

print(df.head())


from sklearn.tree import DecisionTreeClassifier
from sklearn.model_selection import train_test_split
from sklearn.metrics import classification_report
import matplotlib.pyplot as plt
from sklearn import tree

df_tree = df

# Encode the target variable
df_tree['fatigue_status_encoded'] = df_tree['fatigue_status'].map({'Low': 0, 'Medium': 1, 'High': 2})
X = df_tree.drop(columns=['fatigue_status', 'fatigue_status_encoded', 'position', 'fatigue_rating'])
y = df_tree['fatigue_status_encoded']

# Split the data
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

# Train the decision tree classifier
clf = DecisionTreeClassifier(max_depth=3, random_state=42)
clf.fit(X_train, y_train)

# Predict and evaluate
y_pred = clf.predict(X_test)
report = classification_report(y_test, y_pred, target_names=['Low', 'Medium', 'High'])

# Plot the decision tree
plt.figure(figsize=(12, 6))
tree.plot_tree(clf, feature_names=X.columns, class_names=['Low', 'Medium', 'High'], filled=True)
plt.title("Decision Tree for Fatigue Status Prediction")
plt.tight_layout()
plt.show()

import joblib
joblib.dump(clf, 'fatigue_model.pkl')