locals {
    route_table_list =  concat(var.public_rt_ids, formatlist(var.default_rt_id))
}