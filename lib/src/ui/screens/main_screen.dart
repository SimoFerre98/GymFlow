import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

import 'package:gymflow/src/core/theme/expressive_tokens.dart';
import 'package:gymflow/src/ui/screens/calendar_screen.dart';
import 'package:gymflow/src/ui/screens/dashboard_screen.dart';
import 'package:gymflow/src/ui/screens/program_creator_screen.dart';
import 'package:gymflow/src/ui/screens/program_list_screen.dart';
import 'package:gymflow/src/ui/widgets/spring_page_transition.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const CalendarScreen(),
    const ProgramListScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final motion = context.expressive.motion;

    return Scaffold(
      extendBody: true, // Key for floating effect over body content
      // L'`IndexedStack` resta, e resta lo stesso: tiene in vita le tre
      // schermate, che e la ragione per cui era qui. La molla vive sopra, in un
      // widget che non tocca l'identita dei figli — un `AnimatedSwitcher` con
      // una chiave che cambia le ricostruirebbe tutte a ogni tocco.
      body: SpringPageTransition(
        index: _currentIndex,
        child: IndexedStack(index: _currentIndex, children: _screens),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: GNav(
              gap: 8,
              activeColor: Colors.white,
              iconSize: 24,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              duration: disableAnimations ? Duration.zero : motion.emphasized,
              tabBackgroundColor: Theme.of(context).primaryColor,
              color: Colors.grey,
              tabs: const [
                GButton(icon: Icons.dashboard_rounded, text: 'Dashboard'),
                GButton(icon: Icons.calendar_today_rounded, text: 'Calendar'),
                GButton(icon: Icons.fitness_center_rounded, text: 'Workouts'),
              ],
              selectedIndex: _currentIndex,
              onTabChange: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
            ),
          ),
        ),
      ),
      floatingActionButton: _currentIndex == 2
          ? Padding(
              padding: const EdgeInsets.only(
                bottom: 0.0,
              ), // Anchored above the pill
              child: FloatingActionButton.extended(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProgramCreatorScreen(),
                    ),
                  );
                },
                backgroundColor: Theme.of(context).primaryColor,
                label: const Text(
                  'New Program',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                icon: const Icon(Icons.add),
              ),
            )
          : null,
    );
  }
}
