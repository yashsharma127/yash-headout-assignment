# Project Documentation for Containerized Java Application with AWS ELB and CI/CD Pipeline

---

> **Note:**  
> Looking to deploy or test this project?  
> **See the [Setup Guide](./SETUP.md) for step-by-step deployment instructions.**

---

## 1. Script for Setup and Application Launch (Task 1 & 2)

**What it Does:**
- Loads environment variables from a `.env` file, which includes:
    - Repository SSH URI
    - Repository directory path
    - Path to the JAR file to run
- Verifies if SSH agent is running and configured properly
- Checks that Git is installed and available
- Clones the repository via SSH into the specified directory
- Validates Java installation and version (expects Java 17)
- Checks for the presence of the JAR file inside the cloned repo
- Runs the Java application with `java -jar`
- Prints logs with severity highlights: INFO, ERROR (in red), SUCCESS

**Assumptions:**
- User has the repository SSH URI available and accessible
- SSH keys (public/private) are configured on the machine and added to GitHub for authentication
- SSH agent is running on the machine and connected to GitHub to allow SSH cloning
- Git and Java (v17) are pre-installed and available in the system path
- The repository contains a built JAR file at `build/lib/project.jar` ready to run

---

## 2. Dockerfile for Containerization (Task 3)

**What it Does:**
- Uses an official OpenJDK 17 base image
- Creates and sets a working directory inside the container
- Copies pre-built `project.jar` from the repository’s build folder into the container
- Exposes port 9000 for incoming HTTP connections
- Provides an entrypoint command to run the Java application with `java -jar`

**Assumptions:**
- The project uses Java 17, and the base image should match this version for compatibility
- The `build/lib/project.jar` exists and contains all necessary code and dependencies for the app to run independently
- Running the JAR with `java -jar` starts the HTTP server bound to port 9000 inside the container
- No additional external files, assets, or caches from build folder are required for the application runtime

---

## 3. GitHub Actions Workflow for CI/CD (Task 4)

**What it Does:**
- Triggered on every push to the `main` branch
- Runs on an Ubuntu runner environment
- Sets up Java 17 environment for any build or testing needs
- Configures AWS credentials securely via GitHub Secrets to allow AWS access
- Logs into AWS ECR for Docker image repository operations
- Builds the Docker image using the Dockerfile created in Task 3
- Tags and pushes the Docker image to the specified AWS ECR repository
- Connects via SSH to a running EC2 instance and deploys the container, exposing container port 9000 to EC2's localhost interface

**Assumptions:**
- Deployment pipeline is triggered exclusively from the `main` branch for simplicity/consistency
- Java 17 compatibility for both build and runtime
- AWS IAM credentials have necessary permissions for ECR login, push/pull, and EC2 SSH access
- ECR repository is pre-created and ready to store Docker images
- EC2 instance is already provisioned with Docker installed, with SSH access configured
- All sensitive credentials and secrets are stored in GitHub Actions secrets for secure usage within workflows

---

## 4. Terraform Setup for ELB and Load Balancing (Task 5)

**What it Does:**
- Initializes the AWS provider for Terraform
- Creates a security group for the ALB (Elastic Load Balancer) allowing inbound HTTP (port 80) from anywhere
- Sets up a target group for the ALB to route HTTP traffic on port 9000 to registered EC2 instances
- Registers EC2 instance by instance ID as targets on port 9000
- Creates an Application Load Balancer deployed across specified public subnets in a given VPC
- Configures an ALB listener on port 80 forwarding requests to the target group on port 9000
- Outputs the ALB DNS name for users to access the application

**Assumptions:**
- You have the VPC ID where the EC2 instance and ALB will be deployed
- A list of public subnet IDs (preferably multiple for high availability) within the same VPC is available
- Have EC2 instance ID which is running the containerized application on port 9000
- After ALB creation, the security group created for the ALB will be added to the EC2 instance’s inbound rules, allowing traffic on port 9000 only from the ALB security group (for secure access control)

---

## Additional Assumptions and Considerations

- Java version consistency (using Java 17) across local dev, container image, and deployment environment ensures compatibility
- SSH-based git cloning assumes correct key setup and active SSH agent on the deployment machine
- Terraform provides reproducible and auditable infrastructure provisioning, easing maintenance and future scale-out actions
- Initially opening ports broadly (i.e., ALB ingress to 0.0.0.0/0)

---

> For **detailed commands and deployment steps:**  
> Please follow the [SETUP Guide](./SETUP.md).
