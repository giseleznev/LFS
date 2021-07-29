import json
import datetime
import boto3
import os

def lambda_handler(event, context):
    f_prepare = open('prepare.json', 'r')
    msg_prepare = f_prepare.read()
    msg_prepare = json.loads(msg_prepare)
    f_example = open('example.json', 'r')
    msg_example = f_example.read()
    s3_client = boto3.client('s3')
    for i in event['objects']:
        msg_prepare['objects'].append(dict(json.loads(msg_example)['objects'][0]))
        msg_prepare['objects'][-1]['oid'] = i['oid']
        msg_prepare['objects'][-1]['actions']['download']['href'] = s3_client.generate_presigned_url('get_object', Params = {'Bucket': os.environ['bucket_name'], 'Key': i['oid']}, ExpiresIn = 3600)
        msg_prepare['objects'][-1]['size'] = i['size']
    return msg_prepare


