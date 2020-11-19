### Problem Statement :

#### Create High Availability Architecture with AWS CLI. The architecture includes -

1. Webserver configured on EC2 Instance.
2. Document Root(/var/www/html) made persistent by mounting on EBS Block Device.
3. Static objects used in code such as pictures stored in S3.
4. Setting up Content Delivery Network using CloudFront and using the origin domain as S3 bucket.
5. Finally place the Cloud Front URL on the webapp code for security and low latency.
