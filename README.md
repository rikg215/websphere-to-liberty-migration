# WebSphere → Liberty → Kubernetes Migration Lab

Hands-on lab migrating a legacy Java app off traditional WebSphere onto Open Liberty, then onto Kubernetes. Built to learn the migration pattern enterprise teams are running at scale.

## Before
- Traditional WebSphere 9.0.5 in Podman, config clicked through the admin console
- JDBC provider + data source (jdbc/labapp) + J2C auth alias
- Postgres in Podman on a shared bridge network

## After
- Open Liberty (kernel-slim, Java 17) image with server.xml, driver and WAR baked in
- Image versioned in my private registry
- 3 replicas on kubeadm, DB password from a Secret, NodePort service
- Postgres stays external on the VM, only the app tier moved

## What carried over unchanged
The JNDI name and context root. The app code didn't change at all.

## Repo layout
- app/ - the JSP
- phase1-websphere/ - podman commands and admin console config
- phase2-liberty/ - server.xml and Containerfile
- k8s/ - manifests (secret.example.yaml only, real secret is gitignored)
- docs/lab-log.md - every error, how I diagnosed it, the fix

## Driver
Download postgresql-42.7.14.jar from jdbc.postgresql.org into phase2-liberty/ before building.

## Next
- Readiness and liveness probes
- Phase 3: OpenShift (Routes, random non-root UID)
- CI build for the image
