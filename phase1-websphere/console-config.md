# WebSphere admin console config

## Driver jar
podman exec -u root -it was-server /bin/bash
mkdir -p /opt/driver/postgres
podman cp postgresql-42.7.14.jar was-server:/opt/driver/postgres/

## JDBC provider (Resources > JDBC > JDBC providers)
- Scope: cells:DefaultCell01
- Database type: User-defined
- Name: postgres
- Implementation class: com.ibm.websphere.rsadapter.GenericDataStoreHelper
- Class path: ${User-defined_JDBC_DRIVER_PATH}/opt/driver/postgres/postgresql-42.7.14.jar

## J2C auth alias
- DefaultNode01/postgres (DB user + password)

## Data source (Resources > JDBC > Data sources)
- Name: LabAppDS
- JNDI name: jdbc/labapp
- Helper class: Generic data store helper
- Component-managed alias: DefaultNode01/postgres
- Container-managed alias: DefaultNode01/postgres
- Custom properties:
  - serverName: localhost
  - portNumber: 8082
  - databaseName: postgres
