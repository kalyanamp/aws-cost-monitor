#!/bin/sh

# uncomment the following exports if not already done from outside
#export AWS_CREDENTIAL_FILE=/home/vjames/.aws/credentials-cloudwatch
#export AWS_CLOUDWATCH_URL=http://monitoring.us-east-1.amazonaws.com/
#export AWS_CLOUDWATCH_HOME=/home/vjames/cloudwatch/CloudWatch-1.0.20.0
#export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64/jre
#export PATH=$PATH:$JAVA_HOME/bin:$AWS_CLOUDWATCH_HOME/bin
GRAPHITE_HOST=graphite.example.com # change it to your graphite server
GRAPHITE_PORT=2023

# Get the timestamp from 5 hours ago, to avoid getting > 1440 metrics (which errors).
# also, remove the +0000 from the timestamp, because the cloudwatch cli tries to enforce
# ISO 8601, but doesn't understand it.
#DATE=$(date --iso-8601=hours -d "5 hours ago" |sed s/\+.*//)
DATE=$(date --utc +%FT%TZ -d "5 hours ago")

#echo $COST

SERVICES='AmazonS3 AmazonRDS AmazonRedshift AWSDataTransfer AmazonEC2 AmazonVPC'

for service in $SERVICES; do

#COST=$(/home/charlie/cloudwatch/CloudWatch-1.0.13.4/bin/mon-get-stats EstimatedCharges --aws-credential-file ~/.ec2_credentials --namespace "AWS/Billing" --statistics Sum --dimensions "ServiceName=${service},Currency=USD" --start-time $DATE |tail -1 |awk '{print $3}')
COST=$($AWS_CLOUDWATCH_HOME/bin/mon-get-stats EstimatedCharges --namespace "AWS/Billing" --statistics Sum --dimensions "ServiceName=${service},Currency=USD" --start-time $DATE |tail -1 |awk '{print $3}')

if [ -z $COST ]; then
 echo "failed to retrieve $service metric from CloudWatch.."
 else
# echo "stats.prod.ops.billing.ec2_${service} $COST `date +%s`" |nc graphite.example.com 2023
 echo "stats.prod.ops.billing.ec2_${service} $COST `date +%s`" |nc $GRAPHITE_HOST $GRAPHITE_PORT
 fi

done

# one more time, for the sum:
#COST=$(/home/charlie/cloudwatch/CloudWatch-1.0.13.4/bin/mon-get-stats EstimatedCharges --aws-credential-file ~/.ec2_credentials --namespace "AWS/Billing" --statistics Sum --dimensions "Currency=USD" --start-time $DATE |tail -1 |awk '{print $3}')
COST=$($AWS_CLOUDWATCH_HOME/bin/mon-get-stats EstimatedCharges --namespace "AWS/Billing" --statistics Sum --dimensions "Currency=USD" --start-time $DATE |tail -1 |awk '{print $3}')

if [ -z $COST ]; then
 echo "failed to retrieve EstimatedCharges metric from CloudWatch.."
 exit 1
else
# echo "stats.prod.ops.billing.ec2_total_estimated $COST `date +%s`" |nc graphite.example.com 2023
 echo "stats.prod.ops.billing.ec2_total_estimated $COST `date +%s`" |nc $GRAPHITE_HOST $GRAPHITE_PORT
fi
