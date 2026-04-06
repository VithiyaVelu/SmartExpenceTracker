# Web Dashboard - Feature Documentation

## Overview

The **Web Dashboard** is a responsive, feature-rich analytics and management interface optimized for desktop and tablet viewing. It provides a comprehensive overview of your finances with advanced charts, budget tracking, and transaction management.

## Features

### 1. **Key Performance Indicators (KPIs)**
- **Total Income**: Aggregate of all income transactions
- **Total Expense**: Aggregate of all expense transactions
- **Net Balance**: Your overall financial balance (Income - Expense)
- **Save Rate**: Percentage of income you're saving

All KPIs display in your base currency with color-coded indicators for quick visual analysis.

### 2. **Income vs Expense Chart**
A responsive bar chart showing:
- Total income for the period (green bars)
- Total expenses for the period (red bars)
- Automatic scaling for large amounts
- Touch-friendly on mobile, interactive on desktop

### 3. **Spending by Category**
A comprehensive pie chart visualization showing:
- Percentage breakdown of spending by category
- Category legend with actual amounts
- Color-coded categories for easy identification
- Support for unlimited categories

### 4. **Budget Status Panel**
Displays all active budgets with:
- Progress bars for each category
- Percentage indicators (0-100%+)
- Green highlighting for under budget
- Red highlighting for over budget
- Exact amount spent vs. budgeted amount

### 5. **Recent Transactions Table**
Shows your latest transactions with:
- Date of transaction
- Transaction description/title
- Category
- Amount (with +/- indicator)
- Responsive design (table on desktop, card list on mobile)

## How to Access

### On Mobile/Tablet
1. Open the Expense Tracker app
2. Tap the **Dashboard** icon (📊) in the top-right AppBar
3. The dashboard will load with responsive mobile layout

### On Web (Progressive Web App)
1. Build the web version: `flutter build web`
2. Serve the output: `python -m http.server` (from `build/web` directory)
3. Open `http://localhost:8000` in your browser
4. Bookmark as PWA for offline access

### Running in Development
```bash
# Web development mode
flutter run -d chrome

# Navigate to the web dashboard by tapping the dashboard icon
```

## Responsive Design

The dashboard adapts to different screen sizes:

**Desktop (800+ px width)**
- 2-column chart layout (Income vs Expense + Category Breakdown)
- Full-width transaction table with all columns
- Optimized spacing and padding
- All 4 KPI cards in a horizontal scrollable row

**Mobile/Tablet (<800 px width)**
- Single-column layout with stacked charts
- Transaction list with card-style items
- KPI cards in a horizontal scrollable row
- Touch-optimized button sizes

## Data Aggregation

### Currency Handling
- All amounts are automatically converted to your **base currency**
- Original currencies are tracked but displayed in base currency
- Exchange rates are fetched from the live API
- Conversion happens transparently in all calculations

### Time Periods
- **Income/Expense Totals**: All-time aggregations
- **Category Spending**: Current month tracking
- **Budgets**: Current month comparison against spending

### Budget Calculations
- Budget percentage = (Spent / Budget Amount) × 100
- Over budget indicated by red progress bar
- Text turns red when spending exceeds budget
- Exact amount comparison shown below each bar

## Performance Optimizations

1. **Data Loading**: Efficient batch loading of all expenses and budgets
2. **Caching**: Categories and amounts cached in state
3. **Lazy Rendering**: Charts render only when dashboard is visible
4. **Responsive Images**: Icons loaded efficiently on all platforms
5. **Chart Performance**: fl_chart optimized for smooth interactions

## Features & Integrations

✅ **Multi-Currency Support**
- Automatic conversion to base currency
- Live exchange rates via API
- All calculations in base currency

✅ **Dynamic Theming**
- Respects your selected theme from Theme Settings
- 8 available themes (Light, Dark, Teal, Purple, etc.)
- Mood-based dynamic theming support
- Dark mode for low-light environments

✅ **Budget Tracking**
- Visual progress indicators
- Real-time percentage calculations
- Over-budget alerts in color

✅ **Spending Analytics**
- Category breakdown by pie chart
- Income vs expense comparison
- Save rate calculation
- Net balance overview

## Example Dashboard Sections

### KPI Row (Top)
```
┌─────────────┬─────────────┬─────────────┬─────────────┐
│ Income      │ Expense     │ Balance     │ Save Rate   │
│ $5,000      │ $2,500      │ $2,500      │ 50%         │
└─────────────┴─────────────┴─────────────┴─────────────┘
```

