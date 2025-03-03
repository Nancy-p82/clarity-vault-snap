# VaultSnap
A secure image storage platform built on Stacks blockchain using Clarity smart contracts.

## Features
- Store image metadata on-chain (hash, size, timestamp)
- Access control for image storage and retrieval
- Ownership verification system
- Image data validation
- User storage limits and statistics
- Event tracking for all operations
- Secure deletion capabilities

## Storage Limits
- Maximum 100 images per user
- Maximum image size: 10MB
- Total storage tracking per user

## Setup and Installation
1. Clone the repository
2. Install Clarinet
3. Run `clarinet check` to verify the contract
4. Run `clarinet test` to run test suite

## Usage Examples
```clarity
;; Store new image metadata
(contract-call? .vault-snap store-image "QmHash123" u1000)

;; Verify image ownership
(contract-call? .vault-snap verify-ownership "QmHash123" tx-sender)

;; Get image metadata
(contract-call? .vault-snap get-image-data "QmHash123")

;; Get user statistics
(contract-call? .vault-snap get-user-stats tx-sender)
```

## Dependencies
- Clarity language
- Clarinet for testing and deployment
