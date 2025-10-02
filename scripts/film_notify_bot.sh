#!/usr/bin/env bash
# ============================================================================
# Name: film_notify_bot.sh
# Version: 1.9.4
# Organization: MontageSubs (蒙太奇字幕组)
# Contributors: Meow P (小p)
# License: MIT License
# Source: https://github.com/MontageSubs/film-notify-bot/
#
# Description / 描述:
#   This script monitors new digital movie releases for the MontageSubs
#   subtitles group, fetches detailed information from TMDB and MDblist APIs,
#   formats the data into structured messages, and sends notifications via
#   Telegram. It also maintains a deduplication record to avoid sending
#   repeated notifications.
#   本脚本用于监控蒙太奇字幕组关注的新数字电影发行，调用 TMDB 与
#   MDblist API 获取电影详细信息，将数据格式化为结构化消息，并通过
#   Telegram 发送通知。同时维护去重记录，避免重复发送消息。
#
# Features / 功能:
#   - Fetches daily new movie releases based on IMDb rating thresholds.
#   - Retrieves detailed movie information from TMDB (Chinese/English titles,
#     release year, overview, genres, runtime, production companies, etc.)
#   - Retrieves aggregated ratings (IMDb, Letterboxd, Metacritic, RogerEbert)
#   - Formats messages in a structured, human-readable format
#   - Maintains a deduplication file to prevent repeated notifications
#     每日获取 IMDb 评分阈值以上的新电影发行列表。
#     获取 TMDB 详细信息（中英文片名、上映年份、简介、类型、时长、
#     制作公司等）。
#     获取综合评分（IMDb、Letterboxd、Metacritic、RogerEbert）。
#     将信息格式化为结构化、易读的消息。
#     维护去重文件以防重复通知。
#
# Dependencies / 依赖:
#   - curl
#   - jq
#
# Usage / 用法:
#   ./film_notify_bot.sh
#
# Output / 输出:
#   - Structured movie messages printed to stdout (or sent via Telegram)
#   - Updates 'sent_tmdb_ids.txt' with already processed movie IDs
#     格式化电影消息打印到 stdout（或通过 Telegram 发送）
#     更新 'sent_tmdb_ids.txt' 文件，记录已处理的电影 ID
#----------------------------------------------------------------------
# ---------------- API Key 与列表 ID / API Keys and IDs ----------------
# 警告 / WARNING
# 在 GitHub Actions 中，请勿直接修改此段。
# 所有变量应通过仓库的 Repository Secrets 注入。
# 请在仓库设置中的 “Secrets and variables” 中添加。
# In GitHub Actions, do NOT modify this section directly.
# All variables should be provided via repository Secrets.
# Please add them in the repository settings under "Secrets and variables".
MDBLIST_API_KEY="${MDBLIST_API_KEY}"            # MDBList API Key
MDBLIST_LIST_ID="${MDBLIST_LIST_ID}"            # Watchlist ID / 监控列表 ID
TMDB_API_KEY="${TMDB_API_KEY}"                  # TMDB API Key
TELEGRAM_BOT_TOKEN="${TELEGRAM_BOT_TOKEN}"      # Telegram Bot Token
TELEGRAM_CHAT_IDS="${TELEGRAM_CHAT_IDS}"        # Target chat IDs (space separated) / 目标聊天 ID，可多个用空格分隔
TELEGRAM_BUTTON_URL="${TELEGRAM_BUTTON_URL}"    # Telegram Button URL (Optional) / Telegram 按钮链接（可选）

# ---------------- 配置 / Configuration ----------------
# 脚本所在目录 / Script directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# 去重文件，用于记录已发送的 TMDB 电影 ID / Deduplication file to track sent TMDB IDs
DEDUP_FILE="$SCRIPT_DIR/sent_tmdb_ids.txt"

# 简介最大长度，默认 300 / Maximum overview length
MAX_OVERVIEW_LEN="300"

# 确保去重文件存在 / Ensure dedup file exists
[ ! -f "$DEDUP_FILE" ] && touch "$DEDUP_FILE"

# ---------------- 日志函数 / Logging ----------------
log_info() { printf "[INFO] %s\n" "$1"; }           # 普通信息 / General info
log_warn() { printf "[WARN] %s\n" "$1"; }           # 警告信息 / Warning
log_error() { printf "[ERROR] %s\n" "$1" >&2; }     # 错误信息 / Error

