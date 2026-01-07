package argocd.security

# Deny applications without proper security annotations
deny[msg] {
    input.kind == "Application"
    not input.metadata.annotations["argocd.argoproj.io/sync-wave"]
    msg := "Application must have sync-wave annotation for proper ordering"
}

# Require automated sync for infrastructure components
deny[msg] {
    input.kind == "Application"
    input.spec.project == "infrastructure"
    not input.spec.syncPolicy.automated
    msg := "Infrastructure applications must have automated sync enabled"
}

# Ensure proper RBAC project restrictions
deny[msg] {
    input.kind == "Application"
    input.spec.project == "default"
    msg := "Applications should not use the default project - create dedicated projects"
}

# Require namespace restrictions
deny[msg] {
    input.kind == "Application"
    not input.spec.destination.namespace
    msg := "Applications must specify a target namespace"
}

# Ensure pruning is enabled for GitOps
warn[msg] {
    input.kind == "Application"
    not input.spec.syncPolicy.automated.prune
    msg := "Consider enabling pruning for better GitOps hygiene"
}