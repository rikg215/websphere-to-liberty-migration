# Lab Log

Every error I hit, how I figured it out, and the fix.

## 01 - SSL errors on 9043 and 9443
**Symptom:** SSLC0008E "received an unencrypted inbound communication" on both ports.
**Cause:** I assumed 9043 was plain HTTP and 9443 was HTTPS. Both are HTTPS only. 9043 = admin console, 9443 = apps. Plain HTTP is 9060 (console) and 9080 (apps).
**Fix:** https://<vm-ip>:9043/ibm/console and accept the self-signed cert.

## 02 - psql syntax error on CREATE TABLE
**Symptom:** `syntax error at or near "CREATE"`, LINE 3.
**Cause:** Two things. The prompt was `-#`, meaning psql was still holding unfinished input from earlier lines. And CREATE TABLE needs column definitions in parentheses, a name alone isn't valid.
**Fix:** `\r` clears the buffer. Every statement ends with `;`. Defined `id SERIAL PRIMARY KEY` plus a column.

## 03 - Permission denied creating the driver folder
**Symptom:** `mkdir: cannot create directory: Permission denied`, and no sudo in the container.
**Cause:** The WebSphere image runs as the `was` user.
**Fix:** `podman exec -u root`. Whatever root creates still has to be readable by `was`.

## 04 - InstantiationException: GenericDataStoreHelper
**Symptom:** Test connection failed with `java.lang.InstantiationException: com.ibm.websphere.rsadapter.GenericDataStoreHelper`.
**Cause:** I put WebSphere's helper class in the provider's Implementation class field. The trace showed newInstance() being called on the helper, and that only happens on whatever's in that field.
**Rule:** Provider -> vendor's driver class. Data source -> WebSphere's helper class.
**How to find the class yourself:** pgjdbc docs, or `unzip -l postgresql-42.7.14.jar | grep -i datasource`.

## 05 - Class path had a variable AND an absolute path
**Cause:** `${User-defined_JDBC_DRIVER_PATH}/opt/driver/...` stacks two paths.
**Fix:** Use one or the other. Absolute path, or a WebSphere variable set to the folder plus the filename.

## 06 - localhost inside a container
**Cause:** Inside the WebSphere container, localhost is the WebSphere container. No Postgres in there.
**Fix attempt:** VM IP 192.168.0.112 and the published port 8082 (left side of -p is the host side).

## 07 - Connection refused to 192.168.0.112:8082
**Symptom:** `Connection to 192.168.0.112:8082 refused`, but `nc -zv 192.168.0.112 8082` from the VM connected fine.
**Cause:** Rootless podman's default network mode (pasta) gives the container a copy of the host's IP, so it was connecting to itself.
**Second problem:** `podman network connect` fails with `"pasta" is not supported`. Network mode is set at creation.
**Fix:** Burned it all down for another rep. Created a network, recreated both containers on it, and used container-name DNS: serverName postgres, port 5432 (container port, not the published one). Added named volumes this time. WebSphere's volume goes on the AppSrv01 profile directory because that's where all the console config lives.
**Note:** -h only sets the container's own hostname. Other containers find it by --name. Kept them the same so WebSphere's stored host name stays stable across rebuilds.

## 08 - Install directory vs context root
**Cause:** I put /labapp in "Directory to install application". That's a filesystem path, and `was` can't write to /.
**Fix:** Left it blank. Context root is set on a later screen.
