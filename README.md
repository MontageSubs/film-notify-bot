# Film Notify Bot

[![Film Notify Bot status](https://github.com/MontageSubs/film-notify-bot/actions/workflows/film_notify_bot.yml/badge.svg)](https://github.com/MontageSubs/film-notify-bot/actions/workflows/film_notify_bot.yml) | 
[![Telegram](https://img.shields.io/badge/Telegram-订阅-blue?logo=telegram&style=flat-square)](https://t.me/+3drwnBP0yjszMmNh) | 
[![IRC](https://img.shields.io/badge/IRC-加入聊天-orange?logo=irc&style=flat-square)](https://web.libera.chat/#MontageSubs)


**中文 | [English](./README.en.md)**

**Film Notify Bot** 是一个 Telegram 机器人，自动监控最新数字发行电影并生成结构化消息。它将新片信息直接发送到指定频道或群组，帮助用户及时了解最新数字发行电影及相关信息。

## 为什么开发

蒙太奇字幕组专注于翻译小而精的电影，致力于提供高质量字幕内容。字幕制作团队需要及时获取最新数字发行电影的通知，以便快速评估和选择值得翻译的作品。

通过 MDBList API 获取评分和发行列表，并结合 TMDB API 获取影片中文信息、制片公司、在线发行平台等数据，实现了自动化的新片监控和通知功能。

## 功能

- 获取每日新数字发行电影列表（根据 IMDb 评分阈值过滤）  
- 获取 TMDB 详细信息（中文/英文片名、上映年份、中文简介、类型、时长、发行公司、在线发行平台）  
- 获取综合评分（IMDb、Letterboxd、Metacritic、RogerEbert）以及平均分  
- 格式化消息为结构化、可读文本，可发送至 Telegram  
- 维护去重文件 (`sent_tmdb_ids.txt`) 避免重复通知

### 消息预览

```text
《宇宙自助洗衣店 (Cosmos Laundromat)》 (2015)  已上线

简介：在一个荒凉的小岛，自杀羊弗兰克满足他的命运在一个古怪的推销员，谁提供他一生的
礼物。他一点也不知道，他只能处理这么多的“寿命”。

影院上映：2015-08-10
数字上线：2015-08-10

语言：#英语
国家：#荷兰
类型：#动画 / #科幻
时长：12 分钟
发行商：Blender 基金会
在线发行：Blender Open Movie

综合评分：61 / 100
网友评分：IMDb 6.8 / 10 (1,178) | Letterboxd 3.3 / 5 (3,599)
专业评分：Metacritic 暂无 | Rotten Tomatoes 暂无 | RogerEbert 暂无

外部资料：https://www.imdb.com/title/tt4957236/
#宇宙自助洗衣店 #CosmosLaundromat
```

#### 官方频道与机器人

- Telegram 频道（新片推荐）：[@FilmNotify](https://t.me/+3drwnBP0yjszMmNh)  
- Telegram 机器人：[@FilmNotifyBot](https://t.me/FilmNotifyBot)

该机器人（Bot）目前仅在指定的频道中运行。如果您希望接收相同的新片通知，或者希望将我们的机器人添加到您的群组或频道中，我们非常乐意提供支持。

请通过我们的群组或在 GitHub Issues 提出请求，说明以下内容：  
- 您的频道、群组或个人账户的链接  
- 您希望接收消息的原因  
- 您的频道或群组面向的观众群体

我们会根据请求为符合条件的用户提供机器人服务，以确保消息发送的针对性与有效性。

## 自托管与部署

本项目既支持在本地或私有服务器自托管部署，也支持通过 GitHub Actions 自动运行，实现每日新片自动获取和消息推送。

详细的部署步骤、API 配置与环境变量说明，请参阅 [DEPLOYMENT.md（部署指南）](./DEPLOYMENT.md)。

### 仓库管理员操作
对于本仓库管理员，可以前往 [Actions - Film Notify Bot 页面](https://github.com/MontageSubs/film-notify-bot/actions/workflows/film_notify_bot.yml) 点击页面右侧 「**Run workflow**」 手动触发新片检查。

也可以前往 [Actions Secrets 设置](https://github.com/MontageSubs/film-notify-bot/settings/secrets/actions) 管理 Token 等环境变量。


## 致谢

特别感谢 [MDBList](https://mdblist.com/) 与 [TMDB](https://www.themoviedb.org/) 提供的服务与 API，没有他们，这个项目无法实现。

同时感谢 GitHub 提供基础设施与自动化环境，使项目能够稳定托管并高效运行。

## 社群

欢迎加入我们的社群交流电影相关话题、反馈本项目意见，或参与字幕制作：  
- **Telegram**：[蒙太奇字幕组电报群](https://t.me/+HCWwtDjbTBNlM2M5)  
- **IRC**：[#MontageSubs](https://web.libera.chat/#MontageSubs) （与 Telegram 互联）

## 许可协议

本仓库的源代码与文档（除另有说明部分外）遵循 [MIT 许可协议](./LICENSE) 授权，由 **蒙太奇字幕组 (MontageSubs)** 开发与维护。



---

<div align="center">

**蒙太奇字幕组 (MontageSubs)**  
“用爱发电 ❤️ Powered by love”

</div>
