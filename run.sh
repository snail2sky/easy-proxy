#!/bin/bash

ssh_user=$1
ssh_host=$2
ssh_port=22
ssh_tunnel_http_port=1081
ssh_tunnel_sock_port=1080

arch=64
v2ary_version=v5.19.0
v2ray_url=https://github.com/v2fly/v2ray-core/releases/download/$v2ary_version/v2ray-linux-$arch.zip
v2ray_client_config_url=https://raw.githubusercontent.com/v2fly/v2ray-examples/refs/heads/master/VMess-Websocket/config_client.json
v2ray_server_config_url=https://raw.githubusercontent.com/v2fly/v2ray-examples/refs/heads/master/VMess-Websocket/config_server.json

uuid=

get_v2ray(){
    wget $v2ray_url
    unzip -d v2ray `basename $v2ray_url`
}

get_v2ray_config(){
    wget $v2ray_client_config_url
    wget $v2ray_server_config_url
}

gen_v2ray_uuid(){
    uuid=`./v2ray uuid`
    echo $uuid
}

modify_v2ray_config(){
    cat `basename $v2ray_client_config_url` | jq '.log.loglevel = "debug"' | jq '.outbounds[0].settings.vnext[0].address = "127.0.0.1"' | jq ".outbounds[0].settings.vnext[0].users[0].id = \"$uuid\"" > client.json
    cat `basename $v2ray_server_config_url` | jq '.log.loglevel = "debug"' | jq '.inbounds[0].listen = "127.0.0.1"' | jq ".inbounds[0].settings.clients[0].id = \"$uuid\"" > server.json
}

gen_ssh_tunnel(){
    ssh -NfR 127.0.0.1:$ssh_tunnel_http_port:127.0.0.1:$ssh_tunnel_http_port $ssh_user@$ssh_host
    ssh -NfR 127.0.0.1:$ssh_tunnel_sock_port:127.0.0.1:$ssh_tunnel_sock_port $ssh_user@$ssh_host
}

run_v2ray(){
    ./v2ray run -c server.json &> server.log &
    ./v2ray run -c client.json &> client.log &
}

main(){
    get_v2ray
    cd v2ray
    
    get_v2ray_config
    gen_v2ray_uuid
    modify_v2ray_config
    gen_ssh_tunnel
    run_v2ray
}

main
