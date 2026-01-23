import 'package:flutter/material.dart';

enum BadgeType { workoutCount, streak }

class BadgeModel {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final BadgeType type;
  final int threshold; // The value needed to unlock (e.g., 10 workouts)

  const BadgeModel({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.type,
    required this.threshold,
  });
}

// Predefined Badges
const List<BadgeModel> allBadges = [
  BadgeModel(
    id: 'first_step',
    name: 'First Step',
    description: 'Complete your first workout',
    icon: Icons.directions_walk,
    type: BadgeType.workoutCount,
    threshold: 1,
  ),
  BadgeModel(
    id: 'getting_serious',
    name: 'Getting Serious',
    description: 'Complete 10 workouts',
    icon: Icons.fitness_center,
    type: BadgeType.workoutCount,
    threshold: 10,
  ),
  BadgeModel(
    id: 'gym_rat',
    name: 'Gym Rat',
    description: 'Complete 50 workouts',
    icon: Icons.emoji_events,
    type: BadgeType.workoutCount,
    threshold: 50,
  ),
  BadgeModel(
    id: 'warming_up',
    name: 'Warming Up',
    description: 'Reach a 3-day streak',
    icon: Icons.local_fire_department_outlined,
    type: BadgeType.streak,
    threshold: 3,
  ),
  BadgeModel(
    id: 'unstoppable',
    name: 'Unstoppable',
    description: 'Reach a 7-day streak',
    icon: Icons.local_fire_department,
    type: BadgeType.streak,
    threshold: 7,
  ),
];
