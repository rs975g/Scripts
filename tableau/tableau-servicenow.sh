#!/bin/bash
# Script to push the ServiceNow CSVs to the Tableau database
# 20151204 Thilak.Somasundaram@ge.com

# Variables
BASE_DIR="/home/SNMidServerUser"
CONFIG_FILE="${BASE_DIR}/tableau.config"
PSQL_OPTIONS="--dbname=supportdb --host=3.48.35.24 --username=502569572"
ARCHIVE_DIR="${BASE_DIR}/archive"
LOG_FILE="${ARCHIVE_DIR}/tableau.`date +%F`.log"
NOTIFY_USERS="thilak.somasundaram@ge.com,santosh.sinha@ge.com"
CSV_DIR="${BASE_DIR}/PredixTableauReports"
SKIP_TRUNCATE="incident_metric" # Space seperated list

# Variables Script
PGSQL_HOME="${BASE_DIR}/pgsql"
LOG_LEVEL=0  # Debug:0, Info:1, Error:2
SCRIPT_NAME=$0
LOG_TYPE=(DEBUG INFO ERROR)

export PATH="${PGSQL_HOME}/bin:${PATH}"
export LD_LIBRARY_PATH="${PGSQL_HOME}/lib64"

# The Good, Bad and the Ugly
yell() {
    LOG_DATE=`date "+%F %R %N -"`
    LOGT=${LOG_TYPE[$1]}
    if [ "$1" -ge "${LOG_LEVEL}" ]; then shift; echo "${LOG_DATE} ${LOGT}: $*" | tee -a ${LOG_FILE}; fi
}

die() { yell 2 "$*"; exit 1; }

try() { "$@" || die "cannot $*"; }

yell 0 "  ----------- Start -------------"
yell 0 "Done setting the threes"

send_data() {
    if [[ ! $SKIP_TRUNCATE =~ $1 ]]; then
        yell 0 "Truncating table ${1}"
        ${PGSQL_HOME}/bin/psql ${PSQL_OPTIONS} -w -c "TRUNCATE table servicenow.${1}" 2>&1 | tee -a ${LOG_FILE} || FAILURE="true"
    fi
    yell 0 "Importing ${2} to table ${1}"
    ${PGSQL_HOME}/bin/psql ${PSQL_OPTIONS} -w -c "\COPY servicenow.${1} from ${2} DELIMITER ',' CSV HEADER" 2>&1 | tee -a ${LOG_FILE} || FAILURE="true"
}

send_mail() {
    yell 0 "Sending failure email"
    cat ${LOG_FILE} | mail -s "Service Now - Tableau script failure" ${NOTIFY_USERS}
}

log_manage() {
    yell 0 "Manging logs"
    find ${ARCHIVE_DIR} -type f -mtime +30 -exec rm {} \;
    find ${ARCHIVE_DIR} -type f -mtime +2 -exec gzip {} \;
}

# Create Archive directory if required
if [ ! -d "${ARCHIVE_DIR}" ]; then
    yell 0 "Creating Archive directory ${ARCHIVE_DIR}"
    mkdir -p ${ARCHIVE_DIR}
fi

while read line; do
    [[ $line = \#* ]] && continue
    [ -z "$line" ] && continue
    yell 0 "Processing $line"
    ARRAY=($line)
    if [ -f ${CSV_DIR}/${ARRAY[0]} ]; then
        send_data ${ARRAY[1]} ${CSV_DIR}/${ARRAY[0]}
    else
        yell 2 "Missing file ${ARRAY[0]}"
        FAILURE="true"
    fi
done < ${CONFIG_FILE}

if [ ! -z "$FAILURE" ]; then
    send_mail
fi

log_manage
