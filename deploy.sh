#!/bin/bash
###############################################################################
# HTML Paste URL Generator — VPS CLI Manager
# Works WITHOUT Docker. Compatible with Ubuntu/Debian VPS (incl. Railway VM).
#
# Menu:
#   1) Install / Update
#   2) Uninstall
#   3) Status
#   0) Exit
###############################################################################
set -u

APP_NAME="htmlpaste"
APP_DIR="/opt/${APP_NAME}"
SERVICE_NAME="${APP_NAME}.service"
PORT="3000"
REPO_URL="${REPO_URL:-https://github.com/siddhantpashte123-hub/web-.git}"
BRANCH="${BRANCH:-arena/d03e5514-web}"

# Colors
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

is_root() { [ "$(id -u)" -eq 0 ]; }
command_exists() { command -v "$1" >/dev/null 2>&1; }
node_installed() { command_exists node && node -v >/dev/null 2>&1; }

detect_os() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_ID="${ID:-}"
  else
    OS_ID="unknown"
  fi
}

install_nodejs() {
  if node_installed; then
    echo -e "${GREEN}Node.js pehle se install hai: $(node -v)${NC}"
    return 0
  fi

  detect_os
  echo -e "${BLUE}Node.js install ho raha hai...${NC}"
  if command_exists curl; then
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
  elif command_exists wget; then
    wget -qO- https://deb.nodesource.com/setup_20.x | bash -
  else
    echo -e "${RED}curl ya wget nahi mila. Node.js manually install karo.${NC}"
    return 1
  fi

  case "$OS_ID" in
    ubuntu|debian) apt-get update -y && apt-get install -y nodejs git ;;
    *) apt-get update -y && apt-get install -y nodejs git ;;
  esac

  if ! node_installed; then
    echo -e "${RED}Node.js install nahi ho paaya.${NC}"
    return 1
  fi
  echo -e "${GREEN}Node.js install hua: $(node -v)${NC}"
}

get_app_dir_status() {
  if [ -d "$APP_DIR" ]; then
    echo "present"
  else
    echo "absent"
  fi
}

service_status() {
  systemctl is-active --quiet "$SERVICE_NAME" 2>/dev/null
}

clone_or_pull() {
  mkdir -p /opt
  if [ -d "$APP_DIR/.git" ]; then
    echo -e "${BLUE}Existing repo update ho raha hai...${NC}"
    git -C "$APP_DIR" fetch origin
    git -C "$APP_DIR" checkout "$BRANCH" 2>/dev/null || git -C "$APP_DIR" checkout -b "$BRANCH" origin/"$BRANCH" 2>/dev/null || true
    git -C "$APP_DIR" pull origin "$BRANCH" --rebase || true
  else
    echo -e "${BLUE}Repo clone ho raha hai...${NC}"
    git clone -b "$BRANCH" "$REPO_URL" "$APP_DIR"
  fi
}

install_app() {
  if ! is_root; then
    echo -e "${RED}Install/Update ke liye root access chahiye (sudo se chalao).${NC}"
    return 1
  fi

  echo -e "${YELLOW}=== HTML Paste — Install / Update ===${NC}"

  install_nodejs || return 1
  command_exists git || apt-get update -y && apt-get install -y git

  clone_or_pull || { echo -e "${RED}Git clone/pull fail hua.${NC}"; return 1; }

  cd "$APP_DIR"
  echo -e "${BLUE}npm install chal raha hai...${NC}"
  npm install --production --silent || { echo -e "${RED}npm install fail hua.${NC}"; return 1; }

  # .env file banaye agar nahi hai
  if [ ! -f "$APP_DIR/.env" ]; then
    cp "$APP_DIR/.env.example" "$APP_DIR/.env" 2>/dev/null || true
    echo "PORT=$PORT" >> "$APP_DIR/.env"
    echo -e "${GREEN}.env create kar diya (PORT=$PORT).${NC}"
  fi

  # systemd service file
  cat > /etc/systemd/system/${SERVICE_NAME} <<EOF
[Unit]
Description=HTML Paste URL Generator (Node.js)
After=network.target

[Service]
Type=simple
WorkingDirectory=${APP_DIR}
EnvironmentFile=${APP_DIR}/.env
ExecStart=/usr/bin/node ${APP_DIR}/server.js
Restart=always
RestartSec=3
User=root

[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  systemctl enable ${SERVICE_NAME}
  systemctl restart ${SERVICE_NAME}

  sleep 2
  if service_status; then
    echo -e "${GREEN}✔ Install/Update complete!${NC}"
    echo -e "${GREEN}Service: ${SERVICE_NAME} (running)${NC}"
    echo -e "${BLUE}URL: http://<your-vps-ip>:${PORT}${NC}"
    echo -e "${BLUE}Logs: journalctl -u ${SERVICE_NAME} -f${NC}"
  else
    echo -e "${RED}Service start nahi hua. Logs check karo: journalctl -u ${SERVICE_NAME}${NC}"
    return 1
  fi
}

uninstall_app() {
  if ! is_root; then
    echo -e "${RED}Uninstall ke liye root access chahiye (sudo se chalao).${NC}"
    return 1
  fi

  echo -e "${YELLOW}=== HTML Paste — Uninstall ===${NC}"

  if service_status || systemctl is-enabled --quiet "$SERVICE_NAME" 2>/dev/null; then
    systemctl stop ${SERVICE_NAME} 2>/dev/null
    systemctl disable ${SERVICE_NAME} 2>/dev/null
    echo -e "${GREEN}Service stop/disable kar diya.${NC}"
  fi

  rm -f /etc/systemd/system/${SERVICE_NAME}
  systemctl daemon-reload
  systemctl reset-failed 2>/dev/null || true

  if [ -d "$APP_DIR" ]; then
    rm -rf "$APP_DIR"
    echo -e "${GREEN}App directory remove kar di: $APP_DIR${NC}"
  fi

  echo -e "${GREEN}✔ Uninstall complete.${NC}"
}

show_status() {
  echo -e "${YELLOW}=== HTML Paste — Status ===${NC}"
  echo -e "App dir: ${APP_DIR} ($(get_app_dir_status))"
  echo -e "Service: ${SERVICE_NAME}"

  if service_status; then
    echo -e "${GREEN}Status: RUNNING${NC}"
    echo -e "URL: http://<your-vps-ip>:${PORT}"
    echo -e "Recent logs:"
    journalctl -u ${SERVICE_NAME} --no-pager -n 10 2>/dev/null || true
  else
    echo -e "${RED}Status: NOT RUNNING${NC}"
    echo -e "Install karne ke liye menu mein option 1 chunein."
  fi
}

show_menu() {
  echo ""
  echo -e "${BLUE}========================================${NC}"
  echo -e "${BLUE}   HTML Paste URL Generator (No Docker)${NC}"
  echo -e "${BLUE}========================================${NC}"
  echo -e "1) Install / Update"
  echo -e "2) Uninstall"
  echo -e "3) Status"
  echo -e "0) Exit"
  echo -e "${BLUE}========================================${NC}"
  printf "${YELLOW}Select an option [0-3]: ${NC}"
}

main() {
  while true; do
    show_menu
    read -r choice
    case "$choice" in
      1) install_app ;;
      2) uninstall_app ;;
      3) show_status ;;
      0) echo -e "${GREEN}Bye!${NC}"; exit 0 ;;
      *) echo -e "${RED}Invalid option.${NC}" ;;
    esac
    echo ""
    echo -e "${YELLOW}Press Enter to continue...${NC}"
    read -r
  done
}

main "$@"
