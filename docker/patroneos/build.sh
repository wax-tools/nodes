#!/bin/bash
################################################################################
#
# Created by Sam Noble for eosdublinwow https://eosdublin.com
# Visit https://github.com/wax-tools for details.
#
#################################################################################
VERSION=${1:-$(<version.txt)}

docker build --network=host --build-arg VERSION=$VERSION --tag=eosdublin/patroneos:"$VERSION" .
