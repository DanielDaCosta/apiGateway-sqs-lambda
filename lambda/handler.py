import json


def lambda_handler(event, context):

    response = {}
    print(event)

    # Response Status
    statusCode = 200
    response["statusCode"] = statusCode
    response["body"] = json.dumps(event)

    return response
