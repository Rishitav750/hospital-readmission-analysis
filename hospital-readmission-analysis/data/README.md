# Data

This uses the Diabetes 130-US Hospitals (1999-2008) dataset from the UCI ML Repository.

- Link: https://archive.ics.uci.edu/dataset/296/diabetes+130-us+hospitals+for+years+1999-2008
- ~101,766 inpatient diabetic encounters, 130 hospitals
- File you need here: `diabetic_data.csv`

The CSV is ~19MB so I didn't commit it (it's in `.gitignore`). Grab it one of two ways:

Download the zip from the UCI link and drop `diabetic_data.csv` in this folder.

Or pull it in Python:

```python
from ucimlrepo import fetch_ucirepo
import pandas as pd

ds = fetch_ucirepo(id=296)
df = pd.concat([ds.data.features, ds.data.targets], axis=1)
df.to_csv("diabetic_data.csv", index=False)
```

Once it's here, run the notebooks in `../notebooks/`.
