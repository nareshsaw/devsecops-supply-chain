package main

import rego.v1

is_workload if input.kind in {"Deployment", "StatefulSet", "DaemonSet", "Job"}

containers contains c if {
	is_workload
	some c in input.spec.template.spec.containers
}

deny contains msg if {
	some c in containers
	endswith(c.image, ":latest")
	msg := sprintf("%s/%s: container '%s' uses the ':latest' tag; pin an exact version", [input.kind, input.metadata.name, c.name])
}

deny contains msg if {
	some c in containers
	not contains(c.image, ":")
	msg := sprintf("%s/%s: container '%s' has no image tag; pin an exact version", [input.kind, input.metadata.name, c.name])
}

deny contains msg if {
	some c in containers
	c.securityContext.privileged == true
	msg := sprintf("%s/%s: container '%s' must not run privileged", [input.kind, input.metadata.name, c.name])
}

deny contains msg if {
	is_workload
	not input.spec.template.spec.securityContext.runAsNonRoot == true
	msg := sprintf("%s/%s: pod must set securityContext.runAsNonRoot: true", [input.kind, input.metadata.name])
}

deny contains msg if {
	some c in containers
	not c.resources.limits.memory
	msg := sprintf("%s/%s: container '%s' must set a memory limit", [input.kind, input.metadata.name, c.name])
}

deny contains msg if {
	some c in containers
	not c.securityContext.allowPrivilegeEscalation == false
	msg := sprintf("%s/%s: container '%s' must set allowPrivilegeEscalation: false", [input.kind, input.metadata.name, c.name])
}
