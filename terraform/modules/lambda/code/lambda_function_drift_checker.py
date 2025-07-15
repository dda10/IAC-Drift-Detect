# lambda_function_drift_checker.py
import json
import boto3
import os
from datetime import datetime, timedelta

s3 = boto3.client("s3")
cloudtrail = boto3.client("cloudtrail")
bedrock_runtime = boto3.client("bedrock-runtime")

def lambda_handler(event, context):
    bucket = os.environ.get("TFSTATE_BUCKET")
    key = os.environ.get("TFSTATE_KEY", "terraform.tfstate")

    # Load Terraform state from S3
    state_obj = s3.get_object(Bucket=bucket, Key=key)
    tfstate = json.load(state_obj["Body"])

    # Parse managed resource IDs
    managed_ids = set()
    for r in tfstate.get("resources", []):
        for i in r.get("instances", []):
            attrs = i.get("attributes", {})
            rid = attrs.get("id")
            if rid:
                managed_ids.add(rid)

    # Lookup recent CloudTrail events
    now = datetime.utcnow()
    start_time = now - timedelta(minutes=5)

    response = cloudtrail.lookup_events(
        StartTime=start_time,
        EndTime=now,
        MaxResults=50
    )

    new_unmanaged = []
    deleted_resources = []

    for event in response.get("Events", []):
        evt = json.loads(event["CloudTrailEvent"])
        username = evt.get("userIdentity", {}).get("arn", "unknown")
        for res in event.get("Resources", []):
            rid = res.get("ResourceName")
            if not rid:
                continue

            if "Create" in event["EventName"] or event["EventName"] in ["RunInstances", "CreateBucket"]:
                if rid not in managed_ids:
                    new_unmanaged.append({
                        "resource_id": rid,
                        "event": event["EventName"],
                        "user": username,
                        "time": str(event["EventTime"])
                    })
            elif "Delete" in event["EventName"]:
                if rid in managed_ids:
                    deleted_resources.append({
                        "resource_id": rid,
                        "event": event["EventName"],
                        "user": username,
                        "time": str(event["EventTime"])
                    })

    result = {
        "unmanaged_created_resources": new_unmanaged,
        "deleted_managed_resources": deleted_resources
    }

    print(json.dumps(result, indent=2))
    return result