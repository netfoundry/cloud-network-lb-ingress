locals {
    user_data = [ for s in var.er_reg_keys : "#cloud-config\nruncmd:\n- [/opt/netfoundry/router-registration, ${s}]"
    ]
}