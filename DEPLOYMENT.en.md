# Film Notify Bot Deployment Guide

**[中文](./DEPLOYMENT.md) | English**

> **Currently, all scripts and outputs are in Chinese only. Bot messages and logs will appear in Chinese. Multilingual support may be added in the future, so please keep this in mind before deployment.**

## Overview

This document provides a complete deployment guide for Film Notify Bot, including preparation, running on GitHub Actions, deploying on local or private servers, and best practices.

## Table of Contents

1. [Intended Audience](#intended-audience)
2. [Prerequisites & Terminology](#prerequisites--terminology)
3. [Deployment Steps Overview](#deployment-steps-overview)
4. [Part 1: Create Custom Lists on MDBList](#part-1-create-custom-lists-on-mdblist)
5. [Part 2: Obtain Required Keys and IDs](#part-2-obtain-required-keys-and-ids)
6. [Pre-deployment Checklist](#pre-deployment-checklist)
7. [Part 3: Deploy on GitHub Actions (Recommended)](#part-3-deploy-on-github-actions-recommended)
8. [Part 4: Local / Private Server Deployment](#part-4-local--private-server-deployment)
9. [Important Notes & Common Issues](#important-notes--common-issues)

## Intended Audience

* Developers or operators with basic command line and GitHub experience. Beginners can also follow this guide.
* Estimated time: 15–60 minutes for key and list preparation; 10–30 minutes for GitHub Actions setup; 10–20 minutes for local deployment.

## Prerequisites & Terminology

* **MDBList**: Service to filter movies and generate custom lists.
* **TMDB**: The Movie Database, providing additional metadata (runtime, posters, synopsis, etc.).
* **Telegram Bot**: Sends notifications to target groups or channels.
* **sent_tmdb_ids.txt**: Tracks already sent movie IDs to avoid duplicates.
* **GitHub Actions**: GitHub’s hosted CI/CD service, used to run scheduled or manual workflows.
* **API Key / Token**: Credentials used to authenticate requests to services (MDBList, TMDB, Telegram). These are sensitive credentials and should be protected like passwords.
* **Film Notify Bot**: Automatically checks MDBList/TMDB lists and pushes new movie notifications via Telegram. See [README.en.md](./README.en.md) for details.

## Deployment Steps Overview

1. Create and populate custom list on MDBList (wait 30–60 minutes).
2. Obtain MDBList API Key, list ID, TMDB API Key, Telegram Bot Token, and Chat ID.
3. Fork repository → Add Secrets → Delete `scripts/sent_tmdb_ids.txt`.
4. Manually trigger Actions or wait for scheduled runs; confirm successful message delivery.

## Part 1: Create Custom Lists on MDBList

1. Open MDBList and log in.

   * Go to [https://mdblist.com](https://mdblist.com) and log in using a third-party account (top right corner).
2. Set filtering rules and create the list (example):

   * Released: `d:14` (digital releases in the last 14 days)
   * Upcoming: `d:1` (digital releases in the next 1 day)
   * Release date from: `2025-01-01`
   * IMDb Rating: `7.0-10`, at least `1000` votes
   * Optional filters: language, region, platform, cast, etc.
3. Click **Search** to preview results; confirm rules, then click **Create List**.
4. Wait 30–60 minutes for the list to populate before use.

## Part 2: Obtain Required Keys and IDs

### MDBList API Key

1. Log in to MDBList → click your account (top right) → **Preferences** → **API Access**.
2. Create and save the **API Key**.

### MDBList List ID

1. In browser, access (replace `<API Key>`):

```text
https://api.mdblist.com/user?apikey=<API Key>
```

2. Extract `user_id`, then query your lists:

```text
https://api.mdblist.com/lists/user/<USER_ID>?apikey=<API Key>
```

3. Find the `id` of your list; save for bot configuration.

    > Tip: If API returns empty or errors, wait until the list has populated.

### TMDB API Key

1. Log in to [TMDB](https://www.themoviedb.org) → Settings → API → Apply for Developer API Key.
2. Copy the **API Key** (not the Read Access Token).
3. Verify availability:

```text
https://api.themoviedb.org/3/configuration?api_key=<API Key>
```

> TMDB Developer API is not for commercial use. Contact TMDB for commercial authorization.

### Telegram Bot Token & Chat ID

1. Create Bot via [@BotFather](https://t.me/BotFather); save **Bot Token**.
2. Add Bot to group/channel (grant admin if channel).
3. Retrieve Chat ID:

```text
https://api.telegram.org/bot<TELEGRAM_BOT_TOKEN>/getUpdates
```

4. Extract `"chat":{"id":-100XXXXXXXXX,...}` for groups/channels or `"from":{"id":XXXXXXXX,...}` for private chats.

   > Tip: Keep the `-` prefix for group/channel IDs.

Test message:

```bash
curl -s -X POST "https://api.telegram.org/bot<TELEGRAM_BOT_TOKEN>/sendMessage" \
  -d chat_id="<CHAT_ID>" -d text="Film Notify Bot test message"
```

## Pre-deployment Checklist

* [ ] MDBList list created and populated
* [ ] MDBList API Key saved
* [ ] MDBList list ID obtained
* [ ] TMDB API Key saved
* [ ] Telegram Bot Token saved
* [ ] Target Chat ID obtained (supports multiple)

## Part 3: Deploy on GitHub Actions (Recommended)

1. **Fork or clone repository**
2. **Add repository secrets** (Settings → Secrets and variables → Actions):

   * `MDBLIST_API_KEY`
   * `MDBLIST_LIST_ID`
   * `TMDB_API_KEY`
   * `TELEGRAM_BOT_TOKEN`
   * `TELEGRAM_CHAT_IDS` (space-separated if multiple, e.g., `12345 67890 -100112233`)
   * `TELEGRAM_BUTTON_URL` (optional, for inline message button)
3. **Clean deduplication file**: Delete or empty [`scripts/sent_tmdb_ids.txt`](./scripts/sent_tmdb_ids.txt) to avoid skipping notifications.
4. **Optional: Update [`README.en.md`](./README.en.md)**: adjust badge to your repo path.
5. **Optional: Manual run**: Actions → Film Notify Bot → **Run workflow**.
6. **Optional: Stagger schedule**: Edit [`.github/workflows/film_notify_bot.yml`](.github/workflows/film_notify_bot.yml), change `- cron: '43 */6 * * *'` `43` to any number between 1–59.

    > Changing the cron minute avoids multiple forks sending requests at the same time, reducing load on API servers.

### Security Reminder

Never write API Keys or Bot Tokens into the code repository. Only store them in GitHub Actions secrets or other secure environments.

## Part 4: Local / Private Server Deployment

1. **System dependencies**

   * Linux / macOS / Unix-like OS
   * `bash` (v4.0+ recommended)
   * `jq` (JSON parser)
   * `curl` (API requests)

2. **Download script**

   * [`scripts/film_notify_bot.sh`](./scripts/film_notify_bot.sh)

3. **Configure script variables** (replace with your keys/IDs):

```bash
MDBLIST_API_KEY="abcdefg"
MDBLIST_LIST_ID="123456"
TMDB_API_KEY="abcdefg"
TELEGRAM_BOT_TOKEN="1234:abcd"
TELEGRAM_CHAT_IDS="12345 -100112233"
TELEGRAM_BUTTON_URL="https://example.com"  # Optional
```

  > Security reminder: only store sensitive keys in secure environments and protect file permissions.

4. **Run script**

```bash
bash film_notify_bot.sh
```

* Generates `sent_tmdb_ids.txt` to track sent movies.
* Automatically deletes records older than 1 year.
* To reset or resend all notifications, remove the file: `rm -f /path/to/scripts/sent_tmdb_ids.txt`

5. **Set up scheduled tasks**

   * Schedule the script to run regularly on your host (cron, systemd timers, launchd, etc.).
   * Recommended: every 6 hours, avoiding exact hour marks (e.g., 02:43, 08:13, 14:43, 20:13) to reduce API server load.

## Important Notes & Common Issues

1. **MDBList**

   * Free accounts: max 1000 API requests/day, sufficient for normal usage.
   * Inactivity warning: After 90 days without login, a warning is added to list name/description; after 120 days, list auto-updates stop.
2. **Support MDBList**

   * To ensure continuous service, consider sponsoring MDBList as per their guide: [MDBList Supporter](https://docs.mdblist.com/docs/supporter).
3. **TMDB**

   * Developer API not for commercial use. Contact TMDB for commercial authorization.
4. **Abuse Warning**

   * Do not abuse any API or send unsolicited mass messages.
   * Do not violate GitHub terms.
   * Do not use the project for illegal or disruptive purposes.
5. **User-Agent & Environment Disclosure**

   * The Bot sends program version and environment info in API request headers to help providers trace and debug traffic, e.g.:
     `User-Agent: film_notify_bot/1.8.4 (+https://github.com/MontageSubs/film-notify-bot; GitHub Actions)`
   * On GitHub Actions: includes "GitHub Actions" and repo source.
   * Local/private server: includes OS and version (e.g., `Ubuntu-22.04`, `Darwin-23.0.0`).
   * The purpose is to help API providers identify traffic and debug issues, and to encourage responsible use of their services.

---


<div align="center">

**MontageSubs (蒙太奇字幕组)**  
“Powered by love ❤️ 用爱发电”

</div>

