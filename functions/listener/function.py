import logging
import azure.functions as func


def main(event: func.EventHubEvent):
    logging.info(f'Function triggered to process a message: {event.get_body().decode()}')
    logging.info(f'  EnqueuedTimeUtc = {event.enqueued_time}')
    logging.info(f'  SequenceNumber = {event.sequence_number}')
    logging.info(f'  Offset = {event.offset}')

    # example: Function triggered to process a message: Message created at: 20-02-27 1  :39:40.0719
    # Zurich time 17:...
    # Metadata
    for key in event.metadata:
        logging.info(f'Metadata: {key} = {event.metadata[key]}')