#!/usr/bin/env bash
# Phase 1 - traditional WebSphere + Postgres (first attempt)

podman run -d --name was-server \
  -p 9043:9043 -p 9443:9443 \
  icr.io/appcafe/websphere-traditional:latest

podman run -d --name postgres \
  -p 8082:5432 \
  -e POSTGRES_USER=admin \
  -e POSTGRES_PASSWORD=changeme \
  postgres:alpine
