#!/bin/bash
#--------------------------------------------------------------------------
# Program     : load_nmap.sh
# Version     : v1.0
# Description : Simulate nmap process version load testing.
# Syntax      : load_nmap <host> <process no>
# Author      : Andrew (andrew@devnull.uk)
#--------------------------------------------------------------------------

#set -x

nmap_bin=$(which nmap)

function help()
{
    cat << EOF
Chaos nmap process version load test.

Usage: $0 [-t|-n|-k|-h]
Options:
  -t|--target	Target host address.
  -n|--no	Number of nmap processes to run.
  -k|--kill     Kill nmap processes.
  -h|--help	Display this help

EOF
}

# Initiate nmap processes with options or defaults.

function nmap_start()
{
    host_ip="${1:-127.0.0.1}"
    proc_no="${2:-5}"
    echo "[X] Loading up $proc_no nmap processes to scan target $host_ip."
    for i in $( seq 1 $proc_no ); do
        $nmap_bin -Pn -sVT -p1-65535 -n \
            --host-timeout=26214s \
            --max-retries=20 \
            --min-rate=40 -O \
            --privileged \
            --randomize-host \
            --scan-delay=3ms -T3 \
            --version-intensity=7 \
            $host_ip &
        sleep 1
    done
}

# Main caller program.

main()
{
    if (( $# < 1 )); then
        help
    else
        while [ $# -ne 0 ]; do
            case $1 in
                -t | --target ) shift;
                    case $2 in
                        -n | --no )
                            nmap_start $1 $3
                            exit
                            ;;
                    esac
                    nmap_start $1
                    exit
                    ;;
                -k | --kill )
                    killall nmap
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
