#!/bin/bash

# --- Color Definitions for output ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}===============================================${NC}"
echo -e "${YELLOW}      NipoVPN Automated Server Installer       ${NC}"
echo -e "${YELLOW}===============================================${NC}"

# 1. Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Error: Please run this script as root or using sudo.${NC}"
    exit 1
fi

# 2. Check architecture compatibility (NipoVPN builds for amd64 and arm64)
ARCH=$(dpkg --print-architecture)
if [[ "$ARCH" != "amd64" && "$ARCH" != "arm64" ]]; then
    echo -e "${RED}Error: Unsupported architecture ($ARCH). NipoVPN supports amd64 and arm64.${NC}"
    exit 1
fi

echo -e "${GREEN}[*] System architecture detected: $ARCH${NC}"

# 3. Update repositories and install essential dependencies
echo -e "${GREEN}[*] Updating package list and installing dependencies (curl, jq)...${NC}"
apt-get update -y && apt-get install -y curl jq wget > /dev/null 2>&1

# 4. Fetch the latest release details from GitHub API
echo -e "${GREEN}[*] Fetching latest NipoVPN release from GitHub...${NC}"
REPO="MortezaBashsiz/nipovpn"
LATEST_RELEASE_JSON=$(curl -s "https://api.github.com/repos/$REPO/releases/latest")

if [ -z "$LATEST_RELEASE_JSON" ] || echo "$LATEST_RELEASE_JSON" | grep -q "message"; then
    echo -e "${RED}Error: Failed to reach GitHub API. Please check your internet connection or try again later.${NC}"
    exit 1
fi

# Filter the download URL specifically for the server's architecture deb package
DEB_URL=$(echo "$LATEST_RELEASE_JSON" | jq -r ".assets[] | select(.name | contains(\"${ARCH}.deb\")) | .browser_download_url")

if [ -z "$DEB_URL" ] || [ "$DEB_URL" == "null" ]; then
    echo -e "${RED}Error: Could not find a suitable .deb package for $ARCH architecture in the latest release.${NC}"
    exit 1
fi

VERSION_TAG=$(echo "$LATEST_RELEASE_JSON" | jq -r ".tag_name")
echo -e "${GREEN}[*] Found version ${VERSION_TAG}. Downloading package...${NC}"

# 5. Download and install the .deb package
TMP_DEB="/tmp/nipovpn_${VERSION_TAG}_${ARCH}.deb"
wget -O "$TMP_DEB" "$DEB_URL"

if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Failed to download the package.${NC}"
    exit 1
fi

echo -e "${GREEN}[*] Installing NipoVPN package...${NC}"
apt-get install -y "$TMP_DEB"

# Clean up temporary download file
rm -f "$TMP_DEB"

# 6. Ensure log directories and files are initialized correctly
echo -e "${GREEN}[*] Configuring directories and log files...${NC}"
mkdir -p /var/log/nipovpn/
touch /var/log/nipovpn/nipovpn.log
chmod 755 /var/log/nipovpn/
chmod 644 /var/log/nipovpn/nipovpn.log

# 7. Start and enable systemd service for NipoVPN Server
echo -e "${GREEN}[*] Configuring and starting nipovpn-server systemd service...${NC}"

# Check if the service file was installed properly by the package
if systemctl list-unit-files | grep -q "nipovpn-server.service"; then
    systemctl daemon-reload
    systemctl enable nipovpn-server.service
    systemctl restart nipovpn-server.service
    
    # 8. Success message and status check
    echo -e "${YELLOW}===============================================${NC}"
    echo -e "${GREEN}✓ NipoVPN Server has been successfully installed!${NC}"
    echo -e "${YELLOW}===============================================${NC}"
    echo -e "To view NipoVPN configuration files, navigate to: ${YELLOW}/etc/nipovpn/${NC}"
    echo -e "To check service logs, run: ${YELLOW}tail -f /var/log/nipovpn/nipovpn.log${NC}"
    echo -e "To check service status, run: ${YELLOW}sudo systemctl status nipovpn-server.service${NC}"
else
    echo -e "${RED}Warning: Package installed, but nipovpn-server.service could not be found.${NC}"
    echo -e "You may need to manually execute: sudo nipovpn server [path_to_config.yaml]"
fi