# ---------------- 语言映射 / Language Mapping ----------------
# 功能: 将 TMDB ISO 语言代码转换为中文描述
# Function: Convert TMDB ISO language code to Chinese name
lang_map() {
    case "$1" in
        ar) echo "阿拉伯语" ;;
        as) echo "阿萨姆语" ;;
        bg) echo "保加利亚语" ;;
        bn) echo "孟加拉语" ;;
        cs) echo "捷克语" ;;
        da) echo "丹麦语" ;;
        de) echo "德语" ;;
        el) echo "希腊语" ;;
        en) echo "英语" ;;
        es) echo "西班牙语" ;;
        fa) echo "波斯语" ;;
        fi) echo "芬兰语" ;;
        fr) echo "法语" ;;
        gu) echo "古吉拉特语" ;;
        he) echo "希伯来语" ;;
        hi) echo "印地语" ;;
        hr) echo "克罗地亚语" ;;
        hu) echo "匈牙利语" ;;
        id) echo "印尼语" ;;
        is) echo "冰岛语" ;;
        it) echo "意大利语" ;;
        ja) echo "日语" ;;
        kn) echo "卡纳达语" ;;
        ko) echo "韩语" ;;
        ml) echo "马拉雅拉姆语" ;;
        mr) echo "马拉地语" ;;
        nl) echo "荷兰语" ;;
        no) echo "挪威语" ;;
        or) echo "奥里亚语" ;;
        pa) echo "旁遮普语" ;;
        pl) echo "波兰语" ;;
        pt) echo "葡萄牙语" ;;
        ro) echo "罗马尼亚语" ;;
        ru) echo "俄语" ;;
        sa) echo "梵语" ;;
        sk) echo "斯洛伐克语" ;;
        sl) echo "斯洛文尼亚语" ;;
        sr) echo "塞尔维亚语" ;;
        sv) echo "瑞典语" ;;
        ta) echo "泰米尔语" ;;
        te) echo "泰卢固语" ;;
        th) echo "泰语" ;;
        tr) echo "土耳其语" ;;
        uk) echo "乌克兰语" ;;
        ur) echo "乌尔都语" ;;
        vi) echo "越南语" ;;
        zh) echo "中文" ;;
        *) echo "$1" ;;
    esac
}

# ---------------- 国家映射 / Country Mapping ----------------
# 功能: 将 TMDB 国家代码转换为中文描述
# Function: Convert TMDB country code to Chinese name
country_map() {
    case "$1" in
        AR) echo "阿根廷" ;;
        AT) echo "奥地利" ;;
        AU) echo "澳大利亚" ;;
        BE) echo "比利时" ;;
        BR) echo "巴西" ;;
        CA) echo "加拿大" ;;
        CH) echo "瑞士" ;;
        CL) echo "智利" ;;
        CN) echo "中国" ;;
        CZ) echo "捷克" ;;
        DE) echo "德国" ;;
        DK) echo "丹麦" ;;
        EG) echo "埃及" ;;
        ES) echo "西班牙" ;;
        FI) echo "芬兰" ;;
        FR) echo "法国" ;;
        GB|UK) echo "英国" ;;
        GR) echo "希腊" ;;
        HK) echo "香港" ;;
        HU) echo "匈牙利" ;;
        IE) echo "爱尔兰" ;;
        IL) echo "以色列" ;;
        IN) echo "印度" ;;
        IR) echo "伊朗" ;;
        IT) echo "意大利" ;;
        JP) echo "日本" ;;
        KR) echo "韩国" ;;
        MA) echo "摩洛哥" ;;
        MX) echo "墨西哥" ;;
        NL) echo "荷兰" ;;
        NO) echo "挪威" ;;
        NZ) echo "新西兰" ;;
        PL) echo "波兰" ;;
        PT) echo "葡萄牙" ;;
        RO) echo "罗马尼亚" ;;
        RU) echo "俄罗斯" ;;
        SA) echo "沙特阿拉伯" ;;
        SE) echo "瑞典" ;;
        SG) echo "新加坡" ;;
        TH) echo "泰国" ;;
        TN) echo "突尼斯" ;;
        TR) echo "土耳其" ;;
        TW) echo "台湾" ;;
        UA) echo "乌克兰" ;;
        US) echo "美国" ;;
        ZA) echo "南非" ;;
        *) echo "$1" ;;
    esac
}

