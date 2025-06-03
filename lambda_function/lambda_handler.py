import json

def lambda_handler(event, context):
    print(f"Received event: {json.dumps(event, indent=2)}")
    
    # Process each record in the event
    for record in event['Records']:
        bucket = record['s3']['bucket']['name']
        key = record['s3']['object']['key']
        event_name = record['eventName']
        
        print(f"File {key} in bucket {bucket} was {event_name}")
        
        # Add your custom processing logic here
        if event_name.startswith('ObjectCreated:'):
            print(f"New object created: {key}")
        elif event_name.startswith('ObjectRemoved:'):
            print(f"Object deleted: {key}")
    
    return {
        'statusCode': 200,
        'body': json.dumps('S3 event processed successfully!')
    }