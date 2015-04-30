# Docker image for munin server

## Configuration

All the configuration is done through the environment.

### HTTP Credentials 

* `MUNIN_USER`
* `MUNIN_PASSWORD`

### SMTP info for alerts

* `SMTP_HOST`
* `SMTP_PORT`
* `SMTP_USERNAME`
* `SMTP_PASSWORD`

### Alert target

* `ALERT_RECIPIENT`
* `ALERT_SENDER`

### List of the nodes to check

* `NODES` format: `name1:ip1 name2:ip2 …`

## Port

Container is listening on the port 8080

## Volumes

For a bit of persistency

* /var/log/munin   -> logs
* /var/lib/munin   -> db
* /var/run/munin   -> lock and pid files
* /var/cache/munin -> file deserved by HTTP
