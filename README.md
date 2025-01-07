# Pre-Conditions

### Create Secret for Proxmox Password

Create a file secrets.tfvars in the base directory of this repo:

```bash
#secrets.tfvars content
proxmox_password = "XXXXXXX"
```

### Generate SSH Keys (Mac)

Create new set of SSH keys if you don't already have a key pair you want to use:

```bash
# Generate a new key pair
ssh-keygen -t ed25519 -C "your_email@example.com" -f ~/.ssh/id_ed25519_proxmox_vm

# Ensure the SSH agent is running
eval "$(ssh-agent -s)"

# Add your private key to the agent
ssh-add ~/.ssh/id_ed25519_proxmox_vm
```

### Update Variables

The content of variables.tf will need to be updated

🖥️ Virtual Machines (vms)
A map of VM configurations, allowing fine-tuned control of each instance.

* vmid (number): Unique VM identifier.
* ipv4_address (string): IPv4 address (e.g., dhcp).
* ipv4_gateway (string): IPv4 gateway address.
* cores (number): Number of CPU cores assigned.
* dedicated_memory (number): Dedicated memory in MB.
* floating_memory (number): Floating memory in MB.
* scsi0_size_gb (number): Disk size for the primary SCSI storage (GB).
* scsi1_size_gb (number): Disk size for the secondary SCSI storage (GB).

Note: I found that I had to downgrade the bgp provider and set the VMIDs statically due to this
issue: https://github.com/bpg/terraform-provider-proxmox/issues/1610.


---

# Execute Terraform

To deploy the template execute the Terraform

```bash
terraform init
terraform plan -var-file="secrets.tfvars" 
terraform apply -var-file="secrets.tfvars" --auto-approve 
```

# Accessing Servers

The created hosts will be available on the local network via `<hostname>.local` where the hostname is the key in the vms
map. The public key is automatically added to each host.

```bash
 ssh ubuntu@k3s-master-2.local
```

If you get his error:

```bash
# Host key for k3s-master-1.local has changed and you have requested strict checking.
# Host key verification failed.
```

Remove the ssh key from hosts.

```bash
# Host key for k3s-master-1.local has changed and you have requested strict checking.
# Host key verification failed.

ssh-keygen -R k3s-master-1.local
ssh-keygen -R k3s-master-2.local
```

---

# Technical Notes

## Why Install mDNS (Avahi) on Your Server?

Installing mDNS (Multicast DNS), facilitated by the Avahi Daemon, allows your server to broadcast its hostname and
services seamlessly across your local network without requiring a central DNS server or manual IP address configuration.
This makes it incredibly easy for devices like macOS, Windows, and Linux machines to discover and connect to your server
using a simple hostname (your-hostname.local) instead of remembering complex IP addresses. With mDNS, services such as
SSH, HTTP, Samba, and printer sharing become instantly accessible to other devices on the same network. Whether you're
running a home server, a development environment, or a lightweight local cloud setup, mDNS significantly simplifies
connectivity, reduces configuration overhead, and improves usability across diverse devices.

mDNS ensures that hostnames are automatically registered on the local network e.g. on the client Mac:

```bash
ssh ubuntu@k3s-master-1.local
ssh ubuntu@k3s-master-2.local
ssh ubuntu@k3s-master-3.local
ssh ubuntu@k3s-worker-1.local
ssh ubuntu@k3s-worker-2.local
```


