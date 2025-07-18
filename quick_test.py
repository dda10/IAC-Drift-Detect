#!/usr/bin/env python3
import boto3
import json
import time

def test_drift_detection():
    print("Testing drift detection system...")
    
    # 1. Create test resource
    print("\nCreating test IAM user...")
    iam = boto3.client('iam')
    try:
        iam.create_user(UserName='test-drift-user')
        print("✅ Test user created")
    except Exception as e:
        print(f"❌ Error: {e}")
    
    # 2. Wait a moment
    print("\nWaiting for changes to propagate...")
    time.sleep(2)
    
    # 3. Invoke Lambda
    print("\nInvoking drift detection Lambda...")
    lambda_client = boto3.client('lambda')
    try:
        response = lambda_client.invoke(
            FunctionName='iac-drift-checker',
            InvocationType='RequestResponse',
            Payload=json.dumps({"test": "manual"})
        )
        
        payload = json.loads(response['Payload'].read())
        print("\nDrift detection result:")
        print(json.dumps(payload, indent=2))
        
        if payload.get('drift_detected'):
            print("✅ Drift detected successfully!")
        else:
            print("❌ No drift detected")
    except Exception as e:
        print(f"❌ Error: {e}")
    
    # 4. Clean up
    print("\nCleaning up test resources...")
    try:
        iam.delete_user(UserName='test-drift-user')
        print("✅ Test user deleted")
    except Exception as e:
        print(f"❌ Error: {e}")
    
    print("\nTest complete!")

if __name__ == "__main__":
    test_drift_detection()