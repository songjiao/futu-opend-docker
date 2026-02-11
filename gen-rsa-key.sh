#!/bin/bash
#
# Generate RSA key pair for Futu OpenD API encryption.
# Private key: PKCS#1 format (required by OpenD)
# Public key:  for use in Futu API client SDK
#
set -e

KEY_SIZE="${1:-1024}"
OUTPUT_DIR="./secrets"

mkdir -p "$OUTPUT_DIR"

PRIVATE_KEY="${OUTPUT_DIR}/rsa_private.pem"
PUBLIC_KEY="${OUTPUT_DIR}/rsa_public.pem"

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

# Extract public key
openssl rsa -in "$PRIVATE_KEY" -pubout -out "$PUBLIC_KEY"

chmod 600 "$PRIVATE_KEY"
chmod 644 "$PUBLIC_KEY"

echo ""
echo "=== Keys generated ==="
echo "Private key (PKCS#1): $PRIVATE_KEY"
echo "Public key:           $PUBLIC_KEY"
echo ""
echo "Next steps:"
echo "  1. Uncomment FUTU_RSA_KEY_PATH in .env"
echo "  2. Use the public key in your API client SDK for encryption"
echo "  3. Restart the container: docker-compose restart"
