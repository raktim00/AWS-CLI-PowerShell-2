$key_name = "MyKey"
$sg_name = "WebSG"
$image_id = "ami-026669ec456129a70"
$instance_type = "t2.micro"
$instance_count = 1
$subnet_id = "subnet-6dfdc705"
$az = "ap-south-1a"
$region = "ap-south-1"
$volume_size = 1
$volume_type = "gp2"
$bucket_name = "raktim123"
$object_name = "Raktim.JPG"

aws ec2 create-key-pair --key-name "$key_name" --query 'KeyMaterial' --output text | out-file -encoding ascii -filepath "$key_name.pem"

$sg_id = aws ec2 create-security-group --group-name "$sg_name" --description "Security group allowing SSH & HTTP" |  jq ".GroupId"

aws ec2 authorize-security-group-ingress --group-id "$sg_id" --protocol tcp --port 22 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id "$sg_id" --protocol tcp --port 80 --cidr 0.0.0.0/0

$instance_id = aws ec2 run-instances --image-id "$image_id" --instance-type "$instance_type" --count "$instance_count"  --subnet-id "$subnet_id" --security-group-ids "$sg_id" --key-name "$key_name" | jq ".Instances[0].InstanceId"

$volume_id = aws ec2 create-volume --availability-zone "$az" --size "$volume_size" --volume-type "$volume_type" | jq ".VolumeId"

Start-Sleep 20

aws ec2 attach-volume --volume-id "$volume_id" --instance-id "$instance_id" --device /dev/xvdh

aws s3api create-bucket --bucket "$bucket_name" --region "$region" --create-bucket-configuration LocationConstraint="$region"

aws s3api put-object --acl public-read-write --bucket "$bucket_name" --key "$object_name" --body "$object_name"

$domain_name = aws cloudfront create-distribution --origin-domain-name "$bucket_name.s3.$region.amazonaws.com" --query Distribution.DomainName --output text

$public_dns = aws ec2 describe-instances --instance-ids "$instance_id" | jq ".Reservations[0].Instances[0].PublicDnsName"

ssh -i "$key_name.pem" "ec2-user@$public_dns" sudo yum install httpd -y
ssh -i "$key_name.pem" "ec2-user@$public_dns" sudo fdisk /dev/xvdh
ssh -i "$key_name.pem" "ec2-user@$public_dns" sudo mkfs.ext4 /dev/xvdh1
ssh -i "$key_name.pem" "ec2-user@$public_dns" sudo mount /dev/xvdh1 /var/www/html

Write-Output "<body> This is a picture of Raktim = > <img src=https://$domain_name/$object_name alt='loading...' width='250' height='250'></body>" > test.html

scp -i "$key_name.pem" test.html ec2-user@"$public_dns":~
ssh -i "$key_name.pem" "ec2-user@$public_dns" sudo cp test.html /var/www/html
ssh -i "$key_name.pem" "ec2-user@$public_dns" sudo service httpd start