import 'package:flutter/material.dart';

class Category {
  final String name;
  final IconData icon;
  final Color color;

  const Category({
    required this.name,
    required this.icon,
    required this.color,
  });
}

const List<Category> predefinedCategories = [
  Category(name: 'Food', icon: Icons.restaurant, color: Colors.orange),
  Category(name: 'Transport', icon: Icons.directions_car, color: Colors.blue),
  Category(name: 'Entertainment', icon: Icons.movie, color: Colors.purple),
  Category(name: 'Bills', icon: Icons.receipt, color: Colors.red),
  Category(name: 'Shopping', icon: Icons.shopping_bag, color: Colors.pink),
  Category(name: 'Health', icon: Icons.local_hospital, color: Colors.green),
  Category(name: 'Education', icon: Icons.school, color: Colors.indigo),
  Category(name: 'Travel', icon: Icons.flight, color: Colors.teal),
  Category(name: 'Salary', icon: Icons.work, color: Colors.amber),
  Category(name: 'Other', icon: Icons.category, color: Colors.grey),
];

Category getCategoryByName(String name) {
  return predefinedCategories.firstWhere(
    (cat) => cat.name == name,
    orElse: () => predefinedCategories.last, // Other
  );
}

String suggestCategory(String title) {
  final lowerTitle = title.toLowerCase();
  if (lowerTitle.contains('food') || lowerTitle.contains('restaurant') || lowerTitle.contains('eat')) {
    return 'Food';
  } else if (lowerTitle.contains('car') || lowerTitle.contains('bus') || lowerTitle.contains('taxi') || lowerTitle.contains('fuel')) {
    return 'Transport';
  } else if (lowerTitle.contains('movie') || lowerTitle.contains('game') || lowerTitle.contains('party')) {
    return 'Entertainment';
  } else if (lowerTitle.contains('electricity') || lowerTitle.contains('water') || lowerTitle.contains('gas') || lowerTitle.contains('internet')) {
    return 'Bills';
  } else if (lowerTitle.contains('shop') || lowerTitle.contains('buy') || lowerTitle.contains('clothes')) {
    return 'Shopping';
  } else if (lowerTitle.contains('doctor') || lowerTitle.contains('medicine') || lowerTitle.contains('hospital')) {
    return 'Health';
  } else if (lowerTitle.contains('book') || lowerTitle.contains('course') || lowerTitle.contains('school')) {
    return 'Education';
  } else if (lowerTitle.contains('flight') || lowerTitle.contains('hotel') || lowerTitle.contains('vacation')) {
    return 'Travel';
  } else if (lowerTitle.contains('salary') || lowerTitle.contains('income') || lowerTitle.contains('pay')) {
    return 'Salary';
  }
  return 'Other';
}

List<Category> getCategories() {
  return predefinedCategories;
}