# Introduction

Embarking on a DevOps journey can be both exciting and daunting, especially for beginners. The landscape is vast, and the learning curve can feel steep. One of the most common challenges is setting up and managing a robust Continuous Integration/Continuous Deployment (CI/CD) pipeline that ensures seamless integration and delivery of code changes. This guide aims to simplify that process by walking you through setting up a CI/CD pipeline for Okta using Terraform, AWS, and GitHub Actions.

## Why Follow This Guide?
Getting started with DevOps often presents a series of challenges:

1. Running Locally: Setting up Terraform locally involves dealing with packages, dependencies, and managing the state file, which can be cumbersome and error-prone.
2. Collaboration: Ensuring that team members can collaborate effectively requires a consistent and reproducible environment.

Making a setup production-ready introduces further complexities:

1. State File Storage: Knowing where and how to store the Terraform state file securely.
2. Secrets Management: Safely storing and managing sensitive information like API keys and passwords.
3. Automation: Automating the deployment process to ensure reliability and efficiency.

## What You Will Learn
In this guide, we will cover:

1. Overview of the Architecture: We'll start with an overview of the architecture, explaining how each component—Okta, Terraform, AWS, GitHub, and GitHub Actions—fits into the CI/CD pipeline.
2. CI/CD Pipeline Overview: You'll learn about a basic CI/CD pipeline integrating with multiple environments.
3. Step-by-Step Setup: We'll provide detailed, step-by-step instructions on how to set up the entire pipeline. This includes:
    - Terraform Integration with Okta: Using Terraform to manage Okta resources via its APIs.
    - AWS for Terraform Backend and Secrets Management: Leveraging AWS services to store Terraform state files and manage secrets securely.
    - GitHub and GitHub Actions: Setting up a GitHub repository for your code and configuring GitHub Actions to automate your CI/CD processes.

By the end of this guide, you will have a solid understanding of how to set up a CI/CD pipeline tailored for Okta, equipped with the knowledge to start implementing infrastructure as code with Terraform.
Let’s dive in and take the first step towards mastering DevOps with a practical, hands-on approach!


# Architecture Overview
First, it's important to understand the key components and their roles in the CI/CD process. This integration of GitHub, Terraform, AWS, and Okta allows for secure and efficient management and deployment of infrastructure. The following overview details each component and its function.

![Architecture Diagram](assets/architecture.png)

**User**
- Develop Code: Develops Terraform code on their local machine using a preferred IDE. Uses Git to push code to the GitHub repository.

**GitHub Repository**
- **Code Storage:** Stores the Terraform configuration code.
- **Triggers Workflow:** Code is checked out by GitHub Actions to automate builds using Terraform based on events within the GitHub repository (e.g. push to branches, pull requests, etc.).

**GitHub Actions**
- **Workflows:** Workflows are automatically triggered by GitHub repository events and execute the necessary commands to integrate with AWS and Terraform.

- AWS:
    - **Assume Role:** Integrates with AWS IAM STS via GitHub OIDC IdP to authenticate and assume roles with web identity.
    - **Temporary Credentials:** Utilises temporary credentials returned from AWS IAM STS for Terraform backend operations.

- **Terraform:** Runs Terraform commands to manage infrastructure.

**Terraform**
- **State Management:**
    - **S3:** Utilises S3 for storing Terraform state files.
    - **DynamoDB:** Uses DynamoDB for state locking to ensure consistency and prevent concurrent operations.
    - **Secrets Management:** Retrieves Okta OAuth2 client credentials private key from AWS Secrets Manager for authentication and authorisation to Okta management APIs.
- **Okta:**
    - **Resource Management:** Leverages Okta APIs via the Terraform Okta provider to manage resources.

# CI/CD Workflow Overview

At a very high level, this is what we are aiming to build out through this article. We'll set up a CI/CD pipeline that automates the deployment of infrastructure using GitHub, Terraform, AWS, and Okta. Here's a simplified overview of the workflow:

![Workflow Diagram](assets/workflow.png)

