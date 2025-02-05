import azure.functions as func
import json


def main(req: func.HttpRequest, context: func.Context) -> func.HttpResponse:
    return func.HttpResponse(body=json.dumps({"msg": "Hello World!"}))