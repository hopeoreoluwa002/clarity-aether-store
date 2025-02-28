# AetherStore
A decentralized e-commerce marketplace built on the Stacks blockchain using Clarity.

## Features
- List products for sale
- Purchase products using STX
- Rate and review sellers
- Manage store inventory
- Dispute resolution system

## Setup and Installation
1. Clone the repository
2. Install Clarinet
3. Run `clarinet check` to verify contracts
4. Run `clarinet test` to execute test suite 

## Usage Examples
```clarity
;; List a product
(contract-call? .aether-store list-product "iPhone 13" u1000000 u5)

;; Purchase a product
(contract-call? .aether-store purchase-product u1)

;; Rate a seller
(contract-call? .aether-store rate-seller 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM u5)
```

## Dependencies
- Clarity language
- Clarinet for testing
