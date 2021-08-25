# ct-haproxy-playground

This is a simple `docker-compose` configuration to use for testing different HAProxy configurations that may be useful to tf-rds-proxy.

## Architecture

This runs three Docker containers:
- MySQL
- HAProxy
- Python DB client

### MySQL

Runs the most basic MySQL configuration using a static username/password.

Makes MySQL available on port `3306` on servername `db`.

### HAProxy

Runs HAProxy with a single backend consisting of port `3306` on the MySQL container.

Exposes two ports on servername `haproxy24`:
- `9001`: proxies to port `3306` on `db`
- `19001`: the HAProxy HTTP `stats` interface
- `5555`: the HAProxy Data Plane API interface

### Python

This container runs a simple Python script (`connect.py`) that makes a single connection to `haproxy:9001` and runs a query using that connection every 5 seconds. This script will fail if/when HAProxy breaks an established connection to MySQL.

## Running It

To start the deployment:
```
$ docker-compose up --remove-orphans
```
Once MySQL is running, the script running in the Python container will send timestamps to the console (`stdout` for the Python container). If its DB connection is broken, the script will fail and quit.

To shut down, use `CTRL-c` or `docker-compose down`.

The HAProxy `stats` interface is available at http://localhost:19001/stats.

## Gracefully Restarting HAProxy

You can have HAProxy gracefully restart and reload its configuration, all while maintaining the integrity of existing connections. Use this command:
```
$ docker-compose kill -s HUP haproxy24
```
## Findings

This configuration confirms that HAProxy can gracefully reload/restart, *but* it also shows that after such a restart, `http://localhost:19001/stats` no longer reports the original connection to MySQL established by the Python script prior to the restart. Prior to restart, `stats` will report `1` current session (for both the frontend and the backend). After restart, `stats` does not report any sessions even though the script is still successfully using its original connection. Apparently, this is expected behavior, based on HAProxy documentation, articles, etc.

Skimming the HAProxy documentation suggests that the connection(s) established prior to restart are maintained by the original HAProxy process and a new HAProxy process running the new configuration is started. The memory usage of the HAProxy container bears this out. Prior to a restart, the HAProxy container uses ~4MiB of memory. After a restart, the HAProxy container usage jumps to ~6.5MiB.

This growth in memory use will have to be watched for production HAProxy deployments using restarts.

## Notes

### Exec bash in haproxy container as haproxy

```
$ docker-compose exec haproxy24 bash
root@610c089aecdd:/#
```

### Exec bash in haproxy container as root

```
$ docker-compose exec --user root haproxy24 bash
root@610c089aecdd:/#
```

### Count the number of actual active frontend and backend sessions

```
# ... inside the container

# Frontend (8080)
$ netstat --numeric --inet | grep 8080 | wc -l
2

# Backend (3306)
$ netstat --numeric --inet | grep 3306 | wc -l
2
```

### Interact with HAProxy socket (Runtime API)

```
$ docker-compose exec haproxy24 bash
$ nc -U /var/run/haproxy/haproxy.sock
prompt

> show info
Name: HAProxy
Version: 2.4.2-553dee3
Release_date: 2021/07/07
Nbthread: 2
Nbproc: 1
Process_num: 1
Pid: 8
Uptime: 0d 0h21m09s
Uptime_sec: 1269
Memmax_MB: 0
PoolAlloc_MB: 0
PoolUsed_MB: 0
PoolFailed: 0
Ulimit-n: 4095
Maxsock: 4095
Maxconn: 2032
Hard_maxconn: 2032
CurrConns: 2
CumConns: 637
CumReq: 3
MaxSslConns: 0
CurrSslConns: 0
CumSslConns: 0
Maxpipes: 0
PipesUsed: 0
PipesFree: 0
ConnRate: 0
ConnRateLimit: 0
MaxConnRate: 2
SessRate: 0
SessRateLimit: 0
MaxSessRate: 2
...
```

### Use Data Plane API ...

#### ... to get basic configuration

```
curl -X GET --user admin:mypassword http://localhost:5555/v2/services/haproxy/configuration/raw

```

#### ... to Update HAProxy Configuration

```
curl -X POST --user admin:mypassword \
    --data-binary @usr-local-etc-haproxy/haproxy.cfg \
    -H "Content-Type: text/plain" \
    "http://localhost:5555/v2/services/haproxy/configuration/raw?skip_version=true"

```

## References

- https://www.haproxy.com/blog/hitless-reloads-with-haproxy-howto/
- https://www.haproxy.com/blog/truly-seamless-reloads-with-haproxy-no-more-hacks/
- https://www.haproxy.com/blog/dynamic-scaling-for-microservices-with-runtime-api/
- https://www.haproxy.com/blog/dynamic-configuration-haproxy-runtime-api/
- https://www.haproxy.com/documentation/hapee/2-2r1/api/data-plane-api/
- https://github.com/haproxytech/dataplaneapi/blob/master/configuration/examples/example-full.hcl
