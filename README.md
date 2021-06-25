# aws-vpc

Cookie-cutter VPC blueprint, setup as per AWS best practice - https://docs.aws.amazon.com/quickstart/latest/vpc/images/quickstart-vpc-design-fullscreen.png

Deploys 3x Private and 3x Public subnets with Internet Egress services using eu-west-2 (London) spanning subnets across 3 Availability Zones. 

To deploy: 

Edit the backend config to store state somewhere other than Terraform Cloud (unless you'd like to use it, in which case create a workspace that matches the backend definition in the code.)

```
terraform login (if using TF cloud)
terraform init
terraform plan
terraform apply
```