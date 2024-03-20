# bcpl-dev-non-prod-cbs
Repositorio para el ambiente dev, proyecto cbs, AWS


<a name="readme-top"></a>

# bcpl-cbs ![Version-img]

bcpl-cbs is a core banking solution based on [temenos][temenos-url] platform.

[![terraform][tf-label]][tf-aws]

<!-- TABLE OF CONTENTS -->
### TABLE OF CONTENTS
1. [Getting started](#getting-started)
    - [Installation](#installation)
2. [Prerequisites](#prerequisites)
3. [Diagram](#diagram)
4. [Scope and functionalities](#scope-and-functionalities)
5. [Settings and dependencies](#settings-and-dependencies)
6. [Project status](#project-status)

## **Getting started**
Below is an example of how you can installing and setting up your app. First go to the [prerequisites](#prerequisites) section and make sure you have the necessary tools.

### Installation
1. Install terraform (Amazon Linux Example)
   ```sh
   sudo yum install -y yum-utils shadow-utils
   sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
   sudo yum -y install terraform
   ```

2. Clone the repo:
    ```sh
   cd https://github.com/BanCoppel-SF/bcpl-cbs
   ```

3. Go to the project directory.
    ```sh
   cd bcpl-cbs
   ```
4. Create a new branch before make changes
    ```sh
   git checkout -b <NAME_OF_YOUR_BRANCH>
   ```
   **Note**: _Don't make changes directly to the `dev` and `main` branches._
5. Initialize Terraform 
    ```sh
   terraform init
   ```

6. Select the correct profile (dev)
    ```sh
   export AWS_PROFILE=dev
   ```

6. Run the terraform validate to make sure your changes are done as intended (dev)
    ```sh
   terraform validate -var-file env/dev/values.tfvars
   ```

7. Run the terraform apply to rollout your changes (dev)
    ```sh
   terraform apply -var-file env/dev/values.tfvars
   ```

<p align="right"><a href="#readme-top">back to top</a></p>

## **Prerequisites**
This repository needs install the tools listed below to run:

* Install [terraform][tf-install]
* Install [awscli][aws-cli]
* Install [Git][git-url]
* Set [AWS Profile][AWS-profile-url]

<p align="right"><a href="#readme-top">back to top</a></p>

## **Diagram**
![Diagram](drawio/***.png)

## **File Structure**

**N_service.tf:** Infrastructure configuration files, the N identify the order for troubleshooting, when debugging comment or rename the higher numbers.

**backend.tf:** S3 Bucket used to store the tfstate. Make sure the bucket is created and the profile have permissions to wriput objects in the specified path.

**mappings.tf:** Engineering parameters, these parameters should not be changed ligthly, unproper modifications could derive in the need to redeploy the whole set.

**provider.tf:** Global Configuration, used to apply Global Tagging.

**variables.tf:** Variables Definition and Descriptions.

**env/<environment>/values.tfvars:** Varibles, these should be adjusted, based on the environment to be deployed

## **Scope and functionalities**
bcpl-cdb uses terraform IaC for building the required AWS services and settings:
- Amazon VPC
- IAM Roles
- Amazon EKS Cluster
- Amazon EKS Managed Nodes
- Amazon ECR Repositories
- Amazon MQ Broker
- Amazon S3 Bucket
- Amazon EFS

This repository only contains the Infrastructure and Code, and does not deploy any of the required application installation.

<p align="right"><a href="#readme-top">back to top</a></p>

## **Settings, dependencies and restrictions**
The following configurations are necessary for the correct deployment of this service:

- A brand new AWS Account.
    - Account must be integrated into the Organization using Landing Zone Accelerator.
    - The Transit Gateway to join corporate network must be shared with the account using RAM.
    - An existing S3 Bucket configured as Backend for Terraform must be configured in backend.tf
- Adjust Provider Tags 
    - Modify provider.tf to adjust Tags
- Create Keys before proceding
    - SCP blocks the creation of KMS keys for IAM Users/Roles not authorized.
- Provide Internet Connectivity Before Cluster Creation
    - Rename files 2-5 with extension tf to tfx. Run Terraform Apply.
    - Adjust the proper networking routes in Networking Account.
    - If needed, manually create NAT gateway
    - Rename files 2-5 wit extension tfx to tf. Run Terraform Apply.
- SCP blocks the creation of NAT Gateway for IAM Users/Roles not authorized.
    
<p align="right"><a href="#readme-top">back to top</a></p>

## **Project Status**
The project continues in development.

## Author
***Jesus Gonzalez Aquino - AWS Cloud Infrastructure Architect***

<!-- MARKDOWN LINKS & IMAGES -->
<!-- https://www.markdownguide.org/basic-syntax/#reference-style-links -->
[git-url]: https://git-scm.com/downloads
[AWS-profile-url]: https://docs.aws.amazon.com/cli/latest/reference/configure/
[Version-img]: https://img.shields.io/badge/version-v1.0.0-green
[tf-label]: https://img.shields.io/badge/TERRAFORM-7545B5?style=for-the-badge&logo=terraform&logoColor=white
[tf-aws]: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
[temenos-url]: https://www.temenos.com/products/core-banking/
[tf-install]: https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli
[aws-cli]: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html