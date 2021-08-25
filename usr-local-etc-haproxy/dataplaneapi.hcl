config_version = 2

name = "reload_example"

mode = "single"

status = "null"

dataplaneapi {
  host = "0.0.0.0"
  port = 5555

  user "admin" {
    insecure = true
    password = "mypassword"
  }

  transaction {
    transaction_dir = "/tmp/haproxy"
  }

  advertised {
    api_address = ""
    api_port    = 0
  }
}

haproxy {
  config_file = "/usr/local/etc/haproxy/haproxy.cfg"
  haproxy_bin = "/usr/sbin/haproxy"

  reload {
    reload_delay = 15
    reload_cmd   = "kill -SIGHUP 1"
    restart_cmd  = "service haproxy restart"
  }
}

log {
  log_to     = "stdout"
  log_level  = "trace"
  log_format = "text"
}
