output "image_url" {
  description = "The image url"
  value       = proxmox_virtual_environment_download_file.ubuntu_cloud_image.url
}

output "image_file_name" {
  description = "The image file name"
  value       = proxmox_virtual_environment_download_file.ubuntu_cloud_image.file_name
}


# output "vm_id" {
#   description = "The VM ID of the created template"
#   value       = proxmox_virtual_environment_vm.ubuntu_vm.vm_id
# }
#
# output "vm_name" {
#   description = "The name of the VM template"
#   value       = proxmox_virtual_environment_vm.ubuntu_vm.name
# }
