# Setup Guide: Java Application Deployment with Containerization, ELB, and CI/CD

## Prerequisites

- Machine has ssh agent running connected to github for ssh cloning.
- AWS account with admin or sufficient IAM permissions
- [Install the AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html)
- [Install Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
- [Install Docker](https://docs.docker.com/get-docker/)
- [Install Git](https://git-scm.com/downloads)
- Java 17 runtime (`java -version`)

---

## 1. Repository Setup and Script Usage

- Fill in the `.env` file with:

    ```
    REPO_SSH_URI=git@github.com:your-org/your-repo.git
    REPO_DIR=/path/to/clone
    JAR_PATH=build/lib/project.jar
    ```

- Make script executable:
    ```
    cd ./script
    chmod +x setup.sh
    ```

- Run the setup script:
    ```
    sudo ./setup.sh
    ```
- Expected: Clones repo, checks for tools, starts the application.

---

## 2. Containerization with Docker

- Build the Docker image:
    ```
    cd ./docker
    docker build -t myapp:latest .
    ```
- Run the container:
    ```
    docker run -p 9000:9000 myapp:latest
    ```
- Visit `http://localhost:9000/` to check output.

---

## 3. CI/CD Pipeline with GitHub Actions

- Configure repository secrets in GitHub:
    - `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION`.
    - `ECR_REGISTRY`, `ECR_REPO`.
    - `EC2_HOST`, `EC2_USER`, `EC2_PRIVATE_KEY`.
- Copy pipeline workflow `./github/workflows/deploy.yml` to the java project repo.
- copy `dockerfile` to the root of java project repo
- Push to `main` branch to trigger pipeline.
- Monitor Actions tab for job progress.
- After build, image is pushed to AWS ECR, and EC2 is updated via SSH.

---

## 4. Infrastructure with Terraform (ELB)

- Edit `terraform.tfvars` with real values:

    ```
    vpc_id = "vpc-xxxxxxxx"
    public_subnets = ["subnet-aaaabbbb", "subnet-ccccdddd"]
    ec2_target_ids = ["i-xxxxxxxx"]
    alb_security_group_ingress_cidr = ["0.0.0.0/0"]
    ```
- Note: remember you are logged into awscli for using this terraform script

- Initialize and deploy:
    ```
    cd ./Terraform_ELB
    terraform init
    terraform apply -var-file=terraform.tfvars
    ```

- After apply, copy the output ALB DNS name, and test app at  
  `http://<alb_dns_name>/`

---

## 5. Security Group Association

- **Important:** In the AWS console, add the ALB security group (created by Terraform) to the EC2 instance’s inbound rules for port 9000, or adjust your EC2's security group to allow inbound from the ALB SG only.

---

## 6. Troubleshooting

- Review application logs.
- Check Target Health in AWS > EC2 > Target Groups if you get 502 or 5xx errors.
- Confirm port mappings and open firewall/security groups.

---

## 7. Cleanup

- To remove infrastructure:
    ```
    cd ./Terraform_ELB
    terraform destroy -var-file=terraform.tfvars
    ```
- To stop Docker containers:
    ```
    docker stop <container_id>
    ```

---
