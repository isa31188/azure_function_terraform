
import os
import logging
import azure.functions as func
import pandas as pd

from azure.identity import DefaultAzureCredential
from azure.storage.blob import BlobServiceClient
from azure.core.exceptions import ResourceExistsError

from avro.schema import parse
from avro.datafile import DataFileWriter, DataFileReader
from avro.io import DatumWriter, DatumReader

def avro_to_pandas(avro_file_path: str) -> pd.DataFrame:

    avro_reader = DataFileReader(open(avro_file_path, "rb"), DatumReader())
    records = [record for record in avro_reader]
    return pd.DataFrame.from_records(records)


account_url = "https://oymdeploysandiacdl01.blob.core.windows.net"
container_name = "source"

default_credential = DefaultAzureCredential()
blob_service_client = BlobServiceClient(account_url, credential=default_credential)
container_client = blob_service_client.get_container_client(container=container_name)

def main(myblob: func.InputStream):
    
    uploaded_blob_name = myblob.name
    logging.info('Python Blob trigger function processed %s', uploaded_blob_name)

    # DOWNLOAD FILE

    # Downloading using the same prefix as in the blob store
    download_file_path = uploaded_blob_name

    logging.info("\nDownloading blob to \n\t" + download_file_path)

    with open(file=download_file_path, mode="wb") as download_file:
        download_file.write(container_client.download_blob(upload_file_path).readall())

    # PROCESS ACCORDING TO FILE FORMAT
    
    file_format = upload_file_path.split(".")[-1]
    if file_format == "csv":
        df = read_csv(download_file_path)
        logging.info(df.head())
    elif file_format == "avro":
        df = avro_to_pandas(download_file_path)
        logging.info(df.head())

