import os
import requests
from flask import Flask, request, abort

app = Flask(__name__)

GITHUB_API_TOKEN = os.environ.get('GITHUB_API_TOKEN')
GITHUB_REPO = os.environ.get('GITHUB_REPO')
GITHUB_OWNER = os.environ.get('GITHUB_OWNER')

@app.route('/', methods=['POST'])
def create_github_issue():
    
    data = request.get_json()
    issue_title = f"Alert: {data['incident']['incident_id']}"
    issue_body = data['incident']['summary']

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
        return "Issue created successfully", 201
    else:
        return f"Failed to create issue: {response.content}", response.status_code

if __name__ == "__main__":
    app.run()