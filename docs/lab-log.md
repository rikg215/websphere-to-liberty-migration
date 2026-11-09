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

## 09 - Never published 9080
**Cause:** Published ports are set at creation. Stop/start doesn't add them.
**Fix:** Recreated was-server with -p 9080:9080. The profile volume kept all my console config, so nothing was lost. Opened 9080 in firewalld for the LAN.

## 10 - relation "websphere" does not exist
**Symptom:** Error 500, PSQLException, relation does not exist.
**Good news:** That error came from Postgres itself, so the whole chain worked. Browser -> WebSphere -> JNDI -> data source -> driver -> network -> DB.
**Cause:** The table was in the `admin` database (prompt said `admin=#`), data source pointed somewhere else. Relation = table in Postgres.
**Second problem:** Restarting the app didn't apply the change. The connection pool is server-scoped.
**Fix:** databaseName: admin, Save, `podman restart was-server`. Restart keeps the container, only rm loses it.

## 11 - Scanner missed JDBC and JNDI
**Cause:** The scanner analyzes compiled classes. My DB code lives in a JSP, which only compiles at runtime, so the scanner never saw it. It only picked up jsp-2.2.
**Fix:** Reviewed the app myself. jsp-2.2 is Java EE 6, so I added the EE6 versions: jdbc-4.0, jndi-1.0.
**Lesson:** The scanner is only as good as what it can see.

## 12 - library written as child elements
**Cause:** id, dir and includes are attributes, not child elements. I'd also never closed `<library>`. First draft before that had the path as text inside `<fileset>`.
**Rule:** `<thing name="value"/>`, settings go inside the opening tag. The library id is a label I make up, the dataSource references it.

## 13 - fileset dir included the filename
**Fix:** dir is the folder only. includes names the file.

## 14 - dataSource syntax
**Cause:** `<datasource>` lowercase (XML is case sensitive), properties line never closed with `/>`, no `</dataSource>`.
**Also:** Swapped the hardcoded password for `${env.DB_PASSWORD}` so it can come from a k8s Secret.

## 15 - webApplication not closed
**Fix:** Single-line elements end with `/>`.

## 16 - httpEndpoint wrong
**Cause:** host is the interface to listen on, not a URL path. Attribute is httpPort, not port. A custom id makes a second endpoint instead of overriding the default.
**Fix:** id="defaultHttpEndpoint" host="*" httpPort="9080". 9080 is Liberty's default and what the image exposes.

## 17 - Containerfile copied from the docs too literally
**Cause:** Kept IBM's interim-fixes line (no such folder). Sent the WAR to dropins while server.xml declares it in apps, those are two different deploy methods. Never copied the driver jar in.
**Fix:** Removed interim-fixes, WAR to /config/apps/, driver to the fileset dir.

## 18 - Push refused to my registry
**Symptom:** `dial tcp 192.168.0.200:5000: connect: connection refused`.
**Cause:** Registry is on 192.168.0.210. .200 is my desktop.
**Fix:** Retagged to 192.168.0.210:5000/labapp:1.0 and pushed with --tls-verify=false (registry:2 serves plain HTTP). Opened 5000 to the LAN on ctrl-ansible-01 and 8082 to the LAN on the podman VM so pods can reach Postgres. In prod I'd scope that to the node IPs.

## 19 - NameNotFoundException: Intermediate context does not exist: jdbc/labapp
**Symptom:** Error 500. Startup logs clean, features installed, app started.
**Cause:** `<jbdcDriver>`, letters swapped. Liberty silently ignores elements it doesn't recognize, so the data source had no driver and never registered in JNDI. "jdbc" context didn't exist at all.
**How I found it:** `kubectl exec <pod> -- cat /config/server.xml` to check the config actually in the pod.
**Fix:** jdbcDriver, rebuilt as 1.1 instead of reusing 1.0 so no node could serve a cached old image.
**Result:** Live data from Postgres across all three replicas.

## 20 - Sandbox can't see my homelab
**Cause:** Developer Sandbox runs in Red Hat's cloud. My registry and DB are on my LAN.
**Fix:** Pushed the image to my private registry and added a dockerconfigjson pull secret. App was up in about 30 minutes.

