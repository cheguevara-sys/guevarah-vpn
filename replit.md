# Guevarah VPN tunnel

An Android VPN application that tunnels all device traffic through an SSH dynamic port forward (SOCKS5 proxy), with HTTP Custom Payload injection support for bypassing network restrictions.

## Stack

- **Language:** Java (Android SDK 26+, target 33)
- **Build:** Gradle 8.0 (Groovy DSL) + Temurin JDK 17 + Android SDK 33
- **SSH library:** `org.connectbot:sshlib:2.2.21` (trilead-ssh2 fork)
- **VPN engine:** bundled `tun2socks.aar` (captures device traffic → SOCKS5)
- **Key dependencies:** Gson, BouncyCastle, Material Components, AmazingSpinner

## Building the APK

Run the helper script (handles JDK + Android SDK setup automatically):

```bash
bash build.sh
```

Output: `app/build/outputs/apk/debug/app-debug.apk` (~34 MB)

Or manually with environment set:

```bash
export JAVA_HOME=/tmp/jdk-17.0.11+9        # Temurin JDK 17 (required — GraalVM won't work)
export ANDROID_SDK_ROOT=~/android-sdk
export ANDROID_HOME=~/android-sdk
export PATH=$JAVA_HOME/bin:$PATH
./gradlew assembleDebug
```

> **Important:** The system JDK is GraalVM 19, which breaks Android's `jlink` step.
> Always use Temurin JDK 17. The path is pinned in `gradle.properties` via `org.gradle.java.home`.
> If `/tmp/jdk-17.0.11+9` doesn't exist (container restart), run `bash build.sh` which re-downloads it.

## Architecture

```
Device traffic
    ↓
tun2socks (SocksProxyService – VpnService)
    ↓ SOCKS5 → 127.0.0.1:1080
SSH dynamic port forwarder (SshService)
    ↓ (optional: via HTTP Payload tunnel or HTTP CONNECT proxy)
Remote SSH server
```

### Key source files

| File | Role |
|------|------|
| `services/SshService.java` | Opens SSH connection, creates SOCKS5 dynamic forwarder |
| `services/SocksProxyService.java` | Android VpnService, routes device traffic through tun2socks |
| `services/LocalPayloadProxyServer.java` | Local bridge proxy for HTTP Custom Payload injection |
| `data/SSHConnectionProfile.java` | Profile model (SSH + HTTP payload settings) |
| `data/PresetProfiles.java` | 8 pre-built VPN configurations (CDN bypass, WebSocket, etc.) |
| `data/utils/SSHConnectionProfileManager.java` | Persist/load/import/export profiles (Gson + SharedPreferences) |
| `MainActivity.java` | Main UI: profile spinner, connect/disconnect, import/export/presets menu |
| `NewConnectionActivity.java` | Create/edit profiles (SSH + HTTP payload fields) |
| `SettingsActivity.java` | DNS, app inclusion, forwarder port |

## Profile Import / Export (.gc files)

Profiles are exported and imported as `.gc` files (JSON with a `# Guevarah VPN tunnel profile export` header).

- **Export:** Menu → Export Profiles → save as `.gc` file
- **Import:** Menu → Import Profiles → pick a `.gc` file  
- **Open from file manager:** The app registers as a handler for `.gc` files
- Duplicate profiles (same UUID) are skipped on import; a new UUID is assigned if missing

### .gc file format
```json
# Guevarah VPN tunnel profile export
[
  {
    "profileName": "My Profile",
    "serverIP": "1.2.3.4",
    "serverPort": 22,
    "username": "root",
    "authenticationType": "PASSWORD",
    "password": "...",
    "httpPayloadEnabled": false,
    "httpPayloadHost": "",
    "httpPayloadPort": 80,
    "httpCustomPayload": "CONNECT [host]:[port] HTTP/1.0\r\n\r\n",
    "uuid": "..."
  }
]
```

## Pre-built Configurations (Presets)

Menu → Add Preset shows 8 bundled configurations:

| Preset | Use case |
|--------|----------|
| Direct SSH (Port 22) | Standard SSH, no proxy |
| SSH on Port 443 (HTTPS) | When only HTTPS is allowed |
| SSH on Port 80 (HTTP) | When only HTTP is allowed |
| HTTP CONNECT Proxy (Port 8080) | Route via corporate/ISP HTTP proxy |
| CDN Bypass (HTTP Injector Style) | Spoof CDN Host header to bypass DPI |
| WebSocket Upgrade Tunnel | Bypass via WebSocket Upgrade |
| Squid Proxy (Port 3128) | Common Squid proxy config |
| Domain Fronting Payload | Front SSH via CDN domain |

After adding a preset, the editor opens so you can fill in your SSH server details.

## HTTP Payload / Remote Proxy

Each profile can optionally enable HTTP Payload injection:

- **Proxy Host + Port** — remote HTTP proxy or CDN entry point
- **Custom Payload** — sent verbatim over the raw TCP socket before the SSH handshake

Supported placeholders:

| Placeholder | Replaced with |
|-------------|---------------|
| `[host]` / `[HOST]` | SSH server hostname |
| `[port]` / `[PORT]` | SSH server port |
| `[crlf]` | `\r\n` |
| `[cr]` | `\r` |
| `[lf]` | `\n` |

## User preferences

- App name: **Guevarah VPN tunnel**
- Profile export file extension: `.gc`
- Keep existing Java code style and project structure
- Use placeholder-based payload syntax compatible with HTTP Injector (`[host]`, `[port]`, `[crlf]`)
- Always use Temurin JDK 17 for builds (GraalVM breaks jlink)
