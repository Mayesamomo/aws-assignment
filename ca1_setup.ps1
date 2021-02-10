# script to setup resources for cloud init lab 
# Peadar Grant

$KeyPairs=(aws ec2 describe-key-pairs --filters Name=key-name,Values=LAB_KEY | ConvertFrom-Json).KeyPairs
if ( $KeyPairs.Count -ne 1 ) {
   throw "must be exactly 1 key pair named LAB_KEY (found $($KeyPairs.Count))."
}
Write-Host "KeyPair: $($KeyPairs[0].KeyPairId)"

$Vpcs=(aws ec2 describe-vpcs --filter Name=tag:Name,Values=CA_VPC | ConvertFrom-Json).Vpcs

if ( $Vpcs.Count -ge 1 ) {
    throw "found $($Vpcs.Count) VPCs named CA_VPC - rename/delete"
}

$Vpc = (aws ec2 create-vpc --cidr-block 10.0.0.0/16 | ConvertFrom-Json ).Vpc
Write-Host "VPC: $($Vpc.VpcId)"
aws ec2 create-tags --resources $Vpc.VpcId --tags Key=Name,Value=CA_VPC

$Subnet = (aws ec2 create-subnet --vpc-id $Vpc.VpcId --cidr-block 10.0.1.0/24 | ConvertFrom-Json).Subnet
Write-Host "Subnet: $($Subnet.SubnetId)"
aws ec2 create-tags --resources $Subnet.SubnetId --tags Key=Name,Value=CA_SN

# turn on auto public IP assignment for instances in this subnet
aws ec2 modify-subnet-attribute --subnet-id $Subnet.SubnetId --map-public-ip-on-launch

# internet gateway
$IGW = (aws ec2 create-internet-gateway | ConvertFrom-Json).InternetGateway
Write-Host "IGW: $($IGW.InternetGatewayId)"
aws ec2 create-tags --resources $IGW.InternetGatewayId --tags Key=Name,Value=CA_IGW
aws ec2 attach-internet-gateway --vpc-id $Vpc.VpcId --internet-gateway-id $IGW.InternetGatewayId

# route table location & renaming
$RT = (aws ec2 describe-route-tables --filters Name=vpc-id,Values=$($Vpc.VpcId) | ConvertFrom-Json).RouteTables[0]
Write-Host "Route Table: $($RT.RouteTableId)"
aws ec2 create-tags --resources $RT.RouteTableId --tags Key=Name,Value=CA_RTB

# standard route
aws ec2 create-route --route-table-id $RT.RouteTableId --gateway-id $IGW.InternetGatewayId --destination-cidr-block 0.0.0.0/0

# security group
$SGId=(aws ec2 create-security-group --group-name 'CA_SG' --description 'ca-security-group' --vpc-id $Vpc.VpcId | ConvertFrom-Json).GroupId
Write-Host "Security Group: $($SGId)"

# allow SSH inbound
aws ec2 authorize-security-group-ingress --group-id $SGId --protocol tcp --port 22 --cidr 0.0.0.0/0
Write-Host "Modified security group to permit SSH [port 22] access"

# allow RDP inbound
aws ec2 authorize-security-group-ingress --group-id $SGId --protocol tcp --port 3389 --cidr 0.0.0.0/0
Write-Host "Modified security group to permit RDP [port 3389] access"

# allow HTTP inbound
aws ec2 authorize-security-group-ingress --group-id $SGId --protocol tcp --port 80 --cidr 0.0.0.0/0
Write-Host "Modified security group to permit HTTP [port 80] access"
$SubnetId =$Subnet.SubnetId
$ImageId = (aws ssm get-parameter --name /aws/service/eks/optimized-ami/1.18/amazon-linux-2-gpu/recommended/image_id --region eu-west-1 --query "Parameter.Value" --output json | ConvertFrom-Json)
#create an Ec2 Instance.
aws ec2 run-instances  --subnet-id $Subnet.SubnetId --image-id $ImageId --instance-type t2.micro --key-name $KeyPairs[0].KeyName  --security-group-ids $SGId --user-data file://userdata.sh
#aws ec2 run-instances  --subnet-id $Subnet --image-id $(aws ssm get-parameters --names /aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2 --query 'Parameters[0].[Value]' --output Json) --count 1  --instance-type t2.micro --key-name $KeyPairs[0].KeyName  --security-group-ids $SG --user-data file://userdata.sh
#capture instance Id
$InstanceId = (aws ec2 describe-instances --query 'Reservations[0].Instances[0].InstanceId')
Write-Host "Instance Id: $($InstanceId)"
if ( $InstanceId.Count -ne 1 ) {
   throw "Instance not created"
}
Write-Host "Ec2 Instance created successfully"

#  capture the JSON and convert to PowerShell objects.
$reservations = $(aws ec2 describe-instances --instance-id $InstanceId | ConvertFrom-Json)
$publicIp = $reservations.Reservations.Instances[0].NetworkInterfaces[0].Association.publicIp
Write-Host "Ip Address: $($publicIp)"
#aws ec2 modify-instance-attribute --instance-id i-01c653d382a855218 --attribute userData --value file://userdata.sh
ssh ec2-user@$publicIp
