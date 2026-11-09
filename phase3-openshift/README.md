# Phase 3 - OpenShift (Red Hat Developer Sandbox)

## Image
The Sandbox runs in Red Hat's cloud, so it can't reach my homelab registry (192.168.0.210:5000) or Postgres on 192.168.0.112.
- Retagged the Liberty image and pushed it to my private registry
- Created pull secret rik215-registry (kubernetes.io/dockerconfigjson) so the project can pull it
- Deployed the image as a Deployment, exposed it with a Route

## Postgres
Used the PostgreSQL (persistent) template from the catalog. Red Hat's image is built to run under a random UID, the official postgres image expects its own fixed user.
- Database Service Name: postgresql
- Username: admin
- Database name: admin
- Password: set in the form (lands in Secret postgresql, key database-password)
- Volume: 1Gi
- Image version: 15 (not the 10-el8 default)

Template creates a DeploymentConfig, PVC, Secret and Service. DeploymentConfigs are deprecated in newer OpenShift in favor of Deployments.

## Data migration (dump and restore, not a volume copy)
A Postgres data directory is a binary format tied to the server version. Real migrations move data, not disk files.

# on the podman VM
podman exec postgres pg_dump -U admin -d admin > db.sql

# into OpenShift
oc cp db.sql <postgres-pod>:/tmp/db.sql
oc exec <postgres-pod> -- psql -U admin -d admin -f /tmp/db.sql
oc exec <postgres-pod> -- psql -U admin -d admin -c 'SELECT * FROM websphere;'
