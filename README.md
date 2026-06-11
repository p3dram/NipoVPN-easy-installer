# NipoVPN Easy Installer

An automated, hassle-free Bash installer script to quickly deploy the NipoVPN Server on Ubuntu/Debian environments. 

This project automatically detects your server's architecture (`amd64` or `arm64`), pulls the latest stable package release, handles configurations, and schedules the service to run smoothly in the background via `systemd`.

---

## 🖤 Acknowledgments & Credits

This installation utility is built specifically for **NipoVPN**, an innovative project developed by **Morteza Bashsiz**. 

We want to extend our sincere thanks to Morteza Bashsiz for creating and maintaining the original repository. Without their open-source contributions, this helper script would not exist. 
* **Original Project Link:** [MortezaBashsiz/nipovpn](https://github.com/MortezaBashsiz/nipovpn)

---

## 🚀 Quick Installation

To install and configure the NipoVPN server instantly, run the following command with root privileges on your server:

```bash
bash <(curl -sL [https://raw.githubusercontent.com/YOUR_GITHUB_USERNAME/NipoVPN-easy-installer/main/install.sh](https://raw.githubusercontent.com/YOUR_GITHUB_USERNAME/NipoVPN-easy-installer/main/install.sh))


🛠️ Service Management
The installer registers NipoVPN as a background service daemon. You can manage it using standard system commands:

Check Service Status: sudo systemctl status nipovpn-server

Restart the Server: sudo systemctl restart nipovpn-server

Stop the Server: sudo systemctl stop nipovpn-server

View Output Logs: tail -f /var/log/nipovpn/nipovpn.log
