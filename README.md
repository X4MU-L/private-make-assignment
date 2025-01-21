# System-monitor Installation

The assignment can be installed via the command line.

> **Note:** You can set an environment variable:

```bash
export WEEK2_TEAMS_WEBHOOK_ENV=<teams_webhook_url>
```

> **Note:** Replace `<teams_webhook_url>` with your actual Microsoft Teams webhook URL.

> **Note:** Your system monitor information will be sent to your `<teams_webhook_url>`. Otherwise, The information will be sent to a default `WEEK2_TEAMS_WEBHOOK_ENV` in the script and I (The Author) will be the one receiving the information 🌚 🌚 🤭.

If `name_of_command` is not provided, the script will be installed as **system-monitor**.

```bash
git clone https://github.com/X4MU-L/private-make-assignment.git
cd month2-week3-assignment
[WEEK2_TEAMS_WEBHOOK_ENV=<teams_webhook_url>] sudo make install [PROJECT_NAME=name_of_command]
```

```bash
# One line command
$ [WEEK2_TEAMS_WEBHOOK_ENV=<teams_webhook_url>] curl -sSL https://raw.githubusercontent.com/X4MU-L/private-make-assignment/main/install.sh | sudo bash
# you can as well run system-monitor to initiate the script outside of the systemd
$ system-monitor
# or
$ [WEEK2_TEAMS_WEBHOOK_ENV=<teams_webhook_url>] curl -sSL https://raw.githubusercontent.com/X4MU-L/private-make-assignment/main/install.sh | sudo bash -s -- <name_of_command>
# you can as well run <name_of_command> to initiate the script outside of the systemd
$ <name_of_command>

```

## Example of teams webhook information 
I apologize in a advance that my image and name 🤓 🌚 will be the one appearing in the webhook information (hoping to probably modify this in future, nevertheless, your PR will be appreciated)

![System Monitor information](system-monitor.png)

# Create Nginx server and capture and analyze packages 

```bash
sudo bash capture_nginx
# or run
sudo ./capture_nginx
```

```bash
sudo tcpdump -i any port 80 -w nginx_traffic.pcap
```

In a different terminal:

```bash
curl http://localhost
```

```bash
# Read and analyze the captured packets using Wireshark
wireshark -r nginx_traffic.pcap
```
