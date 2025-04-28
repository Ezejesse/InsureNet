# InsureNet: Decentralized Insurance Protocol

A peer-to-peer insurance smart contract that enables users to create insurance pools, contribute funds, purchase coverage, file claims, and receive payouts based on predefined conditions.

## Overview

This protocol implements a decentralized approach to insurance, allowing users to:
- Create insurance pools for specific coverage types
- Stake funds in pools as insurance providers
- Purchase insurance coverage with customizable amounts and durations
- File claims with supporting evidence
- Vote on the validity of claims
- Process claims automatically based on voting and risk assessment

The smart contract handles all aspects of the insurance lifecycle with transparency and security provided by blockchain technology.

## Features

- **Multiple Insurance Pools**: Support for various coverage types with customizable parameters
- **Stake-based Participation**: Users can stake funds to become insurance providers
- **Customizable Policies**: Flexible coverage amounts and policy durations
- **Democratic Claim Resolution**: Community voting on claims validity
- **Automated Risk Assessment**: Fraud detection through multiple risk factors
- **Smart Claim Processing**: Claims can be auto-approved based on risk scores and voting

## Contract Functions

### Pool Management

- `create-insurance-pool`: Create a new insurance pool with specific parameters
- `stake-in-pool`: Contribute funds to an existing insurance pool
- `get-pool-info`: Retrieve details about a specific insurance pool

### Policy Management

- `purchase-coverage`: Buy insurance coverage from a specific pool
- `get-user-policy`: View details of a user's policy
- `check-active-policy`: Check if a user has an active policy

### Claims Processing

- `file-claim`: Submit an insurance claim with evidence
- `vote-on-claim`: Vote on the validity of a pending claim
- `get-claim-info`: View details about a specific claim
- `process-claim-if-ready`: Process a claim if it has received enough votes
- `process-claim-with-risk-assessment`: Process a claim using automated risk assessment

## Technical Details

### Data Structures

The contract uses several data maps to store information:

1. **Insurance Pools**:
   - Pool name and coverage type
   - Total staked amount
   - Premium rate and minimum stake requirements
   - Admin information and active status

2. **User Policies**:
   - Premium paid and coverage amount
   - Policy start and end blocks
   - Active status

3. **Insurance Claims**:
   - Claim details and evidence
   - Voting status (yes/no votes)
   - Claim status (pending, approved, rejected)
   - Expiration parameters

4. **Claim Votes**:
   - Tracks which users have voted on which claims

### Risk Assessment

The contract implements sophisticated risk assessment for claims:

- Policy age evaluation
- Claim-to-coverage ratio analysis
- Evidence verification
- Voting confidence factor
- Automated approval/rejection based on risk threshold

## Usage Examples

### Creating an Insurance Pool

```clarity
(contract-call? .decentralized-insurance create-insurance-pool "Health Insurance" "medical" u500 u10000)
```
This creates a health insurance pool with a 5% premium rate and minimum stake of 10,000 STX.

### Staking in a Pool

```clarity
(contract-call? .decentralized-insurance stake-in-pool u1 u20000)
```
This stakes 20,000 STX in pool #1.

### Purchasing Coverage

```clarity
(contract-call? .decentralized-insurance purchase-coverage u1 u100000 u14400)
```
This purchases coverage for 100,000 STX from pool #1 for approximately 100 days (14,400 blocks).

### Filing a Claim

```clarity
(contract-call? .decentralized-insurance file-claim u1 u50000 "Hospital expenses after accident" 0x8a35acfbc15ff81a39ae7d344fd709f28e8600b4aa8c65c6b64bfe7fe36bd19b)
```
This files a claim for 50,000 STX in pool #1 with a description and evidence hash.

### Voting on a Claim

```clarity
(contract-call? .decentralized-insurance vote-on-claim u1 true)
```
This casts a "yes" vote for claim #1.

## Development and Deployment

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) for local development and testing
- [Stacks Wallet](https://www.hiro.so/wallet) for deployment and interaction
- Basic knowledge of Clarity programming language

### Deployment Steps

1. Clone this repository
2. Set up your local development environment with Clarinet
3. Test the contract locally
4. Deploy to the Stacks testnet for further testing
5. Deploy to the Stacks mainnet

### Testing

Run tests using Clarinet:

```bash
clarinet test
```

## Security Considerations

- Funds are held in the contract and only disbursed via approved claims
- Voting mechanisms protect against fraudulent claims
- Risk assessment algorithms provide additional security layers
- Time locks and expiration dates prevent claim exploitation

## Roadmap

- [ ] UI development for easier interaction
- [ ] Additional coverage types and specialized pools
- [ ] Integration with external data oracles for automated claim verification
- [ ] DAO governance for parameter adjustments
- [ ] Cross-chain compatibility

## Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

Please ensure your code adheres to our coding standards and includes appropriate tests.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

```
MIT License

Copyright (c) 2025 Decentralized Insurance Protocol

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

## Acknowledgments

- The Stacks ecosystem and community
- Clarity language developers
- All contributors and testers

## Contact

For questions, suggestions, or collaborations, please open an issue on this repository.
