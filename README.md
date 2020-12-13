# k3s-aws-terraform-module

Deploy a tiny Kubernetes (**`k3s`**) on AWS in seconds!


# Usage

- Make sure you have a working SSH key in `~/.ssh/id_rsa.pub`
- Copy [example](example/main.tf) and customize it
- Run `terraform init` and `terraform apply`
- You can use `KUBECONFIG=~/.kube/config-k3s kubectl ...` to connect to the cluster 
- Optionally: `ln -s ~/.kube/config-k3s ~/.kube/config` (then you can skip `KUBECONFIG=...`)


## Why?

**Mostly for cost cutting**, especially for development, test and machine learning environments:
- AWS services built on top of EC2 are typically more expensive than 'pure' AWS instances
- AWS's Kubernetes (EKS) also costs more
- With `k3s` on AWS you pay only for the AWS instances you use, but you can run
    anything (databases, CI, machine learning, ...) on it
- `k3s` uses as little RAM as possible, giving further cost cuts
- no waiting (unlike other solutions, creating `k3s` cluster takes 1-2 minutes)

Why not:
- `k3s` may be a wrong choice for production environments.
    EKS, KOps or various AWS services (RDS, S3, SageMaker, CodeBuild, ...) can be better
- You have to manage the cluster and all deployed applications yourself


## TODO
- Persistent volumes not attached (data can be destroyed on changes to instances)
- Only one node supported for now