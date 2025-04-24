import pandas as pd
import numpy as np

def generate_fatigue(speed, strength, stamina):
    weighted_score = (0.3 * speed + 0.3 * strength + 0.4 * stamina) / 10
    fatigue = 100 * (1 - weighted_score)
    fatigue += np.random.normal(0, 5) 
    return max(0, min(100, round(fatigue, 2)))

np.random.seed(42)
rows = []
for _ in range(1000):
    speed = np.random.randint(1, 11)
    strength = np.random.randint(1, 11)
    stamina = np.random.randint(1, 11)
    fatigue = generate_fatigue(speed, strength, stamina)
    rows.append([speed, strength, stamina, fatigue])

# Save to CSV
df = pd.DataFrame(rows, columns=['Speed', 'Strength', 'Stamina', 'Fatigue'])
df.to_csv('synthetic_fatigue_data.csv', index=False)
