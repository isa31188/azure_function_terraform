import logging
import azure.functions as func


def main(event: func.EventHubEvent):
    logging.info(f'Function triggered to process a message: {event.get_body().decode()}')
    logging.info(f'  EnqueuedTimeUtc = {event.enqueued_time}')
    logging.info(f'  SequenceNumber = {event.sequence_number}')
    logging.info(f'  Offset = {event.offset}')

    # Metadata
    for key in event.metadata:
        logging.info(f'Metadata: {key} = {event.metadata[key]}')

# Example of a full logging output:
#
# Function triggered to process a message: Message created at: 2025-02-19 16:25:40.002711
# EnqueuedTimeUtc = 2025-02-19 16:25:39.992000
# SequenceNumber = 256
# Offset = 29696
# Metadata: SequenceNumber = 256
# Metadata: EnqueuedTimeUtc = 2025-02-19T16:25:39.992
# Metadata: SystemProperties = {'x-opt-sequence-number-epoch': -1, 'x-opt-sequence-number': 256, 'x-opt-offset': 29696, 'x-opt-enqueued-time': '2025-02-19T16:25:39.992+00:00', 'SequenceNumber': 256, 'Offset': 29696, 'PartitionKey': None, 'EnqueuedTimeUtc': '2025-02-19T16:25:39.992'}
# Metadata: Properties = {}
# Metadata: PartitionContext = {'FullyQualifiedNamespace': 'oym-sand-testeventhub-eh-namespace.servicebus.windows.net', 'EventHubName': 'events', 'ConsumerGroup': '$Default', 'PartitionId': '1'}
# Metadata: Offset = 29696

# Note that SequenceNumber's do not come ordered:
# 2/19/2025, 4:25:25.026 PM SequenceNumber = 253
# 2/19/2025, 4:25:30.036 PM SequenceNumber = 255
# 2/19/2025, 4:25:35.030 PM SequenceNumber = 254