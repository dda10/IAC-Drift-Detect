import json
import boto3
import os
from datetime import datetime

def lambda_handler(event, context):
    """Analyze drift reports using Amazon Bedrock"""
    
    # Initialize Bedrock client
    bedrock = boto3.client('bedrock-runtime')
    model_id = os.environ.get('MODEL_ID', 'anthropic.claude-3-sonnet-20240229-v1:0')
    
    # Extract drift report from event
    drift_report = event.get('drift_report', '{}')
    if isinstance(drift_report, dict):
        drift_report = json.dumps(drift_report)
    
    # Create prompt for Bedrock
    prompt = f"""
You are an Infrastructure Drift Analyzer. Analyze this infrastructure drift report and provide:

1. SEVERITY ASSESSMENT (Critical/High/Medium/Low)
2. IMPACT ANALYSIS
3. ROOT CAUSE ANALYSIS
4. REMEDIATION STEPS
5. PREVENTION RECOMMENDATIONS

Drift Report:
{drift_report}

Format your response as a structured report with clear sections.
"""
    
    try:
        # Call Bedrock
        response = bedrock.invoke_model(
            modelId=model_id,
            body=json.dumps({
                "anthropic_version": "bedrock-2023-05-31",
                "max_tokens": 1000,
                "messages": [
                    {
                        "role": "user",
                        "content": prompt
                    }
                ]
            })
        )
        
        # Parse response
        result = json.loads(response['body'].read())
        analysis = result['content'][0]['text']
        
        return {
            'statusCode': 200,
            'body': {
                'analysis': analysis,
                'model_used': model_id
            }
        }
    except Exception as e:
        print(f"Error calling Bedrock: {str(e)}")
        return {
            'statusCode': 500,
            'body': {
                'error': str(e)
            }
        }