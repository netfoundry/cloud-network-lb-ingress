locals {
    er_zones_map = tomap({
        for i, zone in var.zone_list :
        zone => {key = var.er_reg_keys[i], ip = var.dns_svc_ip_range[i]}
    })

    user_data = [ for v in local.er_zones_map : <<EOF
#cloud-config
runcmd:
- |
  LANIF="$(/sbin/ip -o link show up|awk '$9=="UP" {print $2;}'|head -1|tr -d ":")"
  /opt/netfoundry/set-ip.sh -tp=static -ip=${var.tunnel_ip} -pr=32 -in="lo" -f
  /opt/netfoundry/router-registration --dnsIPRange ${v.ip} --tunnel_ip ${var.tunnel_ip} --lanIf $LANIF ${v.key}
  /usr/sbin/ufw allow in to any port 8081 proto tcp from 35.191.0.0/16
  /usr/sbin/ufw allow in to any port 8081 proto tcp from 130.211.0.0/22
EOF
  ]
}