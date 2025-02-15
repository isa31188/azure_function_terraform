
# Requirements:
# pandas
# avro
# azure-storage-blob
# azure-identity
# python-snappy

from azure.identity import DefaultAzureCredential
from azure.storage.blob import BlobServiceClient

import pandas as pd

from avro.datafile import DataFileReader
from avro.io import DatumReader
from io import BytesIO

storage_account = "oymcorepfm01devdl1"
container = "raw"
blob = "DataEvents/SCT/N_02_A/SQJ/Raw/046f89d7-7af4-4845-9836-d628c7f9a0fd__TSV1.avro"


# Acquire a credential object
credential = DefaultAzureCredential()

service_client = BlobServiceClient(account_url=f"https://{storage_account}.blob.core.windows.net",
                                   credential=credential)

container_client = service_client.get_container_client(container)
blob_client = container_client.get_blob_client(blob)
streamdownloader = blob_client.download_blob()

stream = BytesIO()
streamdownloader.readinto(stream)

avro_reader = DataFileReader(stream, DatumReader())

records = [record for record in avro_reader]

df = pd.DataFrame.from_records(records)

print(df.head())