## 21 - No SCC errors (and why)
**Expected:** Problems with OpenShift's random UID.
**What happened:** Nothing broke. restricted-v2 ignores the image's USER 1001 and runs as a random UID from the project's range, but always with group 0. My Containerfile chowns everything 1001:0, so the random UID gets in through group permissions. That's Red Hat's documented pattern (group 0, chmod g=u). I didn't bypass the SCC, I complied with it.
**Why it's more secure:** Group 0 isn't root, no UID 0, no capabilities. Each project gets its own UID range plus SELinux labels, so a breakout lands as an unprivileged UID that owns nothing and can't touch other projects' files. Plain kubeadm runs whatever user the image says, root included.
**Check:** `oc exec <pod> -- id`

## 22 - "Create PVC" upload form failed with my .sql
**Cause:** "With Data upload form" is OpenShift Virtualization's Containerized Data Importer. It loads VM disk images (qcow2, iso) into a Block-mode volume. A SQL dump isn't a disk image.
**Fix:** "With Form" is the normal empty PVC. And a .sql dump isn't something you put on disk anyway, it's commands Postgres has to execute.

## 23 - Template defaulted to Postgres 10
**Cause:** Default image version was 10-el8, long out of support, and older than my source DB.
**Fix:** Picked a newer version. Restore into the same or newer major version.

## 24 - oc cp: Permission denied
**Cause:** I copied into /. The pod runs as a random non-root UID, which can't write to the filesystem root.
**Fix:** Copy to /tmp.

## 25 - Restore threw errors but the data landed
**Symptom:** `invalid command \restrict`, `\unrestrict`, and `unrecognized configuration parameter "transaction_timeout"`.
**Cause:** Dump came from a newer Postgres than the target (15). Newer pg_dump adds a \restrict guard and newer session settings the old psql/server don't know.
**Result:** Only session settings failed. CREATE TABLE, COPY 1 and setval all succeeded. Worked because the schema is trivial, a real schema could fail for real. Restore into same or newer.

## 26 - envFrom vs secretKeyRef
**Question:** Can I envFrom the template's Secret?
**Answer:** No. envFrom imports keys with their names as-is: database-password, database-user, database-name. server.xml wants DB_PASSWORD, and hyphens make bad env var names.
**Rule:** envFrom when keys already match what the app expects (my Phase 2 Secret). secretKeyRef when I need to map a key to a new name.
**Note:** Same project, so DB_HOST is just the Service name. Cross-project would need postgresql.<project>.svc.cluster.local.

## 27 - NameNotFoundException again
**Symptom:** Same `Intermediate context does not exist: jdbc/labapp` as Phase 2.
**How I found it:** `oc exec <pod> -- env | grep DB_` showed `DB_PORT="5432"`. env doesn't print quotes, so they were part of the value.
**Cause:** I set the ConfigMap in form mode and quoted the value like I would in YAML. In YAML quotes are syntax and get stripped. In the form everything is already a string, so the quotes became literal characters. Liberty got "5432" with quote marks, not a valid port, so the dataSource was skipped. Same silent failure pattern as jbdcDriver.
**Fix:** Plain 5432 in the form, then Restart rollout (env from a ConfigMap is only read at container start).

## 28 - Probes
**Liveness:** First instinct was HTTP GET on /. Works today because Liberty serves its welcome page there (200). But production usually disables that page since it advertises the exact Liberty version, and then / goes 404 and liveness restart-loops healthy pods. Went with TCP 9080: "is Liberty listening," nothing more.
**Readiness:** HTTP GET /labapp/. It hits the DB, which is what I want for readiness. DB down = pods pulled from the Service, not restarted. Liveness must never touch the DB or a DB blip restarts every app pod.
**Startup:** TCP 9080 so liveness doesn't kill Liberty while it's still booting (~5s).
**Test:** Deleted a pod. New one stayed not-ready until /labapp/ passed while the Route kept serving from the others.
**Next:** mpHealth gives real /health/ready and /health/live, but MicroProfile doesn't mix with my Java EE 6 features. That's a platform upgrade.
