# WebSphere → Liberty → OpenShift Migration Lab

Hands-on lab migrating a legacy Java app off traditional WebSphere onto Open Liberty, then onto Kubernetes and OpenShift. Built to learn the migration pattern enterprise teams are running at scale.

## Before
- Traditional WebSphere 9.0.5 in Podman, config clicked through the admin console
- JDBC provider + data source (jdbc/labapp) + J2C auth alias
- Postgres in Podman on a shared bridge network

## After (kubeadm)
- Open Liberty (kernel-slim, Java 17) image with server.xml, driver and WAR baked in
- 3 replicas, password from a Secret, endpoint from a ConfigMap
- Postgres stays external on the VM, only the app tier moved

## After (OpenShift)
- Same image, no rebuild between platforms
- Runs under OpenShift's random UID with no SCC changes
- Postgres from Red Hat's template, data moved with pg_dump and restore
- Public Route, startup/liveness/readiness probes

## What carried over unchanged
The JNDI name and context root. The app code never changed.

## Repo layout
- app/ - the JSP
- phase1-websphere/ - podman commands and admin console config
- phase2-liberty/ - server.xml and Containerfile
- k8s/ - kubeadm manifests (secret.example.yaml only)
- phase3-openshift/ - OpenShift manifests and migration steps
- docs/lab-log.md - every error, how I diagnosed it, the fix

## Driver
Download postgresql-42.7.14.jar from jdbc.postgresql.org into phase2-liberty/ before building.

## Next
- mpHealth endpoints (needs a move off Java EE 6 features)
- Deployment instead of the template's DeploymentConfig
- CI build for the image
