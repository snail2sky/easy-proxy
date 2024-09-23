#!/bin/bash

ssh_user=$1
ssh_host=$2
ssh_port=22
ssh_tunnel_port=1081

v2ray_url=
v2ray_client_config_url=
v2ray_server_config_url=


get_v2ray(){
    wget $v2ray_url
}

get_v2ray_config(){
    wget $v2ray_client_config_url
    wget $v2ray_server_config_url
}

modify_v2ray_config(){
    
}

gen_ssh_tunnel(){
    ssh -NfR 127.0.0.1:$ssh_tunnel_port:127.0.0.1:$ssh_tunnel_port $ssh_user@$ssh_host
}

run_v2ray(){

}

main(){
    get_v2ray
    cd v2ray
    get_v2ray_config
    modify_v2ray_config
    gen_ssh_tunnel
    run_v2ray
}
