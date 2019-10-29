# Copyright (c) 2019 Oracle and/or its affiliates,  All rights reserved.


###################
# tenancy details
###################
variable "tenancy_id" {}
variable "user_id" {}
variable "fingerprint" {}
variable "private_key_path" {}
variable "region" {}
variable "compartment_id" {}

#######################
# configuration details
#######################

variable cluster_size {}

#######################
# ssh_key_management
#######################
variable new_ssh_public_key {}
variable new_ssh_private_key {}
variable add_public_ssh_key {}
variable replace_all_public_ssh_keys {}
variable remove_public_ssh_key {}
variable to_be_removed_public_key {}





