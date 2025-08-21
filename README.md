# 🏠 Rent-to-Own Smart Contracts

A Clarity smart contract that enables rent-to-own agreements on the Stacks blockchain. Tenants make regular payments until asset ownership automatically transfers when all payments are complete.

## ✨ Features

- 📋 **Asset Registration**: Owners can list assets with custom payment terms
- 👥 **Tenant Enrollment**: Tenants can enroll in rent-to-own agreements
- 💰 **Automated Payments**: Regular payment processing with ownership tracking
- 🔄 **Automatic Transfer**: Ownership transfers automatically when payments complete
- 📊 **Payment Tracking**: Real-time progress monitoring and ownership percentage
- ⏰ **Payment Scheduling**: Block-based payment intervals with due date tracking

## 🚀 Getting Started

### Prerequisites
- Clarinet CLI installed
- Stacks wallet for testing

### Installation
```bash
git clone https://github.com/danmatu402/Rent-to-Own-Smart-Contracts
cd Rent-to-Own-Smart-Contracts
clarinet check
```

## 📖 Usage

### 1. Create an Asset 🏘️
```clarity
(contract-call? .Rent-to-Own-Smart-Contracts create-asset u1000000 u100000 u144)
```
- `total-value`: Total asset value in microSTX
- `payment-amount`: Payment amount per installment
- `payment-interval`: Blocks between payments (144 blocks ≈ 1 day)

### 2. Enroll as Tenant 🤝
```clarity
(contract-call? .Rent-to-Own-Smart-Contracts enroll-tenant u1)
```

### 3. Make Payments 💸
```clarity
(contract-call? .Rent-to-Own-Smart-Contracts make-payment u1)
```

### 4. Check Payment Status 📈
```clarity
(contract-call? .Rent-to-Own-Smart-Contracts get-payment-status u1)
```

### 5. View Asset Details 🔍
```clarity
(contract-call? .Rent-to-Own-Smart-Contracts get-asset u1)
```

## 🛠️ Contract Functions

| Function | Description | Access |
|----------|-------------|---------|
| `create-asset` | Register a new rent-to-own asset | Asset Owner |
| `enroll-tenant` | Enroll in a rent-to-own agreement | Any User |
| `make-payment` | Process a scheduled payment | Enrolled Tenant |
| `cancel-contract` | Cancel an active agreement | Asset Owner |
| `get-payment-status` | Check payment progress | Read-Only |
| `get-asset` | View asset details | Read-Only |
| `calculate-ownership-percentage` | Calculate ownership progress | Read-Only |

## 💡 Example Workflow

1. **Owner** creates asset: Car worth 1,000,000 μSTX, 100,000 μSTX payments every 144 blocks
2. **Tenant** enrolls in the agreement
3. **Tenant** makes 10 payments of 100,000 μSTX each
4. **Ownership** automatically transfers to tenant after final payment
5. **Asset** becomes fully owned by the former tenant

## 🔐 Security Features

- Payment validation and timing enforcement
- Ownership verification for administrative functions
- Automatic state transitions prevent manual errors
- STX transfer validation ensures secure payments

## 🧪 Testing

```bash
clarinet test
```

## 📄 License

MIT License - feel free to use and modify for your projects!

---

Built with ❤️ on Stacks blockchain