# ---------------- 公司映射 / Company Mapping ----------------
# 功能: 将 TMDB 制片公司名称转换为中文描述
# Function: Convert TMDB production company name to Chinese
company_map() {
    case "$1" in
        "20th Century Fox"|"20th Century Studios") echo "二十世纪影业 (20th Century Studios)" ;;
        "A24") echo "A24 影业" ;;
        "Amazon Studios") echo "亚马逊影业 (Amazon Studios)" ;;
        "Apple Studios"|"Apple Original Films") echo "苹果影业 (Apple Studios)" ;;
        "BBC Films") echo "BBC 电影" ;;
        "Blumhouse Productions") echo "恐怖工厂 (Blumhouse Productions)" ;;
        "CJ Entertainment") echo "CJ 娱乐 (CJ Entertainment)" ;;
        "Columbia Pictures") echo "哥伦比亚影业 (Columbia Pictures)" ;;
        "Constantin Film") echo "康斯坦丁影业 (Constantin Film)" ;;
        "DC Films"|"DC Studios") echo "DC 影业 (DC Studios)" ;;
        "Disney"|"Walt Disney Pictures") echo "迪士尼 (Disney)" ;;
        "DreamWorks"|"DreamWorks Animation") echo "梦工厂 (DreamWorks)" ;;
        "Eros International") echo "Eros 国际 (Eros International)" ;;
        "Focus Features") echo "焦点影业 (Focus Features)" ;;
        "Gaumont") echo "高蒙 (Gaumont)" ;;
        "HBO Films") echo "HBO 影业" ;;
        "Kadokawa") echo "角川 (Kadokawa)" ;;
        "Legendary Pictures") echo "传奇影业 (Legendary Pictures)" ;;
        "Lionsgate") echo "狮门影业 (Lionsgate)" ;;
        "Marvel Studios") echo "漫威影业 (Marvel Studios)" ;;
        "Metro-Goldwyn-Mayer"|"MGM") echo "米高梅 (MGM)" ;;
        "Mosfilm") echo "莫斯科电影制片厂 (Mosfilm)" ;;
        "Neon") echo "Neon 影业" ;;
        "Netflix") echo "奈飞 (Netflix)" ;;
        "New Line Cinema") echo "新线影业 (New Line Cinema)" ;;
        "Paramount Pictures") echo "派拉蒙影业 (Paramount Pictures)" ;;
        "Pathé") echo "百代 (Pathé)" ;;
        "Pixar") echo "皮克斯动画 (Pixar)" ;;
        "Shochiku") echo "松竹 (Shochiku)" ;;
        "Sony Pictures"|"Sony Pictures Entertainment") echo "索尼影业 (Sony Pictures)" ;;
        "STX Entertainment") echo "STX 娱乐 (STX Entertainment)" ;;
        "StudioCanal") echo "StudioCanal 影业" ;;
        "Studio Ghibli") echo "吉卜力工作室 (Studio Ghibli)" ;;
        "Toho") echo "东宝 (Toho)" ;;
        "TriStar Pictures") echo "三星影业 (TriStar Pictures)" ;;
        "Universal Pictures") echo "环球影业 (Universal Pictures)" ;;
        "Warner Bros."|"Warner Bros. Pictures") echo "华纳兄弟 (Warner Bros.)" ;;
        "Working Title Films") echo "Working Title 电影公司" ;;
        *) echo "$1" ;;
    esac
}

# ---------------- 工具函数 / Utility Functions ----------------
# 功能: 格式化评分，支持不同来源
# Function: Format score according to provider
format_score() {
    SCORE="$1"
    PROVIDER="$2"
    if [ "$SCORE" = "N/A" ] || [ -z "$SCORE" ]; then
        echo "暂无"
    else
        case "$PROVIDER" in
            imdb) echo "$SCORE / 10" ;;
            letterboxd) echo "$SCORE / 5" ;;
            metacritic) echo "$SCORE / 100" ;;
            rotten) echo "$SCORE / 100" ;;
            rogerebert) echo "$SCORE / 4" ;;
            avg) echo "$SCORE / 100" ;;
            *) echo "$SCORE" ;;
        esac
    fi
}

# 功能: 格式化评分数量，支持不同来源
# Function: Format rating count according to provider
format_count() {
    local count="$1"

    if [ -z "$count" ] || [ "$count" = "N/A" ] || [ "$count" = "null" ]; then
        echo ""
        return
    fi

    formatted=$(echo "$count" | awk '{
        n = $0
        sign = ""
        if(n ~ /^-/){ sign = "-"; n = substr(n,2) }
        split(n, parts, ".")
        intpart = parts[1]
        fracpart = (length(parts) > 1) ? "." parts[2] : ""
        s = ""
        while(length(intpart) > 3){
            s = "," substr(intpart,length(intpart)-2,3) s
            intpart = substr(intpart,1,length(intpart)-3)
        }
        print sign intpart s fracpart
    }')

    echo "($formatted) "
}

