#!/bin/bash
debug2Syslog()
{
  command -v logger >/dev/null && logger -t "$script" -p user.info $1
}
