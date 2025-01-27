locals {
    er_list = tomap({
        for i, er in range(0,var.num_instances,1) :
        er => {key = var.er_reg_keys[i], ip = var.dns_svc_ip_range[i]}
    })

    user_data = [ for v in local.er_list : <<EOF
#cloud-config
runcmd:
- |
  LANIF="$(/sbin/ip -o link show up|awk '$9=="UP" {print $2;}'|head -1|tr -d ":")"
  /opt/netfoundry/set-ip.sh -tp=static -ip=${var.tunnel_ip} -pr=32 -in="lo" -f
  /opt/netfoundry/router-registration --dnsIPRange ${v.ip} --tunnel_ip ${var.tunnel_ip} --lanIf $LANIF ${v.key}
EOF
  ]
}