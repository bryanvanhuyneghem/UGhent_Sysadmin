# Lab 7: Terraform and Ansible

## `main.tf`

With Terraform, the desired state of your infrastructure is defined in `.tf` files. When you run `terraform apply` in a directory, all `.tf` files will be combined and applied to the existing infrastructure.

The first thing to define in this file is the provider you're using. For this project, we use GCE and thus the google Terraform provider.

```tf
terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "3.5.0"
    }
  }
}
```

By executing `terraform init`, you instruct the tool to download the required providers and install them locally in the `.terraform` directory.

The second block is the provider configuration. Credentials are stored externally, so that you can't accidentally commit them to your git repository.

```tf
provider "google" {
  # The file with the GCE credentials
  credentials = file("~/sysadmin-test-307123-79fd2bedbfaa.json")
  # The _ID_ of the project
  project = "sysadmin-test-307123"
  region  = "europe-west3"
  zone    = "europe-west3-a"
}
```

Finally, `main.tf` declares two resources: a network and a firewall. Resource declarations have the following structure:

```tf
resource "<provider>_<resource_type>" "name" {
    config options.....
    key = "value"
    key2 = "another value"
}
```

* `resource` shows this block defines a resource.
* `"<provider>_<resource_type>"` shows the provider to use for this resource and the resource type.
* `"name"` is a Terraform-internal name for this resource.

