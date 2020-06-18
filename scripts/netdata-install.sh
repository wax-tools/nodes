#!/bin/bash
################################################################################
#
# Created by Sam Noble for eosdublinwow https://eosdublin.com
# Visit https://github.com/wax-tools for details.
#
#################################################################################
# NOTE: Do not run as root. The script will prompt if needed
# NOTE: This script can also be used to update netdata
bash <(curl -Ss https://my-netdata.io/kickstart.sh) --dont-wait --no-updates --stable-channel --disable-telemetry --dont-start-it