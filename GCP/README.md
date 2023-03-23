## Deploy LoadBalancer and 2 Customer Hosted Edge Routers to your VPC Network

This terraform plan when used will create a new load balancer and 2 new NF Edge Routers in your existing VPC network. All NLB associated resources and options will be created/configured as well, among other things health checks to each ER, the lb algorithm will be set to "CLIENT_IP_PORT_PROTO", and backend pool will be set to 2 ERs created part of this deployment. Obviously, one can add more ERs or change any configuration option once all the resources are created. The vcn name, subnet prefix must be provided. It is recommended to use a dedicated subnet prefix for this deployment.

**PREREQUISITES** \
Need to Create 2 Customer Hosted Edge Routers on your NF Network using the following link [Get Reg Keys](https://nfconsole.io/login) and copy registration keys in the input variables file under nf_router_registration_key_list.

**STEPS** 
1. Install Terraform

    [Get Terraform](https://www.terraform.io/downloads)

1. Set up your service account and get API CRED JSON file

    [Create Service Account](https://cloud.google.com/iam/docs/creating-managing-service-accounts)
    
    [Api Key](https://cloud.google.com/iam/docs/creating-managing-service-account-keys)

1. Clone the repo and cd into NetworkLoadBalancer/GCP/tf-provider
1. Create provider.tf in this folder with the api file details in it as shown:
    ```powershell
    provider "google" {
        project     = "YOUR PROJECT NAME"
        region      = "us-east1"
        zone        = "us-east1-b"
        credentials = pathexpand(var.gcp-creds)
    }

    variable "gcp-creds" {
        default = "~/.gcp/nf-cloud-dev-700d695c36c3.json"
    }
    ```
    ***Note - Multiregion Deployment***

    To deploy in more than one region, one can use workspaces if the creds or access controls are the same(not recommended if not [as state here](https://www.terraform.io/language/state/workspaces#using-workspaces)). Here is how to initialize them. You would need to update the region and nf_subnet_cidr in your input_vars.tfvars.json as well when you switch workspaces and you want to create a new region.

    ```bash
    terraform workspace new us-east1
    terraform workspace new us-west1
    etc...
    ```
    Then you can list or select one:
    ```
    terraform workspace list
    terraform workspace select us-west1
    ```
1.  Initialize terraform
    ```bash
    terraform init
    ```
1. Update the variables input file with your parameters
    ```bash
    nano input_vars.tfvars.json
    ```
    ```json
    {
        "region": "us-east1",
        "nf_subnet_cidr": "10.2.0.0/24",
        "vcn_name": "nf-lb-test-01",
        "nf_router_registration_key_list": ["EF1ZII5Z5S","BU15J943VF"]
    }
    ```
1. Run the plan

    ```bash
    terraform plan -var-file input_vars.tfvars.json
    ```

1. Apply the plan if no errors otherwise fix them

    ```bash
    terraform apply -var-file input_vars.tfvars.json
    ```

1. At this point the destination prefixes that need to be forwarded across the NetFoundry Network can be configured in the routes section under  VPC Network. Select a forwarding rule of internal TCP/UDP load balancer created by this plan as the next hop ip, one to reach TCP and one for UDP LB. Furthermore, the network firewall policy for the netfoundry edge routers are set to only allow traffic in from the subnet that they are deployed in by default. If sessions originated from other subnets in the virtual network need to be forwarded through the load balancer, then one needs to add the ingress rules to allow that to happen.

1. Destroy the plan if required

    ```bash
    terraform destroy -var-file input_vars.tfvars.json
    ```

**TESTING NOTE**

If one wants to test the configuration before deployment, it can be done on the new virtual network. The new virtual network will be created by the terraform plan. To do that enable the following parameters in the root terrafrom file (i.e .tf).

```powershell
    module "vcn1" {
        ...
        create_vcn = true
    }
```