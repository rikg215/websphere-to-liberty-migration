# WebSphere admin console config

## Driver jar
podman exec -u root -it was-server /bin/bash
mkdir -p /opt/driver/postgres
podman cp postgresql-42.7.14.jar was-server:/opt/driver/postgres/

## JDBC provider (Resources > JDBC > JDBC providers)
- Scope: cells:DefaultCell01
- Database type: User-defined
- Name: postgres
- Implementation class: org.postgresql.ds.PGConnectionPoolDataSource
- Class path: /opt/driver/postgres/postgresql-42.7.14.jar

## J2C auth alias
- DefaultNode01/postgres (DB user + password)

## Data source (Resources > JDBC > Data sources)
- Name: LabAppDS
- JNDI name: jdbc/labapp
- Helper class: Generic data store helper
- Component-managed alias: DefaultNode01/postgres
- Container-managed alias: DefaultNode01/postgres
- Custom properties:
  - serverName: postgres
  - portNumber: 5432
  - databaseName: admin

## Build and deploy the WAR
cd app && jar cvf labapp.war index.jsp && jar tf labapp.war
Applications > New application > New Enterprise Application > Fast Path
- Directory to install application: blank (default)
- Context root: /labapp
Save, then start it under WebSphere enterprise applications.
