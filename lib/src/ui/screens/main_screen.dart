import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gymflow/src/core/providers/localization_provider.dart';
import 'package:gymflow/src/core/theme/expressive_tokens.dart';
import 'package:gymflow/src/ui/screens/calendar_screen.dart';
import 'package:gymflow/src/ui/screens/dashboard_screen.dart';
import 'package:gymflow/src/ui/screens/program_creator_screen.dart';
import 'package:gymflow/src/ui/screens/program_list_screen.dart';
import 'package:gymflow/src/ui/widgets/expressive_cta_button.dart';
import 'package:gymflow/src/ui/widgets/spring_page_transition.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    CalendarScreen(),
    ProgramListScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(localizationNotifierProvider);

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
        child: _NavBar(
          currentIndex: _currentIndex,
          onSelect: (index) => setState(() => _currentIndex = index),
          items: [
            _NavItem(icon: Icons.dashboard_rounded, label: loc.t('home')),
            _NavItem(
              icon: Icons.calendar_today_rounded,
              label: loc.t('calendar_tab'),
            ),
            _NavItem(
              icon: Icons.fitness_center_rounded,
              label: loc.t('programs_tab'),
            ),
          ],
        ),
      ),
      floatingActionButton: _currentIndex == 2
          ? ExpressiveCtaButton(
              // Glifo `+`, non `→`: e un'azione di creazione, e nel mockup 02
              // e la stessa forma usata da «Nuovo esercizio». `→` e per
              // continuare qualcosa che esiste gia.
              arw: '+',
              label: loc.t('new_program'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ProgramCreatorScreen(),
                  ),
                );
              },
            )
          : null,
    );
  }
}

class _NavItem {
  const _NavItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

/// La barra di navigazione del mockup 02: icone sole, nessuna etichetta,
/// nessuna pillola dietro la voce attiva.
///
/// `DESIGN-SPEC.md`, voce «Barra di navigazione»: margine 12dp, raggio 27dp,
/// fondo `ink-700`, icona selezionata in ambra, le altre al 42%. Il CSS del
/// mockup (`.nav i`) non definisce altro — nessun'ombra, nessun testo, nessuna
/// dimensione diversa per la voce attiva — quindi non c'e altro da disegnare:
/// e la sostituzione di `google_nav_bar`, che portava pillola ambra dietro
/// l'icona attiva ed etichette testuali, nessuna delle due nel mockup.
///
/// `ink-700` e `scheme.surfaceContainerHigh` nel tema scuro: verificato in
/// `app_theme.dart`, non assunto.
class _NavBar extends StatelessWidget {
  const _NavBar({
    required this.items,
    required this.currentIndex,
    required this.onSelect,
  });

  final List<_NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final t = context.expressive;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      // 12dp del mockup: fra i token piu vicini (`sm`=8, `md`=16) nessuno e
      // esatto. `sm` per restare una barra compatta e vicina ai bordi, invece
      // del margine di 24 della precedente "isola" flottante — quello era il
      // valore che rendeva la barra un dock separato dal contenuto, non la
      // striscia continua del mockup.
      margin: EdgeInsets.all(t.spacing.sm),
      padding: EdgeInsets.symmetric(
        horizontal: t.spacing.sm,
        vertical: t.spacing.sm,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: t.shape.cornerLg,
        // «Elementi flottanti: barra di navigazione, overlay del timer» — e
        // il commento che accompagna `level3` da quando e stato scritto per
        // l'overlay del tempo. La barra e il secondo elemento previsto.
        boxShadow: t.elevation.level3(scheme.shadow),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (var i = 0; i < items.length; i++)
            _VoceNav(
              item: items[i],
              selezionata: i == currentIndex,
              onTap: () => onSelect(i),
            ),
        ],
      ),
    );
  }
}

class _VoceNav extends StatelessWidget {
  const _VoceNav({
    required this.item,
    required this.selezionata,
    required this.onTap,
  });

  final _NavItem item;
  final bool selezionata;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.expressive;
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      label: item.label,
      button: true,
      selected: selezionata,
      child: IconButton(
        onPressed: onTap,
        tooltip: item.label,
        iconSize: t.sizing.iconLg,
        style: IconButton.styleFrom(
          minimumSize: Size.square(t.sizing.minTouchTarget),
        ),
        icon: AnimatedScale(
          // Il mockup non ha una pillola che scorre dietro l'icona attiva:
          // il "moto a molla" del cambio di sezione e questo, un piccolo
          // balzo sull'icona stessa, non un indicatore che non esiste.
          scale: selezionata ? 1.15 : 1.0,
          duration: t.motion.quick,
          curve: t.motion.spring,
          child: Icon(
            item.icon,
            color: selezionata
                ? scheme.primary
                : scheme.onSurface.withValues(alpha: 0.42),
          ),
        ),
      ),
    );
  }
}
