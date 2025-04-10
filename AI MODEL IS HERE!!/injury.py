# -*- coding: utf-8 -*-
"""injury_model.ipynb

Automatically generated by Colab.

Original file is located at
    https://colab.research.google.com/drive/1TIN8Wzvywe4dP9objUjdH3C4-oWqiUDY
"""

import pandas as pd
import matplotlib
import matplotlib.pyplot as plt
import seaborn as sns
import numpy as np
import sklearn
from sklearn.model_selection import train_test_split
from sklearn.metrics import classification_report, accuracy_score, recall_score
from sklearn.metrics import confusion_matrix
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import classification_report

import joblib

import kagglehub

# Download latest version
path = kagglehub.dataset_download("mrsimple07/injury-prediction-dataset")

print("Path to dataset files:", path)

df = pd.read_csv(path + "/injury_data.csv")

df.head()

df['Player_Weight'] = df['Player_Weight'].round(2)
df['Player_Height'] = df['Player_Height'].round(2)
df['Training_Intensity'] = df['Training_Intensity'].round(2)

df.head(5)

df_info = pd.DataFrame(df.dtypes, columns=['Dtype'])
df_info['Unique'] = df.nunique().values
df_info['Null'] = df.isnull().sum().values
df_info

df['BMI'] = df['Player_Weight'] / (df['Player_Height'] / 100) ** 2

df_info = pd.DataFrame(df.dtypes, columns=['Dtype'])
df_info['Unique'] = df.nunique().values
df_info['Null'] = df.isnull().sum().values
df_info

df

df = df.drop(columns=["Recovery_Time", "Training_Intensity", "Recovery_Time"])
df

X = df.drop('Likelihood_of_Injury', axis=1)
y = df['Likelihood_of_Injury']

X

y

X.columns

X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.1, random_state=42)

from sklearn.metrics import classification_report, accuracy_score, precision_score, recall_score

# Dictionary models | Dicionário de modelos
models = {
    "LGBMClassifier": LGBMClassifier(),
    "AdaBoostClassifier": AdaBoostClassifier(),
    "ExtraTreesClassifier": ExtraTreesClassifier(),
    "NuSVC": NuSVC(probability=True),
    "ExtraTreeClassifier": ExtraTreeClassifier(),
    }

for model_name, model in models.items():
    model.fit(X_train, y_train)
    predictions = model.predict(X_test)
    recall = recall_score(y_test, predictions)
    accuracy = accuracy_score(y_test, predictions)
    precision = precision_score(y_test, predictions)

    print(f"Model: {model_name}")
    print(f"Recall: {recall}")
    print(f"Accuracy: {accuracy}")
    print(f"Precision: {precision}")
    print("-" * 50)

"""# Feature Engineering"""

df['BMI_Age_Ratio'] = df['BMI'] / df['Player_Age']
df['Prev_Injury_Age'] = df['Previous_Injuries'] / df['Player_Age']

!pip install catboost

from catboost import CatBoostClassifier
from sklearn.metrics import classification_report

model = CatBoostClassifier(verbose=0, random_state=42)
model.fit(X_train, y_train)

y_pred = model.predict(X_test)
print(classification_report(y_test, y_pred, target_names=["No Injury", "Injury"]))

"""# Deep Learning"""

from sklearn.feature_selection import SelectKBest, f_classif

selector = SelectKBest(score_func=f_classif, k='all')  # or try k=5
X_selected = selector.fit_transform(X, y)
selected_features = X.columns[selector.get_support()]

import tensorflow as tf
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import Dense, LeakyReLU
from tensorflow.keras.optimizers import Adam

# Define the model
neural_net = Sequential()
neural_net.add(Dense(128, input_dim=7))  # No activation here
neural_net.add(LeakyReLU(alpha=0.1))     # Add LeakyReLU as a separate layer
neural_net.add(Dense(64, activation='relu'))
neural_net.add(Dense(32, activation='relu'))
neural_net.add(Dense(5, activation='relu'))
neural_net.add(Dense(1, activation='sigmoid'))

# Compile the model
neural_net.compile(optimizer=Adam(learning_rate=0.001), loss='binary_crossentropy', metrics=['accuracy'])

neural_net.summary()

neural_net.compile(loss='binary_crossentropy', optimizer=Adam(learning_rate=0.001), metrics=['accuracy'])

from sklearn.preprocessing import StandardScaler

scaler=StandardScaler()

X_train_scaled=scaler.fit_transform(X_train)

X_test_scaled=scaler.transform(X_test)

neural_net.fit(X_train_scaled,y_train,epochs=400,batch_size=16,validation_data=(X_test_scaled,y_test))

joblib.dump(neural_net, 'injury_model.pkl')

# Commented out IPython magic to ensure Python compatibility.
# %cd DIRECTORY_NAME

y_pred_prob = neural_net.predict(X_test_scaled)
y_pred = (y_pred_prob > 0.5).astype(int)
y_pred

joblib.dump(scaler, 'scaler.pkl')

import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.metrics import classification_report
from sklearn.preprocessing import StandardScaler
from sklearn.neural_network import MLPClassifier
import joblib
import kagglehub

# Download dataset
path = kagglehub.dataset_download("mrsimple07/injury-prediction-dataset")
df = pd.read_csv(path + "/injury_data.csv")

# Data preprocessing
df['Player_Weight'] = df['Player_Weight'].round(2)
df['Player_Height'] = df['Player_Height'].round(2)
df['BMI'] = df['Player_Weight'] / (df['Player_Height'] / 100) ** 2

# Feature Engineering
df['BMI_Age_Ratio'] = df['BMI'] / df['Player_Age']
df['Prev_Injury_Age'] = df['Previous_Injuries'] / df['Player_Age']

# Drop unnecessary columns
df = df.drop(columns=["Recovery_Time", "Training_Intensity"], errors='ignore')

# Define features and target
X = df.drop('Likelihood_of_Injury', axis=1)
y = df['Likelihood_of_Injury']

# Split data
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.1, random_state=42)

# Scaling
scaler = StandardScaler()
X_train_scaled = scaler.fit_transform(X_train)
X_test_scaled = scaler.transform(X_test)

# Neural network model training
model = MLPClassifier(hidden_layer_sizes=(128, 64, 32, 5), activation='relu', solver='adam', max_iter=400, random_state=42)
model.fit(X_train_scaled, y_train)

# Predictions and evaluation
y_pred = model.predict(X_test_scaled)
print(classification_report(y_test, y_pred, target_names=["No Injury", "Injury"]))

# Save model and scaler
joblib.dump(model, 'injury_model.pkl')
joblib.dump(scaler, 'scaler.pkl')

