module "eks" {
  source          = "./modules/eks"
  name-cluster    = var.name-cluster
  instance-ami    = var.instance-ami
  instance-type   = var.instance-type
  name-sg         = var.name-sg
  cluster-version = var.cluster-version
  region          = var.region
}

# resource "null_resource" "eks_cluster_config" {
#   # count = var.create_kubeconfig ? 1 : 0

#   depends_on = [
#     module.eks.eks,
#     module.eks.eks_cluster_ready,
#   ]


#   provisioner "local-exec" {
#     command = "sleep 30" # Aguarde 30 segundos para dar tempo ao cluster EKS de ser totalmente provisionado
#   }

#   provisioner "local-exec" {
#     command = <<-EOT
#       aws eks --region ${var.region} update-kubeconfig --name ${var.name-cluster}
#     EOT
#   }
# }

# resource "null_resource" "executa_script" {
#   depends_on = [null_resource.eks_cluster_config]
#   provisioner "local-exec" {
#     command = "scripts/script.sh"
#   }
# }