1. **Branch Creation:** Developers create and work on a develop branch.
2. **Push to Develop:** Code changes are committed locally and pushed to the remote develop branch.
3. **Dev Build:** GitHub Actions run Terraform commands to deploy to the development environment. This is triggered automatically by the push to develop.
4. **Pull Request to Main:** A pull request is made from develop to main for code review. Any GitHub Action workflow executions are included in the pull request for review.
5. **Prod Plan:** GitHub Actions preview changes for the production environment. This is triggered automatically by the pull request to main. This lets reviewers of the pull request validate potential changes before the production environment is modified.
6. **Merge to Main:** The pull request is approved and merged into the main branch.
7. **Prod Build:** GitHub Actions runs Terraform commands to deploy to the production environment. This is triggered automatically by the merge to main.



# Configuration
## Integrated Development Environment (IDE)
First things first, let's start with the local development environment. Choosing the right Integrated Development Environment (IDE) with a Terraform plugin is crucial for an efficient and error-free workflow. Some essential features to look for in your IDE:

1. Variable Declaration Warnings: If your Terraform module requires certain variables, the IDE will alert you when any required variables are not declared.
2. Resource Declaration Assistance: When you declare a resource, the IDE will warn you if any required attributes are missing and suggest attributes to be added.
3. Resource and Attribute Autocompletion: The IDE will autocomplete resource names and attributes when referencing other resources, saving you time and reducing errors.