# 功能: 发送消息到 Telegram，支持可选按钮
# Function: Send message to Telegram, supports optional button
send_telegram() {
    MSG="$1"
    MSG_ESCAPED=$(echo "$MSG" | jq -R -s .)

    for CHAT_ID in $TELEGRAM_CHAT_IDS; do
        [ -z "$CHAT_ID" ] && continue
        if [ -n "$TELEGRAM_BUTTON_URL" ]; then
            BUTTONS_JSON="$(jq -n --arg url "$TELEGRAM_BUTTON_URL" '{inline_keyboard: [[{text: "新片推荐", url: $url}]]}')"
            curl -s -A "$UA_STRING" -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
                -H "Content-Type: application/json" \
                -d "{\"chat_id\":$CHAT_ID,\"text\":$MSG_ESCAPED,\"parse_mode\":\"HTML\",\"reply_markup\":$BUTTONS_JSON}" >/dev/null
        else
            curl -s -A "$UA_STRING" -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
                -H "Content-Type: application/json" \
                -d "{\"chat_id\":$CHAT_ID,\"text\":$MSG_ESCAPED,\"parse_mode\":\"HTML\"}" >/dev/null
        fi
    done
}

# ---------------- Token 检测 / Token Check ----------------
# 功能: 检查 API Token 是否有效
# Function: Verify API token validity
token_check_errors=""
check_tokens() {
    MDB_HTTP=$(curl -s -A "$UA_STRING" -o /dev/null -w "%{http_code}" "https://api.mdblist.com/user?apikey=${MDBLIST_API_KEY}&format=json")
    [ "$MDB_HTTP" != "200" ] && token_check_errors="$token_check_errors MDBLIST_API_KEY:$MDB_HTTP"
    TMDB_HTTP=$(curl -s -A "$UA_STRING" -o /dev/null -w "%{http_code}" "https://api.themoviedb.org/3/configuration?api_key=${TMDB_API_KEY}")
    [ "$TMDB_HTTP" != "200" ] && token_check_errors="$token_check_errors TMDB_API_KEY:$TMDB_HTTP"
    if [ -n "$token_check_errors" ]; then
        ERR_MSG="⚠️ API Token 错误: $token_check_errors"
        log_error "$ERR_MSG"
        send_telegram "$ERR_MSG"
        exit 1
    fi
}

# ---------------- 前置检查 / Pre-checks ----------------
# 功能: 检查必须的环境变量是否为空
# Function: Ensure required environment variables are set
check_env_vars() {
    missing_vars=""
    for var in MDBLIST_API_KEY MDBLIST_LIST_ID TMDB_API_KEY TELEGRAM_BOT_TOKEN TELEGRAM_CHAT_IDS; do
        if [ -z "${!var}" ]; then
            missing_vars="$missing_vars $var"
        fi
    done

    if [ -n "$missing_vars" ]; then
        log_error "缺少必要环境变量 / Missing required environment variables: $missing_vars"
        log_error "请检查是否忘记在运行前配置这些变量 / Please check if you forgot to set these variables before running."
        exit 1
    fi
}

# 功能: 检查依赖命令是否存在
# Function: Ensure required dependencies are installed
check_dependencies() {
    missing_deps=""
    for dep in curl jq; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            missing_deps="$missing_deps $dep"
        fi
    done

    if [ -n "$missing_deps" ]; then
        log_error "缺少必要依赖 / Missing required dependencies: $missing_deps"
        log_error "请安装上述依赖后再运行脚本 / Please install the above dependencies before running the script."
        exit 1
    fi
}

# ---------------- 数据获取 / Data Retrieval ----------------
# 功能: 获取今日电影列表
# Function: Fetch today's movie list from MDBList
get_movie_list() {
if [ "$OFFICIAL_REPO" -eq 1 ]; then
    RAW_HTML="$(curl -s \
    -A "Mozilla/5.0 (X11; Linux i686; rv:143.0) Gecko/20100101 Firefox/143.0" \
    -H "Referer: https://mdblist.com/" \
    -H "Accept-Language: en-US,en;q=0.9" \
    "${MDBLIST_SOURCE_URL}")"

    MOVIE_ITEMS_JSON="$(echo "$RAW_HTML" \
      | grep -oP 'https://www.themoviedb.org/movie/\K[0-9]+' -A1 --no-group-separator \
      | paste - - \
      | while read -r tmdb imdb; do
            imdb_id=$(echo "$imdb" | grep -oP 'tt[0-9]+')
            if [ -n "$tmdb" ] && [ -n "$imdb_id" ]; then
                echo "{\"id\":$tmdb,\"imdb_id\":\"$imdb_id\"},"
            fi
       done \
      | sed '$ s/,$//')"

    [ -n "$MOVIE_ITEMS_JSON" ] && MOVIE_ITEMS_JSON="[$MOVIE_ITEMS_JSON]" || MOVIE_ITEMS_JSON=""
