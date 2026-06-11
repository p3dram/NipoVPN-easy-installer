#!/bin/bash

# --- Color Definitions ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}===============================================${NC}"
echo -e "${YELLOW}         NipoVPN Easy Server Installer         ${NC}"
echo -e "${YELLOW}           Maintained by: p3dram               ${NC}"
echo -e "${YELLOW}===============================================${NC}"

# 1. Check for root privileges
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Error: Please run this script as root or using sudo.${NC}"
    exit 1
fi

# 2. Detect server architecture
ARCH=$(dpkg --print-architecture)
if [[ "$ARCH" != "amd64" && "$ARCH" != "arm64" ]]; then
    echo -e "${RED}Error: Unsupported architecture ($ARCH). NipoVPN supports amd64 and arm64.${NC}"
    exit 1
fi

echo -e "${GREEN}[*] Architecture detected: $ARCH${NC}"
echo -e "${GREEN}[*] Updating system packages & installing required tools...${NC}"
apt-get update -y && apt-get install -y curl jq wget > /dev/null 2>&1

# 3. Fetch the latest release details from the upstream creator (MortezaBashsiz)
echo -e "${GREEN}[*] Querying MortezaBashsiz/nipovpn upstream releases...${NC}"
REPO="MortezaBashsiz/nipovpn"
RELEASE_JSON=$(curl -s "https://api.github.com/repos/$REPO/releases/latest")

if [ -z "$RELEASE_JSON" ] || echo "$RELEASE_JSON" | grep -q "message"; then
    echo -e "${RED}Error: Failed to fetch release details from GitHub API.${NC}"
    exit 1
fi

DEB_URL=$(echo "$RELEASE_JSON" | jq -r ".assets[] | select(.name | contains(\"${ARCH}.deb\")) | .browser_download_url")

if [ -z "$DEB_URL" ] || [ "$DEB_URL" == "null" ]; then
    echo -e "${RED}Error: Could not find a valid release package for $ARCH.${NC}"
    exit 1
fi

VERSION=$(echo "$RELEASE_JSON" | jq -r ".tag_name")
echo -e "${GREEN}[*] Downloading version ${VERSION}...${NC}"

# 4. Download and install the .deb package
TMP_DEB="/tmp/nipovpn_${VERSION}_${ARCH}.deb"
wget -O "$TMP_DEB" "$DEB_URL"

if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Download failed.${NC}"
    exit 1
fi

echo -e "${GREEN}[*] Installing NipoVPN package...${NC}"
apt-get install -y "$TMP_DEB"
rm -f "$TMP_DEB"

# 5. Set up logging structure
mkdir -p /var/log/nipovpn/
touch /var/log/nipovpn/nipovpn.log
chmod 755 /var/log/nipovpn/
chmod 644 /var/log/nipovpn/nipovpn.log

# 6. Initialize and start the Systemd Service
echo -e "${GREEN}[*] Starting NipoVPN systemd daemon...${NC}"
if systemctl list-unit-files | grep -q "nipovpn-server.service"; then
    systemctl daemon-reload
    systemctl enable nipovpn-server.service
    systemctl restart nipovpn-server.service
    
    # --- Service Management Section Printed directly inside bash output ---
    echo -e "\n${YELLOW}=====================================================${NC}"
    echo -e "${GREEN}✓ Installation complete! Thank you Morteza Bashsiz!${NC}"
    echo -e "${YELLOW}=====================================================${NC}"
    echo -e "${YELLOW}🛠️  SERVICE MANAGEMENT CHEAT SHEET:${NC}"
    echo -e "-----------------------------------------------------"
    echo -e "• Check Status:  ${GREEN}sudo systemctl status nipovpn-server${NC}"
    echo -e "• Stop Server:   ${GREEN}sudo systemctl stop nipovpn-server${NC}"
    echo -e "• Start Server:  ${GREEN}sudo systemctl start nipovpn-server${NC}"
    echo -e "• Restart Server:${GREEN}sudo systemctl restart nipovpn-server${NC}"
    echo -e "• Stream Logs:   ${GREEN}tail -f /var/log/nipovpn/nipovpn.log${NC}"
    echo -e "-----------------------------------------------------"
    echo -e "Find updates at: ${YELLOW}https://github.com/p3dram/NipoVPN-easy-installer${NC}"
    echo -e "${YELLOW}=====================================================${NC}\n"
else
    echo -e "${RED}Warning: Installation completed but nipovpn-server.service was not found.${NC}"
fi
