variable "cluster_name" {
  description = "Name of the EKS cluster."
  type        = string
}
variable "kubernetes_version" {
  description = "Kubernetes version for the control plane."
  type        = string
}
variable "public_subnet_ids" {
  description = "Public subnet IDs the cluster control plane can reach."
  type        = list(string)
}
variable "private_subnet_ids" {
  description = "Private subnet IDs where worker nodes are placed."
  type        = list(string)
}
variable "node_instance_type" {
  description = "EC2 instance type for the managed node group."
  type        = string
}
variable "node_desired_size" {
  description = "Desired number of worker nodes."
  type        = number
}
variable "node_min_size" {
  description = "Minimum number of worker nodes."
  type        = number
}
variable "node_max_size" {
  description = "Maximum number of worker nodes."
  type        = number
}
