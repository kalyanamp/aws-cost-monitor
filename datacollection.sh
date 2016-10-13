#!/bin/sh

#
# Uncomment the following exports if not already done from outside
#
#export AWS_CREDENTIAL_FILE=/home/vjames/.aws/credentials-cloudwatch
#export AWS_CLOUDWATCH_URL=http://monitoring.us-east-1.amazonaws.com/
#export AWS_CLOUDWATCH_HOME=/home/vjames/cloudwatch/CloudWatch-1.0.20.0
#export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64/jre
#export PATH=$PATH:$JAVA_HOME/bin:$AWS_CLOUDWATCH_HOME/bin
GRAPHITE_HOST=graphite.example.com # change it to your graphite server
GRAPHITE_PORT=2023

# Get the timestamp in ISO 8601 from 5 hours ago, to avoid getting > 1440 metrics (which errors).
DATE=$(date --utc +%FT%TZ -d "5 hours ago")

# Add/Remove services as needed
SERVICES='AmazonS3 AmazonRDS AmazonRedshift AWSDataTransfer AmazonEC2 AmazonVPC'

for service in $SERVICES; do

COST=$($AWS_CLOUDWATCH_HOME/bin/mon-get-stats EstimatedCharges --namespace "AWS/Billing" --statistics Sum --dimensions "ServiceName=${service},Currency=USD" --start-time $DATE |tail -1 |awk '{print $3}')

if [ -z $COST ]; then
 echo "failed to retrieve $service metric from CloudWatch.."
 else
 echo "stats.prod.ops.billing.ec2_${service} $COST `date +%s`" |nc $GRAPHITE_HOST $GRAPHITE_PORT
 fi

done

# one more time, for the sum:
COST=$($AWS_CLOUDWATCH_HOME/bin/mon-get-stats EstimatedCharges --namespace "AWS/Billing" --statistics Sum --dimensions "Currency=USD" --start-time $DATE |tail -1 |awk '{print $3}')

if [ -z $COST ]; then
 echo "failed to retrieve EstimatedCharges metric from CloudWatch.."
 exit 1
else
 echo "stats.prod.ops.billing.ec2_total_estimated $COST `date +%s`" |nc $GRAPHITE_HOST $GRAPHITE_PORT
fi
