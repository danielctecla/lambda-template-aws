locals {
  src_dir = "${path.root}/../../src"

  # Functions exposed through the API, keyed by route path
  routes = {
    for k, l in var.lambdas : coalesce(l.route_path, k) => {
      http_method       = l.http_method
      lambda_invoke_arn = module.lambda[k].invoke_arn
    } if l.expose
  }
}
