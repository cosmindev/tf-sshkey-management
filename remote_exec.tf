# Copyright (c) 2019 Oracle and/or its affiliates,  All rights reserved.


resource "null_resource" "add_ssh_key" {
  count = var.add_public_ssh_key == true ? var.cluster_size : 0

  provisioner "remote-exec" {
    connection {
      user        = "opc"
      agent       = false
      private_key = chomp(file("/Users/cotudor/my_ssh_keys/cos_key.openssh"))
      timeout     = "10m"
      host        = oci_core_instance.techflow_instances[count.index].public_ip
    }

    inline = [
      "echo ${chomp(file(var.new_ssh_public_key))} >> /home/opc/.ssh/authorized_keys",
    ]
  }
}

resource "null_resource" "replace_all_ssh_keys" {
  count = "${var.replace_all_public_ssh_keys == true ? var.cluster_size : 0}"

  provisioner "remote-exec" {
    connection {
      user        = "opc"
      agent       = false
      private_key = chomp(file("/Users/cotudor/my_ssh_keys/cos_key.openssh"))
      timeout     = "10m"
      host        = oci_core_instance.techflow_instances[count.index].public_ip
    }

    inline = [
      "echo ${chomp(file(var.new_ssh_public_key))} > /home/opc/.ssh/authorized_keys",
    ]
  }
}

resource "null_resource" "replace_one_ssh_key" {
  count = "${var.remove_public_ssh_key == true ? var.cluster_size : 0}"

  provisioner "remote-exec" {
    connection {
      user        = "opc"
      agent       = false
      private_key = chomp(file("/Users/cotudor/my_ssh_keys/cos_key.openssh"))
      timeout     = "10m"
      host        = oci_core_instance.techflow_instances[count.index].public_ip
    }

    inline = [
      "grep -v ${local.key_string} /home/opc/.ssh/authorized_keys > /home/opc/.ssh/tmp_authorized_keys ",
      "rm /home/opc/.ssh/authorized_keys",
      "mv /home/opc/.ssh/tmp_authorized_keys /home/opc/.ssh/authorized_keys",
      "chmod 600 /home/opc/.ssh/authorized_keys"
    ]

  }
}

locals {
  key_string   = "${format("%s%s%s", local.single_quote, chomp(file(var.to_be_removed_public_key)), local.single_quote)}"
  single_quote = "'"
  double_quote = "\\\""
}


