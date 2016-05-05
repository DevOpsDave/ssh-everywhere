group=$1
region='us-east-1'
if [ $# -eq 2 ] ; then
  region=$2
fi

#echo $group
#echo $region

aws ec2 describe-instances --region $region --filter "Name=group-name,Values=$group" --query 'Reservations[*].Instances[*].[Tags[?Key==`Name`]]' --output text | sort | awk {' print $2 '}
