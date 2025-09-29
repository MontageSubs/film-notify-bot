# Film Notify Bot Deployment Guide

**[中文](./DEPLOYMENT.md) | English**

## Important Notice

At present, all project scripts and their outputs are available in **Chinese only**. The bot’s messages and console logs will appear in Chinese. Future versions may add multilingual support, but please be aware of this limitation before deployment.

## Overview

This document provides comprehensive deployment instructions for Film Notify Bot. It covers preparation steps, GitHub Actions deployment, local or private server deployment, as well as best practices and troubleshooting notes.

## Table of Contents

1. [Target Audience](#target-audience)
2. [Prerequisites and Terminology](#prerequisites-and-terminology)
3. [Quick Steps Overview](#quick-steps-overview)
4. [Part 1: Create a Custom List on MDBList](#part-1-create-a-custom-list-on-mdblist)
5. [Part 2: Obtain Required Keys and IDs](#part-2-obtain-required-keys-and-ids)
6. [Pre-deployment Checklist](#pre-deployment-checklist)
7. [Part 3: Deploy with GitHub Actions (Recommended)](#part-3-deploy-with-github-actions-recommended)
8. [Part 4: Deploy Locally or on a Private Server](#part-4-deploy-locally-or-on-a-private-server)
9. [Notes and Common Issues](#notes-and-common-issues)

## Target Audience

This guide is intended for developers and system administrators with basic command-line and GitHub experience. Beginners can also follow step-by-step to complete deployment.

**Estimated time**: Preparing keys and list (15–60 minutes); GitHub Actions setup (10–30 minutes); Local deployment (10–20 minutes).

## Prerequisites and Terminology

* **MDBList**: Service to filter and generate custom movie lists.
* **TMDB**: The Movie Database, used to fetch additional metadata (runtime, posters, synopsis).
* **Telegram Bot**: Sends notifications to groups or channels.
* **sent_tmdb_ids.txt**: Tracks previously sent movie IDs to prevent duplicate notifications.
* **GitHub Actions**: GitHub’s hosted CI/CD service, used to run scheduled or manual workflows.
* **API Key / Token**: Credentials issued by third-party services (MDBList, TMDB, Telegram). Handle them as sensitive information, like passwords.
* **Film Notify Bot**: The program that checks MDBList/TMDB lists and pushes new films to Telegram chats. See [README.en.md](./README.en.md) for details.

## Quick Steps Overview

1. Create and populate a list on MDBList (wait 30–60 minutes).
2. Obtain MDBList API Key, List ID, TMDB API Key, Telegram Bot Token, and Chat ID.
3. Fork the repository → Add Secrets → Delete `scripts/sent_tmdb_ids.txt`.
4. Run GitHub Actions manually or wait for scheduled runs and confirm messages are delivered.

## Part 1: Create a Custom List on MDBList

1. Visit [https://mdblist.com](https://mdblist.com) and log in with a third-party account.
2. Configure filters and create a list. Example configuration:

   * Released: `d:14` (films released digitally in the last 14 days)
   * Upcoming: `d:1` (films releasing in the next 1 day)
   * Release date from: `2025-01-01`
   * IMDb Rating: `7.0-10` with at least `1000` votes
   * Add language, region, or platform filters if needed
3. Click **Search** to preview results, then click **Create List**.
4. Allow 30–60 minutes for the list to be populated.

   > Tip: MDBList’s UI may change over time. If you cannot find the exact options described, check their [documentation](https://docs.mdblist.com) for updated instructions.

## Part 2: Obtain Required Keys and IDs

### MDBList API Key

1. Log in to MDBList → click your username → **Preferences** → **API Access**.
2. Generate an **API Key** and store it in a secure location, such as a password manager or encrypted notes.

### MDBList List ID

1. Retrieve your `user_id` (replace `<API Key>`):

   ```text
   https://api.mdblist.com/user?apikey=<API Key>
   ```
2. Use `user_id` to fetch lists and locate your list `id`:

   ```text
   https://api.mdblist.com/lists/user/<USER_ID>?apikey=<API Key>
   ```

    > **Note**: If the API response is empty, wait for list population and try again.

### TMDB API Key

1. Log in at [https://www.themoviedb.org](https://www.themoviedb.org) → Settings → API → apply for Developer API Key.

   > **Note**: Copy the **API Key**, not the Read Access Token.
2. Verify by visiting:

   ```text
   https://api.themoviedb.org/3/configuration?api_key=<API Key>
   ```

   If no error appears, the key is valid.

  > **Note**: TMDB Developer API is for non-commercial use only. For commercial use, contact TMDB.

### Telegram Bot Token and Chat ID

1. Create a Bot with [@BotFather](https://t.me/BotFather) and copy the **Bot Token**.
2. Add the Bot to a group or channel (grant admin rights for channels).
3. Retrieve Chat ID:

   ```text
   https://api.telegram.org/bot<TELEGRAM_BOT_TOKEN>/getUpdates
   ```
4. In the JSON response, locate `"chat":{"id":-100XXXXXXXXX,...}` or `"from":{"id":XXXXXXXX,...}` and write down the ID.

    > **Note**: Group and channel IDs often begin with `-100`. Keep the minus sign.

Test message:

```bash
curl -s -X POST "https://api.telegram.org/bot<TELEGRAM_BOT_TOKEN>/sendMessage" \
  -d chat_id="<CHAT_ID>" -d text="Film Notify Bot test message"
```

If it fails, confirm the Bot has joined and has permission.

## Pre-deployment Checklist

* [ ] Custom MDBList list created and populated
* [ ] MDBList API Key generated and stored securely
* [ ] MDBList List ID obtained
* [ ] TMDB API Key generated and stored securely
* [ ] Telegram Bot created and Token stored securely
* [ ] Target Chat ID(s) obtained

## Part 3: Deploy with GitHub Actions (Recommended)

1. **Fork or clone** this repository.
2. **Add Repository Secrets** under Settings → Secrets and variables → Actions:

   * `MDBLIST_API_KEY`
   * `MDBLIST_LIST_ID`
   * `TMDB_API_KEY`
   * `TELEGRAM_BOT_TOKEN`
   * `TELEGRAM_CHAT_IDS` (space-separated, e.g. `12345 67890 -100112233`)
   * `TELEGRAM_BUTTON_URL` (optional, link for inline button under messages)
3. **Clean duplicate tracking file**: delete or empty [`scripts/sent_tmdb_ids.txt`](./scripts/sent_tmdb_ids.txt) to avoid skipped pushes.
4. **(Optional) Update [`README.en.md`](./README.en.md)**: adjust status badge to your repository URL.
5. **(Optional) Trigger manually**: go to Actions → Film Notify Bot → **Run workflow**.
6. **(Optional) Adjust schedule**: edit [`.github/workflows/film_notify_bot.yml`](.github/workflows/film_notify_bot.yml). For example:

   * Default: `- cron: '43 */6 * * *'`
   * Adjusted: `- cron: '17 */6 * * *'`
     This helps prevent the official project and forks from sending requests at the same time.

### Security Reminder

Never commit API Keys or Tokens to your repository. Always store sensitive values in GitHub Secrets.

## Part 4: Deploy Locally or on a Private Server

1. **System Requirements**

   * OS: Linux / macOS / other Unix-like systems
   * `bash` (v4.0+ recommended)
   * `jq` (for JSON parsing)
   * `curl` (for API requests)

2. **Download Script**

   * Get [`scripts/film_notify_bot.sh`](./scripts/film_notify_bot.sh).

3. **Edit Script Variables**
   Open the script and replace placeholders (example shown):

   ```bash
   MDBLIST_API_KEY="abcdefg"
   MDBLIST_LIST_ID="123456"
   TMDB_API_KEY="abcdefg"
   TELEGRAM_BOT_TOKEN="1234:abcd"
   TELEGRAM_CHAT_IDS="12345 -100112233"
   TELEGRAM_BUTTON_URL="https://example.com"
   ```

   > **Security Note**: Only fill in credentials in safe environments. Protect file permissions.

4. **Run Script**
   Execute in the script directory:

   ```bash
   bash film_notify_bot.sh
   ```

   > A file `sent_tmdb_ids.txt` will be generated to prevent duplicate notifications.
   > Entries older than one year are auto-cleaned.
   > To reset and resend all notifications, delete the file: `rm -f /path/to/scripts/sent_tmdb_ids.txt`.

5. **Set Up Scheduling**
   Configure a scheduler on your host (systemd timers, cron, launchd, etc.).

   * Recommended interval: every 6 hours, offset from exact hours (e.g., `02:43`, `08:13`, `14:43`, `20:13`) to distribute requests more evenly.


## Notes and Common Issues

1. **MDBList**

   * Free accounts allow up to 1000 requests per day, usually sufficient.
   * Accounts inactive for over 90 days may pause list updates; inactive for over 120 days may be terminated.

2. **Support MDBList**

   * Consider sponsoring MDBList for stable service: [MDBList Supporter](https://docs.mdblist.com/docs/supporter).

3. **TMDB**

   * Developer API is for non-commercial use only. Contact TMDB for commercial licensing.

4. **Responsible Usage**

   * Use APIs and services respectfully and within their terms of service.
   * Follow GitHub’s policies when deploying with Actions.
   * Send Telegram notifications only with recipient consent; avoid spamming.
   * Do not use this project for illegal or harmful activities.

5. **User-Agent and Runtime Info**

   * Requests include program version and environment in the User-Agent header. Example:
     `User-Agent: film_notify_bot/1.8.4 (+https://github.com/MontageSubs/film-notify-bot; GitHub Actions)`
   * GitHub Actions runs include source repository; local runs include OS info (e.g., `Ubuntu-22.04`, `Darwin-23.0.0`).
   * Purpose: helps API providers identify traffic and troubleshoot issues. Please respect their services and terms.

---

<div align="center">

**MontageSubs (蒙太奇字幕组)**  
“Powered by love ❤️ 用爱发电”

</div>
