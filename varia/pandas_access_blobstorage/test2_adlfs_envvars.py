
import pandas as pd
import os

os.environ["AZURE_STORAGE_ANON"] = "false"
os.environ["AZURE_STORAGE_ACCOUNT_NAME"] = "oymcorepfm01devdl1"

url = "az://usage-optimized/Science/RND/DD/MJU_wb__CMJ/MJU_wb__CMJ.parquet"

df = pd.read_parquet(url)

print(df.head())
