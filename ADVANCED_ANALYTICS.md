# Advanced Analytics - Feature Documentation

## Overview

The **Advanced Analytics** screen provides comprehensive financial insights, spending trends, and detailed analytics to help you understand your spending patterns and make informed financial decisions.

## Key Features

### 1. **Key Metrics Dashboard**
Displays 4 important metrics in grid cards:
- **Total Spending**: Aggregate of all expenses across all time periods
- **Avg Monthly**: Average monthly spending amount
- **Highest Month**: The month with the maximum spending
- **Categories**: Total number of spending categories

Each card shows:
- Label describing the metric
- Color-coded value (red for spending, orange for average, etc.)
- Visual emphasis with colored borders

### 2. **Monthly Spending Trend Line Chart**
- **Visualization**: Interactive line chart showing spending over time
- **X-Axis**: Month labels (e.g., "01", "02", "03" for January, Feburary, March)
- **Y-Axis**: Amount spent in base currency
- **Features**:
  - Smooth curve connecting monthly data points
  - Area shading below the line for visual impact
  - Interactive hovering (on web)
  - Automatic scaling based on data

### 3. **Category Breakdown Analysis**
Shows top 6 spending categories with:
- Category name
- Total amount spent in that category
- Percentage of total spending
- Progress bar showing relative spending
- Color-coded bars for visual differentiation

Example:
```
Food
$1,500 (35%)
████████░░░░░░░░░

Transport  
$900 (21%)
█████░░░░░░░░░░░░░
```

### 4. **Analytics Insights**
Smart insights that automatically generate based on your spending data:

**Types of Insights:**

a) **High Spending Alert** (Red)
- Generated when a month's spending is >150% of average
- Shows percentage difference from average
- Example: "March had 67% higher spending than average"

b) **Top Spending Category** (Blue)
- Shows which category dominates your spending
- Displays percentage of total spending
- Example: "Food accounts for 35% of total spending"

c) **Spending Increase** (Orange)
- Generated when current month spending increases >10% vs previous month
- Shows exact percentage increase
- Helpful for budget alerts

d) **Spending Reduction** (Green)
- Generated when spending decreases >10% vs previous month
- Congratulates you on savings
- Motivational insight

### 5. **Spending by Day of Week**
Bar chart showing spending patterns across days:
- **X-Axis**: Days of the week (Mon, Tue, Wed, Thu, Fri, Sat, Sun)
- **Y-Axis**: Total amount spent on each day
- **Color**: Different shades of blue for each day
- **Insight**: Identifies your highest spending days

Example:
```
Friday has highest spending
Saturday has moderate spending
Sunday has lower spending
```

## How to Access

### From Home Screen
1. Tap the **Trending Up icon** (📈) in the AppBar
2. The Advanced Analytics screen will load
3. Scroll to view all charts and insights

### Navigation
- Use the top **Period Selector** to view Month/Quarter/Year data
- Scroll down to see all analytics sections
- Back button returns to Home Screen

## Period Selector

Located at the top of the screen:
- **Month** (default): Shows current month analytics
- **Quarter**: Shows last 3 months trends
- **Year**: Shows last 12 months trends

Currently selected button is highlighted in primary color.

## Data Aggregation

### Currency Conversion
- All amounts automatically converted to your **base currency**
- Exchange rates applied transparently
- Consistent calculations across all charts

### Time Periods
- **Spending Data**: All-time aggregation (full history)
- **Monthly Trends**: Groups by YYYY-MM format
- **Category Spending**: Cumulative across all time
- **Day of Week**: Aggregates across all weeks in dataset

### Calculations
- **Average Monthly**: Total Spending / Number of Months
- **Percentages**: (Category Amount / Total Spending) × 100
- **Trends**: (Current - Previous) / Previous × 100

## Visual Design

### Color Scheme
- **Spending Charts**: Red (high), Orange (medium), Blue (patterns)
- **Metric Cards**: Color-coded by type (red, orange, purple)
- **Insights**: 
  - Red = High (concerning)
  - Orange = Warning (notable change)
  - Green = Success (positive change)
  - Blue = Info (neutral information)

### Responsive Layout
- Desktop: All charts displayed in efficient grid
- Mobile: Stacked layout with scrollable content
- Tablet: Optimized 2-column layout
- Charts auto-scale based on screen size

## Example Analytics Session

1. **User opens Advanced Analytics**
   - Sees total spending: $15,000
   - Average monthly: $1,250
   - Highest month: $2,100
   - 8 spending categories

