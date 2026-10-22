#!/bin/bash

# Debian Docker & 3x-ui 自动安装脚本
# 适用于 Debian 系统

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 打印带颜色的信息
info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查是否为 root 用户
check_root() {
    if [ "$EUID" -ne 0 ]; then
        error "请使用 root 用户运行此脚本，或使用 sudo"
        exit 1
    fi
}

# 更新系统包
update_system() {
    info "正在更新系统包..."
    apt-get update -y
    apt-get upgrade -y
}

# 安装 Docker
install_docker() {
    info "正在安装 Docker..."

    # 检查 Docker 是否已安装
    if command -v docker &> /dev/null; then
        info "Docker 已经安装，跳过安装步骤"
        return 0
    fi

    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh

    # 清理安装文件
    rm -f get-docker.sh

    info "Docker 安装完成"
}

# 检查 Docker 安装
check_docker() {
    info "正在检查 Docker 安装..."

    if ! command -v docker &> /dev/null; then
        error "Docker 安装失败！"
        exit 1
    fi

    DOCKER_VERSION=$(docker --version)
    info "Docker 安装成功: $DOCKER_VERSION"

    # 检查 Docker Compose
    if docker compose version &> /dev/null; then
        COMPOSE_VERSION=$(docker compose version)
        info "Docker Compose 安装成功: $COMPOSE_VERSION"
    else
        error "Docker Compose 未安装或不可用！"
        exit 1
    fi

    # 启动 Docker 服务
    systemctl start docker
    systemctl enable docker

    info "Docker 服务已启动并设置为开机自启"
}

# 创建 docker-compose.yml 文件
create_compose_file() {
    info "正在创建 docker-compose.yml 文件..."

    # 创建 3x-ui 目录
    mkdir -p 3x-ui/db

    cat > docker-compose.yml << 'EOF'
version: '3.8'
services:
  3xui:
    image: ghcr.io/mhsanaei/3x-ui:latest
    container_name: 3xui_app
    # hostname: yourhostname <- optional
    ports:
      - "443:443"
      - "2096:2096"
      - "2053:2053"
    volumes:
      - ./3x-ui/db/:/etc/x-ui/
    environment:
      - TZ=Asia/Shanghai
      - XRAY_VMESS_AEAD_FORCED="false"
      - XUI_ENABLE_FAIL2BAN="true"
    #tty: true
    #network_mode: host
    restart: unless-stopped
EOF

    info "docker-compose.yml 文件创建成功"
}

# 启动 Docker Compose
start_compose() {
    info "正在启动 Docker Compose 服务..."

    docker compose up -d

    if [ $? -eq 0 ]; then
        info "Docker Compose 服务启动成功！"
    else
        error "Docker Compose 服务启动失败！"
        exit 1
    fi
}

# 获取公网IP地址
get_public_ip() {
    # 尝试多个服务获取公网IP
    PUBLIC_IP=$(curl -s --connect-timeout 5 ifconfig.me 2>/dev/null || \
                curl -s --connect-timeout 5 ipinfo.io/ip 2>/dev/null || \
                curl -s --connect-timeout 5 icanhazip.com 2>/dev/null || \
                echo "无法获取公网IP")
    echo "$PUBLIC_IP"
}

# 显示安装信息
show_info() {
    PUBLIC_IP=$(get_public_ip)

    echo ""
    info "=========================================="
    info "安装完成！"
    info "=========================================="
    echo ""
    info "3x-ui 面板已启动，端口如下："
    info "  - 443 (HTTPS)"
    info "  - 2096"
    info "  - 2053"
    echo ""
    info "默认面板地址: http://${PUBLIC_IP}:2053/面板路径"
    info "默认用户名: admin"
    info "默认密码: admin"
    echo ""
    warn "请首次登录后立即修改用户名和密码！"
    echo ""
    info "查看日志: docker compose logs -f"
    info "停止服务: docker compose down"
    info "重启服务: docker compose restart"
    echo ""
}

# 主函数
main() {
    info "开始执行 3x-ui 自动安装脚本..."

    check_root
    update_system
    install_docker
    check_docker
    create_compose_file
    start_compose
    show_info
}

# 执行主函数
main
