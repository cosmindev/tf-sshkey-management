# Copyright (c) 2019 Oracle and/or its affiliates,  All rights reserved.

# get current AD
data "oci_identity_availability_domains" "this" {
  compartment_id = var.compartment_id
}

# VCN
resource "oci_core_vcn" "techflow_vcn" {
  #Required
  cidr_block     = "10.0.0.0/16"
  compartment_id = var.compartment_id

  #Optional
  defined_tags  = {}
  display_name  = "techflow_vcn"
  dns_label     = "techflow"
  freeform_tags = {}
}

# Internet Gateway
resource "oci_core_internet_gateway" "techflow_ig" {
  #Required
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.techflow_vcn.id

  #Optional
  enabled       = true
  defined_tags  = {}
  display_name  = "techflow_ig"
  freeform_tags = {}
}

# Route Table
resource "oci_core_route_table" "techflow_route_table" {
  #Required
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.techflow_vcn.id

  #Optional
  defined_tags  = {}
  display_name  = "techflow_route_table"
  freeform_tags = {}
  route_rules {
    #Required
    network_entity_id = oci_core_internet_gateway.techflow_ig.id

    #Optional
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
  }
}

# Network Security Group
resource "oci_core_network_security_group" "techflow_nsg" {
  #Required
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.techflow_vcn.id

  #Optional
  defined_tags  = {}
  display_name  = "techflow_nsg"
  freeform_tags = {}
}

# Network Security Group Security Rule port 22 ingress
resource "oci_core_network_security_group_security_rule" "techflow_22_ingress_nsg_sec_rule" {
  #Required
  network_security_group_id = oci_core_network_security_group.techflow_nsg.id
  direction                 = "INGRESS"
  protocol                  = "6"

  #Optional
  description = "techflow_nsg_sec_rule"
  source      = "0.0.0.0/0"
  source_type = "CIDR_BLOCK"
  stateless   = false
  tcp_options {

    #Optional
    destination_port_range {
      #Required
      max = 22
      min = 22
    }
  }
}

# Network Security Group Security Rule all ports egress
resource "oci_core_network_security_group_security_rule" "techflow_all_egress_nsg_sec_rule" {
  #Required
  network_security_group_id = oci_core_network_security_group.techflow_nsg.id
  direction                 = "EGRESS"
  protocol                  = "6"

  #Optional
  description      = "techflow_nsg_sec_rule"
  destination      = "0.0.0.0/0"
  destination_type = "CIDR_BLOCK"
  stateless        = false
  tcp_options {
  }
}

# dhcp_options
resource "oci_core_dhcp_options" "techflow_dhcp_options" {
  #Required
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.techflow_vcn.id
  options {
    type        = "DomainNameServer"
    server_type = "VcnLocalPlusInternet"
  }

  options {
    type                = "SearchDomain"
    search_domain_names = ["test.com"]
  }

  #Optional
  display_name = "techflow_dhcp_options"
}

# subnet
resource "oci_core_subnet" "techflow_subnet" {
  #Required
  cidr_block     = "10.0.0.0/24"
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.techflow_vcn.id

  #Optional
  availability_domain        = null
  defined_tags               = {}
  dhcp_options_id            = oci_core_dhcp_options.techflow_dhcp_options.id
  display_name               = "techflow_subnet"
  dns_label                  = "techflow"
  freeform_tags              = {}
  ipv6cidr_block             = null
  prohibit_public_ip_on_vnic = false
  route_table_id             = oci_core_route_table.techflow_route_table.id
}

# block volumes
resource "oci_core_volume" "techflow_volumes" {
  count = var.cluster_size
  #Required
  availability_domain = lookup(data.oci_identity_availability_domains.this.availability_domains[count.index], "name")
  compartment_id      = var.compartment_id

  #Optional
  defined_tags  = {}
  display_name  = "techflow_volume_${count.index}"
  freeform_tags = {}
  size_in_gbs   = "50"
}

# instances
resource "oci_core_instance" "techflow_instances" {
  count = var.cluster_size
  #Required
  availability_domain = lookup(data.oci_identity_availability_domains.this.availability_domains[count.index], "name")
  compartment_id      = var.compartment_id
  shape               = "VM.Standard2.1"

  create_vnic_details {
    #Required
    subnet_id = oci_core_subnet.techflow_subnet.id

    #Optional
    assign_public_ip       = true
    defined_tags           = {}
    display_name           = "techflow_instance_${count.index}_vnic_01"
    freeform_tags          = {}
    hostname_label         = "techflowinstance${count.index}"
    nsg_ids                = [oci_core_network_security_group.techflow_nsg.id]
    skip_source_dest_check = false
  }
  defined_tags   = {}
  display_name   = "techflow_instance_${count.index}"
  freeform_tags  = {}
  hostname_label = "techflowinstance${count.index}"
  metadata = {
        ssh_authorized_keys = chomp(file("/Users/cotudor/my_ssh_keys/cos_key.pub"))
  }
  source_details {
    #Required
    source_id   = "ocid1.image.oc1.eu-frankfurt-1.aaaaaaaajqghpxnszpnghz3um66jywaw5q3pudfw5qwwkyu24ef7lcsyjhsq"
    source_type = "image"
  }
  preserve_boot_volume = false
}

resource "oci_core_volume_attachment" "techflow_volumes_attachments" {
  count = var.cluster_size
  #Required
  attachment_type = "iscsi"
  instance_id     = oci_core_instance.techflow_instances[count.index].id
  volume_id       = oci_core_volume.techflow_volumes[count.index].id

  connection {
    type        = "ssh"
    host        = oci_core_instance.techflow_instances[count.index].public_ip
    port        = "22"
    user        = "opc"
    private_key = chomp(file("/Users/cotudor/my_ssh_keys/cos_key.openssh"))
  }

  # register and connect the iSCSI block volume
  provisioner "remote-exec" {
    inline =  [
      "sudo -s bash -c 'iscsiadm -m node -o new -T ${self.iqn} -p ${self.ipv4}:${self.port}'",
      "sudo -s bash -c 'iscsiadm -m node -o update -T ${self.iqn} -n node.startup -v automatic '",
      "sudo -s bash -c 'iscsiadm -m node -T ${self.iqn} -p ${self.ipv4}:${self.port} -l '",
      "sudo -s bash -c 'mkfs.ext4 -F /dev/sdb'",
      "sudo -s bash -c 'mkdir -p /u01'",
      "sudo -s bash -c 'mount -t ext4 /dev/sdb /u01 '",
      "echo '/dev/sdb  /u01 ext4 defaults,noatime,_netdev,nofail    0   2' | sudo tee --append /etc/fstab > /dev/null",
    ]
  }

  # unmount and disconnect on destroy
  provisioner "remote-exec" {
    when       = destroy
    on_failure = continue

    inline = concat(
      [
        "if [ 'true' = 'true' ]; then",
        "  set -x",
        "fi",
        "export DEVICE_ID=ip-${self.ipv4}:${self.port}-iscsi-${self.iqn}-lun-1",
      ],
      [
        "sleep 5 # ensure all unmount operations have completed",
        "sudo iscsiadm -m node -T ${self.iqn} -p ${self.ipv4}:${self.port} -u",
        "sudo iscsiadm -m node -o delete -T ${self.iqn} -p ${self.ipv4}:${self.port}",
      ],
    )
  }

}