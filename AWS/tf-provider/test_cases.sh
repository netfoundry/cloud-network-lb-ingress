#!/bin/bash

get_nf_network_id () {

    export network_list=`curl --silent --location --request GET "https://gateway.production.netfoundry.io/core/v2/networks" \
           --header "Content-Type: application/json" \
           --header "Authorization: $token_type $token"`
    export NETWORK_ID=`echo $network_list | jq -r --arg NF_NETWORK_NAME "$NF_NETWORK_NAME" '._embedded.networkList[] | select(.name==$NF_NETWORK_NAME).id'`
    export NETWORK_STATUS=`echo $network_list | jq -r --arg NF_NETWORK_NAME "$NF_NETWORK_NAME" '._embedded.networkList[] | select(.name==$NF_NETWORK_NAME).status'`

}

resume_network () {

    if [ -n "$NF_NETWORK_NAME" ]; then
        get_nf_network_id
        if [ -n "$NETWORK_ID" ] && [ "$NETWORK_STATUS" == "SUSPENDED" ]; then
            echo "Resuming Network ID $NETWORK_ID!"
            network_resume_response=`curl --silent --location --request POST "https://gateway.production.netfoundry.io/core/v2/networks/$NETWORK_ID/resume" \
                    --header "Content-Type: application/json" \
                    --header "Authorization: $token_type $token"`

            while : ; do
                sleep 15
                network_status=`curl --silent --location --request GET "$(echo $network_resume_response | jq -r ._links.execution.href)" \
                --header "Content-Type: application/json" \
                --header "Authorization: $token_type $token"`
                if [ "$(echo $network_status | jq -r .status)" == "SUCCESS" ]; then
                    echo "The event is to \"$(echo $network_status | jq -r .description)\"."
                    echo "The status is $(echo $network_status | jq -r .status), and Network ID is $(echo $network_status | jq -r .resourceId)."
                    break
                fi
                echo "Network ID $(echo $network_status | jq -r .resourceId) is being resumed".
                echo "The status is $(echo $network_status | jq -r .status)"
            done

            return
        fi
        if [ "$NETWORK_STATUS" == "PROVISIONED" ]; then
            echo "The network status is already $NETWORK_STATUS"
            unset NETWORK_STATUS
            return
        fi
    fi

    echo "Network Name or ID is not found: $NF_NETWORK_NAME or $NETWORK_ID!"
    echo "Failed to resume the network: $NF_NETWORK_NAME!"
    exit 1

}

suspend_network () {

    if [ -n "$NF_NETWORK_NAME" ]; then
        get_nf_network_id
        if [ -n "$NETWORK_ID" ]; then
            echo "Suspending Network ID $NETWORK_ID!"
            network_suspend_response=`curl --silent --location --request POST "https://gateway.production.netfoundry.io/core/v2/networks/$NETWORK_ID/suspend" \
                    --header "Content-Type: application/json" \
                    --header "Authorization: $token_type $token"`

            while : ; do
                sleep 15
                network_status=`curl --silent --location --request GET "$(echo $network_suspend_response | jq -r ._links.execution.href)" \
                --header "Content-Type: application/json" \
                --header "Authorization: $token_type $token"`
                if [ "$(echo $network_status | jq -r .status)" == "SUCCESS" ]; then
                    echo "The event is to \"$(echo $network_status | jq -r .description)\"."
                    echo "The status is $(echo $network_status | jq -r .status), and iNetwork ID is $(echo $network_status | jq -r .resourceId)."
                    unset NETWORK_ID
                    break
                fi
                echo "Network ID $(echo $network_status | jq -r .resourceId) is being suspended".
                echo "The status is $(echo $network_status | jq -r .status)"
            done

            return
        fi
    fi
    echo "Network Name or ID is not found: $NF_NETWORK_NAME or $NETWORK_ID!"
    echo "Failed to suspend the network: $NF_NETWORK_NAME!"
    exit 1

}

get_nf_router_id () {
    if [ -n "$NF_NETWORK_NAME" ]; then
        get_nf_network_id
        if [ -n "$NETWORK_ID" ]; then
            er_create_response=`curl --silent --location --request GET "https://gateway.production.netfoundry.io/core/v2/edge-routers?name=$ER&networkId=$NETWORK_ID" \
                --header "Content-Type: application/json" \
                --header "Authorization: $token_type $token"`
            total_er_count=`echo $er_create_response |jq -r .page.totalElements`
            if [[ $total_er_count > 0 ]]; then
                export ER_ID=`echo $er_create_response | jq -r --arg ER_NAME "$ER" '._embedded.edgeRouterList[] | select(.name==$ER_NAME).id'`
                echo "ER ID is $ER_ID!"
                return
            fi
        fi
    fi
    unset ER_ID
    echo "All or none from Network Name or Network ID or Router ID is not found: $NF_NETWORK_NAME or $NETWORK_ID or $ER_ID!"
    echo "Failed to get ER ID for $ER!"
    
}

get_nf_er_reg_keys () {

    delete_nf_er
        
    sleep 15

    er_create_response=`curl --silent --location --request POST "https://gateway.production.netfoundry.io/core/v2/edge-routers" \
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

    while : ; do
        sleep 15
        er_status=`curl --silent --location --request GET "$(echo $er_create_response | jq -r ._links.execution.href)" \
        --header "Content-Type: application/json" \
        --header "Authorization: $token_type $token"`
        if [ "$(echo $er_status | jq -r .status)" == "SUCCESS" ]; then
            echo "The event is to \"$(echo $er_status | jq -r .description)\"."
            echo "The status is $(echo $er_status | jq -r .status), and id is $(echo $er_status | jq -r .resourceId)."
            export ER_ID=`jq -r .resourceId <<< "$er_status"`
            break
        fi
        echo "ER ID $(echo $er_status | jq -r .resourceId) is being created".
        echo "The status is $(echo $er_status | jq -r .status)"
    done

    sleep 15

    if [ -n "$ER_ID" ]; then
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
        return
    fi
    echo "ER ID is not found  $ER_ID!"
    exit 1

}

delete_nf_er () {

    if [ -n "$ER" ]; then
        get_nf_router_id
        if [ -n "$ER_ID" ]; then
            echo "Deleting Edge Router $ER"
            er_delete_response=`curl --silent --location --request DELETE "https://gateway.production.netfoundry.io/core/v2/edge-routers/$ER_ID" \
                --header "Content-Type: application/json" \
                --header "Authorization: $token_type $token"`

            while : ; do
                sleep 15
                er_status=`curl --silent --location --request GET "$(echo $er_delete_response | jq -r ._links.execution.href)" \
                --header "Content-Type: application/json" \
                --header "Authorization: $token_type $token"`
                if [ "$(echo $er_status | jq -r .status)" == "SUCCESS" ]; then
                    echo "The event is to \"$(echo $er_status | jq -r .description)\"."
                    echo "The status is $(echo $er_status | jq -r .status), and id is $(echo $er_status | jq -r .resourceId)."
                    unset ER_ID
                    break
                fi
                echo "ER ID $(echo $er_status | jq -r .resourceId) is being deleted".
                echo "The status is $(echo $er_status | jq -r .status)"
            done

            return
        fi
    fi
    echo "ER Name or ID is empty for $ER or $ER_ID!"
    echo "Skipping router delete"

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
    resume_network
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
    suspend_network

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