2. **Views Monthly Trend Chart**
   - Sees a spike in March (high spending alert)
   - Recent months show decline (good spending control)
   - Overall trend is slightly downward (positive)

3. **Reviews Category Breakdown**
   - Food: 35% ($5,250)
   - Rent: 25% ($3,750)
   - Transport: 20% ($3,000)
   - Entertainment: 12% ($1,800)
   - Utilities: 5% ($750)
   - Other: 3% ($450)

4. **Reads Insights**
   - "High Spending Alert: March had 68% higher spending than average"
   - "Top Spending Category: Food accounts for 35% of total spending"
   - "Spending Increase: Your spending increased by 12% in April"
   - Decides to budget food spending more carefully

5. **Checks Day of Week Pattern**
   - Friday: $250 (highest)
   - Saturday: $220
   - Sunday: $180
   - Realizes weekend spending is highest
   - Plans to reduce weekend entertainment

## Performance Optimizations

1. **Data Loading**: Efficient batch loading from database
2. **Calculations**: Cached metric calculations
3. **Charts**: Lazy rendering of charts
4. **Memory**: Disposable expensive objects on unmount

## Future Enhancements

Planned features:
- 📊 Custom date range selection (start/end dates)
- 🎯 Budget vs actual spending comparison
- 📈 Year-over-year comparison (2024 vs 2025)
- 🔮 Spending forecasts (predicted next month spending)
- 💾 Export analytics as PDF/CSV report
- 📊 Category-specific trend analysis
- 🏆 Spending goals and progress tracking
- 📱 Push notifications for spending alerts
- 🌐 Multi-year historical comparisons
- 🎨 Custom chart customization options

## Troubleshooting

### No Data Showing
- Solution: Add some expenses first via "Add Expense"
- Ensure expenses have valid dates
- Check database has loaded correctly

### Charts Not Rendering
- Refresh the screen (back and re-open)
- Verify `fl_chart` dependency is installed
- Check for console errors (web dev tools)

### Incorrect Amounts
- Verify base currency is set in Currency Settings
- Check exchange rates are up-to-date
- Confirm expense amounts are correct

### Insights Not Generating
- Insights only show if calculations are valid
- Need at least 2 months of data for trend analysis
- May need at least 1 category with significant spending

## Analytics Best Practices

1. **Weekly Review**: Check analytics once per week
2. **Compare Trends**: Look at month-over-month changes
3. **Identify Patterns**: Use day-of-week chart to spot habits
4. **Act on Insights**: Implement budget adjustments based on data
5. **Monitor Categories**: Focus on your top 3 spending categories
6. **Set Goals**: Use highest month as baseline to reduce
7. **Track Progress**: Compare current vs previous periods

## Related Screens

- 🏠 [Home Screen](../screens/home_screen.dart) - Quick overview
- 📊 [Web Dashboard](../screens/web_dashboard.dart) - Desktop analytics
- 📈 [Analytics Screen](../screens/analytics_screen.dart) - Basic analytics
- 💰 [Budget Screen](../screens/budget_screen.dart) - Budget management
- 💱 [Currency Settings](../screens/currency_settings_screen.dart) - Currency config

## Architecture Notes

**Advanced Analytics Architecture**:
```
AdvancedAnalyticsScreen (StatefulWidget)
├── loadAnalyticsData() - Fetches from DBHelper
├── _calculateMetrics() - Computes KPI statistics
├── _generateInsights() - Creates smart insights
├── _buildPeriodSelector() - Month/Quarter/Year picker
├── _buildKeyMetrics() - 4-card metric grid
├── _buildMonthlyChart() - Line chart visualization
├── _buildCategoryBreakdown() - Category bars
├── _buildInsights() - Insight cards
└── _buildSpendingPatterns() - Day-of-week bar chart
```

**Data Flow**:
1. `initState()` calls `loadAnalyticsData()`
2. DBHelper returns all expenses
3. `_calculateMetrics()` aggregates by month/category
4. CurrencyService converts amounts to base currency
5. `_generateInsights()` analyzes data patterns
6. setState() rebuilds UI with all calculated data
7. Charts render with aggregated totals

**Metric Calculations**:
- Total Year: Sum of all expense amounts
- Average Monthly: Total / Number of unique months
- Highest Month: Max spending in any single month
- Categories: Count of unique category names

---

**Last Updated**: April 6, 2026  
**Version**: 1.0.0  
**Status**: ✅ Production Ready

