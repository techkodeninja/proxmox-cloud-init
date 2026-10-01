#!/bin/bash

#Create template
#args:
# vm_id
# vm_name
# image url
function create_template() {
    local vmid="$1"
    local name="$2"
    local url="$3"
    local file
    file="$(basename "$url")"

    #Skip if this VM ID is already in use (VM or template)
    if qm status "$vmid" &>/dev/null; then
        echo "VM ID $vmid already exists, skipping $name"
        return 0
    fi

    #Print all of the configuration
    echo "Creating template $name ($vmid)"

    #Download the image (-O overwrites any leftover file from a failed run)
    if ! wget -O "$file" "$url"; then
        echo "Download failed for $name, skipping"
        rm -f "$file"
        return 0
    fi

    #Enlarge the source image itself to 64 G before import
    qemu-img resize "$file" 64G

    #Create new VM
    #Feel free to change any of these to your liking
    qm create "$vmid" --name "$name" --ostype l26

    #Set networking to default bridge
    qm set "$vmid" --net0 virtio,bridge=vmbr0

    #Set display to serial
    qm set "$vmid" --serial0 socket --vga serial0

    #Set memory, cpu, type defaults
    #If you are in a cluster, you might need to change cpu type
    qm set "$vmid" --memory 2048 --cores 2 --cpu host

    #Set boot device to new file
    qm set "$vmid" --scsi0 "${storage}:0,import-from=$(pwd)/$file,discard=on"

    #Set scsi hardware as default boot disk using virtio scsi single
    qm set "$vmid" --boot order=scsi0 --scsihw virtio-scsi-single

    #Enable Qemu guest agent in case the guest has it available
    qm set "$vmid" --agent enabled=1,fstrim_cloned_disks=1

    #Add cloud-init device
    qm set "$vmid" --ide2 "${storage}:cloudinit"

    #Add the user
    qm set "$vmid" --ciuser "${username}"

    #Import the ssh keyfile
    #If you want to do password-based auth instead,
    #use the --cipassword line and comment out the --sshkeys line
    qm set "$vmid" --sshkeys "${ssh_keyfile}"
    #qm set "$vmid" --cipassword password

    #Make it a template
    qm template "$vmid"

    #Remove file when done
    rm -f "$file"
}

#Path to your ssh authorized_keys file
#Alternatively, use /etc/pve/priv/authorized_keys if you are already authorized
#on the Proxmox system
ssh_keyfile=/root/.ssh/id_ed25519.pub

#Username to create on VM template
username=root

#Name of your storage
storage=local

#The images that I've found premade
#Feel free to add your own

# Debian 11 (Bullseye)
create_template 1000 "temp-debian-11" "https://cloud.debian.org/images/cloud/bullseye/latest/debian-11-genericcloud-amd64.qcow2"

# Debian 12 (Bookworm)
create_template 1001 "temp-debian-12" "https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2"

# Debian 13 (Trixie)
create_template 1002 "temp-debian-13" "https://cloud.debian.org/images/cloud/trixie/latest/debian-13-genericcloud-amd64.qcow2"

# Ubuntu 22.04 (Jammy Jellyfish) LTS
create_template 1003 "temp-ubuntu-22-04" "https://cloud-images.ubuntu.com/releases/22.04/release/ubuntu-22.04-server-cloudimg-amd64.img"

# Ubuntu 24.04 (Noble Numbat) LTS
create_template 1004 "temp-ubuntu-24-04" "https://cloud-images.ubuntu.com/releases/24.04/release/ubuntu-24.04-server-cloudimg-amd64.img"

# Ubuntu 26.04 (Resolute Raccoon) LTS
create_template 1005 "temp-ubuntu-26-04" "https://cloud-images.ubuntu.com/releases/26.04/release/ubuntu-26.04-server-cloudimg-amd64.img"
