
import logging
import pandas as pd

from avro.schema import parse
from avro.datafile import DataFileWriter, DataFileReader
from avro.io import DatumWriter, DatumReader

def avro_to_pandas(avro_file_path: str) -> pd.DataFrame:

    logging.warning("Inside avro_to_pandas.")

    try:
        avro_reader = DataFileReader(open(avro_file_path, "rb"), DatumReader())
    except Exception as e:
        logging.error("Error creating DataFileReader")
        logging.error(e)
    
    try:
        records = [record for record in avro_reader]
    except Exception as e:
        logging.error("Error getting records.")
        logging.error(e)

    try:
        df = pd.DataFrame.from_records(records)
    except Exception as e:
        logging.error("Error converting to pandas.")
        logging.error(f"Records: {records}")
        logging.error(e)

    return df
