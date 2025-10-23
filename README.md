# 🔐 Universal Decentralized KYC/Verification Layer

A one-time verified identity system reusable across education, fintech, logistics, and other dApps built on the Stacks blockchain.

## ✨ Features

- 🎯 **One-Time Verification**: Get verified once, use everywhere
- 🔒 **Encrypted ID Registry**: Store verification data with privacy-preserving hashes
- 🛡️ **Access Control Logic**: Granular permission system for dApps
- ⏰ **Expirable Verifications**: Time-bound verification with renewal capability
- 👥 **Verifier Registry**: Decentralized network of trusted verifiers
- 🚀 **dApp Integration**: Easy integration for any decentralized application
- 📊 **Reputation System**: Track verifier performance and reliability

## 🏗️ Contract Architecture

### Core Components

1. **Verifiers**: Trusted entities that can verify user identities
2. **User Verifications**: Encrypted verification records with expiry
3. **dApp Registry**: Registered applications that can request access
4. **Access Grants**: User-controlled permissions for dApps

## 📋 Data Structures

### Verifier
- `active`: Active status
- `registered-at`: Registration block height
- `verification-count`: Total verifications performed
- `reputation-score`: Verifier reputation

### User Verification
- `verified`: Verification status
- `verifier`: Principal of verifying entity
- `verified-at`: Verification block height
- `encrypted-data-hash`: 32-byte hash of encrypted identity data
- `verification-level`: Level of verification (1-5)
- `expiry-block`: Block height when verification expires

### dApp Access Grant
- `granted`: Access status
- `granted-at`: Grant block height
- `access-level`: Level of access permitted
- `expiry-block`: Block height when access expires

## 🚀 Usage

### For Verifiers

#### Register as a Verifier
```clarity
(contract-call? .Universal-Decentralized-KYCVerification-Layer register-verifier)
```

#### Verify a User
```clarity
(contract-call? .Universal-Decentralized-KYCVerification-Layer 
    verify-user 
    'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM
    0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef
    u3)
```

#### Deactivate Your Verifier Status
```clarity
(contract-call? .Universal-Decentralized-KYCVerification-Layer deactivate-verifier)
```

### For Users

#### Request Verification
```clarity
(contract-call? .Universal-Decentralized-KYCVerification-Layer 
    request-verification 
    'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG
    0xabcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890)
```

#### Grant dApp Access
```clarity
(contract-call? .Universal-Decentralized-KYCVerification-Layer 
    grant-dapp-access 
    'ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC
    u2
    u52560)
```

#### Revoke dApp Access
```clarity
(contract-call? .Universal-Decentralized-KYCVerification-Layer 
    revoke-dapp-access 
    'ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC)
```

#### Renew Verification
```clarity
(contract-call? .Universal-Decentralized-KYCVerification-Layer 
    renew-verification 
    0x9876543210fedcba9876543210fedcba9876543210fedcba9876543210fedcba)
```

### For dApps

#### Register Your dApp
```clarity
(contract-call? .Universal-Decentralized-KYCVerification-Layer 
    register-dapp 
    "MyFinTechApp"
    "fintech")
```

#### Check User Verification Status
```clarity
(contract-call? .Universal-Decentralized-KYCVerification-Layer 
    is-verified 
    'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
```

#### Check Access Permission
```clarity
(contract-call? .Universal-Decentralized-KYCVerification-Layer 
    has-dapp-access 
    'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM
    'ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC)
```

## 📖 Read-Only Functions

### Get Verifier Info
```clarity
(contract-call? .Universal-Decentralized-KYCVerification-Layer 
    get-verifier 
    'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG)
```

### Get User Verification
```clarity
(contract-call? .Universal-Decentralized-KYCVerification-Layer 
    get-user-verification 
    'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
```

### Get dApp Access Status
```clarity
(contract-call? .Universal-Decentralized-KYCVerification-Layer 
    get-dapp-access 
    'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM
    'ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC)
```

### Get Verification Fee
```clarity
(contract-call? .Universal-Decentralized-KYCVerification-Layer get-verification-fee)
```

### Get Verification Validity Period
```clarity
(contract-call? .Universal-Decentralized-KYCVerification-Layer get-verification-validity)
```

## 🔢 Error Codes

| Code | Description |
|------|-------------|
| `u100` | ERR-NOT-AUTHORIZED |
| `u101` | ERR-ALREADY-VERIFIED |
| `u102` | ERR-NOT-VERIFIED |
| `u103` | ERR-INVALID-VERIFIER |
| `u104` | ERR-ALREADY-REGISTERED |
| `u105` | ERR-VERIFIER-NOT-FOUND |
| `u106` | ERR-DAPP-ACCESS-DENIED |
| `u107` | ERR-INVALID-HASH |
| `u108` | ERR-EXPIRED-VERIFICATION |
| `u109` | ERR-ALREADY-GRANTED |
| `u110` | ERR-NOT-GRANTED |

## 🎯 Use Cases

### 🎓 Education
- Verify student credentials once
- Grant access to multiple educational platforms
- Transcript verification across institutions

### 💰 FinTech
- KYC compliance for DeFi platforms
- Age verification for restricted services
- Credit score verification

### 📦 Logistics
- Verify supplier credentials
- Track certified handlers
- Compliance verification for shipping

## 🔧 Development

### Requirements
- Clarinet
- Stacks blockchain

### Testing
```bash
clarinet check
clarinet test
```

### Deployment
```bash
clarinet deploy
```

## 🛡️ Security Features

- ✅ Encrypted data storage using hash references
- ✅ Time-bound verifications with automatic expiry
- ✅ User-controlled access permissions
- ✅ Verifier reputation tracking
- ✅ Multi-level verification support
- ✅ Revocation capabilities for all parties

## 📝 License

MIT License

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📧 Contact

For questions and support, please open an issue in the repository.

---

**Built with ❤️ on Stacks Blockchain**
