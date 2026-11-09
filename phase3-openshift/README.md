# Phase 3 - OpenShift (Red Hat Developer Sandbox)

## Image
The Sandbox runs in Red Hat's cloud, so it can't reach my homelab registry (192.168.0.210:5000) or Postgres on 192.168.0.112.
- Retagged the Liberty image and pushed it to my private registry
- Created pull secret rik215-registry (kubernetes.io/dockerconfigjson) so the project can pull it
- Deployed the image as a Deployment, exposed it with a Route
