#!/bin/bash
set -e

OPEND_DIR="/opt/futu-opend"
CONFIG_FILE="${OPEND_DIR}/FutuOpenD.xml"
DATA_DIR="/data"

# ── Validate required env vars ──────────────────────────────────────
if [ -z "$FUTU_LOGIN_ACCOUNT" ]; then
    echo "ERROR: FUTU_LOGIN_ACCOUNT is required"
    exit 1
fi

if [ -z "$FUTU_LOGIN_PWD_MD5" ] && [ -z "$FUTU_LOGIN_PWD" ]; then
    echo "ERROR: FUTU_LOGIN_PWD_MD5 or FUTU_LOGIN_PWD is required"
    exit 1
fi

# ── Persist AppData.dat via symlink ─────────────────────────────────
# AppData.dat stores device trust (avoids re-verification on restart).
# Symlink it to the persistent volume so writes go directly to /data.
mkdir -p "$DATA_DIR"
if [ ! -f "${DATA_DIR}/AppData.dat" ] && [ -f "${OPEND_DIR}/AppData.dat" ]; then
    # First run: copy default AppData.dat to persistent volume
    cp "${OPEND_DIR}/AppData.dat" "${DATA_DIR}/AppData.dat"
fi
# Replace with symlink (remove original first)
rm -f "${OPEND_DIR}/AppData.dat"
ln -sf "${DATA_DIR}/AppData.dat" "${OPEND_DIR}/AppData.dat"

# ── Generate FutuOpenD.xml from environment variables ───────────────
cat > "$CONFIG_FILE" <<EOF
<futu_opend>
    <ip>0.0.0.0</ip>
    <api_port>${FUTU_API_PORT:-11111}</api_port>
    <login_account>${FUTU_LOGIN_ACCOUNT}</login_account>
EOF

# Prefer MD5 password over plaintext
if [ -n "$FUTU_LOGIN_PWD_MD5" ]; then
    echo "    <login_pwd_md5>${FUTU_LOGIN_PWD_MD5}</login_pwd_md5>" >> "$CONFIG_FILE"
elif [ -n "$FUTU_LOGIN_PWD" ]; then
    echo "    <login_pwd>${FUTU_LOGIN_PWD}</login_pwd>" >> "$CONFIG_FILE"
fi

cat >> "$CONFIG_FILE" <<EOF
    <lang>${FUTU_LANG:-en}</lang>
    <log_level>${FUTU_LOG_LEVEL:-info}</log_level>
    <push_proto_type>${FUTU_PUSH_PROTO_TYPE:-0}</push_proto_type>
    <price_reminder_push>${FUTU_PRICE_REMINDER_PUSH:-1}</price_reminder_push>
    <auto_hold_quote_right>${FUTU_AUTO_HOLD_QUOTE_RIGHT:-1}</auto_hold_quote_right>
    <future_trade_api_time_zone>${FUTU_TIMEZONE:-UTC+8}</future_trade_api_time_zone>
    <telnet_ip>127.0.0.1</telnet_ip>
    <telnet_port>22222</telnet_port>
EOF

# Optional: RSA private key
if [ -n "$FUTU_RSA_KEY_PATH" ] && [ -f "$FUTU_RSA_KEY_PATH" ]; then
    echo "    <rsa_private_key>${FUTU_RSA_KEY_PATH}</rsa_private_key>" >> "$CONFIG_FILE"
fi

# Optional: WebSocket
if [ -n "$FUTU_WEBSOCKET_PORT" ]; then
    echo "    <websocket_ip>0.0.0.0</websocket_ip>" >> "$CONFIG_FILE"
    echo "    <websocket_port>${FUTU_WEBSOCKET_PORT}</websocket_port>" >> "$CONFIG_FILE"
fi
if [ -n "$FUTU_WEBSOCKET_KEY_MD5" ]; then
    echo "    <websocket_key_md5>${FUTU_WEBSOCKET_KEY_MD5}</websocket_key_md5>" >> "$CONFIG_FILE"
fi

# Optional: FUTU US settings
if [ -n "$FUTU_PDT_PROTECTION" ]; then
    echo "    <pdt_protection>${FUTU_PDT_PROTECTION}</pdt_protection>" >> "$CONFIG_FILE"
fi

echo "</futu_opend>" >> "$CONFIG_FILE"

echo "=== FutuOpenD config generated ==="

# ── Start FutuOpenD (exec: stdin forwarded for console interaction) ──
cd "$OPEND_DIR"
exec ./FutuOpenD
