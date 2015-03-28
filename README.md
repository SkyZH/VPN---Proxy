VPN-->Proxy
===========

A socks5 proxy server. Based on clowwindy's socks5 proxy.

This software can convert VPN into Socks5 Proxy for Windows 8.1.

Usage
-----------

1. Download the lastest Node stable release. You can find them [here](http://nodejs.org/). Don't just use master branch of
Node source code from Github! It's not stable.

2. Clone this project.

3. Create a file named `config.json` in '`./VPN---Proxy/bin`, with the following content.

        {
            "local_port":1080,
            "timeout":600
        }
    
    And the Proxy Server will Run at the port `1080`

4. After installing the lastest Node.js stable release, open CMD by pressing `WinKey+R`, input `cmd` and then press enter.

    You may be able to install Coffee by entering `npm install -g coffee`
    
    You may install inet by entering `npm install -g inet`

5. Navigate to Control Panel > Network and Sharing Center > Change Adapter Settings and Create some VPN connections.

   Then Open REGEDIT, go to HKEY_LOCAL_MACHINE > SYSTEM > CurrentControlSet > Class > {4d36e972-e325-11ce-bfc1-08002be10318} > 0021 (or 0020, 0022, etc)
   
   Change MaxWanEndpoints to a certain number which depends on how many VPNs you will use.
   
   NOTICE THE VPN NAME! You'd better change it into `MultiVPN`

   Right click on the VPN connection, then choose Properties.
   
   Select the Networking tab
   
   Select Internet Protocol Version 4 (TCP/IPv4) and click Properties
   
   Click Advanced
   
   Uncheck "Use default gateway on remote network" and Click OK.
   
6. Create the shortcut of `RunProxy.bat` and Set the Properties of the shortcut so that you can run it as administer.

7. Edit RunProxy.bat (Change the path of proxy.coffee)

8. Connect to VPN in Network and Sharing Center. Then run RunProxy.bat

9. Set the network settings in your web broswer. 

        protocol: socks5
        hostname: 127.0.0.1
        port:     your local_port

10. Then you can surf the Internet using VPN through Socks5 Proxy.