fi

if [ -z "$MOVIE_ITEMS_JSON" ]; then
    echo "Using MDBList API..."
    MOVIE_ITEMS_JSON=$(curl -s -A "$UA_STRING" \
      "https://api.mdblist.com/lists/${MDBLIST_LIST_ID}/items?apikey=${MDBLIST_API_KEY}&format=json&limit=100&order=asc&sort=releasedigital&unified=true")
fi
}

get_mdb_movie_info() {
    TMDB_ID="$1"
    MDB_MOVIE_JSON=""
    MDB_MOVIE_JSON=$(curl -s -A "$UA_STRING" \
        "https://api.mdblist.com/tmdb/movie/${TMDB_ID}?apikey=${MDBLIST_API_KEY}&append_to_response=keyword&format=json")
    if [ -z "$MDB_MOVIE_JSON" ] || [ "$MDB_MOVIE_JSON" = "null" ]; then
        log_warn "MDBList API returned empty JSON for TMDB_ID=${TMDB_ID}"
        MDB_MOVIE_JSON="{}"
    fi
}

# 功能: 判断是否重复
# Function: Check if TMDB ID is already sent
is_duplicate() {
    grep -q "^$1 " "$DEDUP_FILE"
}

# 功能: 获取 TMDB 电影详细信息
# Function: Fetch TMDB movie details
get_tmdb_info() {
    TMDB_ID="$1"
    TMDB_JSON=$(curl -s -A "$UA_STRING" "https://api.themoviedb.org/3/movie/${TMDB_ID}?api_key=${TMDB_API_KEY}&language=zh-CN")
}

# 功能: 获取各评分
# Function: Fetch IMDb, Letterboxd, Metacritic, RogerEbert, average scores
get_ratings() {
    TMDB_ID="$1"

    RATING_IMDB_RAW=$(echo "$MDB_MOVIE_JSON" | jq -r '.ratings[] | select(.source=="imdb") | .value // "N/A"')
    RATING_IMDB_COUNT_RAW=$(echo "$MDB_MOVIE_JSON" | jq -r '.ratings[] | select(.source=="imdb") | .votes // "N/A"')

    RATING_LETTERBOXD_RAW=$(echo "$MDB_MOVIE_JSON" | jq -r '.ratings[] | select(.source=="letterboxd") | .value // "N/A"')
    RATING_LETTERBOXD_COUNT_RAW=$(echo "$MDB_MOVIE_JSON" | jq -r '.ratings[] | select(.source=="letterboxd") | .votes // "N/A"')

    RATING_METACRITIC_RAW=$(echo "$MDB_MOVIE_JSON" | jq -r '.ratings[] | select(.source=="metacritic") | .value // "N/A"')
    RATING_METACRITIC_COUNT_RAW=$(echo "$MDB_MOVIE_JSON" | jq -r '.ratings[] | select(.source=="metacritic") | .votes // "N/A"')

    RATING_ROTTEN_RAW=$(echo "$MDB_MOVIE_JSON" | jq -r '.ratings[] | select(.source=="tomatoes") | .value // "N/A"')
    RATING_ROTTEN_COUNT_RAW=$(echo "$MDB_MOVIE_JSON" | jq -r '.ratings[] | select(.source=="tomatoes") | .votes // "N/A"')

    RATING_ROGEREBERT_RAW=$(echo "$MDB_MOVIE_JSON" | jq -r '.ratings[] | select(.source=="rogerebert") | .value // "N/A"')

    AVG_SCORE_RAW=$(echo "$MDB_MOVIE_JSON" | jq -r '.score_average // "N/A"')
}

