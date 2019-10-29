# Copyright (c) 2019 Oracle and/or its affiliates,  All rights reserved.

output "techflow_vcn" {
  value = oci_core_vcn.techflow_vcn
}

output "techflow_ig" {
  value = oci_core_internet_gateway.techflow_ig
}

output "techflow_route_table" {
  value = oci_core_route_table.techflow_route_table
}

output "techflow_nsg" {
  value = oci_core_network_security_group.techflow_nsg
}

output "techflow_nsg_ingress_22_rule" {
  value = oci_core_network_security_group_security_rule.techflow_22_ingress_nsg_sec_rule
}

output "techflow_nsg_egress_all_rule" {
  value = oci_core_network_security_group_security_rule.techflow_all_egress_nsg_sec_rule
}

output "techflow_dhcp_options" {
  value = oci_core_dhcp_options.techflow_dhcp_options
}

output "techflow_subnet" {
  value = oci_core_subnet.techflow_subnet
}

output "techflow_volumes" {
  value = oci_core_volume.techflow_volumes
}

output "techflow_instances" {
  value = oci_core_instance.techflow_instances
}

output "techflow_volumes_attachments" {
  value = oci_core_volume_attachment.techflow_volumes_attachments
}
