
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

    try:
        avro_reader = DataFileReader(open(avro_file_path, "rb"), DatumReader())
    except Exception as e:
        logging.error("Error creating DataFileReader")
        logging.error(e)
    
    records = [record for record in avro_reader]

    try:
        df = pd.DataFrame.from_records(records)
    except Exception as e:
        logging.error("Error converting to pandas.")
        logging.error(f"Records: {records}")
        logging.error(e)

    return df


account_url = "https://oymdeploysandiacdl01.blob.core.windows.net"
container_name = "source"

default_credential = DefaultAzureCredential()
blob_service_client = BlobServiceClient(account_url, credential=default_credential)
container_client = blob_service_client.get_container_client(container=container_name)

def main(myblob: func.InputStream):
    
    blob_path_wcontainer = myblob.name
    blob_path = "/".join(blob_path_wcontainer.split("/")[1:])
    logging.warning('Python Blob trigger function processed %s', blob_path)

    # DOWNLOAD FILE

    # Downloading to tmp, otherwise, the function filesystem is read-only:
    # https://stackoverflow.com/questions/63318567/azure-function-exception-oserror-errno-30-read-only-file-system
    file_name = blob_path.split("/")[-1]
    download_file_path = f'/tmp/{file_name}'
    logging.warning("\nDownloading blob to \n\t" + download_file_path)

    try:
        with open(file=download_file_path, mode="wb") as download_file:
            download_file.write(container_client.download_blob(blob_path).readall())

    except Exception as e:
        logging.error("Error downloading blob.")
        logging.error(e)

    logging.warning("Blob successfully downloaded.")

    # PROCESS ACCORDING TO FILE FORMAT
    
    file_format = download_file_path.split(".")[-1]
    if file_format == "csv":
        logging.warning("Reading as csv.")
        try:
            read_func = pd.read_csv
        except Exception as e:
            logging.error("Error getting pd.read_csv")
            logging.error(e)
    elif file_format == "avro":
        logging.warning("Reading as avro.")
        try:
            read_func = avro_to_pandas
        except Exception as e:
            logging.error("Error getting avro_to_pandas")
            logging.error(e)

    try:
        df = read_func(download_file_path)
        logging.warning(df.head())
    except Exception as E:
        logging.error("Error reading to pandas.")
        logging.error(e)

    # DELETING BLOB

    logging.warning("Deleting blob.")
    try:
        blob_client = blob_service_client.get_blob_client(container=container_name, blob=blob_path)
        blob_client.delete_blob(delete_snapshots="include")
    except Exception as e:
        logging.error("Error deleting blob.")
        logging.error(e)
