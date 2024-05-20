
# Deploy Gateway Load Balancer and 2 Customer Hosted Edge Routers to VPC

This terraform plan when used will create a new gateway load balancer and 2 new NF Edge Routers in a new VPC. All NLB associated resources and options will be created/configured as well, among other things health checks to each ER, the lb algorithm will be set to "Five Tuple", and backend pool will be set to 2 ERs created part of this deployment.

## **PREREQUISITES**

Need to Create 2 Customer Hosted Edge Routers on your NF Network using the following link [Get Reg Keys](https://nfconsole.io/login) and copy registration keys to [input_vars.tfvars.json](tf-provider/input_vars.tfvars.json) file under `edgeRouterKey`. Here  are the full list of input vars that need to be provided:

```json
{
    "er_map_be": [
        {
            "edgeRouterKey": "55JMPJ8B4W",
            "dnsSvcIpRange": "100.64.0.0/13",
            "zone": "a",
            "publicSubnet": "10.40.101.0/24"
        },
        {
            "edgeRouterKey": "7Z7JS9MEB4",
            "dnsSvcIpRange": "100.72.0.0/13",
            "zone": "b",
            "publicSubnet": "10.40.102.0/24"
        }
    ],
    "region": "us-east-2"
}
```

## **STEPS**

If you need such HA set up in more than one region, one could use workspaces. Just don't forget to change the zone and region in the provider file.

1. Install Terraform

    [Get Terraform](https://www.terraform.io/downloads)

1. Set up your AWS provider Authentication

    [Terraform AWS Provider File](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

    1. Create provider.tf

        ```shell
        vi tf-provider/provider.tf
        ```

    1. Add this connect with your own credentials

        ```ini
        # Declaring the aws provider in provider block using assume_role.
        provider "aws" {
            # The security credentials for AWS Main Account.
            access_key = "XXXXXXXXXXXXXXXXXXXX"
            secret_key = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
            region     = var.region
            assume_role {
                role_arn = "arn:aws:iam::XXXXXXXXXXXX:role/ops-mgmt-user"
                session_name = "AWS_sesion_1"
            }
        }
        ```
    if using sso, then `aws configure sso`, `aws sso login --profile {profile name}` and `export AWS_PROFILE={profile name}`
    
1. Clone the repo and cd into it

    ```shell
    cd AWS/tf-provider
    ```

1. Update the variables input file with your parameters

```bash
nano input_vars.tfvars.json
```

```json
{
    "er_map_be": [
        {
            "edgeRouterKey": "55JMPJ8B4W",
            "dnsSvcIpRange": "100.64.0.0/13",
            "zone": "a",
            "publicSubnet": "10.40.101.0/24"
        },
        {
            "edgeRouterKey": "7Z7JS9MEB4",
            "dnsSvcIpRange": "100.72.0.0/13",
            "zone": "b",
            "publicSubnet": "10.40.102.0/24"
        }
    ]
}
```

1. Initialize terraform

    ```bash
    terraform init
    ```

1. Run the plan

    ```bash
    terraform plan -var-file input_vars.tfvars.json -var 'region=us-east-2'
    ```

1. Apply the plan if no errors otherwise fix them

    ```bash
    terraform apply -var-file input_vars.tfvars.json -var 'region=us-east-2'
    ```

1. At this point, one should have GLB deployed with 2 Backend Edge Routers along with 2 Ubuntu VM Test Clients.

    ***Note: The Client VM Resolver is configured  to point to the edge router resolver for dns based services. Details of what was done***

    ```shell
    sudo vi /etc/systemd/resolved.conf
    # uncomment dns and add edge router resolver
    ...
    [Resolve]
    DNS=100.127.255.254
    ...
    ```

1. Destroy the plan if required

    ```bash
    terraform destroy -var-file input_vars.tfvars.json -var 'region=us-east-2'
    ```

Note:
One can deploy this in more than one region by using workspace option and passing region variable with the command line var option instead of including it in the vars file.

```bash
terraform workspace new us-east-2
terraform apply -var-file input_vars.tfvars.json -var 'region=us-east-2'
```
