# Reader App Infrastructure with Terraform on AWS

This project provisions the cloud infrastructure for the **Reader App** using Terraform and AWS.
It leverages **Auto Scaling Groups, Launch Templates, Security Groups, and Load Balancers** to ensure scalability and high availability.
The application connects to a **Supabase database** instead of AWS RDS.

## Project Structure

```
.
├── main.tf                # Main entrypoint (providers, backend config)
├── vpc.tf                 # VPC, subnets, and networking
├── security_groups.tf     # Security groups for app and bastion
├── alb.tf                 # Application Load Balancer and target group
├── asg.tf                 # Auto Scaling Group and Launch Template
├── variables.tf           # Input variables
├── outputs.tf             # Key outputs (ALB DNS, etc.)
├── user-data.sh           # EC2 bootstrap script for app deployment
└── terraform.tfvars       # Variable values (gitignored if sensitive)
```
## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/downloads) `>= 1.3`
- AWS CLI configured with appropriate credentials
- A Supabase instance with connection string ready
- An existing SSH key pair in AWS (to access Bastion host)

## Steps to Deploy

1. **Clone the repository**
   ```bash
   git clone https://github.com/Masterpitan/reader.git
   git clone https://github.com/Masterpitan/practical_devops.git
   cd practical_devops/three_tier_architecture
````

2. **Initialize Terraform**

   ```bash
   terraform init
   ```

3. **Review and update variables**
   Edit `terraform.tfvars`:

   ```hcl
   env              = "dev"
   region           = "us-east-1"
   instance_type    = "t3.micro"
   key_pair_name    = "my-keypair"
   vpc_cidr         = "10.0.0.0/16"
   public_subnets   = ["10.0.1.0/24"]
   private_subnets  = ["10.0.2.0/24"]
   supabase_url     = "postgresql://<supabase-connection-string>"
   ```

5. **Plan resources**

   ```bash
   terraform plan
   ```

6. **Apply infrastructure**

   ```bash
   terraform apply
   ```

7. **Get ALB DNS Name**
   After apply, Terraform outputs the ALB DNS name. Access your app in the browser:

## User Data (EC2 Bootstrap)

Each EC2 instance in the Auto Scaling Group runs `user-data.sh` on startup.
This script:

* Updates packages
* Installs Node.js, Git, Nginx, and PM2
* Clones the Reader App repo from GitHub
* Installs dependencies for server and client
* Configures environment variables (including Supabase DB connection)
* Runs Prisma migrations and seeds
* Starts server and client via PM2
* Configures Nginx as a reverse proxy for API and client


## Cleanup

To tear down the infrastructure:

```bash
terraform destroy
```

## Notes

* Supabase is used for database needs. No RDS instance is provisioned.
* Each AWS service (VPC, SG, ALB, ASG, etc.) is defined in a **separate Terraform file** for clarity.
* EC2 instances are configured entirely through the `user-data.sh` script.

## Outputs

* **Application Load Balancer DNS** → Entry point for the Reader App
* **Bastion Host Public IP** (if provisioned) → For SSH into private EC2 instances
