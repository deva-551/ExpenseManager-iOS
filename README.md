# MyExpenseTracker

A feature-rich personal expense tracking app for iOS, built with SwiftUI and Core Data. It includes AI-powered smart expense entry, receipt scanning, detailed analytics, multi-account management, and monthly budgeting.

## Screenshots

<!-- Add screenshots here -->

## Features

### Transaction Management
- Add income and expense transactions with category, account, notes, and date
- View transactions grouped by date within a selected month
- Swipe-to-delete transactions
- Edit existing transactions from the detail screen
- Filter transactions by category and account

### AI-Powered Smart Entry
- **Text-to-Expense** — Type natural language like *"Spent 500 on groceries"* or *"Received 25000 salary"* and let on-device AI parse it into a transaction
- **Receipt Scanning** — Capture or pick a receipt image, extract text via OCR (Vision framework), and automatically parse line items into transactions

### Analytics
- Income vs Expense pie chart breakdown
- Expense by category pie chart with percentages
- Category-wise spending details
- Daily spending trend / bar chart
- Monthly summary cards (total income, total expense, net savings)

### Accounts
- Create and manage multiple accounts (Bank, Cash)
- Set initial balance per account
- Track current balance (initial balance + income - expenses)
- View monthly statistics per account
- Delete accounts with transaction reassignment

### Budgeting
- Create monthly budgets per category and account
- Visual progress bars with color coding:
  - Green: under 80% spent
  - Orange: 80–100% spent
  - Red: over budget
- Edit and delete budgets

### Settings
- **Currency** — Choose from 12 supported currencies (USD, EUR, GBP, INR, JPY, AUD, CAD, CHF, CNY, SGD, AED, SAR)
- **Categories** — Create, edit, and delete custom income/expense categories with icons and colors
- **Accounts** — Manage accounts with safe deletion and transaction reassignment
- **Data Actions** — Populate sample data or clear all data

## Default Categories

| Expense | Income |
|---------|--------|
| Food | Salary |
| Transport | Freelance |
| Shopping | Investments |
| Bills | Rental Income |
| Entertainment | Gifts |
| Healthcare | Other Income |
| Education | |
| Travel | |
| Other | |

## Tech Stack

| Area | Technology |
|------|------------|
| UI Framework | SwiftUI |
| Architecture | MVVM |
| Data Persistence | Core Data |
| Charts | Swift Charts |
| AI / NLP | FoundationModels (on-device) |
| OCR | Vision framework |
| Image Picker | PhotosUI (PhotosPicker) |
| Reactive Layer | Combine |
| Min Deployment Target | iOS 26.1 |
| Language | Swift 5 |

## Project Structure

```
MyExpenceTracker/
├── MyExpenceTrackerApp.swift          # App entry point
├── Models/
│   ├── CoreDataStack.swift            # Core Data persistent container
│   ├── Transaction+Extensions.swift   # Transaction entity helpers
│   ├── Category+Extensions.swift      # Category entity helpers
│   ├── Account+Extensions.swift       # Account entity helpers
│   └── Budget+Extensions.swift        # Budget entity helpers
├── ViewModels/
│   ├── TransactionViewModel.swift     # Transaction CRUD, filtering, grouping
│   ├── CategoryViewModel.swift        # Category CRUD, defaults
│   ├── AccountViewModel.swift         # Account CRUD, balance calculation
│   └── BudgetViewModel.swift          # Budget CRUD, progress tracking
├── Views/
│   ├── MainTabView.swift              # 4-tab navigation
│   ├── Home/
│   │   ├── HomeScreen.swift           # Main transaction list with FAB
│   │   ├── FilterView.swift           # Category & account filter
│   │   ├── TransactionDetailScreen.swift
│   │   └── ExpenseListView.swift
│   ├── Analytics/
│   │   └── AnalyticsScreen.swift      # Charts and spending insights
│   ├── Accounts/
│   │   └── AccountsScreen.swift       # Account & budget management
│   ├── Settings/
│   │   └── SettingsScreen.swift       # App configuration
│   ├── AddTransaction/
│   │   ├── AddTransactionScreen.swift # Manual transaction entry
│   │   ├── SmartExpenseView.swift     # AI text & receipt parsing
│   │   ├── CategoryPickerScreen.swift
│   │   └── AccountPickerScreen.swift
│   └── Components/
│       ├── PieChartView.swift         # Reusable donut chart
│       ├── TransactionRowView.swift   # Transaction list row
│       └── MonthPickerView.swift      # Month/year navigator
├── Utilities/
│   ├── CurrencyFormatter.swift        # Currency formatting & persistence
│   ├── AIExpenseService.swift         # Text recognition & AI parsing
│   └── DefaultCategories.swift        # First-launch category seeding
└── ExpenseTracker.xcdatamodeld/       # Core Data model
```

## Core Data Model

**4 Entities:**

- **Transaction** — amount, date, type (income/expense), notes; relationships to Category and Account
- **Category** — name, icon, color, type (income/expense), isDefault flag
- **Account** — name, type (Bank/Cash), initial balance
- **Budget** — amount limit, month, year; relationships to Category and Account

## Requirements

- Xcode 26+
- iOS 26.1+
- Swift 5

## Getting Started

1. Clone the repository:
   ```bash
   git clone <repository-url>
   ```
2. Open `MyExpenceTracker.xcodeproj` in Xcode.
3. Select a simulator or connected device running iOS 26.1+.
4. Build and run (Cmd + R).

## Version

**1.0.0**

## License

This project is for personal/educational use.
