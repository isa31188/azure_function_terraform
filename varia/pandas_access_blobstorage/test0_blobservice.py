from azure.identity import DefaultAzureCredential
from azure.storage.blob import BlobServiceClient


storage_account = "oymcorepfm01devdl1"
container = "raw"
blob = ""


# Acquire a credential object
credential = DefaultAzureCredential()

service_client = BlobServiceClient(account_url=f"https://{storage_account}.blob.core.windows.net",
                                   credential=credential)

container_client = service_client.get_container_client(container)

blobs = container_client.list_blobs()

for blob in blobs:
    print(blob.name)
