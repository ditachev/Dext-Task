# Dext-Task  
## How to run  

In order to run the terraform configuration you need to supply the AWS_ACCESS_KEY and AWS_SECRET_KEY_ID values that are specific to your own account. You can export those to environment variables or create a file which should be located at ~/.aws/credentials.

## Commands to run  

Destroy infrastructure: *terraform destroy*  
Apply infrastructure: *terraform apply*  

You must supply a database username and password of choice, if you want to apply the configuration. The are 2 ways to go about this:
    1. add the -var option to the command(e.g. *terraform apply -var db_username=username -var db_password=password* )
    2. populate a *terraform.tfvars* file with the values like so:  
    db_username=username  
    db_password=password  
                 
                 
This is necessary to keep the configuration secure and not expose these sensitive values in plain text.                                                     


You can optionally supply the option "-auto-approve" to either of the commands to not get prompted for confirmation.

## Architecture  

The WordPress application runs on 2 EC2 instances which are sat behind a load balancer. This load balancer is exposed to the internet and receives traffic which it evenly distributes to the 2 instances.  
The applications communicate with a single MySQL RDS instance.

## VPC configuration  

2 public subnets to host the load balancer  

2 private subnets to host the web servers(due to problems while developing the solution the web servers are currently in the public subnets)  

2 database subnets which create a database subnet group that the RDS instance uses to create multi-AZ database  

There is an internet gateway attached to the VPC to allow communication with the internet.
