
## Deploy LoadBalancer and 2 Customer Hosted Edge Routers to your Resource Group
This arm template when used will create a new load balancer and 2 new NF Edge Routers in your existing/new resource group. All NLB associated resources and options will be created/configured as well, among other things health checks to each ER, the lb algorithm will be set to "SourceIPProtocol", and backend pool will be set to 2 ERs created part of this deploymnet. Obviously, one can add more ERs or change any configuration option once all the resources are created. The vnet and route table names must be provided either of existing resources or new unique names to be used for creation of such resources. It is recommended to use a new or existing dedicated subnet prefix for this deployment.

***PREREQUISITES***
    Need to Create 2 Customer Hosted Edge Routers on your NF Network using the [Get Reg Keys](https://nfconsole.io/login) and save registration keys

***STEPS***
    If you need such HA set up in more than one region, you can rerun it more than once. Just don't forget to change the region name. You can use Azure Cli or Azure Button.

1. az cli

***IMPORTANT***
    Update the parameters file to match your Azure Cloud / NetFoundry configurations, and install azure cli for your os. If you want to change any of the default values, you can just add the new value to the parameters file, i.e.
```json
{
    ...
    "subnet":{"value": "10.1.1.0/24"}
    ...
}
```
```bash
git git@github.com:netfoundry/azure-deploy.git
cd azure-deploy/NetworkLoadBalancer/Azure
az login
az deployment group create --subscription "Your Subscription ID"   --resource-group "Your RG" --template-file template.json --parameters parameters.json
```
2. Using Azure Button
[![Deploy to Azure](https://azurecomcdn.azureedge.net/mediahandler/acomblog/media/Default/blog/deploybutton.png)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FNetFoundry%2Fazure-deploy%2Fmaster%2FNetworkLoadBalancer%2FAzure%2Ftemplate.json)
