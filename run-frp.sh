#!/bin/bash

ssh_user=root
p2p_pub_host=127.0.0.1
p2p_pub_port=7000
p2p_pub_secret=I_Love_Github
frp_auth_token=
local_ip=127.0.0.1
local_port=1234

arch=64
v2ary_version=v5.19.0
v2ray_url=https://github.com/v2fly/v2ray-core/releases/download/${v2ary_version}/v2ray-linux-${arch}.zip
v2ray_client_config_url=https://raw.githubusercontent.com/v2fly/v2ray-examples/refs/heads/master/VMess-Websocket/config_client.json
v2ray_server_config_url=https://raw.githubusercontent.com/v2fly/v2ray-examples/refs/heads/master/VMess-Websocket/config_server.json
uuid=

frp_version=0.60.0
frp_url=https://github.com/fatedier/frp/releases/download/v${frp_version}/frp_${frp_version}_linux_amd64.tar.gz


exe=$0

display_help(){
    echo "Usage: ${exe} [--help] [-h|--host P2P_HOST] [-p|--port P2P_PORT] [-a|--auth-token FRP_AUTH_TOKEN] [--v2ray-version V2RAY_VERSION]"
    echo "Clean: ${exe} -C"

    exit 1
}

parse_args(){
    for arg in $@; do
        case ${arg} in
        -h|--host)
            shift
            p2p_pub_host=$1
            shift
            ;;
        -p|--port)
            shift
            p2p_pub_port=$1
            shift
            ;;
        -a|--auth-token)
            shift
            frp_auth_token=$1
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
    echo "p2p_pub_host: ${p2p_pub_host}"
    echo "p2p_pub_port: ${p2p_pub_port}"
    echo "frp_auth_token: ${frp_auth_token}"
    echo "v2ray-version: $v2ary_version"
}

get_v2ray(){
    wget ${v2ray_url}
    unzip -d v2ray `basename ${v2ray_url}`
}

get_v2ray_config(){
    wget -P v2ray ${v2ray_client_config_url}
    wget -P v2ray ${v2ray_server_config_url}
}

gen_v2ray_uuid(){
    uuid=`./v2ray/v2ray uuid`
}

modify_v2ray_config(){
    cat ./v2ray/`basename ${v2ray_client_config_url}` | \
    jq '.log.loglevel = "debug"' | \
    jq ".outbounds[0].settings.vnext[0].address = \"${p2p_pub_host}\"" | \
    jq ".outbounds[0].settings.vnext[0].users[0].id = \"${uuid}\"" | \
    jq ".inbounds |= map( if .protocol == \"http\" then .port = \"1081\" else . end )" | \
    jq ".inbounds |= map( if .protocol == \"socks\" then .port = \"1080\" else . end )" > ./v2ray/client.json

    cat ./v2ray/`basename ${v2ray_server_config_url}` | \
    jq '.log.loglevel = "debug"' | \
    jq '.inbounds[0].listen = "127.0.0.1"' | \
    jq ".inbounds[0].settings.clients[0].id = \"${uuid}\"" > ./v2ray/server.json
}


run_v2ray(){
    ./v2ray/v2ray run -c ./v2ray/server.json &>> ./v2ray/server.log &
    # ./v2ray/v2ray run -c ./v2ray/client.json &>> ./v2ray/client.log &
}

get_frp(){
    wget ${frp_url}
    tar xf `basename ${frp_url}`
    rm -f `basename ${frp_url}`
    mv frp* frp
}

gen_frp_config(){
    cat > ./frp/frpc.toml << EOF
user = "git"
serverAddr = "${p2p_pub_host}"
serverPort = ${p2p_pub_port}
transport.protocol = "kcp"
auth.token = "${frp_auth_token}"

[[proxies]]
name = "v2ray"
type = "tcp"
localIP = "${local_ip}"
localPort = ${local_port}
remotePort = ${local_port}
EOF
}


run_frp(){
    ./frp*/frpc -c ./frp*/frpc.toml
}

clean(){
    rm -vrf v2ray*
    killall -v ssh
    exit 0
}

main(){
    parse_args $@
    _debug

    get_v2ray
    get_v2ray_config
    gen_v2ray_uuid
    modify_v2ray_config

    get_frp
    gen_frp_config

    run_v2ray
    run_frp
}

main $@
