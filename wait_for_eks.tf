resource "null_resource" "wait_for_eks" {
  provisioner "local-exec" {
    command = <<EOT
for i in {1..60}; do
  echo "Waiting for EKS API endpoint..."
  aws eks describe-cluster --name ${module.eks.cluster_name} --region ${var.region} >/dev/null 2>&1 && exit 0
  sleep 5
done
echo "EKS not ready after timeout"
exit 1
EOT
  }
}