# ---------------- 消息生成与发送 / Message Generation and Sending ----------------
# 功能：生成电影信息的完整消息，并发送到 Telegram
# Function: Generate a complete message containing movie details and send it via Telegram
generate_and_send_msg() {
    # 获取中文和英文电影标题 / Get movie titles in Chinese and English
    TITLE_CN="$(echo "$TMDB_JSON" | jq -r '.title')"
    TITLE_EN="$(echo "$TMDB_JSON" | jq -r '.original_title')"
    if [ "$TITLE_CN" = "$TITLE_EN" ]; then
        TITLE_CN=""
    fi

    # 构造标题显示 / Build display title
    if [ -n "$TITLE_CN" ] && [ "$TITLE_CN" != "null" ]; then
        DISPLAY_TITLE="《$TITLE_CN ($TITLE_EN)》"
    else
        DISPLAY_TITLE="$TITLE_EN"
    fi

    # 从上映日期提取年份 / Extract release year from release date
    RELEASE_YEAR="$(echo "$TMDB_JSON" | jq -r '.release_date' | cut -d- -f1)"
    [ -z "$RELEASE_YEAR" ] || [ "$RELEASE_YEAR" = "null" ] && RELEASE_YEAR="未知"

    # 获取电影简介 / Get movie overview
    OVERVIEW="$(echo "$TMDB_JSON" | jq -r '.overview')"

    if [ -z "$OVERVIEW" ] || [ "$OVERVIEW" = "null" ]; then
        TMDB_JSON_EN=$(curl -s -A "$UA_STRING" "https://api.themoviedb.org/3/movie/${TMDB_ID}?api_key=${TMDB_API_KEY}")
        OVERVIEW="$(echo "$TMDB_JSON_EN" | jq -r '.overview')"
    fi
        if [ -z "$OVERVIEW" ] || [ "$OVERVIEW" = "null" ]; then
        OVERVIEW="暂无简介"
    fi
    [ ${#OVERVIEW} -gt $MAX_OVERVIEW_LEN ] && OVERVIEW="${OVERVIEW:0:$MAX_OVERVIEW_LEN}..."

    # 获取上映日期 / Get release date
    RELEASED_CINEMA=$(echo "$MDB_MOVIE_JSON" | jq -r '.released // "未定"')
    RELEASED_DIGITAL=$(echo "$MDB_MOVIE_JSON" | jq -r '.released_digital // "未上线"')

    # 获取数字发行日期 / Get digital release date
    RELEASE_DATE="$(echo "$MDB_MOVIE_JSON" | jq -r '.released_digital')"

    if [ -z "$RELEASE_DATE" ] || [ "$RELEASE_DATE" = "null" ]; then
        RELEASE_STATUS="上映日期未知"
    else
        TODAY_TS=$(date -u +%s)
        RELEASE_TS=$(date -u -d "$RELEASE_DATE" +%s 2>/dev/null)
        if [ -z "$RELEASE_TS" ]; then
            RELEASE_TS=$(date -j -f "%Y-%m-%d" "$RELEASE_DATE" +"%s" 2>/dev/null)
        fi
        if [ -z "$RELEASE_TS" ]; then
            RELEASE_STATUS="上映日期无效"
        else
            DIFF=$(( (RELEASE_TS - TODAY_TS) / 86400 ))
            if [ "$DIFF" -le 0 ]; then
                RELEASE_STATUS="已上线"
            else
                RELEASE_STATUS="即将 ${DIFF} 天后上线"
            fi
        fi
    fi

    # 获取电影语言 / Get spoken languages
    LANGS="$(echo "$TMDB_JSON" | jq -r '.spoken_languages[].iso_639_1')"
    LANG_CN=""
    for l in $LANGS; do
        L_CLEAN=$(lang_map "$l" | sed 's/[[:space:][:punct:]]//g')
        [ -n "$L_CLEAN" ] && LANG_CN="$LANG_CN#$L_CLEAN / "
    done
    LANG_CN="${LANG_CN% / }"
    [ -z "$LANG_CN" ] && LANG_CN="未知"

    # 获取电影类型 / Get movie genres
    GENRES_RAW="$(echo "$TMDB_JSON" | jq -r '[.genres[].name] | join(" / ")')"
    GENRES=""
    if [ -n "$GENRES_RAW" ] && [ "$GENRES_RAW" != "null" ]; then
        IFS=' / ' read -ra GEN_ARRAY <<< "$GENRES_RAW"
        for g in "${GEN_ARRAY[@]}"; do
            G_CLEAN=$(echo "$g" | sed 's/[[:space:][:punct:]]//g')
            [ -n "$G_CLEAN" ] && GENRES="$GENRES#$G_CLEAN / "
        done
        GENRES="${GENRES% / }"
    fi
    [ -z "$GENRES" ] && GENRES="未知"

    # 获取电影时长（分钟） / Get movie runtime in minutes
    RUNTIME="$(echo "$TMDB_JSON" | jq -r '.runtime')"
    if [ "$RUNTIME" = "null" ] || [ -z "$RUNTIME" ] || [ "$RUNTIME" -eq 0 ]; then
        RUNTIME_DISPLAY="暂无时长信息"
    else
        # 换算成小时+分钟 / Conversion time
        if [ "$RUNTIME" -ge 60 ]; then
            HOURS="$((RUNTIME / 60))"
            MINUTES="$((RUNTIME % 60))"
            RUNTIME_DISPLAY="${RUNTIME} 分钟 （${HOURS} 小时 ${MINUTES} 分钟）"
        else
            RUNTIME_DISPLAY="${RUNTIME} 分钟"
        fi
    fi

    # 获取制作国家 / Get production countries
    COUNTRIES="$(echo "$TMDB_JSON" | jq -r '.production_countries[].iso_3166_1')"
    COUNTRIES_CN=""
    for c in $COUNTRIES; do
        C_CLEAN=$(country_map "$c" | sed 's/[[:space:][:punct:]]//g')
        [ -n "$C_CLEAN" ] && COUNTRIES_CN="$COUNTRIES_CN#$C_CLEAN / "
    done
    COUNTRIES_CN="${COUNTRIES_CN% / }"
    [ -z "$COUNTRIES_CN" ] && COUNTRIES_CN="未知"

    # 获取制作公司 / Get production companies
    COMPANIES_CN="$(echo "$TMDB_JSON" | jq -r '.production_companies[].name' | while IFS= read -r co; do
        echo -n "$(company_map "$co") / "
    done)"
    COMPANIES_CN="$(echo "$COMPANIES_CN" | sed 's: / $::')"
    [ -z "$COMPANIES_CN" ] && COMPANIES_CN="未知" 

    # 获取美国可租/可买平台 / Get US rent/buy providers
    ONLINE_STREAMS="$(curl -s -A "$UA_STRING" "https://api.themoviedb.org/3/movie/${TMDB_ID}/watch/providers?api_key=${TMDB_API_KEY}" \
        | jq -r '[.results.US.rent[]?.provider_name, .results.US.buy[]?.provider_name] | unique | join(" / ")')"
    [ -z "$ONLINE_STREAMS" ] && ONLINE_STREAMS="暂无上线信息"

    # 将各类评分格式化显示 / Format different scores
    RATING_IMDB="$(format_score "$RATING_IMDB_RAW" "imdb")"
    RATING_IMDB_COUNT=$(format_count "$RATING_IMDB_COUNT_RAW")
    RATING_LETTERBOXD="$(format_score "$RATING_LETTERBOXD_RAW" "letterboxd")"
    RATING_LETTERBOXD_COUNT=$(format_count "$RATING_LETTERBOXD_COUNT_RAW")
    RATING_METACRITIC="$(format_score "$RATING_METACRITIC_RAW" "metacritic")"
    RATING_METACRITIC_COUNT=$(format_count "$RATING_METACRITIC_COUNT_RAW")
    RATING_ROTTEN="$(format_score "$RATING_ROTTEN_RAW" "rotten")"
    RATING_ROTTEN_COUNT=$(format_count "$RATING_ROTTEN_COUNT_RAW")
    RATING_ROGEREBERT="$(format_score "$RATING_ROGEREBERT_RAW" "rogerebert")"
    AVG_SCORE="$(format_score "$AVG_SCORE_RAW" "avg")"

    # 构造 IMDb 链接 / Construct IMDb URL
    IMDB_ID="$(echo "$TMDB_JSON" | jq -r '.imdb_id')"
    if [ "$IMDB_ID" = "null" ] || [ -z "$IMDB_ID" ]; then
        if [ -n "$TMDB_ID" ]; then
            DB_URL="https://www.themoviedb.org/movie/${TMDB_ID}"
        else
            DB_URL="暂无资料链接"
        fi
    else
        DB_URL="https://www.imdb.com/title/${IMDB_ID}"
    fi

    # 生成电影片名标签 / Generate movie title tags
    if [ -n "$TITLE_CN" ] && [ "$TITLE_CN" != "null" ]; then
        TITLE_CN_CLEAN=$(echo "$TITLE_CN" | sed 's/[[:space:][:punct:]]//g')
        [ -n "$TITLE_CN_CLEAN" ] && TAG_CN="#$TITLE_CN_CLEAN" || TAG_CN=""
    else
        TAG_CN=""
    fi
    if [ -n "$TITLE_EN" ] && [ "$TITLE_EN" != "null" ]; then
        TITLE_EN_CLEAN=$(echo "$TITLE_EN" | sed 's/[[:space:][:punct:]]//g')
        [ -n "$TITLE_EN_CLEAN" ] && TAG_EN="#$TITLE_EN_CLEAN" || TAG_EN=""
    else
        TAG_EN=""
    fi
    if [ -n "$TAG_CN" ] && [ -n "$TAG_EN" ]; then
        TAGS="$TAG_CN $TAG_EN"
    elif [ -n "$TAG_CN" ]; then
        TAGS="$TAG_CN"
    elif [ -n "$TAG_EN" ]; then
        TAGS="$TAG_EN"
    else
        TAGS=""
    fi

    # 将所有信息拼接为一条消息 / Combine all info into one message
    MSG="$DISPLAY_TITLE ($RELEASE_YEAR)  $RELEASE_STATUS

简介：$OVERVIEW

影院上映：$RELEASED_CINEMA
数字上线：$RELEASED_DIGITAL

语言：$LANG_CN
国家：$COUNTRIES_CN
类型：$GENRES
时长：$RUNTIME_DISPLAY
制作公司：$COMPANIES_CN
在线发行：$ONLINE_STREAMS

综合评分：$AVG_SCORE
网友评分：IMDb $RATING_IMDB $RATING_IMDB_COUNT| Letterboxd $RATING_LETTERBOXD $RATING_LETTERBOXD_COUNT
专业评分：Metacritic $RATING_METACRITIC $RATING_METACRITIC_COUNT| Rotten Tomatoes $RATING_ROTTEN $RATING_ROTTEN_COUNT| RogerEbert $RATING_ROGEREBERT

外部资料：$DB_URL
$TAGS"
    log_info "$MSG"
    send_telegram "$MSG" # 调用发送函数 / Call send function
}

