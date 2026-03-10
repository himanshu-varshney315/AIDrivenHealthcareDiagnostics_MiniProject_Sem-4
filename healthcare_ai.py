# Install dependencies before running:
# pip install pandas scikit-learn shap transformers torch

import pandas as pd
import shap
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from transformers import pipeline
# ----------------------------
# here we load data set from frontend 
# ----------------------------
data = pd.read_csv("healthcare_dataset - Sheet1.csv")

X = data.drop("disease", axis=1)
y = data["disease"]

X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2)

# ----------------------------
#  here we Train Model by using Random forest 
# ----------------------------
model = RandomForestClassifier()
model.fit(X_train, y_train)
print("Model Accuracy:", model.score(X_test, y_test))

# ----------------------------
# here we Take Input From User only for now after creating data we use upper data
# ----------------------------

print("\nEnter symptoms (1 = Yes, 0 = No)\n")

fever = int(input("Do you have fever? (1/0): "))
cough = int(input("Do you have cough? (1/0): "))
fatigue = int(input("Do you feel fatigue? (1/0): "))
headache = int(input("Do you have headache? (1/0): "))
patient_data = [[fever, cough, fatigue, headache]]

# ----------------------------
# here from patient_data we Predict Disease 
# ----------------------------

prediction = model.predict(patient_data)
print("\nPredicted Disease:", prediction[0])

# ----------------------------
# herre we use SHAP AI to explain 
# ----------------------------

explainer = shap.TreeExplainer(model)
shap_values = explainer.shap_values(X_test)

print("\nGenerating explanation graph...")
shap.summary_plot(shap_values, X_test)

# ----------------------------
#  here the ai explation about the Disease 
# ----------------------------

generator = pipeline("text-generation", model="gpt2")
prompt = f"""
Patient symptoms:
Fever: {fever}
Cough: {cough}
Fatigue: {fatigue}
Headache: {headache}
Predicted Disease: {prediction[0]}
Explain the diagnosis and give precautions.
"""

result = generator(prompt, max_length=120)

print("\nAI Medical Advice:\n")
print(result[0]['generated_text'])
