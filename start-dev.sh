#!/bin/bash
# set -e

# Read each line in .env file
# Each line represents key=value pairs
# while read -r line || [[ -n "$line" ]];
# do
#   # Split env variables by character `=`
#   if printf '%s\n' "$line" | grep -q -e '='; then
#     varname=$(printf '%s\n' "$line" | sed -e 's/=.*//')
#     varvalue=$(printf '%s\n' "$line" | sed -e 's/^[^=]*=//')
#   fi

#   # Read value of current variable if exists as Environment variable
#   value=$(printf '%s\n' "${!varname}")
#   # Otherwise use value from .env file
#   [[ -z $value ]] && value=${varvalue}
  
#   # Set new VUE_APP variables with existing variables
#   newval=$(printf 'VUE_APP_%s=%s' "${varname}" "${value}")
#   echo $newval
#   export $newval
# done < .env


## IN ORDER TO SWAP BETWEEN HOTLOAD (DEV) AND PROD PREVIEW (PREVIEW) BUILDS COMMENT TOGGLE BETWEEN THE FOLLOWING TWO LINES

# (cd /app; npm run dev)
(cd /app; npm run build; npm run preview)