## GitHub
We will be using GitHub as our code repository and GitHub Actions for our CI/CD workflows, so you'll need a GitHub account. If you don't have one, create one at [GitHub](https://github.com/).

You will also need a GitHub Organization. If you are an enterprise user, you likely already have one. If not, or if you're experimenting, you can create one for free. Navigate to the Organizations section in your GitHub profile settings ('Profile icon' > ‘Settings’ > ‘Organizations’) or follow this link: [GitHub Organizations](https://github.com/settings/organizations) to get started with creation of an Organization.

### Creating a New Repository
Next, we'll create a new repository within your GitHub Organization and initialise it in our local development environment.

1. **Create a new repository:** For the purpose of this guide, we have created a templated repository for you to use. To use the template repository in your newly created GitHub Organization, navigate to the template at the following [link](https://github.com/verysecureorg/yourorg-okta-terraform) and select ‘Use this template'.  A wizard will open to create a new repository (which looks like creating a new repository from scratch). Select the owner (your Organization) and the repository name (consider using a structure such as {okta-domain-name}-okta-terraform (e.g., verysecureorg-okta-terraform). Ensure that the repository is set to Private. This setting is crucial as the repository will run GitHub Actions workflows and have information related to your environment (e.g. AWS resource names).
2. **Clone the Repository:** Once your repository is created, click the '<> Code' button and copy the HTTPS clone link for later use.

With these steps completed, you’re ready to move on to initialising the repository in your local development environment and setting up your CI/CD pipeline.

## Git

To manage code in the repository, we will be using Git on our local machine's command line. Follow these steps to initialise the repository locally:

1. **Install Git CLI or Git Credential Manager:**
- Ensure you have either Git CLI or Git Credential Manager installed on your machine.
- Git Credential Manager allows you to use your browser to authenticate to GitHub, simplifying the process compared to using SSH keys.
- More information on installation can be found here: [GitHub Docs](https://docs.github.com/en/get-started/getting-started-with-git/caching-your-github-credentials-in-git).

2. Clone the Repository:
- Navigate to a suitable parent folder on your local machine.
- Run the following command to clone the repository, which will create a subfolder with the same name as the repository. Include your GitHub username to ensure that GitHub CLI or GitHub Credential Manager opens accordingly. You will be prompted to authenticate and authorize using your browser. Select continue to complete the authorization and clone the repository.

  ```git clone https://<github_username>@github.com/<organization>/<repository>.git```

  Example:

  ```git clone https://johnsmith@github.com/acme/acme-okta-terraform.git```

3. **Navigate to the Repository Directory:**
- Once the repository is cloned, navigate into the directory using:

  ``` cd <repository> ```

With these steps, you have successfully cloned your repository.


## Okta OAuth2
To access Okta APIs, we will use the OAuth2 client credentials flow. This is considered the most secure method for integrating with Okta APIs, as we can tightly bound authorisations using scopes, and access tokens are short lived, compared to the long lived ‘SSWS’ API keys.

The Okta OAuth2 client requires ‘scopes’ to interact with the management API. For the purposes of this guide, we will be interacting with the Groups resource in Terraform and corresponding APIs. To understand the corresponding scopes related to a Terraform resource and underlying Management APIs, refer to the [Okta API documentation](https://developer.okta.com/docs/api/openapi/okta-management/guides/overview/).

Finally, the OAuth2 client requires an Administrator Role to make administrative changes. We will be assigning Super Administrator, but feel free to downscope this (e.g. Org Administrator would be sufficient). If you intend to use Terraform to manage your environment ongoing, Super Administrator is typically required (especially for managing resources like Admin Roles). The effective permissions are a combination of the scopes permitted for the client and the Administrator Role - so even though we provide the client ‘Super Administrator’, if we only provide access to ‘groups’ related scopes, all the client can do via the API is manage groups!

Follow these steps to set up an API Services application in Okta:

1. **Create an API Services Application:**
    - Navigate to the Okta Admin Console.
    - Go to 'Applications' > 'Applications' > 'Create App Integration'.
    - Select 'API Services' and give your application an appropriate name (e.g., Terraform).

2. **Configure Authentication:**
- On the General tab, in the ‘Client Credentials’ section, click 'Edit'.
- Change the authentication method to 'Public key / Private key'.

**3. Generate and Add Public Key:**
- In the Public Keys section, click 'Add key' and then 'Generate new key'.
- The private key will be displayed only once. Select the 'PEM' tab and copy the contents to a notepad for later use.
- Select ‘Done’ and ‘Save’

**4. Disable DPoP**
- In the ‘General Settings’ section on the same page, click ‘Edit’
- Unselect the ‘Proof of possession’ configuration
- Select ‘Save’

**5. Add Scopes**
- Select the ‘Okta API Scopes’ tab to navigate to the Scopes section
- Select ‘Grant’ for okta.groups.manage

**6. Add Admin Role**
- Select the ‘Admin Roles’ tab to navigate to the Admin roles section
- Select the ‘Edit assignments’ button which will redirect to assign the Admin Role
- In the ‘Role' drop down, select ‘Super Administrator’, or your preferred Admin Role
- Select ‘Save Changes’ to finish assigning the role

7. Repeat for any additional environments
- Login to any additional Okta tenants and perform steps 1 to 3

>[!IMPORTANT]
>Do not save the private key locally. We will securely onboard it to secrets management in the next steps.


## AWS for Terraform Backend and Secrets Management
We will utilise AWS for both the Terraform backend and Secrets Management. The Terraform backend will store state files, which track the status of your Okta environment based on previous builds. For authentication with Terraform, we will use the GitHub OIDC integration with AWS. This allows GitHub to authenticate with AWS using OpenID Connect (OIDC) and assume the necessary role via web identity to interact with required services. This approach eliminates the need for long-lived or persistent secrets (such as AWS access keys and secrets), ensuring a more secure setup.

### Backend Components
First, let's create the necessary components for the Terraform backend.

1. **Create an S3 Bucket:**
- Go to AWS Management Console, search for ‘S3’, and select ‘Create bucket’.
- Name the bucket (e.g., `{okta-domain-name}-okta-terraform-state`).
- By default, ‘Block all public access’ is enabled, do not modify this setting
- Select ‘Enable’ for Bucket Versioning to enable versioning of your state files. This is useful if you need to rollback to a previous version of state.
- If you use non-default encryption options, ensure you include the necessary KMS permissions later.
- Select ‘Create bucket’ to finalise the configuration. Then, click into the bucket.
- Copy the ARN from the ‘Properties’ tab; this will be used in the AWS Role Policy definition.
- Go to the ‘Objects’ tab; and select the ‘Create folder’ button to create a folder within the bucket for each environment (e.g., dev and prod).

2. **Create a DynamoDB Table for State Locking:**
- In the AWS Management Console, search for ‘DynamoDB’ and select ‘Create table’.
- Name the table (e.g., `{okta-domain-name}-okta-terraform-dev`).
- Set the partition key to ‘LockID’ and leave other configurations as defaults. Select ‘Create table' to finalise the configuration.
- Note the table name; it will be used in the AWS Role Policy definition.
- Repeat this for any additional environments, naming accordingly.
- For more information on the AWS S3 Terraform backend, please refer to [Terraform S3 Backend Documentation](https://developer.hashicorp.com/terraform/language/settings/backends/s3).

### Secrets Management
Next, we will set up AWS Secrets Manager to securely store the Okta OAuth2 private key for authentication and authorisation to Okta management APIs.

1. **Store the Secret in AWS Secrets Manager:**
- Navigate to AWS Secrets Manager, search for ‘Secrets Manager’, and select ‘Store a new secret’.
- For ‘Secret type’, choose ‘Other type of secret'
- For ‘Key/value pairs’, select the ‘Plaintext’ tab. Remove any existing text and paste the entire PEM key (including headers and footers) into the field.
- Click ‘Next’, and name the secret something meaningful (e.g., `dev/okta-terraform-key`).
- Click ‘Next’, and keep the default options for rotation, finalising the configuration by selecting ‘Store’ to store the secret.
- After storing the secret, click into it and copy the ARN; this will be used in the AWS Role Policy definition.
- Repeat this for any additional environments secrets, naming accordingly.

### IAM Policy
Next, we'll create the IAM Policy definition. This policy will be used by the role that GitHub will assume via OpenID Connect (OIDC).

1. **Navigate to IAM:**
- Go to the AWS Management Console and search for ‘IAM’.
- Select ‘Policies’ and then ‘Create Policy’.

2. **Define the Policy:**
- Choose the 'JSON' tab in the Policy wizard. Use the following template and fill in the appropriate ARNs in the respective lines
- Line 7: Replace `<S3-ARN>` with the ARN of your S3 bucket. This grants permission to list the bucket. This can be found under the ‘Properties' tab of the S3 Bucket.  Example: `arn:aws:s3:::acme-okta-terraform`
- Lines 16 and 17: Replace <S3-ARN>/* with the ARN of your S3 bucket and any folder structures for respective environments. This grants permission to get and update objects in the relevant path. Alternatively, you can use a wildcard (*) for the entire bucket. Example: `arn:aws:s3:::acme-okta-terraform/dev/*`
- Lines 29 and 30: Replace `<AWS-Region>`,  `<Account-Number>`, and `<DynamoDB-Table-Name>` with the AWS Region, AWS Account Number (found in the top right corner when signed into the management console) and DynamoDB Table Name respectively. This grants permission to add and remove rows in the table for the Terraform state file locking process. Include any additional tables for each environment. Example: `arn:aws:dynamodb:ap-southeast-2:99123456789:table/acme-okta-terraform-dev`
- Lines 40 and 41: Replace `<SecretsManager-ARN>` with the ARN of your Secrets Manager secret. This grants permission to retrieve the secret value. Include any additional ARNs for each environment. Example: `arn:aws:secretsmanager:ap-southeast-2:99123456789:secret:dev/acme_okta_terraform_key-QuqiGR`

```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "s3:ListBucket",
            "Resource": "<S3-ARN>"
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:PutObject"
            ],
            "Resource": [
                "<S3-ARN>/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "dynamodb:DescribeTable",
                "dynamodb:GetItem",
                "dynamodb:PutItem",
                "dynamodb:DeleteItem"
            ],
            "Resource": [
                "arn:aws:dynamodb:<AWS-Region>:<Account-Number>:table/<DynamoDB-Table-Name>"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "secretsmanager:ListSecrets",
                "secretsmanager:GetSecretValue"
            ],
            "Resource": [
                "<SecretsManager-ARN>"
            ]
        }
    ]
}
```

3. **Name and Create the Policy:**
- Name the policy something meaningful (e.g., Okta_Terraform_Backend).
- Select 'Create policy'.

By following these steps, you will have created an IAM policy that provides the necessary permissions for Terraform to interact with AWS services securely.


### IAM OIDC Identity Provider
Next, we'll configure the OIDC Identity Provider for GitHub.

1. **Navigate to IAM:**
- Go to the AWS Management Console and search for ‘IAM’.
- Select ‘Identity providers’ and then ‘Add provider’.

2. **Configure the OIDC Provider:**
- For ‘Provider type’ select OpenID Connect
- For the ‘Provider URL’, enter `https://token.actions.githubusercontent.com`
- For the ‘Audience’, enter `sts.amazonaws.com`.
- Click ‘Add provider’ to create the OIDC Identity Provider.

For more information on integrating GitHub with AWS using OIDC, refer to the [GitHub and AWS integration documentation](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services).


### IAM Role
Finally, we'll create an IAM Role for the GitHub OIDC Identity Provider to assume. This role will link the OIDC Identity Provider via the trusted entity and the Policy via Permissions.

1. **Navigate to IAM:**
- Go to the AWS Management Console and search for ‘IAM’.
- Select ‘Roles’ and then ‘Create role’.

2. **Select Trusted Entity:**
    - In the ‘Select trusted entity’ step, fill in the following details - note, this is important as without the organization and repository conditions, any GitHub Actions workflow could assume your role!
        - Trusted entity type: Web Identity
        - Identity provider: `token.actions.githubusercontent.com`
        - Audience: `sts.amazonaws.com`
        - GitHub organization: `{your_github_organization}` (the unique identifier for your GitHub Organization)
        - GitHub repository: `{your_github_repository}` (the name of your GitHub repository)
- Click ‘Next’ to proceed to the ‘Add permissions’ step.

3. **Add Permissions:**
- Search for the IAM Policy you created earlier (e.g., `Okta_Terraform_Backend`).
- Select the policy and click ‘Next’.

4. **Name the Role:**
- Name the role something meaningful (e.g., `GitHub_Okta_Terraform_Backend`).
- Click ‘Create Role’.

5. Copy the Role ARN:
- Click into the role you just created and copy the Role ARN. This is the only variable we need to pass to our pipeline to initialise the backend and retrieve the secret to authenticate and authorize to Okta APIs—and it's not even a secret.

By following these steps, you will have created an IAM Role that GitHub can assume via OIDC, enabling secure interactions with AWS and Okta.


## GitHub Actions
GitHub Actions allows us to run our build and deployment activities using Terraform commands executed in a temporary virtual machine.

### Setting Up Environment Variables
First, we need to store the Role ARN and other environment variables in GitHub.

1. **Store the Role ARN:**
- Within your repository in the GitHub user interface, navigate to 'Settings' > ‘Secrets and variables’ > ‘Actions’.
- Go to the ‘Variables’ tab and click ‘New repository variable’.
- Name the variable `AWS_ROLE_ARN` and enter the Role ARN in the Value field.

2. **Store the Region:**
- Click ‘New repository variable’.
- Name the variable `AWS_REGION` and enter the Region that the resources in AWS were created in (e.g. `ap-southeast-2`). Refer to the following documentation for more details on Region names: AWS Regions Documentation

> [!WARNING]
> Ensure this is done at at a ‘Repository’ level and not at an ‘Organization’ level, or the GitHub Actions workflows will not be able to read the variables

### GitHub Actions Workflow
We will use multiple pre-built GitHub Actions to authenticate to AWS and run our Terraform commands. No action is required from you to configure these workflows. At a high level, the configured GitHub Actions workflows will perform the following:

1. **GitHub Actions Runner:**
- This action checks out your repository onto the runner, allowing you to run Terraform commands against your code.

2. **AWS Configure AWS Credentials:**
- This action establishes an AWS session using the GitHub OIDC Identity Provider (IdP) and the Assume Role with Web Identity capability. There is no need to manage any secrets or custom scripts, as this action will handle session establishment.

3. **Terraform CLI:**
- This action runs the Terraform commands.

For more information and to refer to the code, refer to the `github/workflows` folder within the repository.

## Repository
In the following section, we will go over the high level structure of the repository.

### Folder Structure

```
github/
├─ workflows/
│  ├─ push-main.yml
│  ├─ push-develop.yml
│  ├─ pr-main.yml
terraform/
├─ modules/
│  ├─ {module}/
│  │  ├─ {resource}.tf
│  │  ├─ variables.tf
├─ main.tf
├─ variables.tf
├─ backend-dev.conf
├─ backend-prod.conf
├─ vars-dev.tfvars
├─ vars-prod.tfvars
```


**GitHub Workflows**
- github/workflows/: This directory contains the GitHub Actions workflow files that define the CI/CD pipeline.
    - push-main.yml: Workflow triggered by a push to the main branch.
    - push-develop.yml: Workflow triggered by a push to the develop branch.
    - pr-main.yml: Workflow triggered by a pull request to the main branch.

**Terraform Configuration**
- terraform/: The root directory for all Terraform configuration files.
    - modules/: This directory contains reusable Terraform modules.
        - {module}/: Each module has its own directory.
            - {resource}.tf: The Terraform configuration file for specific resources within the module.
            - variables.tf: The child module input variables definition file
- main.tf: The main Terraform configuration file where all providers, modules, and variables are configured.
- variables.tf: The parent module input variables definition file.
- backend-dev.conf: Configuration for the backend components for the development environment. This configuration must be passed in via CLI since named variables cannot be used directly in the backend block.
- backend-prod.conf: Configuration for the backend components for the production environment, similar to the development configuration.
- vars-dev.tfvars: Input variable values specific to the development environment.
- vars-prod.tfvars: Input variable values specific to the production environment.

# Lets Build Something!
Now that we have everything setup, lets actually build something!

First we will need to update a few files with some of the necessary configurations relevant to your environment. Then we will create a new group in your Okta environment, using variables to declare the group name.

**Step 1: Create Develop Branch**

Ensure your local repository is up-to-date with the remote main branch.

```
git checkout main
git pull origin main
```

Create and switch to the branch named develop.

```
git checkout -b develop
```

**Step 2: Finalise Configuration**

Now that we have checked out our code, let’s finalise the configurations required for Terraform to interact with our backend, retrieve the necessary secrets and interact with the Okta Management APIs. Open the repository in your preferred IDE so that we can edit some files.

- **Backend Configuration:**
    - The Terraform backend configuration is stored within the backend-*.conf files and contain configurations relevant to your environments. Within these files you will find placeholders for the following:
        - `bucket` - the name of your bucket (not the ARN!)
        - `key` - the path to your Terraform state file (i.e. the folder and resultant file name, which defaults to terraform.tfstate)
        - `dynamodb_table` - the name of your DynamoDB table (not the ARN!)
        - `region` - the AWS Region
- Replace all the placeholders in the backend-*.conf files. There are two placeholders for development and production environments respective. Refer to the following example as a reference:

```
bucket         = "acme-okta-terraform"
key            = "dev/terraform.tfstate"
dynamodb_table = "acme-okta-terraform-dev"
region         = "ap-southeast-2"
```

- **Terraform Variables (tfvars):**
    - Variables are a critical component within infrastructure as code configurations, as they allow you to have a single set of configurations, whilst maintaining environment specific values. Within Terraform, one way to manage such environment specific values is using ‘tfvars’ files. The ‘tfvars’ file contains a set of variable values specific to an environment, and is passed in via the Terraform CLI in our GitHub Actions workflow when we are running specific parts of the workflow.
    - There are additional configuration related variables stored within the vars-*.tfvars files which require update. Within these files you will find placeholders for the following:
        - `region` - the AWS Region
        - `okta_org_name` - the prefix value for your Okta tenant
        - `okta_base_url` - the base or suffix value for your Okta tenant
        - `okta_scopes` - the scopes for the Terraform Okta OAuth2 client application
        - `okta_client_id` - the client ID for the Terraform Okta OAuth2 client application
        - `okta_private_key_id` - the private key ID for the Terraform Okta OAuth2 client application. This is the ‘KID’ value which can be obtained in the ‘Public Keys’ section of the OAuth2 application configuration
        - `okta_secret_id` - the AWS Secrets Manager ‘secret name’ for the Terraform Okta OAuth2 client application private key. This is the ‘Secret name’ value, not the ‘Secret ARN’.
    - Replace all the placeholders in the vars-*.tfvars files. Refer to the following example as a reference:


```
region            = "ap-southeast-2"
okta_org_name     = "acme"
okta_base_url     = "oktapreview.com"
okta_scopes       = [
  "okta.groups.manage"
]
okta_client_id    = "0oaes123y1FekjfoE1d7"
okta_private_key_id = "ievOgRgNc7eAoyZJkR_Nvlf0qWnqGg5-JKaJJn5ra_4"
okta_secret_id    = "dev/okta_terraform_key"
```

**Step 3: Make Code Changes**
- Included in the repository is a `directory` module which contains a resource `okta_groups.tf` which we’re going to use to provision a group to your Okta tenant. In doing so, we’re also going to walkthrough a core tenet of the previously mentioned variables where we will define both input and output variables. This may be a little confusing at first, so take some time to understand how the different files and modules interact with each other!

- First, open `terraform/modules/directory/variables.tf` and uncomment the following entry. This is the variables file for the directory module and it defines which input variables are required. Each module you develop will have its own variables file.
```
variable "okta_group_name" {
  type = string
}
```

- Secondly, open `terraform/modules/directory/okta_groups.tf` and uncomment the following entry. This is a resource block. The resource block itself has 2 parts, firstly the resource type, which is `okta_group`, and the resource name which is `okta_test_group`. Feel free to change the resource block name (`okta_test_group`) to something of your choosing. Within the resource block body are the configuration arguments for the resource. We have one argument defined, which is the name,  referencing the input variable `okta_group_name`.
```
resource "okta_group" "okta_test_group" {
  name = var.okta_group_name
}
```

- Third, open `terraform/variables.tf` and uncomment the following entry. This is the variables file for the parent or main module. The variables within this file are assigned via the ‘tfvars’ files which are passed in with environment specific configurations via the Terraform CLI
```
variable "okta_group_name" {
  type = string
}
```

- Next, open `terraform/main.tf` and uncomment the following entry. The main file contains key configurations for the backend as well as providers (like Okta or AWS). It also is where we reference any modules, including the `directory` module, via their path within the local repository. Within this module block, it is also necessary to pass through any variables. We can either configure the variable values directly within the main file, which may be acceptable for any standardised or non environment specific variables, or we can reference the parent module variables file like we have done so in this example.
```
okta_group_name = var.okta_group_name
```

- Finally, open `terraform/dev.tfvars` and `terraform/prod.tfvars` and uncomment the following entry. This sets the the value of the `okta_group_name` variable for each respective environment. Feel free to change it and make the values environments specific.
```
okta_group_name = "Okta Test Group GitHub Actions"
```

- Now, we can stage the changes we have made. Use `git add` to add the changes for the next commit.
```
git add .
```

- Lastly, commit the changes:
```
git commit -m "Initial commit"
```


**Step 3: Push to Develop**
With the changes committed, we can now push your changes to the remote develop branch.
```
git push origin develop
```

**Step 4: GitHub Actions Triggers Terraform Dev Build**
- GitHub Actions is configured to trigger a build when changes are pushed to the develop branch.
- The workflow defined in the repository will:
    - Authenticate with AWS: Use GitHub OIDC to assume the necessary role.
    - Run Terraform Commands: Execute terraform init, terraform plan, and terraform apply to deploy changes to the development environment.
- Monitor the Actions tab in GitHub to ensure the build completes successfully.
- Check your Okta environment to observe the creation of the group with the name specified in the tfvars file.

> [!TIP]
>If GitHub Actions has any errors, refer to the error message within the GitHub Actions workflow for further details.
> If you missed any configurations within the repository files (e.g. backend-*.conf or vars-*.tfvars), make the changes on your local and perform the git add, git commit and git push commands again.
> If you missed any configurations within Okta (e.g. OAuth2 scopes) or AWS (e.g. IAM Role permissions, etc.), then correct the issue and re-run the GitHub Actions workflow from the GitHub Actions console using the ‘Re-run jobs' button on a failed workflow.

**Step 5: Create a Pull Request to Main**
- Navigate to the repository on GitHub.
- Open a pull request from develop to main.
- Provide a detailed description of the changes and any context or considerations for the reviewers.


**Step 6: GitHub Actions Triggers Terraform Prod Plan**
- When a pull request is opened, GitHub Actions triggers a Terraform plan for the production environment.
- This plan will:
    - Authenticate with AWS: Use GitHub OIDC to assume the necessary role.
    - Run Terraform Plan: Execute terraform init,  terraform plan to show the potential changes without applying them against the production environment.
- Reviewers can inspect the plan output to understand the impact of the changes before merging.

**Step 7: Merge Pull Request to Main**
After reviewing and approving the pull request, merge it into the main branch. This can be done via the GitHub interface by selecting "Merge pull request".



**Step 8: GitHub Actions Triggers Terraform Prod Build**
- Merging to the main branch triggers a new GitHub Actions workflow.
- The workflow will:
    - Authenticate with AWS: Use GitHub OIDC to assume the necessary role.
    - Run Terraform Commands: Execute terraform init, terraform plan, and terraform apply to deploy changes to the production environment.
- Monitor the Actions tab to ensure the deployment completes successfully.

# Conclusion
In this article, we have outlined the architecture and steps needed to set up a secure and efficient CI/CD pipeline using GitHub Actions, Terraform, AWS, and Okta. By leveraging these technologies, we can automate infrastructure management, ensuring consistency and reducing the risk of manual errors. We covered the integration of GitHub with AWS for secure authentication and authorization, the configuration of Terraform for state management and secrets handling, and the overall workflow for deploying changes from development to production. Stay tuned for subsequent articles which will detail Okta recommended policies to help get you started with secure by design configurations from day one!


 
