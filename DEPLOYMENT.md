# Film Notify Bot 部署指南

**中文 | [English](./DEPLOYMENT.en.md)**

## 说明

本文档为 Film Notify Bot 的完整部署说明。涵盖：前期准备、在 GitHub Actions 上运行、在本地或私有服务器部署，以及一些建议。

## 目录

1. [适用读者](#适用读者)
2. [先决条件与术语](#先决条件与术语)
3. [步骤预览](#步骤预览)
4. [第 1 部分 在 MDBList 上创建自定义列表](#第-1-部分-在-mdblist-上创建自定义列表)
5. [第 2 部分 获取所需 Key 与 ID](#第-2-部分-获取所需-key-与-id)
6. [部署前检查清单](#部署前检查清单)
7. [第 3 部分 在 GitHub Actions 上部署（推荐）](#第-3-部分-在-github-actions-上部署推荐)
8. [第 4 部分 本地 / 私有服务器部署](#第-4-部分-本地--私有服务器部署)
9. [注意事项与常见问题汇总](#注意事项与常见问题汇总)

## 适用读者

**适用读者**：具备基本命令行、GitHub 使用经验的开发者与运维人员。初学者亦可跟随本指南完成部署。

**预估时间**：准备 Key 与列表（15–60 分钟）；GitHub Actions 配置（10–30 分钟）；本地部署（10–20 分钟）。

## 先决条件与术语

* **MDBList**：用于筛选电影并生成自定义列表的服务。
* **TMDB**：The Movie Database，用于补充影片元数据（时长、海报、简介等）。
* **Telegram Bot**：用于把通知发送到群组或频道的 Bot（机器人）。
* **sent_tmdb_ids.txt**：记录已发送的电影 ID，避免重复通知。

## 步骤预览

1. 在 MDBList 创建并填充列表（等待 30–60 分钟）。
2. 获取 MDBList API Key、列表 ID、TMDB API Key、Telegram Bot Token 与 Chat ID。
3. Fork 仓库 → 添加 Secrets → 删除 `scripts/sent_tmdb_ids.txt`。
4. 手动触发 Actions 或等待定时任务，确认消息成功推送。

## 第 1 部分 在 MDBList 上创建自定义列表

1. 打开 MDBList 并登录

   * 访问 [https://mdblist.com](https://mdblist.com) 并在页面右上角用第三方账号登录。
2. 设置筛选规则并创建列表（示例）：

   * Released：`d:14`（仅过去 14 天数字发行）
   * Upcoming：`d:1`（纳入未来 1 天数字发行）
   * Release date 起始：`2025-01-01`
   * IMDb Rating：`7.0-10`，至少 `1000` votes
   * 根据需要添加语言、地区或平台过滤
3. 点击 **Search** 查看结果，确认规则后点击 **Create List** 创建列表。
4. 等待 30–60 分钟，列表填充完成后即可使用。

## 第 2 部分 获取所需 Key 与 ID

### 获取 MDBList API Key

1. 登录 MDBList，点击右上角用户名 → **Preferences** → **API Access**。
2. 创建并保存 **API Key**。

### 获取 MDBList 列表 ID

1. 在浏览器访问以下链接获取 `user_id`（将 `<API Key>` 替换为你的 MDBList API Key）：

```text
https://api.mdblist.com/user?apikey=<API Key>
```

2. 使用 `user_id` 查询列表并找到你创建列表的 `id`：

```text
https://api.mdblist.com/lists/user/<USER_ID>?apikey=<API Key>
```

> **提示**：若 API 返回错误或为空，请等待列表填充完成后重试。

### 获取 TMDB API Key

1. 登录 [https://www.themoviedb.org](https://www.themoviedb.org) → Settings → API → 申请 Developer API Key。

   > **提示**：复制 **API Key** 而非 Read Access Token。
2. 验证是否可用，在浏览器打开下方链接，若无报错则可用：

```text
https://api.themoviedb.org/3/configuration?api_key=<API Key>
```

> **提示**：TMDB Developer API 禁止商业用途，如需商业使用请联系 TMDB。

### 获取 Telegram Bot Token 与 Chat ID

1. 在 Telegram 中与 [@BotFather](https://t.me/BotFather) 创建 Bot，保存 **Bot Token**。
2. 将 Bot 加入群组或频道，若为频道请授予管理员权限。
3. 在浏览器访问：

```text
https://api.telegram.org/bot<TELEGRAM_BOT_TOKEN>/getUpdates
```

4. 在返回的 JSON 中查找 `"chat":{"id":-100XXXXXXXXX,...}` 或 `"from":{"id":XXXXXXXX,...}` 并保存 ID。

> **提示**：群组或频道 ID 通常以 -100 开头，请保留前缀 `-`。

调试命令示例（发送测试消息）：

```bash
curl -s -X POST "https://api.telegram.org/bot<TELEGRAM_BOT_TOKEN>/sendMessage" \
  -d chat_id="<CHAT_ID>" -d text="Film Notify Bot 测试消息"
```

若发送失败，请确认 Bot 已加入对话并具有权限。

## 部署前检查清单

* [ ] 已在 MDBList 创建并填充列表
* [ ] MDBList API Key 已生成并保存
* [ ] MDBList 列表 ID 已获取
* [ ] TMDB API Key 已生成并保存
* [ ] Telegram Bot 已创建并保存 Token
* [ ] 目标 Chat ID 已获取（支持多个）

## 第 3 部分 在 GitHub Actions 上部署（推荐）

1. **Fork 或 clone 仓库**
2. **添加 Repository secrets**（路径：Settings → Secrets and variables → Actions）：

   * `MDBLIST_API_KEY`
   * `MDBLIST_LIST_ID`
   * `TMDB_API_KEY`
   * `TELEGRAM_BOT_TOKEN`
   * `TELEGRAM_CHAT_IDS`（多个用空格分隔，并在 Secrets 中用引号包裹，如 `"12345 67890 -100112233"`）
   * `TELEGRAM_BUTTON_URL`（可选，Bot 消息按钮链接）
3. **清理去重文件**：删除或清空 [`scripts/sent_tmdb_ids.txt`](./scripts/sent_tmdb_ids.txt)，避免跳过推送。
4. **（可选）修改 [`README.md`](./README.md)**：调整状态徽章为你自己的仓库路径。
5. **（可选）手动运行**：在 GitHub Actions → Film Notify Bot 页面点击 **Run workflow** 手动触发一次。
6. **（可选）错开运行时间**：
   修改 [`.github/workflows/film_notify_bot.yml`](.github/workflows/film_notify_bot.yml)，将 `- cron: '43 */6 * * *'` 中的 `43` 替换为 `1` 到 `59` 任意数字，即可错开运行时间。

### 重要安全提醒

在 GitHub Actions 环境中，**不要**将 API Key 或 Bot Token 写入代码库，所有敏感信息必须放入 Secrets。

## 第 4 部分 本地 / 私有服务器部署

1. **系统依赖**

   * 操作系统：Linux / macOS / 其他类 Unix
   * `bash`（建议 v4.0+）
   * `jq`（解析 JSON 数据）
   * `curl`（用于请求 API）

2. **下载脚本**

   * 下载 [`scripts/film_notify_bot.sh`](./scripts/film_notify_bot.sh) 至本地或服务器。

3. **修改脚本变量**
   打开脚本并替换以下变量：（例：`MDBLIST_LIST_ID="123456"`）

   > **重要安全提醒**：仅在安全环境下将 API Key 和 Token 写入脚本，请妥善保护文件权限。

```bash
MDBLIST_API_KEY="abcdefg"
MDBLIST_LIST_ID="123456"
TMDB_API_KEY="abcdefg"
TELEGRAM_BOT_TOKEN="1234:abcd"
TELEGRAM_CHAT_IDS="12345 -100112233"
TELEGRAM_BUTTON_URL="https://example.com"
```

4. **运行脚本**
   在脚本所在目录执行：

```bash
bash film_notify_bot.sh
```

> **提示**：脚本会在目录下生成 `sent_tmdb_ids.txt` 文件，记录已发送电影，避免重复。
> 超过一年的历史记录会自动删除。
> 若需重置或重新发送全部通知，删除该文件即可：`rm -f /path/to/scripts/sent_tmdb_ids.txt`。

## 注意事项与常见问题汇总

1. **MDBList**

   * 免费账号每日请求上限 1000 次，足以支持本项目常规使用。
   * 若超过 90 天未登录，列表更新可能暂停；超过 120 天未登录，账号可能被终止。

2. **TMDB**

   * Developer API 禁止用于商业用途，如需商业授权请联系 TMDB。

3. **支持 MDBList 和 TMDB**

   * 若希望服务持续运行，建议按官方方式赞助 MDBList 与 TMDB。

4. **滥用警告**

   * 禁止任何形式的 API 滥用或未经授权的使用。
   * 禁止对 GitHub 的滥用，必须遵守 GitHub 条款。
   * 禁止未经同意的群发消息，避免骚扰。
   * 请勿将本项目用于任何违法、违规或滥用目的。

