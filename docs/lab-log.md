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
