
## Deploy LoadBalancer and 2 Customer Hosted Edge Routers to your Virtual Cloud Network

This terraform plan when used will create a new load balancer and 2 new NF Edge Routers in your existing virtual network (vcn). All NLB associated resources and options will be created/configured as well, among other things health checks to each ER, the lb algorithm will be set to "Five Tuple", and backend pool will be set to 2 ERs created part of this deployment. Obviously, one can add more ERs or change any configuration option once all the resources are created. The vcn name, subnet prefix, and route table name must be provided. It is recommended to use a dedicated subnet prefix for this deployment.

**PREREQUISITES** 
Need to Create 2 Customer Hosted Edge Routers on your NF Network using the following link [Get Reg Keys](https://nfconsole.io/login) and copy registration keys in the input variables file under nf_router_registration_key_list.

**STEPS** 
If you need such HA set up in more than one region, you can rerun it more than once. Just don't forget to change the region name. The next iteration of this deployment plan could be to  modify the input variables into a list, so one can deploy network load balancers in multiple regions at a time. This would also help with keeping the latest state of the deployed plan in one location for the entire network.

1. Install Terraform

    [Get Terraform](https://www.terraform.io/downloads)

1. Set up your OCI provider Authetication

    [Add API Key-Based Authentication](https://docs.oracle.com/en-us/iaas/developer-tutorials/tutorials/tf-provider/01-summary.htm#:~:text=Add%20API%20Key%2DBased%20Authentication)

1. Clone the repo and cd into cloud-network-lb-ingress/OCI
1. Update the variables input file with your parameters
    ```bash
    nano input_vars.tfvars.json
    ```
    ```json
    {
        "region": "",
        "compartment_id": "",
        "nf_subnet_cidr": "",
        "vcn_name": "",
        "route_table_name": "",
        "nf_router_registration_key_list": []
    }
1.  Initialize terraform
    ```bash
    terraform init
    ```
1.  Run the plan

    ```bash
    terraform plan -var-file input_vars.tfvars.json
    ```

1. Apply the plan if no errors otherwise fix them

    ```bash
    terraform apply -var-file input_vars.tfvars.json
    ```

1. At this point the destination prefixes that need to be forwarded across the NetFoundry Network can be configured in the route table that was provided for this plan. The next hop ip will be the private ip address of the network load balancer created by this plan. Furthermore, the security group for the netfoundry edge routers are set to only allow traffic in from the subnet that they are deployed in by default. If sessions originated from other subnets in the virtual network need to be forwarded through the load balancer, then one needs to add the ingress rules to allow that to happen.

1. Destroy the plan if required

    ```bash
    terraform destroy -var-file input_vars.tfvars.json
    ```

**TESTING NOTE** \
If one wants to test the configuration before deployment, it can be done on the new virtual network. The new virtual network will be created by the terraform plan. To do that enable the following parameters in the variables file (i.e input_vars.tfvars.json).

```json
"include_m_oci_vcn": true,
"vcn_cidr": "10.100.0.0/16"
```