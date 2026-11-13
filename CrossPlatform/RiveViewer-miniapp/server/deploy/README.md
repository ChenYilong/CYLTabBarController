# Rive 托管服务部署

本目录只保存服务部署约定，不执行发布。正式数据必须位于发布目录之外。

## 线上布局

```text
/opt/rive-host/releases/<时间戳>/server/   后端版本
/opt/rive-host/current                     后端原子软链接
/var/www/rive-host/releases/<时间戳>/      H5 根路径静态产物
/var/www/rive-host/current                 H5 原子软链接
/var/lib/rive-host                         文件与状态数据
```

后端入口为 `/opt/rive-host/current/server/src/server.mjs`。服务固定监听
`127.0.0.1:8097`，由 Nginx 代理 `/api/`；不要开放额外公网端口。

`rive-host.service` 使用 systemd `DynamicUser` 与 `StateDirectory` 创建低权限
运行身份和 `/var/lib/rive-host`。发布目录应由 `root:root` 持有，目录可读但
不可由服务写入。状态文件和 `.riv` 文件不得放在 `release` 或 `current` 中。

## 运行环境

线上 `/usr/bin/node` 当前为 `v18.19.1`，后端兼容该版本且没有生产依赖或
构建步骤。Node 22 与 npm 仅存在于 `ubuntu` 用户的 NVM 目录；低权限动态
用户无法穿过 `/home/ubuntu`，systemd 不应引用该 NVM 路径。

部署文件的目标位置：

```text
server/deploy/rive-host.service          -> /etc/systemd/system/rive-host.service
h5/deploy/nginx-rive-host.conf           -> /etc/nginx/sites-available/rive.mikeywa.site
```

线上已经启用同名站点软链接。正式切换时应先备份并替换该站点文件，不能再
并行启用第二个包含相同 `server_name` 或 `upstream rive_host_api` 的配置。

## 发布前检查

```bash
cd server
npm test

cd ../h5
RIVE_VIEWER_BASE=/ npm run check
RIVE_VIEWER_BASE=/ npm run build
```

根路径构建输出仍为 `h5/dist-static/`。复制发布产物后，先创建
`current.next`，确认目标目录、权限和 SHA-256，再以原子重命名替换
`current`。后端发布不需要在线执行 `npm install`。

首次安装 unit 后需要执行 systemd 配置检查、重新加载并启动服务。服务验收：

```bash
systemd-analyze verify /etc/systemd/system/rive-host.service
curl --fail --silent --show-error http://127.0.0.1:8097/healthz
```

正式平台不预置示例，也不要执行 `seed-examples.mjs`；该脚本只保留给隔离测试或
停服迁移，运行中的服务旁执行会造成两个进程各自持有状态快照。归档和恢复请求
必须携带 `X-Rive-Action` 操作头；Nginx 还会按来源地址限制上传和其他写操作频率。

当前初始总存储上限为 `5 GiB`。服务还会在数据盘可用空间低于 `6 GiB` 时
拒绝新上传；不要用发布或回滚脚本清理 `/var/lib/rive-host`。

## Nginx 与回滚

正式虚拟主机模板位于 `h5/deploy/nginx-rive-host.conf`。启用前必须确认：

- `rive.mikeywa.site` 证书存在；
- 前端根路径构建和后端健康检查都已通过；
- `sudo nginx -t` 成功；
- 原 `mikeywa.site/rive-viewer/` 保持不变。

将 `certbot-reload-nginx.sh` 安装到
`/etc/letsencrypt/renewal-hooks/deploy/reload-nginx` 并设为可执行，确保续签证书后
Nginx 自动加载新证书。

首次发布还没有上一版 `current`，所以替换 Nginx 前必须单独备份现有站点文件；
失败时恢复旧站点配置并停止首次安装的服务。后续回滚时分别把前端、后端
`current` 指回上一版本，重启 API，再检查正式域名。
数据目录不回滚；若状态格式发生变化，必须使用上线前备份或向后兼容迁移。
