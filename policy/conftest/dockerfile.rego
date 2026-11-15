package dockerfile

# conftest passes a Dockerfile as a flat list of instructions: [{"Cmd": "from", "Value": [...]}, ...]

import rego.v1

from_images contains img if {
	some cmd in input
	cmd.Cmd == "from"
	img := cmd.Value[0]
}

deny contains msg if {
	some img in from_images
	endswith(img, ":latest")
	msg := sprintf("Base image '%s' uses ':latest'; pin an exact version", [img])
}

deny contains msg if {
	some img in from_images
	not contains(img, ":")
	not contains(img, "@sha256:")
	msg := sprintf("Base image '%s' has no tag or digest; pin it", [img])
}

has_user if {
	some cmd in input
	cmd.Cmd == "user"
}

deny contains msg if {
	not has_user
	msg := "Dockerfile must switch to a non-root USER"
}

deny contains msg if {
	some cmd in input
	cmd.Cmd == "user"
	cmd.Value[0] in {"root", "0"}
	msg := "Dockerfile must not run as root"
}

deny contains msg if {
	some cmd in input
	cmd.Cmd == "add"
	some v in cmd.Value
	startswith(v, "http")
	msg := "Use COPY or a verified download instead of ADD with a remote URL"
}

warn contains msg if {
	some img in from_images
	not contains(img, "@sha256:")
	msg := sprintf("Base image '%s' is pinned by tag only; consider pinning by digest", [img])
}
