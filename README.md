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

Exposes two ports on servername `haproxy`:
- `9001`: proxies to port `3306` on `db`
- `19001`: the HAProxy HTTP `stats` interface

### Python

This container runs a simple Python script (`connect.py`) that makes a single connection to `haproxy:9001` and runs a query using that connection every 5 seconds. This script will fail if/when HAProxy breaks an established connection to MySQL.

## Running It

To start the deployment:
```
$ docker-compose up
```
Once MySQL is running, the script running in the Python container will send timestamps to the console (`stdout` for the Python container). If its DB connection is broken, the script will fail and quit.

To shut down, use `CTRL-c` or `docker-compose down`.

The HAProxy `stats` interface is available at http://localhost:19001/stats.

## Gracefully Restarting HAProxy

You can have HAProxy gracefully restart and reload its configuration, all while maintaining the integrity of existing connections. Use this command:
```
$ docker-compose kill -s HUP haproxy
```
## Findings

This configuration confirms that HAProxy can gracefully reload/restart, *but* it also shows that after such a restart, `http://localhost:19001/stats` no longer reports the original connection to MySQL established by the Python script prior to the restart. Prior to restart, `stats` will report `1` current session (for both the frontend and the backend). After restart, `stats` does not report any sessions even though the script is still successfully using its original connection.

Skimming the HAProxy documentation suggests that the connection(s) established prior to restart are maintained by the original HAProxy process and a new HAProxy process running the new configuration is started. The memory usage of the HAProxy container bears this out. Prior to a restart, the HAProxy container uses ~4MiB of memory. After a restart, the HAProxy container usage jumps to ~6.5MiB.

This growth in memory use will have to be watched for production HAProxy deployments using restarts.
