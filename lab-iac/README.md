# Besturingssystemen 3 Lab 7 - Infrastructure as Code

This repository contains the necessary files for this lab.

## Getting started

Install Terraform

```bash
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install terraform
touch ~/.bashrc
terraform -install-autocomplete
sudo snap install code --classic
code --install-extension HashiCorp.terraform
```

Install ansible

```bash
pip3 install ansible
```

Configure terraform to use your GCE credentials.

1. Go to [the GCP console](https://console.cloud.google.com) and get the project ID of the project you created in the cloud lab.
1. Make sure the following api's are enabled for this project by going to their respective API settings, choosing your project in the dropdown in the top bar, and checking if you see "API Enabled". If not, press "ENABLE".
   * [GCP](https://console.developers.google.com/apis/library/compute.googleapis.com)
   * [Cloud SQL Admin API](https://console.developers.google.com/apis/api/sqladmin.googleapis.com/overview)
1. Create a GCP service account key by going to [the credentials console](https://console.cloud.google.com/apis/credentials/serviceaccountkey)
   1. choose your project in the dropdown in the top bar
   1. click `CREATE SERVICE ACCOUNT`
   1. give it any name you like and click `CREATE`
   1. choose the role `Basic` > `Editor`
   1. click `CONTINUE`
   1. in the table of service accounts, press the three dots in the Actions column and choose `Manage Keys`.
   1. press `ADD KEY` > `Create new key`
   1. Choose Key type `JSON` and press `CREATE`.
   1. Save the key on your system.
1. Modify `credentials` in `main.tf` to point to your downloaded credential file. (`~` is a shorthand for your home directory)
1. Modify `project` in `main.tf` to point to your project ID (this is different from the project name!).

To test if everything works, run the following commands in the root of this repository.

```bash
$ terraform init
$ terraform apply
Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # google_compute_network.vpc_network will be created
  + resource "google_compute_network" "vpc_network" {
      + auto_create_subnetworks         = true
      + delete_default_routes_on_create = false
      + gateway_ipv4                    = (known after apply)
      + id                              = (known after apply)
      + ipv4_range                      = (known after apply)
      + name                            = "terraform-network"
      + project                         = (known after apply)
      + routing_mode                    = (known after apply)
      + self_link                       = (known after apply)
    }

Plan: 1 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

google_compute_network.vpc_network: Creating...
google_compute_network.vpc_network: Still creating... [10s elapsed]
google_compute_network.vpc_network: Still creating... [20s elapsed]
google_compute_network.vpc_network: Still creating... [30s elapsed]
google_compute_network.vpc_network: Still creating... [40s elapsed]
google_compute_network.vpc_network: Creation complete after 47s [id=projects/sysadmin-test-307123/global/networks/terraform-network]
```

If this works, you can start the lab by following the instructions in [lab.md](./lab.md).

## Copyright

You can use and modify this lab as part of your education, but you are not allowed to share this lab, your modifications, and your solutions. Please contact the teaching staff if you want to use (part of) this lab for teaching other courses.

Copyright © teaching staff of the course "Besturingssystemen 3" (E765002A) at the Faculty of Engineering and Architecture - Ghent University.
