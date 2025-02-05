import logging

import azure.functions as func
import azurefunctions.extensions.bindings.blob as blob

# Just for testing correct application of requirements.txt
from seaborn import load_dataset

app = func.FunctionApp(http_auth_level=func.AuthLevel.ANONYMOUS)

@app.function_name(name="BlobTrigger")
@app.blob_trigger(arg_name="client", path="source/{name}.jpg", connection="AzureWebJobsStorage")
def blob_trigger(client: blob.BlobClient):
    logging.info(
        f"Python blob trigger function processed blob \n"
        f"Properties: {client.get_blob_properties()}\n"
        f"Blob content head: {client.download_blob().read(size=1)}"
    )