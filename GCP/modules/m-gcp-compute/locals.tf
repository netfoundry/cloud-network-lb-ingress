locals {
    ufw_string = "/usr/sbin/ufw, allow, in, to, any, port, 8081, proto, tcp, from"
    user_data = [ for s in var.er_reg_keys : "#cloud-config\nruncmd:\n- [/opt/netfoundry/router-registration, ${s}]\n- [${local.ufw_string}, 35.191.0.0/16]\n- [${local.ufw_string}, 130.211.0.0/22]"
    ]
}