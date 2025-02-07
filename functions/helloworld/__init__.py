import logging
import azure.functions as func

# Just for verifying correct build.
from seaborn import load_dataset

def main(myblob: func.InputStream, inputblob: bytes, outputblob: func.Out[bytes]):
    logging.info('Python Blob trigger function processed %s', myblob.name)
    logging.info(f'Python Queue trigger function processed {len(inputblob)} bytes')
    outputblob.set(inputblob)