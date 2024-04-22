#!/bin/bash

#Create template
#args:
# vm_id
# vm_name
# file name in the current directory
function create_template() {
    #Print all of the configuration
    echo "Creating template $2 ($1)"

    #Create new VM 

    #Feel free to change any of these to your liking
    qm create $1 --name $2 --ostype l26 

    #Set networking to default bridge
    qm set $1 --net0 virtio,bridge=vmbr0

    #Set display to serial
    qm set $1 --serial0 socket --vga serial0

    #Set memory, cpu, type defaults
    #If you are in a cluster, you might need to change cpu type
    qm set $1 --memory 2048 --cores 2 --cpu host

    #Set boot device to new file
    qm set $1 --scsi0 ${storage}:0,import-from="$(pwd)/$3",discard=on

    #Set scsi hardware as default boot disk using virtio scsi single
    qm set $1 --boot order=scsi0 --scsihw virtio-scsi-single

    #Enable Qemu guest agent in case the guest has it available
    qm set $1 --agent enabled=1,fstrim_cloned_disks=1

    #Add cloud-init device
    qm set $1 --ide2 ${storage}:cloudinit

    #If you want to do password-based auth instaed
    #Then use this option and comment out the line above
    #qm set $1 --cipassword password
    #Add the user
    qm set $1 --ciuser ${username}

    #Import the ssh keyfile
    qm set $1 --sshkeys ${ssh_keyfile}

   #Make it a template
    qm template $1

    #Remove file when done
    rm $3
}

#Path to your ssh authorized_keys file
#Alternatively, use /etc/pve/priv/authorized_keys if you are already authorized
#on the Proxmox system
export ssh_keyfile=/root/.ssh/id_ed25519.pub

#Username to create on VM template
export username=root

#Name of your storage
export storage=storage

#The images that I've found premade
#Feel free to add your own

## Debian
#Bullseye (11) (oldstable)
wget "https://cloud.debian.org/images/cloud/bullseye/latest/debian-11-genericcloud-amd64.qcow2"
create_template 8000 "temp-debian-11" "debian-11-genericcloud-amd64.qcow2" 

#Bookworm (12) (stable)
wget "https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2"
create_template 8001 "temp-debian-12" "debian-12-genericcloud-amd64.qcow2"

## Ubuntu
#20.04 (Focal Fossa) LTS
wget "https://cloud-images.ubuntu.com/releases/focal/release/ubuntu-20.04-server-cloudimg-amd64.img"
create_template 8002 "temp-ubuntu-20-04" "ubuntu-20.04-server-cloudimg-amd64.img" 

#22.04 (Jammy Jellyfish) LTS
wget "https://cloud-images.ubuntu.com/releases/22.04/release/ubuntu-22.04-server-cloudimg-amd64.img"
create_template 8003 "temp-ubuntu-22-04" "ubuntu-22.04-server-cloudimg-amd64.img" 
