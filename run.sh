#!/bin/bash

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
