import base64
import json
import os
import logging
import requests
from flask import Flask, request

app = Flask(__name__)

GITHUB_API_TOKEN = os.environ.get('GITHUB_API_TOKEN')
GITHUB_REPO = os.environ.get('GITHUB_REPO')
GITHUB_OWNER = os.environ.get('GITHUB_OWNER')

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def create_github_issue(data):
    issue_title = f"Alert: {data['incident']['incident_id']}"
    issue_body = data['incident']['summary']

    logger.info(f"Creating issue with title: {issue_title} body: {issue_body}")

    response = requests.post(
        f"https://api.github.com/repos/{GITHUB_OWNER}/{GITHUB_REPO}/issues",
        headers={
            "Authorization": f"token {GITHUB_API_TOKEN}",
            "Accept": "application/vnd.github.v3+json",
        },
        json={
            "title": issue_title,
            "body": issue_body,
        },
    )

    if response.status_code == 201:
        logger.info("Issue created successfully")
        return "Issue created successfully", 201
    else:
        logger.error(f"Failed to create issue: {response.content}")
        return f"Failed to create issue: {response.content}", response.status_code

@app.route('/', methods=['POST'])
def main(d, context): #Need to receive arguments
    envelope = request.get_json()
    
    if not envelope:
        logger.error("No envelope received")
        return "Bad Request", 400
    
    logger.info(f"envelope: {envelope}")

    pubsub_data = envelope.get('data', {})

    if not pubsub_data:
        logger.error(f"No outside data received: ")
        return "Bad Request", 400

    try:
        data_base64 = pubsub_data.get('data', '')
        if not data_base64:
            raise ValueError("No data field in outside data")
        
        data = base64.b64decode(data_base64.encode('utf-8')).decode('utf-8')
        logger.info(f"Decoded data: {data}")
        data = json.loads(data)
        
        logger.info(f"Received data: {data}")
    except Exception as e:
        logger.error(f"Error processing message: {e}")
        return "Bad Request", 400
    
    return create_github_issue(data)

if __name__ == "__main__":
    app.run()