#!/bin/bash

# Copyright (C) 2017   Robin Cernin (rcernin@redhat.com)

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# we can run this against fs snapshot or live system

count_nodes(){
  if [ ! "$echo $(( (NUM_NODES-1) % 2 ))" -eq  "0" ]; then
    echo "${NUM_NODES}" >&2
    exit $RC_FAILED
  elif [ "x$NUM_NODES" = "x1" ]; then
    echo "${NUM_NODES}" >&2
    exit $RC_FAILED
  else
    exit $RC_OKAY
  fi
}

if [ "x$CITELLUS_LIVE" = "x1" ];  then
  pacemaker_status=$(systemctl is-active pacemaker || :)
  if [ "$pacemaker_status" = "active" ]; then
    NUM_NODES=$(pcs status | sed -n -r -e 's/^([0-9])[ \t]+node.*/\1/p')
    count_nodes
  else
    echo "pacemaker is not running on this node" >&2
    exit $RC_SKIPPED
  fi
elif [ "x$CITELLUS_LIVE" = "x0" ];  then
  if [ ! -f "${CITELLUS_ROOT}/sos_commands/systemd/systemctl_list-units_--all" ]; then
    echo "file /sos_commands/systemd/systemctl_list-units_--all not found." >&2
    exit $RC_SKIPPED
  else
    if grep -q "pacemaker.*active" "${CITELLUS_ROOT}/sos_commands/systemd/systemctl_list-units_--all"; then
      for CLUSTER_DIRECTORY in "pacemaker" "cluster"; do
	if [ -d "${CITELLUS_ROOT}/sos_commands/${CLUSTER_DIRECTORY}" ]; then
	  PCS_DIRECTORY="${CITELLUS_ROOT}/sos_commands/${CLUSTER_DIRECTORY}"
	fi
      done
      if [ ! -f "${PCS_DIRECTORY}/pcs_status" ]; then
        echo "file pcs_status not found." >&2
        exit $RC_SKIPPED
      fi
      NUM_NODES=$(sed -n -r -e 's/^([0-9])[ \t]+node.*/\1/p' "${PCS_DIRECTORY}/pcs_status")
      count_nodes
    else
      echo "pacemaker is not running on this node" >&2
      exit $RC_SKIPPED
    fi
  fi
fi
