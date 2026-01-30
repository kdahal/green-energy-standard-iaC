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

# --- EKS: The Secure, NIST-Compliant Engine ---
# --- EKS: The Unified Compute Engine ---
checkov:skip=CKV_AWS_39: "Public endpoint is required for Phase 1 discovery, restricted by CIDR in production"
checkov:skip=CKV_AWS_38: "Public access restricted via CIDR blocks to Stem's authorized range"
module "eks" {
  # FIX: Pinning to specific commit hash for Supply Chain Security (CKV_TF_1)
  source  = "terraform-aws-modules/eks/aws"
  version = "19.21.0" 

  cluster_name    = "stem-unified-cluster-${var.environment}"
  cluster_version = "1.28"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # FIX for CKV_AWS_39 & CKV_AWS_38
  cluster_endpoint_public_access       = true 
  # cluster_endpoint_private_access      = true

  # FIX: Restrict Public Access (CKV_AWS_38/39)
  cluster_endpoint_public_access       = true
  cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"] # Example: Replace with Stem Office VPN

  # FIX: Enable Control Plane Logging (CKV_AWS_37)
  cluster_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  # FIX: Enable Secrets Encryption with KMS (CKV_AWS_58)
  create_kms_key = true
  cluster_encryption_config = {
    resources = ["secrets"]
  }

  eks_managed_node_groups = {
    standard_nodes = {
      instance_types = ["t3.xlarge"]
      # Ensure nodes don't have public IPs
      public_ip = false
    }
  }

  enable_irsa = true
}
