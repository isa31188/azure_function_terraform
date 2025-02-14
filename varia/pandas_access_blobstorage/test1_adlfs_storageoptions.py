
import pandas as pd

storage_options = {"account_name": "oymcorepfm01devdl1", "anon": False}

url = "az://usage-optimized/Science/RND/DD/MJU_wb__CMJ/MJU_wb__CMJ.parquet"

df = pd.read_parquet(url, storage_options=storage_options)

print(df.head())