The [Terraform Google provider reference documentation](https://registry.terraform.io/providers/hashicorp/google/latest/docs) contains a list of all available resources for this provider. The below code defines a network and a firewall which allows ping, ssh and HTTP traffic.

```tf
resource "google_compute_network" "vpc_network" {
  name = "terraform-network"
}

resource "google_compute_firewall" "default" {
  name    = "flask-app-firewall"
  network = "terraform-network"

  allow {
    protocol = "icmp"
  }
  allow {
    protocol = "tcp"
    ports = [
      "22"
    ]
  }
  allow {
    protocol = "tcp"
    ports = [
      "5000"
    ]
  }
}
```

Modify `main.tf` to add a VM. Use the [`google_compute_instance`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance) resource type for this. Some tips:

* Name the resource `smoketest` and give the VM the name `smoketest-vm`
* As `machine_type`, choose `"f1-micro"`.
* Make sure it's an Ubuntu VM by specifying the `boot_disk` `image` `"ubuntu-os-cloud/ubuntu-2004-lts"`.
* Add a `network_interface` connected to the defined network which has an empty `access_config`, in order to ensure the VM gets a public address.
* Have GCE create an account in the VM and add your SSH key by adding the `metadata` block inside of the resource.
  
  ```tf
  metadata = {
    ssh-keys =  "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }
  ```

  This is a feature of GCE. What terraform does is to add your public SSH key to the metadata of the VM. GCE will then create a user and add your public key to that user to enable SSH login. For more information, see [Managing SSH keys in metadata](https://cloud.google.com/compute/docs/instances/adding-removing-ssh-keys). This docs page also instructs you how to create an SSH key if you don't have one already.

When this is finished, run `terraform apply` in the root directory in order to create the resources. After everything is deployed, you can see the created resources using `terraform state list` and see the state of the VM using `terraform state show google_compute_instance.smoketest`. The `nat_ip` is the public IP of the server. SSH to the server using `ssh ubuntu@<nat_ip>` to check if the VM is reachable.

## `database.tf`

The second piece of infrastructure to deploy is the database. The file `database.tf` already contains a resource which creates a random password for MySQL of length 16 and without special characters.

```tf
resource "random_password" "mysql_password" {
  length           = 16
  special          = false
}
```

Secondly, create the database itself using the resource ["google_sql_database_instance"](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/sql_database_instance). Use `master` as the terraform name and `testdb` as the name in Google Cloud.

* Use `MYSQL_5_7` for the database version.
* Use the activation policy `ALWAYS`.
* Use the following ip configuration to allow access from anywhere:

  ```tf
  ip_configuration {
    ipv4_enabled = "true"

    authorized_networks {
      value           = "0.0.0.0/0"
      name            = "all"
    }
  }
  ```

Secondly, create a MySQL user account using the [`google_sql_user`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/sql_user) resource.

* Use `default` as the Terraform name and `ubuntu` as the name of the user in Google Cloud.
* As `instance`, you need to give the Google Cloud name of the database you declared earlier. Instead of duplicating this name, you can dynamically get the name of the database using `google_sql_database_instance.master.name`. Make sure to use this _without quotes_ so that it's interpreted as a statement and not as a string.
* As `host`, use `%`.
* As `password`, use refer to the password declared at the start of this file: `random_password.mysql_password.result`. Also write this without quotes so that it's not interpreted as a string.

As the final resource for this file, add a MySQL database to this database server. Use the [`google_sql_database`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/sql_database) type.

* As `instance`, refer to the name of the database server you declared (`google_sql_database_instance`).
* Use `testdb` as the Google Cloud name of the database and `default` as the Terraform name of the resource.

In order to make it easy to get the database address and password, you can use [Terraform `outputs`](https://www.terraform.io/docs/language/values/outputs.html). These make it easy for users to get specific information about resources. These values get shown after running `terraform apply` and can be obtained afterwards using `terraform output <output-name>`.

The file already declares an output to show the DB password. This password is marked internally in Terraform as "sensitive", which means it won't show it in arbitrary logs and output. In order to create an output for a sensitive value, you have to explicitly mark the output as `sensitive=true`.

Now create an additional output for the address of the DB named `db_address`. To do this, you need to know the name of the state variable where the ip address is stored. An easy way to obtain this is to first create the resources using `terraform apply`, and then use `terraform state list` and `terraform state show <resource-name>` to inspect the state of the resource. Run `terraform apply` and try to find which value holds the public ip address.

Once you know this IP address, declare an additional output in `database.tf`, and run `terraform apply` again to test it out.

After adding the output, you can test the database locally by running `mysql --host=$(terraform output --raw db_address) --user=ubuntu --password=$(terraform output --raw db_password)`.

## `webserver.tf`

In `webserver.tf`, create an additional Ubuntu 20.04 LTS VM which is connected to the network from `main.tf`. Add your SSH key to this VM and declare an output for the public IP of this VM called `webserver_address` which returns the `nat_ip` of this VM. Use `webserver` as the Terraform name and `test-webserver` as the name in the Google Cloud.

Run `terraform apply` again to create the VM and test if you can SSH into the VM.

We will now use Ansible to deploy a simple Flask server on this VM which connects to the MySQL database. The `playbooks` directory already contains the code of a test server, a systemd service template to start this server, and a bare-bones playbook `Webserver.yaml`.

Ansible playbooks are yaml files which contain a set plays and each play has a of tasks to execute. The plays and tasks are executed from top to bottom.

The existing playbook contains a single play with a single task to install `apt` dependencies of the webserver.

* `name` is an arbitrary name of the play.
* `hosts` is a pattern defining which hosts this play should run on. Use `all` if this play should run on all specified hosts.
* `remote_user` specifies the user to use for the SSH connection.
* `become` specifies whether Ansible should run as `sudo` on the remote host.
* `tasks` contains the list of tasks. Each task has an arbitrary name and the name of the module to use for that task. The value are the arguments to give to that module. Many Ansible modules use the desired state principle.

```yaml
---
- name: Install the webserver
  hosts: all
  remote_user: ubuntu
  become: yes

  tasks:
    - name: Install testserver apt requirements
      apt:
        pkg:
          - python3-dev
          - python3-pip
          - default-libmysqlclient-dev
          - build-essential
        state: latest
        update_cache: true
```

You execute this playbook by running `ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ubuntu -i "$(terraform output --raw webserver_address)," playbooks/Webserver.yaml`.

* `ANSIBLE_HOST_KEY_CHECKING=False` disables SSH host key checking. Without this, ansible would ask the user to accept the SSH host key and would throw an error when that key changes. Since, during development, you might destroy and deploy a VM multiple times, it's easier to just disable SSH host key checking.
* `-u ubuntu` use ubuntu user for the SSH connection.
* `-i '<webserver-ip>,'` this flag specifies a list of hosts. If you want to run the playbook on a single host, you _have_ to add a comma after the hostname or ip address. Replace `<webserver-ip>` with the ip address you get from Terraform. Note that `-i` only specifies the _pool_ of hosts to run the playbook on. The `hosts` key in the play further narrows down which hosts each play runs on.
* `playbooks/Webserver.yaml` the playbook to run.

Execute the playbook, ssh into the host and run `apt show default-libmysqlclient-dev` to see if the package is installed correctly.

Next, modify the playbook to add a task using the [pip module](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/pip_module.html) which installs the `flask-mysqldb` pip package.

Add a task to copy the testserver.py script to `/opt/testserver.py` and make sure it is readable and executable by `user` and `group`. You can use [the `copy` module](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/copy_module.html) for this.

Next, we need to create a systemd service which starts the webservice. The file `testserver.service` contains the right configuration to do this. You add the service by copying this file to `/etc/systemd/system/testserver.service` in the VM. The database ip, user and password are supplied to the service as environment variables. Since these values are only known by Terraform after creating the infrastructure, we need a way to fill these in dynamically when executing Ansible. Ansible supports `jinja2` templates using [the `template` module](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/template_module.html). Turn `testserver.service` into a template which extracts these values from the environment. This way, Terraform can communicate these values to ansible by setting environment variables during execution of Ansible. You can extract environment variables in Ansible using the `lookup` function:

```j2
{{ lookup('env','HOME') }}
```

Test this script by manually exporting these environment variables before executing ansible.

```bash
export MYSQL_HOST="$(terraform output --raw db_address)"
export MYSQL_USER="ubuntu"
export MYSQL_PASSWORD="$(terraform output --raw db_password)"
ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ubuntu -i '<webserver-ip>,' playbooks/Webserver.yaml
```

Finally, create on last task which uses [the `systemd` module](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/systemd_module.html) to start the service and set is as `enabled`. Make sure this tasks sets `daemon_reload` to `yes` so that systemd picks up changes to the service file.

Run the ansible script again, ssh into the server and check if the webapp is started correctly using `systemctl status testserver.service` and `journalctl -f -n 20`. Finally, surf to the public ip of the server to port `5000` to check if the service works correctly.

The next step is to configure Terraform to automatically run Ansible when provisioning the VM. To do this, add the following blocks to the VM resource.

```tf
  provisioner "remote-exec" {
    inline = ["sudo apt update", "sudo apt install python3 -y", "echo Done!"]

    connection {
      host        = google_compute_instance.webserver.network_interface[0].access_config[0].nat_ip
      type        = "ssh"
      user        = "ubuntu"
    }
  }

  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ubuntu -i '${google_compute_instance.webserver.network_interface[0].access_config[0].nat_ip},' playbooks/Webserver.yaml" 
    environment = {
      MYSQL_HOST = google_sql_database_instance.master.ip_address.0.ip_address
      MYSQL_USER = "ubuntu"
      MYSQL_PASSWORD = nonsensitive(random_password.mysql_password.result)
    }
  }
```

After adding these blocks, remove the virtual machine using `terraform destroy --target=google_compute_instance.webserver` and recreate it using `terraform apply`. Terraform doesn't automatically remove VM's when the provisioner block changes.

## Extension

The next step is to modify this setup so that there are two VM's and MySQL servers running, each in a different region. Put a load balancer in front of these VM's which automatically chooses the VM closest to the user.

## Assignment

The assignment for this lab is **individual**.

For this lab, follow the instructions to create the setup, including the extension, and add your solution to your repository in a folder `lab-iac`. The deadline for this lab is 12/05/2021 23:59.
