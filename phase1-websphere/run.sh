#!/usr/bin/env bash
# Phase 1 - traditional WebSphere + Postgres on a shared podman network

podman network create websphere

podman volume create websphere
podman volume create postgres

podman run -d --name was-server -h was-server \
  --network websphere \
  -p 9043:9043 -p 9443:9443 \
  -v websphere:/opt/IBM/WebSphere/AppServer/profiles/AppSrv01 \
  icr.io/appcafe/websphere-traditional:latest

podman run -d --name postgres -h postgres \
  --network websphere \
  -p 8082:5432 \
  -e POSTGRES_USER=admin \
  -e POSTGRES_PASSWORD=changeme \
  -v postgres:/var/lib/postgresql \
  postgres:alpine
