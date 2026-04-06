import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/theme.dart';
import '../providers/theme_provider.dart';

class ThemeSettingsScreen extends StatefulWidget {
  const ThemeSettingsScreen({super.key});

  @override
  State<ThemeSettingsScreen> createState() => _ThemeSettingsScreenState();
}

class _ThemeSettingsScreenState extends State<ThemeSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Theme Settings'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dynamic Theme Section
                _buildDynamicThemeSection(themeProvider),

                const SizedBox(height: 24),

                // Theme Selection Section
                Text(
                  'Choose Theme',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Theme Grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: AppTheme.allThemes.length,
                  itemBuilder: (context, index) {
                    final theme = AppTheme.allThemes[index];
                    final isSelected = themeProvider.selectedThemeType == theme.type &&
                                     !themeProvider.useDynamicTheme;

                    return _buildThemeCard(theme, isSelected, themeProvider);
                  },
                ),

                const SizedBox(height: 24),

                // Current Mood Display (only show if dynamic theme is enabled)
                if (themeProvider.useDynamicTheme) ...[
                  Text(
                    'Current Spending Mood',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildMoodDisplay(themeProvider),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDynamicThemeSection(ThemeProvider themeProvider) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Dynamic Theme',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Automatically change theme based on your spending habits',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Enable Dynamic Theming'),
              subtitle: Text(
                themeProvider.useDynamicTheme
                    ? 'Theme changes based on budget status'
                    : 'Use selected theme',
              ),
              value: themeProvider.useDynamicTheme,
              onChanged: (value) {
                themeProvider.setDynamicTheme(value);
              },
              activeColor: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeCard(AppTheme theme, bool isSelected, ThemeProvider themeProvider) {
    return GestureDetector(
      onTap: () {
        themeProvider.setTheme(theme.type);
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? theme.primaryColor : Colors.grey.shade300,
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: Column(
            children: [
              // Color preview
              Expanded(
                flex: 3,
                child: Container(
                  color: theme.primaryColor,
                  child: Center(
                    child: Icon(
                      Icons.palette,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ),
              // Theme name
              Expanded(
                flex: 2,
                child: Container(
                  color: theme.surfaceColor,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Center(
                    child: Text(
                      theme.name,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: theme.type == ThemeType.dark || theme.type == ThemeType.midnight
                            ? Colors.white
                            : Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoodDisplay(ThemeProvider themeProvider) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              themeProvider.getMoodIcon(),
              color: themeProvider.getMoodColor(),
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    themeProvider.getMoodDescription(),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: themeProvider.getMoodColor(),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Theme automatically adjusts based on your spending',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}