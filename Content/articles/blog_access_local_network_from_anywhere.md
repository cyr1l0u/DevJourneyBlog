---
title: 在外访问家庭内网资源
date: 2023-06-18
comments: true
urlname: access-local-network-from-anywhere
tags: ⦿network
updated:
---

上篇文章提到我成功拥有了公网 IP, 那么这篇我们来探索下如何安全地在外访问家庭资源吧

<!-- more -->

有了公网 IP 后, 我们可以很轻松地在路由器中将端口映射到内网设备端口, 以达到外网访问的目的. 但是这样会存在安全隐患, 你能访问到的端口别人也可以访问到, 即使需要登录也存在被暴力破解的可能, 本文介绍一种我认为更加安全地访问家庭内网服务的方式

## 整体思路

在家庭设备中搭建 ss 服务端, 在代理软件中添加家庭 ss 节点信息, 同时在代理软件中设置家庭内网域名规则, 匹配到家庭内网域名规则后则使用家庭 ss 节点进行网络连接

> 在这个方案中, 代理软件是核心, 是需要持续运行的, 我使用的是 Surge, 当然你可以可以使用如 Clash 之类的代理软件

## 配置步骤

### 第一步: 搭建 ss 服务端

首先我们找一台长时间开机的家庭设备, 软路由是一个理想的选择, 或者也可以使用电脑

#### 软路由运行 ss 服务

以最流行的软路由系统 Openwrt 为例, 我们只需要在 `Services` -> `ShadowsSocksR Plus+` -> `SSR Server` 中配置相关信息即可并启用即可

![himg](https://a.hanleylee.com/HKMS/2023-07-04220716.png?x-oss-process=style/WaMa)

#### 电脑运行 ss 服务

电脑运行 ss 服务也很简单, 首先我们保证电脑上安装了 docker, 在电脑任意位置创建 `docker-compose.yaml` 文件, 其内容如下:

```yaml
shadowsocks:
  image: shadowsocks/shadowsocks-libev
  ports:
    - "8388:8388/tcp"
    - "8388:8388/udp"
  environment:
    - SERVER_ADDR=0.0.0.0
    - SERVER_ADDR_IPV6=::0
    - METHOD=aes-256-gcm
    - DNS_ADDRS=1.1.1.1,1.0.0.1
    - PASSWORD=xxxxxxxxx
  restart: always
```

然后在该文件目录下执行 `docker-compose up -d` 即可, 这样我们的 ss 服务就在后台默默地运行了

#### 放行 ss 服务端口

我们的 ss 服务最终是要被外部网络访问的, 所以需要在路由中添加端口转发. 以 Openwrt 系统为例, 在 `Network` -> `Firewall` -> `Port Forwards` 中做如下配置:

![himg](https://a.hanleylee.com/HKMS/2023-07-04223649.png?x-oss-process=style/WaMa)

这里 `192.168.6.200` 是我 mac mini 的内网地址, 所以这个映射的含义是让外部所有网络访问 8388 端口的请求转发到内网 `192.168.6.200` 设备的 `8388` 端口上

### 第二步: 配置代理软件

在我们的代理软件中创建名为 *HomeProxySS* 的代理节点, 节点信息为第一步创建的节点信息, 以我现在使用的 Surge 为例:

![himg](https://a.hanleylee.com/HKMS/2023-07-04221603.png?x-oss-process=style/WaMa)

然后我们想一个好记的家庭内网访问域名段(这个域名只是为了方便记忆, 并不需要你真实拥有), 以我为例, 我会使用 `home.hanley.com` 作为家庭域名段, 然后再添加四级域名 `router`, `nas` 等作为访问的完整域名, 比如 `router.home.hanley.com` 作为我访问路由器管理页面的域名.

在 Surge 中配置 `DOMAIN-SUFFIX` 规则:

![himg](https://a.hanleylee.com/HKMS/2023-07-04222749.png?x-oss-process=style/WaMa)

这样只有当我们访问为 `home.hanley.com` 后缀的域名时才会使用到 *HomeProxySS*

### 第三步: 配置本地 Hostnames

在路由中配置本地域名解析, 还是以 Openwrt 为例, 在 `Network` -> `Hostnames` 中, 添加 `router.home.hanley.com` 对应的内网地址

![himg](https://a.hanleylee.com/HKMS/2023-07-04224748.png?x-oss-process=style/WaMa)

到这里配置就完成了! 🥳

## 实际使用

经过以上的配置, 当我们使用 iPhone 在家庭外访问 `router.home.hanley.com` 的时候

1. 代理工具会把网络请求会转发到 *HomeProxySS* 节点
2. *HomeProxySS* 再去请求 `router.home.hanley.com`
3. 由于 *HomeProxySS* 是我们家庭内网运行的服务, 其网络请求必然会经过路由器, 路由器根据 Hostnames 配置对 *HomeProxySS* 返回了 `192.168.8.1` 地址
4. *HomeProxySS* 进而请求 `192.168.8.1` 获得路由器管理页面的响应
5. *HomeProxySS* 将该响应返回给 iPhone

然后我们就能在 iPhone 上看到家庭路由器的登录页面了, 激动不激动?

![himg](https://a.hanleylee.com/HKMS/2023-07-04231107.jpg?x-oss-process=style/WaMa)

## 更多拓展玩法

- ss 只是我们建立代理连接的一种方式而已, 除了 ss 我们还可以使用其他的方式, 比如 wireguard, openvpn, surge 开发的 snell 等等
- 我们可以在家中的多个设备上部署代理服务, 这样可以保证在其中一个设备不能访问的时候有备用的代理节点可以使用
- 你可以在 Hostnames 中添加更多局域网内设备域名映射关系, 比如 `nas.home.hanley.com`, `lenovo_pc.home.hanley.com` 等
- 这种方式可以不止用于访问网页服务, 同时可以访问 vnc, smb 等服务, 比如可以通过在 Finder 中 `Go` -> `Connect to server...` 中输入 `smb://lenovo_pc.home.hanley.com` 来访问内网设备通过 smb 共享的相关文件

<!-- ## 坑 -->

<!-- - surge 在 wireguard 模式下的 smb 访问时不能使用 local dns map -->
<!-- - surge 在域名访问资源时最快速度不超过 12MB/s, 使用 ip 可以无速度损失 -->

## Ref

- [Surge Guide — 轻松访问家中的网络服务](https://blankwonder.medium.com/surge-guide-轻松访问家中的网络服务-6188ef189ca8)