### Charts Section (Middle)
```
┌──────────────────────────┬──────────────────────────┐
│  Income vs Expense       │  Spending by Category    │
│  (Bar Chart)             │  (Pie Chart)             │
│  Income: $5,000          │  Food: 30%               │
│  Expense: $2,500         │  Transport: 25%          │
├──────────────────────────┴──────────────────────────┤
│  Budget Status                                      │
│  ✓ Food: $500 / $600 (83%)                          │
│  ✗ Transport: $450 / $400 (112% - OVER!)            │
└─────────────────────────────────────────────────────┘
```

### Recent Transactions (Bottom)
```
Date         │ Description      │ Category   │ Amount
─────────────┼──────────────────┼────────────┼────────
2024-04-06   │ Grocery Store    │ Food       │ -$85
2024-04-05   │ Salary Deposit   │ Income     │ +$5,000
2024-04-05   │ Gas Station      │ Transport  │ -$45
```

## Keyboard Shortcuts (Web Only)

- **Esc**: Goes back to home screen
- **R**: Refresh dashboard data
- **D**: Open dashboard from any screen
- **T**: Open theme settings

## Troubleshooting

### Dashboard Shows "No Data"
- Ensure expenses are added to the app
- Check that current month has transactions
- Verify budget creation for current month

### Charts Not Displaying
- Refresh the page (web) or app (mobile)
- Ensure `fl_chart: ^0.66.1` is installed
- Check for JavaScript console errors (web)

### Currency Conversion Issues
- Verify base currency is set in Currency Settings
- Check internet connection for live exchange rates
- Rates updated within last hour are cached

### Export/Report Issues
- Use "Recent Transactions" section as reference
- For PDF: Use browser's "Print to PDF" feature
- For CSV: Data can be exported from future export feature

## Future Enhancements

Planned features for the Web Dashboard:
- 📊 Advanced date range filtering (Week, Month, Year, Custom)
- 💾 Export to CSV, PDF, Excel formats
- 📈 Trend lines and historical comparisons
- 🔄 Real-time sync across devices
- 📱 Mobile app notifications from dashboard
- 🎯 Budget forecasting and goal tracking
- 🌍 Multi-language support
- ⚙️ Customizable widget arrangement
- 📋 Report scheduling and email delivery
- 🔐 Data encryption and cloud backup

## Best Practices

1. **Regular Review**: Check dashboard weekly to monitor spending trends
2. **Budget Updates**: Update budgets based on category insights
3. **Currency Verification**: Verify base currency matches your primary account
4. **Theme Selection**: Choose a theme that reduces eye strain
5. **Mobile Sync**: Use web dashboard on computer for detailed analysis

## Related Features

- 🏠 [Home Screen](../screens/home_screen.dart) - Quick overview and transaction management
- 📊 [Analytics Screen](../screens/analytics_screen.dart) - Detailed financial analysis
- 💰 [Budget Screen](../screens/budget_screen.dart) - Budget creation and management
- 💱 [Currency Settings](../screens/currency_settings_screen.dart) - Multi-currency configuration
- 🎨 [Theme Settings](../screens/theme_settings_screen.dart) - Appearance customization

## Architecture Notes

**Web Dashboard Architecture**:
```
WebDashboard (StatefulWidget)
├── loadDashboardData() - Fetches from DBHelper
├── _buildKPIRow() - KPI cards
├── _buildExpenseChart() - Bar chart (Income vs Expense)
├── _buildCategoryChart() - Pie chart (Category breakdown)
├── _buildBudgetStatus() - Budget progress bars
└── _buildRecentTransactions() - Transaction list/table
```

**Data Flow**:
1. `initState()` calls `loadDashboardData()`
2. DBHelper returns all expenses and budgets for the month
3. Data aggregated into categories, income/expense totals
4. CurrencyService converts all amounts to base currency
5. setState() rebuilds UI with calculated data
6. Charts and lists render with aggregated totals

**Responsive Logic**:
- `MediaQuery.of(context).size.width < 800` determines layout
- Single-column on mobile, dual-column on desktop
- Table on desktop, card list on mobile
- All text scales appropriately

---

**Last Updated**: April 6, 2026  
**Version**: 1.0.0  
**Status**: ✅ Production Ready