# 功能: 清理一年以前的去重记录
# Function: Remove deduplication records older than one year
clean_old_dedup() {
    [ ! -f "$DEDUP_FILE" ] && touch "$DEDUP_FILE"

    NOW_TS=$(date +%s)
    YEAR_AGO=$((NOW_TS - 31536000))

    sed -i -e '/^[[:space:]]*$/d' -e 's/[[:space:]]*$//' "$DEDUP_FILE"

    TMP_FILE="/tmp/sent_tmdb_ids.tmp"
    
    awk -v cutoff="$YEAR_AGO" '{
        if ($2 >= cutoff) data[$1] = $0
    }
    END {
        for (id in data) print data[id]
    }' "$DEDUP_FILE" | sort -k2,2n > "$TMP_FILE"

    mv "$TMP_FILE" "$DEDUP_FILE"
}

# ---------------- 主流程 / Main Flow ----------------
# 从脚本头部获取版本号 / Get script version from header
VERSION="$(grep -m1 '^# Version:' "$0" | awk '{print $3}')"
OFFICIAL_REPO=0
# 根据运行环境动态设置 Source 和 UserAgent / Set SOURCE_URL and UA_STRING dynamically based on environment
if [ -n "$GITHUB_REPOSITORY" ]; then
    SOURCE_URL="https://github.com/${GITHUB_REPOSITORY}"
    UA_STRING="film_notify_bot/$VERSION (+$SOURCE_URL; GitHub Actions)"
    if [ "$GITHUB_REPOSITORY" = "MontageSubs/film-notify-bot" ]; then
        OFFICIAL_REPO=1
    fi
