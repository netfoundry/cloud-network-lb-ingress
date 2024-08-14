#!/bin/bash

get_nf_network_id () {

    export network_list=`curl --silent --location --request GET "https://gateway.production.netfoundry.io/core/v2/networks" \
           --header "Content-Type: application/json" \
           --header "Authorization: $token_type $token"`
    export NETWORK_ID=`echo $network_list | jq -r --arg NF_NETWORK_NAME "$NF_NETWORK_NAME" '._embedded.networkList[] | select(.name==$NF_NETWORK_NAME).id'`

}

get_nf_er_reg_keys () {

    get_nf_network_id
    export ER_RESP=`curl --silent --location --request POST "https://gateway.production.netfoundry.io/core/v2/edge-routers" \
        --header "Content-Type: application/json" \
        --header "Authorization: $token_type $token" \
        --data "{
            \"name\":\"$ER\",
            \"networkId\":\"$NETWORK_ID\",
            \"linkListener\":false,
            \"attributes\":[],
            \"tunnelerEnabled\": true,
            \"noTraversal\": false
        }"`
    export ER_ID=`jq -r .id <<< "$ER_RESP"`
    sleep 10
    export ER_KEY_JSON=`curl --silent --location --request POST "https://gateway.production.netfoundry.io/core/v2/edge-routers/$ER_ID/registration-key" \
        --header "Content-Type: application/json" \
        --header "Authorization: $token_type $token"`
    export ER_KEY=`jq -r .registrationKey <<< "$ER_KEY_JSON"` 
    jq ".er_map_be[$COUNT].edgeRouterKey = \"$ER_KEY\"" input_vars.tfvars.json > "tmp" && mv "tmp" input_vars.tfvars.json
    jq ".er_map_be[$COUNT].name = \"$ER\"" input_vars.tfvars.json > "tmp" && mv "tmp" input_vars.tfvars.json
    ER_IDENT_RESP=`curl --silent --location --request GET "https://gateway.production.netfoundry.io/core/v2/endpoints?name=$ER" \
        --header "Content-Type: application/json" \
        --header "Authorization: $token_type $token"`
    ER_IDENT_ID=`jq -r ._embedded.endpointList[0].id <<< "$ER_IDENT_RESP"`
    curl --silent --location --request PATCH "https://gateway.production.netfoundry.io/core/v2/endpoints/$ER_IDENT_ID" \
        --header "Content-Type: application/json" \
        --header "Authorization: $token_type $token" \
        --data "{\"attributes\": [\"#$ATTRIBUTE\"]}"

}

delete_nf_er () {

    export ER_RESP=`curl --silent --location --request GET "https://gateway.production.netfoundry.io/core/v2/edge-routers?name=$ER" \
        --header "Content-Type: application/json" \
        --header "Authorization: $token_type $token"`
    export ER_ID=`jq -r ._embedded.edgeRouterList[0].id <<< "$ER_RESP"`
    curl --silent --location --request DELETE "https://gateway.production.netfoundry.io/core/v2/edge-routers/$ER_ID" \
        --header "Content-Type: application/json" \
        --header "Authorization: $token_type $token"

}

get_nf_token () {

    if [ -z "$NF_API_CLIENT_ID" ] && [ -z "$NF_API_CLIENT_SECRET" ]; then
        echo " NF Environmental Var Creds not set, it will use the NF Creds File in home directory"
        export NF_API_CLIENT_ID=`jq -r .clientId $NF_API_CREDENTIALS_PATH`
        export NF_API_CLIENT_SECRET=`jq -r .password $NF_API_CREDENTIALS_PATH`
    else
        echo " NF Environmental Var Creds set!!!"
    fi
    export RESPONSE=`curl --silent --location --request POST "https://netfoundry-production-xfjiye.auth.us-east-1.amazoncognito.com/oauth2/token" \
                        --header "Content-Type: application/x-www-form-urlencoded" \
                        --user "$NF_API_CLIENT_ID:$NF_API_CLIENT_SECRET" --data-urlencode "grant_type=client_credentials"`
    export token=`echo $RESPONSE |jq -r .access_token`
    export token_type=`echo $RESPONSE |jq -r .token_type`

}

run () {

    get_nf_token
    terraform init -backend-config=backend.tfvars.json
    x=0
    for region in "${REGIONS[@]}"
    do
        y=0
        export AWS_REGION=$region
        export ATTRIBUTE="${ATTRIBUTES[$x]}"
        terraform workspace select -or-create=true $AWS_REGION
        ANY_RESOURCES=`terraform state list |wc -l`
        if [ $ANY_RESOURCES > 0 ]; then
            terraform apply -destroy -var-file input_vars.tfvars.json -var region=$AWS_REGION -auto-approve
        fi
        for router in "${ROUTERS[@]}"
        do
            export COUNT=$y
            export ER="$router-$region"
            get_nf_er_reg_keys
            let "y++"
        done
        terraform apply -var-file input_vars.tfvars.json -var region=$AWS_REGION -auto-approve
        let "x++"
    done
    
} 

cleanup () {

    get_nf_token
    for region in "${REGIONS[@]}"
    do
        export AWS_REGION=$region
        for router in "${ROUTERS[@]}"
        do 
            export ER="$router-$region"
            delete_nf_er
        done
        terraform workspace select $AWS_REGION
        terraform apply -destroy -var-file input_vars.tfvars.json -var region=$AWS_REGION -auto-approve
    done

    terraform workspace select default
    sleep 300
    for workspace in $(terraform workspace list | grep -v default)
    do
        terraform workspace delete $workspace
    done

}

env_vars () {

    export NF_API_CREDENTIALS_PATH="$HOME/.netfoundry/credentials.json"
    export REGIONS=(us-west-2 us-east-2)
    export ATTRIBUTES=(bind-services novis)
    ROUTERS=()
    if [ -z $NF_NETWORK_NAME ]; then export NF_NETWORK_NAME="dariuszdev"; fi
    if [ -z $ROUTER_PREFIX ]; then export ROUTER_PREFIX="be-er"; fi
    if [ -z $ROUTER_COUNT ]; then export ROUTER_COUNT=2; fi

    for (( c=1; c<=$ROUTER_COUNT; c++ ))
    do
        ROUTERS+=("$ROUTER_PREFIX-$c")
    done
    export ROUTERS

}

# Main Program
if [ $# -ne 1 ]; then
     echo "You need to provide an action [run/cleanup]"
     exit 0
fi
 
env_vars

case $1 in

    run)
        run
        ;;

    cleanup)
        cleanup
        ;;
    
    *)
    echo "unknown action"
    exit 0
    ;;

esac


