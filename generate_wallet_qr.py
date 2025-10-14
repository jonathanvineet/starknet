#!/usr/bin/env python3
"""
Generate a QR code with your Starknet wallet credentials.
This will create a QR that includes your address, private key, and public key.
"""

import json
import qrcode
import sys

def generate_wallet_qr(address, private_key, public_key, output_file="wallet_qr.png"):
    """
    Generate a QR code containing wallet credentials in JSON format.
    
    Args:
        address: Your Starknet wallet address (0x...)
        private_key: Your private key (0x...)
        public_key: Your public key (0x...)
        output_file: Output filename for the QR code image
    """
    
    # Create JSON data
    wallet_data = {
        "address": address,
        "private_key": private_key,
        "public_key": public_key
    }
    
    # Convert to JSON string
    json_data = json.dumps(wallet_data, indent=2)
    
    print("=== Wallet QR Code Generator ===")
    print("\nJSON Data:")
    print(json_data)
    
    # Generate QR code
    qr = qrcode.QRCode(
        version=None,  # Auto-size
        error_correction=qrcode.constants.ERROR_CORRECT_L,
        box_size=10,
        border=4,
    )
    
    qr.add_data(json_data)
    qr.make(fit=True)
    
    # Create image
    img = qr.make_image(fill_color="black", back_color="white")
    img.save(output_file)
    
    print(f"\n✅ QR code saved to: {output_file}")
    print("\nScan this QR code with your app to connect!")
    
    return output_file


if __name__ == "__main__":
    # YOUR WALLET CREDENTIALS GO HERE
    # Replace these with your actual wallet details from Ready wallet
    
    MY_ADDRESS = "0xYOUR_WALLET_ADDRESS_HERE"
    MY_PRIVATE_KEY = "0xYOUR_PRIVATE_KEY_HERE"
    MY_PUBLIC_KEY = "0xYOUR_PUBLIC_KEY_HERE"
    
    if "YOUR_" in MY_ADDRESS:
        print("❌ Error: Please edit this script and add your actual wallet credentials!")
        print("\nTo get your wallet info from Ready wallet:")
        print("1. Open Ready wallet")
        print("2. Go to Settings → Show Private Key")
        print("3. Copy your address, private key, and public key")
        print("4. Paste them into this script")
        sys.exit(1)
    
    try:
        generate_wallet_qr(
            address=MY_ADDRESS,
            private_key=MY_PRIVATE_KEY,
            public_key=MY_PUBLIC_KEY
        )
    except Exception as e:
        print(f"\n❌ Error generating QR code: {e}")
        print("\nMake sure you have qrcode installed:")
        print("  pip3 install qrcode[pil]")
        sys.exit(1)
