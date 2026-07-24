#!/usr/bin/env python3
"""
Decrypts MyMoney - Track Expense & Budget (com.raha.app.mymoney.free) backup (.mbak) files.

Reverse-engineered from the app's APK (class k3/h3, referenced from gl1.s / gl1.y):
  - Format on disk: base64(iv) : base64(mac) : base64(ciphertext)
  - Key derivation: PBKDF2WithHmacSHA1(password, salt, 10000 iterations, 384-bit output)
      password = literal string "my_money_password"
      salt     = base64.b64decode("my_money_salt")   (8 raw bytes)
    -> first 16 bytes = AES-128 key
    -> next  32 bytes = HMAC-SHA256 key
  - Integrity: HMAC-SHA256(iv || ciphertext) must equal the stored mac
  - Cipher: AES/CBC/PKCS5Padding using the derived AES key and the stored iv

This matches the widely-used "AesCbcWithIntegrity" pattern; this app hardcodes the
password/salt in the app itself rather than deriving them from anything user-specific.
"""

import base64
import hashlib
import hmac
import json
import sys
from Crypto.Cipher import AES
from Crypto.Util.Padding import unpad

APP_PASSWORD = "my_money_password"
APP_SALT_B64 = "my_money_salt"


def derive_keys():
    # Replicate android.util.Base64.decode(APP_SALT_B64, 2) (flag 2 = NO_WRAP, standard alphabet)
    padded = APP_SALT_B64 + "=" * (-len(APP_SALT_B64) % 4)
    salt = base64.b64decode(padded)

    # PBKDF2WithHmacSHA1, 10000 iterations, 384-bit (48 byte) output
    key_material = hashlib.pbkdf2_hmac(
        "sha1", APP_PASSWORD.encode("utf-8"), salt, 10000, dklen=48
    )
    aes_key = key_material[:16]
    hmac_key = key_material[16:48]
    return aes_key, hmac_key


def decrypt_mbak(path):
    with open(path, "r", encoding="utf-8") as f:
        raw = f.read().strip()

    parts = raw.split(":")
    if len(parts) != 3:
        raise ValueError(f"Expected iv:mac:ciphertext, got {len(parts)} parts")

    iv = base64.b64decode(parts[0])
    mac = base64.b64decode(parts[1])
    ciphertext = base64.b64decode(parts[2])

    aes_key, hmac_key = derive_keys()

    computed_mac = hmac.new(hmac_key, iv + ciphertext, hashlib.sha256).digest()
    if not hmac.compare_digest(computed_mac, mac):
        raise ValueError(
            "MAC mismatch — file may be corrupted, truncated, or not a MyMoney .mbak file"
        )

    cipher = AES.new(aes_key, AES.MODE_CBC, iv)
    plaintext = unpad(cipher.decrypt(ciphertext), AES.block_size)
    return plaintext.decode("utf-8")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <path-to-.mbak>")
        sys.exit(1)

    plaintext = decrypt_mbak(sys.argv[1])

    # Save raw decrypted JSON alongside for inspection
    out_path = sys.argv[1] + ".decrypted.json"
    with open(out_path, "w", encoding="utf-8") as f:
        f.write(plaintext)
    print(f"Decrypted {len(plaintext)} characters -> {out_path}")

    # Try to pretty-print a preview
    try:
        data = json.loads(plaintext)
        print("Top-level keys:", list(data.keys()) if isinstance(data, dict) else type(data))
    except Exception as e:
        print("Note: output isn't plain JSON at the top level:", e)
        print("First 500 chars:\n", plaintext[:500])
