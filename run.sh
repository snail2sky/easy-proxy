#!/bin/bash

ssh_user=root
ssh_host=127.0.0.1
ssh_port=22
ssh_tunnel_http_port=1081
ssh_tunnel_sock_port=1080

arch=64
v2ary_version=v5.19.0
v2ray_url=https://github.com/v2fly/v2ray-core/releases/download/$v2ary_version/v2ray-linux-$arch.zip
v2ray_client_config_url=https://raw.githubusercontent.com/v2fly/v2ray-examples/refs/heads/master/VMess-Websocket/config_client.json
v2ray_server_config_url=https://raw.githubusercontent.com/v2fly/v2ray-examples/refs/heads/master/VMess-Websocket/config_server.json
uuid=

exe=$0

display_help(){
    echo "Usage: $exe [--help] [-u|--user SSH_USERNAME] [-h|--host SSH_HOST] [-p|--port SSH_PORT] [--http-port HTTP_PORT] [--sock-port SOCK_PORT] [--v2ray-version V2RAY_VERSION]"
    echo "Clean: $exe -C"

    exit 1
}

parse_args(){
    for arg in $@; do
        case $arg in
        -u|--user)
            shift
            ssh_user=$1
            shift
            ;;
        -h|--host)
            shift
            ssh_host=$1
            shift
            ;;
        -p|--port)
            shift
            ssh_port=$1
            shift
            ;;
        --http-port)
            shift
            ssh_tunnel_http_port=$1
            shift
            ;;
        --sock-port)
            shift
            ssh_tunnel_sock_port=$1
            shift
            ;;
        --v2ray-version)
            shift
            v2ary_version=$1
            shift
            ;;
        -C)
            clean
            ;;
        --help)
            display_help
            ;;
        esac
    done
}

_debug(){
    echo "user: $ssh_user"
    echo "host: $ssh_host"
    echo "port: $ssh_port"
    echo "http-port: $ssh_tunnel_http_port"
    echo "sock-port: $ssh_tunnel_sock_port"
    echo "v2ray-version: $v2ary_version"
}

get_v2ray(){
    wget $v2ray_url
    unzip -d v2ray `basename $v2ray_url`
}

get_v2ray_config(){
    wget -P v2ray $v2ray_client_config_url
    wget -P v2ray $v2ray_server_config_url
}

gen_v2ray_uuid(){
    uuid=`./v2ray/v2ray uuid`
}

modify_v2ray_config(){
    cat ./v2ray/`basename $v2ray_client_config_url` | \
    jq '.log.loglevel = "debug"' | \
    jq '.outbounds[0].settings.vnext[0].address = "127.0.0.1"' | \
    jq ".outbounds[0].settings.vnext[0].users[0].id = \"$uuid\"" | \
    jq ".inbounds |= map( if .protocol == \"http\" then .port = \"$ssh_tunnel_http_port\" else . end )" | \
    jq ".inbounds |= map( if .protocol == \"socks\" then .port = \"$ssh_tunnel_sock_port\" else . end )" > ./v2ray/client.json

    cat ./v2ray/`basename $v2ray_server_config_url` | \
    jq '.log.loglevel = "debug"' | \
    jq '.inbounds[0].listen = "127.0.0.1"' | \
    jq ".inbounds[0].settings.clients[0].id = \"$uuid\"" > ./v2ray/server.json
}

gen_ssh_tunnel(){
    ssh -NfR $ssh_tunnel_http_port:127.0.0.1:$ssh_tunnel_http_port $ssh_user@$ssh_host
    ssh -NfR $ssh_tunnel_sock_port:127.0.0.1:$ssh_tunnel_sock_port $ssh_user@$ssh_host
}

run_v2ray(){
    ./v2ray/v2ray run -c ./v2ray/server.json &>> ./v2ray/server.log &
    ./v2ray/v2ray run -c ./v2ray/client.json &>> ./v2ray/client.log &
}

tail_log(){
    tail -f ./v2ray/server.log
}

clean(){
    rm -vrf v2ray*
    killall -v v2ray ssh
    exit 0
}

main(){
    parse_args $@
    _debug

    get_v2ray
    get_v2ray_config
    gen_v2ray_uuid
    modify_v2ray_config
    gen_ssh_tunnel
    run_v2ray
    tail_log
}

main $@
