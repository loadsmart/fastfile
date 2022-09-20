module "circleci" {
  source = "git@github.com:loadsmart/terraform-modules.git//circleci-app"

  project = local.project

  allow_aws_access = false
}
