# --- VPC: The Secure Foundation ---
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "stem-unified-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-west-2a", "us-west-2b", "us-west-2c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true # Cost-optimized for early Phase 1
  enable_dns_hostnames = true

  tags = {
    "Environment" = var.environment
    "Project"     = "Platform-Unification"
    "Compliance"  = "NIST-Ready"
  }
}

# --- EKS: The Unified Compute Engine ---
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = "stem-unified-cluster-${var.environment}"
  cluster_version = "1.28"

  vpc_id                         = module.vpc.vpc_id
  subnet_ids                     = module.vpc.private_subnets
  cluster_endpoint_public_access = true # Secured via IAM/Security Groups

  eks_managed_node_groups = {
    # General Purpose Node Group (for Athena/PowerTrack microservices)
    standard_nodes = {
      instance_types = ["t3.xlarge"]
      min_size     = 2
      max_size     = 5
      desired_size = 3
    }
    # AI/ML Optimized Group (for SageMaker/Locus heavy lifting)
    ai_workloads = {
      instance_types = ["m5.2xlarge"]
      min_size     = 1
      max_size     = 3
      desired_size = 1
    }
  }

  # Enable OIDC for IAM Roles for Service Accounts (Security best practice)
  enable_irsa = true
}
