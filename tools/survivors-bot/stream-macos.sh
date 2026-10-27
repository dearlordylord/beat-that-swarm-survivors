#!/bin/bash
set -euo pipefail

repo=$(cd -- "$(dirname -- "$0")/../.." && pwd)
label=com.dearlordylord.nightfall-stream-bot
command=${1:-start}
[[ $# -le 1 ]] || { echo 'Usage: stream-macos.sh start|stop|status|install|uninstall' >&2; exit 2; }
case "$command" in start|stop|status|install|uninstall|run) ;; *) echo 'Usage: stream-macos.sh start|stop|status|install|uninstall' >&2; exit 2 ;; esac
[[ $(uname -s) == Darwin ]] || { echo 'Run this launcher on your Mac in a logged-in desktop session.' >&2; exit 1; }
export PATH="$HOME/.bend/bin:$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
domain="gui/$(id -u)"
state_dir="$HOME/Library/Application Support/Nightfall Stream Bot"
login_plist="$HOME/Library/LaunchAgents/$label.plist"
local_plist="$state_dir/agent.plist"
mkdir -p "$state_dir"

xml() { printf '%s' "$1" | sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g' -e 's/"/\&quot;/g' -e "s/'/\&apos;/g"; }
write_plist() {
  cat > "$1" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>Label</key><string>$label</string>
<key>ProgramArguments</key><array><string>/bin/bash</string><string>$(xml "$repo/tools/survivors-bot/stream-macos.sh")</string><string>run</string></array>
<key>WorkingDirectory</key><string>$(xml "$state_dir")</string>
<key>RunAtLoad</key><true/>
<key>KeepAlive</key><dict><key>SuccessfulExit</key><false/></dict>
<key>ThrottleInterval</key><integer>60</integer>
<key>ProcessType</key><string>Interactive</string>
<key>LimitLoadToSessionType</key><string>Aqua</string>
<key>StandardOutPath</key><string>/dev/null</string>
<key>StandardErrorPath</key><string>/dev/null</string>
</dict></plist>
PLIST
  plutil -lint "$1" >/dev/null
}
loaded() { launchctl print "$domain/$label" >/dev/null 2>&1; }
stop() {
  if loaded; then launchctl bootout "$domain/$label"; fi
}
case "$command" in
  run)
    cd "$state_dir"
    # A process restart replaces the previous launch's log.
    exec > "$state_dir/last-launch.log" 2>&1
    exec /usr/bin/caffeinate -d -i /bin/bash "$repo/tools/survivors-bot/visible.sh" --stream
    ;;
  stop)
    stop
    echo 'Stream bot stopped. An installed login agent starts again at your next login.'
    ;;
  status)
    if loaded; then
      launchctl print "$domain/$label"
    else
      echo 'Stream bot is not loaded.'
    fi
    echo "Log: $state_dir/last-launch.log"
    if [[ -f $login_plist ]]; then echo 'Login startup is installed.'; else echo 'Login startup is not installed.'; fi
    ;;
  uninstall)
    stop
    rm -f "$login_plist" "$local_plist"
    echo 'Stream bot stopped and login startup removed.'
    ;;
  start|install)
    echo 'Checking the native Mac build. The first build can take several minutes.'
    /bin/bash "$repo/tools/survivors-bot/visible.sh" --stream --build-only
    if [[ $command == install ]]; then
      mkdir -p "$(dirname "$login_plist")"
      write_plist "$login_plist"
      stop
      launchctl bootstrap "$domain" "$login_plist"
      echo 'Stream bot started. It also starts after you log in to this Mac.'
    else
      write_plist "$local_plist"
      if loaded; then launchctl kickstart "$domain/$label"; else launchctl bootstrap "$domain" "$local_plist"; fi
      echo 'Stream bot started for this desktop session.'
    fi
    echo 'Capture the Beat That Swarm: Survivors window in OBS.'
    echo "Log: $state_dir/last-launch.log"
    ;;
esac
