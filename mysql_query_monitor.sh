#!/bin/bash

# MySQL 连接参数
MYSQL_USER="xxxx"                       # MySQL 用户名
MYSQL_PASSWORD="xxxxxxxx"          # MySQL 密码
MYSQL_HOST="xx.xx.xx.xx"             # MySQL 主机地址
MYSQL_PORT="xxxx"                       # MySQL 端口

# 日志文件配置
LOG_FILE="/var/log/mysql_query_monitor.log"
TEMP_FILE="/tmp/mysql_query_monitor_temp.log"

# 监控参数
QUERY_LIMIT=20                          # 显示的进程数量
REFRESH_INTERVAL=2                      # 刷新间隔时间（秒）

# 输出标题函数
function print_header() {
    echo "------------------- MySQL Query Monitor -------------------"
    echo "Time: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "------------------------------------------------------------"
    echo ""
    # 打印表头，格式对齐
    printf "%-5s %-8s %-20s %-6s %-8s %-6s %-20s %-100s\n" "Id" "User" "Host" "db" "Command" "Time" "State" "Info"
    echo "------------------------------------------------------------"
}

# 主循环
while true; do
    # 执行查询并排除 Sleep 状态及当前会话
    mysql -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" -h"${MYSQL_HOST}" -P"${MYSQL_PORT}" -e "
    SELECT Id, User, Host, db, Command, Time, State, Info
    FROM information_schema.processlist
    WHERE Command != 'Sleep' AND Id != CONNECTION_ID()
    ORDER BY Time DESC
    LIMIT ${QUERY_LIMIT};" > "${TEMP_FILE}" 2>/dev/null

    # 比较新旧日志，仅在内容变化时更新日志文件和输出
    if ! cmp -s "${TEMP_FILE}" "${LOG_FILE}"; then
        mv "${TEMP_FILE}" "${LOG_FILE}"
        clear
        print_header
        # 格式化输出每行数据，字段对齐
        while IFS=$'\t' read -r id user host db command time state info; do
            # 截断过长的 Info 字段，避免输出过长行
           info=$(echo "$info" | cut -c1-150)
            # 打印格式化后的每一行
            printf "%-5s %-8s %-20s %-6s %-8s %-6s %-20s %-100s\n" "$id" "$user" "$host" "$db" "$command" "$time" "$state" "$info"
        done < "${LOG_FILE}"
    fi

    # 等待下一次刷新
    sleep "${REFRESH_INTERVAL}"
done
