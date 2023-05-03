import json
import urllib.parse
import boto3
import botocore

print('function is Loading ')

s3 = boto3.client('s3')

def lambda_handler(event, context):
    
    print("Received event: " + json.dumps(event, indent=2))

    # Get the object from the event and show its content type
    bucket = event['Records'][0]['s3']['bucket']['name']
    key = urllib.parse.unquote_plus(event['Records'][0]['s3']['object']['key'], encoding='utf-8')
    
    if not key.endswith('.csv'):
        return
    
    response = s3.get_object(Bucket=bucket, Key=key)
    text = response['Body'].read().decode('utf-8')
    text = text.split("\n")  # our elements are stacked vertically so we're using newlines
    
    emailBody = ""
    addresses = []
    subject = ""
    atAddresses = 0
    for i in range(len(text)):
        if i == 0:
            subject = text[0]
        elif "##END OF EMAIL##" in text[i]:
            atAddresses = 1
        elif not atAddresses:
            emailBody += text[i] + "\n"
        elif atAddresses:
            addresses.append(text[i])
            
    print(f"Subject: {subject}")
    print(f"Body: {emailBody}")
    print(f"Addresses: {addresses}")
        # Code adapted from AWS documentation.
    # This address must be verified with Amazon SES.
    SENDER = "K Sai Vivek <saivivek7228@gmail.com>"
    RECIPIENT = ""
    
    # Amazon SES region
    AWS_REGION = "us-east-1"  # If this is not set properly the function will fail to connect
    
    # The character encoding for the email.
    CHARSET = "UTF-8"
    # Create a new SES resource and specify a region.
    client = boto3.client('ses',region_name=AWS_REGION)
    
    # destinations = ','.join(addresses)
    # Try to send the email.
    try:
        for addr in addresses:
            response = client.send_email(
                Destination={
                    'ToAddresses': [
                        addr,
                    ],
                },
                Message={
                    'Body': {
                        'Text': {
                            'Charset': CHARSET,
                            'Data': emailBody,
                        },
                    },
                    'Subject': {
                        'Charset': CHARSET,
                        'Data': subject,
                    },
                },
                Source=SENDER,
            )
    except Exception as e:
        print(e.response['Error']['Message'])
    else:
        print("Email Sent!")
        