else
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        SYS_INFO="${NAME}-${VERSION_ID}"
    else
        SYS_INFO="$(uname -s)-$(uname -r)"
    fi
    SOURCE_URL="local://${SYS_INFO}"
    UA_STRING="film_notify_bot/$VERSION (+$SOURCE_URL; Local)"
fi
log_info "User-Agent: $UA_STRING"
check_env_vars
check_dependencies
check_tokens
clean_old_dedup
get_movie_list

log_info "$MOVIE_ITEMS_JSON" # debug
MOVIE_COUNT=$(echo "$MOVIE_ITEMS_JSON" | jq 'length')
if [ "$MOVIE_COUNT" -eq 0 ]; then
    log_info "今日无新电影，脚本退出 / No new movies today, exiting."
    exit 0
fi

for TMDB_ID in $(echo "$MOVIE_ITEMS_JSON" | jq -r '.[].id'); do
    if ! is_duplicate "$TMDB_ID"; then
        get_tmdb_info "$TMDB_ID"
        get_mdb_movie_info "$TMDB_ID"
        get_ratings "$TMDB_ID"
        generate_and_send_msg
        NOW_TS=$(date +%s)
        echo "$TMDB_ID $NOW_TS" >> "$DEDUP_FILE"
    fi
done

log_info "全部电影消息已发送完成 / All movie notifications sent."
