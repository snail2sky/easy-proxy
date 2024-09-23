#!/bin/bash

ssh_user=$1
ssh_host=$2
ssh_port=22
ssh_tunnel_port=1081

arch=64
v2ary_version=v5.19.0
v2ray_url=https://github.com/v2fly/v2ray-core/releases/download/$v2ary_version/v2ray-linux-$arch.zip
v2ray_client_config_url=https://raw.githubusercontent.com/v2fly/v2ray-examples/refs/heads/master/VMess-Websocket/config_client.json
v2ray_server_config_url=https://raw.githubusercontent.com/v2fly/v2ray-examples/refs/heads/master/VMess-Websocket/config_server.json


get_v2ray(){
    wget $v2ray_url
    unzip -d v2ray `basename $v2ray_url`
}

get_v2ray_config(){
    wget $v2ray_client_config_url
    wget $v2ray_server_config_url
}

modify_v2ray_config(){
    cat `basename $v2ray_client_config_url`
}

gen_ssh_tunnel(){
    ssh -NfR 127.0.0.1:$ssh_tunnel_port:127.0.0.1:$ssh_tunnel_port $ssh_user@$ssh_host
}

run_v2ray(){
    ./v2ray --version
}

main(){
    get_v2ray
    cd v2ray
    get_v2ray_config
    modify_v2ray_config
    gen_ssh_tunnel
    run_v2ray
}

main
