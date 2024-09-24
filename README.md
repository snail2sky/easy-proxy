# easy-proxy

## function

- use github workspace or gitpod workspace to create a free tunnel(vpn)
- you need a public ip to deploy ssh server, the github or gitpod workspace will connect your public ip through ssh remote port forward
- then you can use your public ip and http_proxy_port or sock_proxy_port to proxy your request to access google, etc..

## run

```bash
bash run.sh --help

ssh_user=root
ssh_host=your_public_ip
ssh_port=22

http_proxy_port=1081
sock_proxy_port=1080

bash run.sh -u $ssh_user -h $ssh_host -p $ssh_port --http-port $http_proxy_port --sock-port $sock_proxy_port
```

```bash
# use http_proxy
curl -x http://your_public_ip:http_proxy_port https://www.google.com

# use sock_proxt
curl --socks5 your_public_ip:sock_proxy_port https://www.google.com
```
