# kcptun-sip003-wrapper
shadowsocks SIP003 wrapper for [xtaci/kcptun](https://github.com/xtaci/kcptun/releases/latest), act like [shadowsocks/kcptun](https://github.com/shadowsocks/kcptun/releases/tag/v20170718).

1. Put kcptun binary in the same directory of this script or into a directory in the PATH environemnt.
   #### searching precedence
   - \`pwd\`/kcptun_client$suffix
   - \`pwd\`/kcptun-client$suffix
   - \`pwd\`/client_${os}_$arch$suffix
   - \`pwd\`/kcptun_server$suffix
   - \`pwd\`/kcptun-server$suffix
   - \`pwd\`/server_${os}_$arch$suffix
   - $PATH/kcptun_client$suffix
   - $PATH/kcptun-client$suffix
   - $PATH/kcptun_server$suffix
   - $PATH/kcptun-server$suffix

Sample usage:
```shell script
ss-redir --plugin kcptun.cmd --plugin-opts 'key=12 3\;4 5$6^&*()@;crypt=aes-128;mode=fast2;conn=4;nocomp;quiet'
```
