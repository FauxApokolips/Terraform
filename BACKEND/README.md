# 🚀 DevOps Project to Automate Infrastructure on AWS Using Terraform and GitLab CICD

## 📝 Prerequisites

1. **AWS Account Creation**

    * Check out the official site to create an AWS account [here](https://signin.aws.amazon.com/signup?request_type=register).

2. **GitLab Account**

    * Login to [GitLab](https://gitlab.com).

    * Sign in via GitHub/Gmail.

    * Verify email and phone.

    * Fill up the questionnaires.

    * Provide group name & project name as per your choice.

3. **Terraform Installed**

    * Check out the official website to install Terraform [here](https://developer.hashicorp.com/terraform/install).

4. **AWS CLI Installed**

    * Navigate to the IAM dashboard on AWS, then select "Users."

    * Enter the username and proceed to the next step.

    * Assign permissions by attaching policies directly, opting for "Administrator access," and then create the user.

        ![](https://cdn.hashnode.com/res/hashnode/image/upload/v1720803283541/12c6404f-2f5a-4523-a50e-a573e1a2d089.png)

        ![](https://cdn.hashnode.com/res/hashnode/image/upload/v1720803345832/2f917349-88ef-4793-a3c6-6a93917cdb2a.png)

    * Locate "Create access key" in user settings, and choose the command line interface (CLI) option to generate an access key.

        ![](https://cdn.hashnode.com/res/hashnode/image/upload/v1720803375154/2dfb24a4-f3ac-42dc-a028-e4d9238e6f85.png)

    * View or download the access key and secret access key either from the console or via CSV download.

        ![](https://cdn.hashnode.com/res/hashnode/image/upload/v1720803402328/eda06a70-5d70-4ac5-856d-2daa2f739760.png)

    ```bash
    sudo apt install unzip  
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"  
    unzip awscliv2.zip  
    sudo ./aws/install  
    aws configure (input created access key id and secret access key)  
    cat ~/.aws/config  
    cat ~/.aws/credentials  
    aws iam list-users (to list all IAM users in an AWS account)
    ```

5. **Code Editor (VS Code)**

    * Download it from [here](https://code.visualstudio.com/download).

## 📂 Project Structure

### Part 1: Manual Setup

1. **Create a new folder named “cicdtf” and open it in VS Code to start writing the code.**

    ![](https://cdn.hashnode.com/res/hashnode/image/upload/v1720803528310/a0187ef8-044e-4085-8c88-86869e7281a9.png)

2. **Write Terraform code in the “cicdtf” folder:**

    ![](https://cdn.hashnode.com/res/hashnode/image/upload/v1720803563971/49c86485-a9cf-4a89-a6ea-2999c49bbc2b.png)

    * Create a file called `provider.tf` to define a provider.

    * Deploy a VPC, a security group, a subnet, and an EC2 instance.

### Part 2: Folder Structure

#### 1\. VPC Module (`vpc` folder)

* **Files:**

  * `main.tf`: Defines resources like VPC, subnets, and security groups.

  * `variables.tf`: Declares input variables for customization.

  * `outputs.tf`: Specifies outputs like VPC ID, subnet IDs, etc.

#### 2\. EC2 Module (`web` folder)

* **Files:**

  * `main.tf`: Configures EC2 instance details, including AMI, instance type, and security groups.

  * `variables.tf`: Defines variables needed for EC2 instance customization.

  * `outputs.tf`: Outputs instance details like public IP, instance ID, etc.

    ![](https://cdn.hashnode.com/res/hashnode/image/upload/v1720803607484/882c8877-d5bb-466f-af48-48887d69b341.png)

* `main.tf` for VPC Module

```go
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
}

resource "aws_subnet" "main" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone = "us-east-1a"
}

resource "aws_security_group" "main" {
  vpc_id = aws_vpc.main.id
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

* **Define** `outputs.tf` in the VPC module:

    ```go
    output "pb_sn" {
      value = aws_subnet.main.id
    }
    
    output "sg" {
      value = aws_security_group.main.id
    }
    ```

* **Define** `variables.tf` in the EC2 module:

    ```go
    variable "subnet_id" {}
    variable "security_group_id" {}
    ```

3. **Initialize and Validate Terraform:**

```bash
terraform init
terraform validate
terraform plan
terraform apply -auto-approve
```

4. **Backend Configuration:**

* Set up a backend using S3 and DynamoDB.

```go
# backend.tf
terraform {
  backend "s3" {
    bucket = "my-terraform-state"
    key    = "terraform/state"
    region = "us-east-1"
    dynamodb_table = "terraform-lock"
  }
}
```

5. **Push Code to GitLab:**

* Initialize the GitLab repository and create a `.gitignore` file.

* Create a branch named "dev" and push the code.

```bash
git remote add origin https://gitlab.com/your-repo.git
git checkout -b dev
git add .
git commit -m "initial commit"
git push -u origin dev
```

![](https://cdn.hashnode.com/res/hashnode/image/upload/v1720803932419/bcf139d7-9ea6-46f4-ac81-6d4b15f3f39e.png)

![](https://cdn.hashnode.com/res/hashnode/image/upload/v1720803976561/2527926c-5a9e-49a0-9c85-8fc42987bd88.png)

![](https://cdn.hashnode.com/res/hashnode/image/upload/v1720804004557/557a5711-82eb-4288-9f03-524830a54378.png)

