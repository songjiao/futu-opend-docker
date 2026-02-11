#!/bin/bash
#
# Generate RSA private key for Futu OpenD API encryption.
# Format: PKCS#1, key size: 512 or 1024 (default 1024).
# The same private key is used by both OpenD and the API client SDK.
#
set -e

KEY_SIZE="${1:-1024}"
OUTPUT_DIR="./secrets"

mkdir -p "$OUTPUT_DIR"

PRIVATE_KEY="${OUTPUT_DIR}/rsa_private.pem"

if [ -f "$PRIVATE_KEY" ]; then
    echo "WARNING: $PRIVATE_KEY already exists."
    read -p "Overwrite? (y/N): " confirm
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        echo "Aborted."
        exit 0
    fi
fi

# Generate PKCS#1 private key (-traditional forces PKCS#1 on OpenSSL 3.x)
openssl genrsa -traditional -out "$PRIVATE_KEY" "$KEY_SIZE"

chmod 600 "$PRIVATE_KEY"

echo ""
echo "=== Key generated ==="
echo "Private key (PKCS#1, ${KEY_SIZE}-bit): $PRIVATE_KEY"
echo ""
echo "Next steps:"
echo "  1. Uncomment FUTU_RSA_KEY_PATH in .env"
echo "  2. Use the same key file in your API client SDK:"
echo "     SysConfig.enable_proto_encrypt(True)"
echo "     SysConfig.set_init_rsa_file('rsa_private.pem')"
echo "  3. Restart the container: docker-compose restart"
