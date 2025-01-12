<p align="center">
	<img src="https://nginxproxymanager.com/github.png">
	<br><br>
	<img src="https://img.shields.io/badge/version-2.12.3-green.svg?style=for-the-badge">
</p>

> **Maintainer Note**: I hate when I want to use an apps, I must install docker to run it, especially in another OS which is doesnt support docker. So, I modified original nginx proxy manager for FreeBSD. Long live FreeBSD!

This project comes as a pre-built docker image that enables you to easily forward to your websites
running at home or otherwise, including free SSL, without having to know too much about Nginx or Letsencrypt.

- [Quick Setup](#quick-setup)
- [Full Setup](https://nginxproxymanager.com/setup/)
- [Screenshots](https://nginxproxymanager.com/screenshots/)

## Project Goal

I created this project to fill a personal need to provide users with an easy way to accomplish reverse
proxying hosts with SSL termination and it had to be so easy that a monkey could do it. This goal hasn't changed.
While there might be advanced options they are optional and the project should be as simple as possible
so that the barrier for entry here is low.

<a href="https://www.buymeacoffee.com/jc21" target="_blank"><img src="http://public.jc21.com/github/by-me-a-coffee.png" alt="Buy Me A Coffee" style="height: 51px !important;width: 217px !important;" ></a>


## Features

- Beautiful and Secure Admin Interface based on [Tabler](https://tabler.github.io/)
- Easily create forwarding domains, redirections, streams and 404 hosts without knowing anything about Nginx
- Free SSL using Let's Encrypt or provide your own custom SSL certificates
- Access Lists and basic HTTP Authentication for your hosts
- Advanced Nginx configuration available for super users
- User management, permissions and audit log


## Hosting your home network

1. Use FreeBSD
2. Pointing your domain to your home network
3. Use Nginx Proxy Manager
4. Done

## Quick Setup

### Jail Configuration (Optional but Recommended)

Originally, the project is designed to run on jail. But, you can run it on your host machine. For example, I will use `bastille` to create a jail called `npm`. You can use `iocage` or `ezjail` or any other jail manager.

1. Create a jail
```bash
bastille create npm 14.1-RELEASE 10.0.2.1
```

2. Configure port forwarding
```bash
bastille rdr npm tcp 80 80
bastille rdr npm tcp 81 81
bastille rdr npm tcp 443 443
```

3. Exec to jail console
```bash
bastille console npm
```

### Installation

You can check the script before running it to make sure it's safe for you because it will delete your existing nginx configuration and install the new one.

```bash
export DISABLE_IPV6="true" # Optional

curl -fsSL https://raw.githubusercontent.com/icaksh/freebsd-nginx-proxy-manager/master/install.sh | sh
```

#### Running

1. Disable IPv6 (Optional)
```bash
echo 'nginxproxymanager_ipv6="NO"' >> /etc/rc.conf
```

2. Enable and start the service
```bash
service nginxproxymanager enable
service nginxproxymanager start
```

3. Log in to the Admin UI

[http://127.0.0.1:81](http://127.0.0.1:81)

Default Admin User:
```
Email:    admin@example.com
Password: changeme
```

Immediately after logging in with this default user you will be asked to modify your details and change your password.


## Contributing

> **Maintainer Note**: I just modified the original project to run on FreeBSD. Feel free to contribute on this repo. But, if you want to contribute to the original project, you can follow the instruction below.

All are welcome to create pull requests for this project, against the `develop` branch. Official releases are created from the `master` branch.

CI is used in this project. All PR's must pass before being considered. After passing,
docker builds for PR's are available on dockerhub for manual verifications.

Documentation within the `develop` branch is available for preview at
[https://develop.nginxproxymanager.com](https://develop.nginxproxymanager.com)


### Contributors

Special thanks to [all of our contributors](https://github.com/NginxProxyManager/nginx-proxy-manager/graphs/contributors).


## Getting Support

1. [Found a bug?](https://github.com/NginxProxyManager/nginx-proxy-manager/issues)
2. [Discussions](https://github.com/NginxProxyManager/nginx-proxy-manager/discussions)
3. [Reddit](https://reddit.com/r/nginxproxymanager)
