import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymflow/src/core/providers/localization_provider.dart';
import 'package:gymflow/src/core/theme/immersivo_tokens.dart';
import 'package:gymflow/src/ui/screens/calendar_screen.dart';
import 'package:gymflow/src/ui/screens/dashboard_screen.dart';
import 'package:gymflow/src/ui/screens/settings_screen.dart';
import 'package:gymflow/src/ui/screens/workout_creator_screen.dart';
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
    WorkoutCreatorScreen(),
    SettingsScreen(),
  ];
  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(localizationNotifierProvider);
    return Scaffold(
      // L'`IndexedStack` resta, e resta lo stesso: tiene in vita le quattro
      // schermate, che e la ragione per cui era qui. La molla vive sopra, in un
      // widget che non tocca l'identita dei figli — un `AnimatedSwitcher` con
      // una chiave che cambia le ricostruirebbe tutte a ogni tocco.
      body: SpringPageTransition(
        index: _currentIndex,
        child: IndexedStack(index: _currentIndex, children: _screens),
      ),
      bottomNavigationBar: _NavBar(
        currentIndex: _currentIndex,
        onSelect: (index) => setState(() => _currentIndex = index),
        items: [
          _NavItem(icon: Icons.home_rounded, label: loc.t('home')),
          _NavItem(icon: Icons.calendar_month_rounded, label: loc.t('calendar_tab')),
          _NavItem(icon: Icons.add_rounded, label: loc.t('create_tab')),
          _NavItem(icon: Icons.settings_rounded, label: loc.t('settings_title')),
        ],
      ),
    );
  }
}
class _NavItem {
  const _NavItem({required this.icon, required this.label});
  final IconData icon;
  final String label;
}
/// 9px del mockup per l'etichetta della barra: piu piccola di `labelSmall`,
/// e specifica di questa barra — non una voce della scala tipografica.
const double _kNavLabelFontSize = 9;
/// Altezza fissa della barra, contenuto escluso il filetto e l'inset di
/// sistema in fondo.
///
/// **Non e un vezzo estetico**: senza un'altezza esplicita qui, `Scaffold`
/// deve interrogare `_NavBar` per la sua altezza intrinseca prima di
/// disporre corpo e barra, e la fila sotto usa `CrossAxisAlignment.stretch`
/// con figli `Expanded` — combinazione per cui `RenderFlex` **non sa
/// rispondere** a quella domanda (l'altezza intrinseca dipende da quanto
/// spazio la barra ricevera, che e proprio cio che si sta calcolando).
/// Misurato sul telefono: senza questa costante l'intera schermata collassava
/// a una striscia in alto, corpo compreso, con la barra spinta fuori posto —
/// non un errore visibile, un numero sbagliato passato in silenzio.
const double _kNavBarHeight = 76;
/// La barra di navigazione del mockup Immersivo (`1d Home`, `data-screen-label`
/// coi quattro item HOME/SCHEDE/CREA/DATI): striscia a piena larghezza,
/// filetto superiore, icona + etichetta sotto — non piu il dock fluttuante
/// arrotondato del mockup 02 (direzione precedente).
///
/// Voce attiva: filetto superiore di 2px in accento invece dell'1px comune, e
/// colore d'accento su icona ed etichetta. Le altre restano a `paper` al 45%
/// (`rgba(234,246,242,.45)` nel mockup).
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
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(top: BorderSide(color: scheme.outline)),
        ),
        child: SizedBox(
          height: _kNavBarHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: _VoceNav(
                    item: items[i],
                    selezionata: i == currentIndex,
                    onTap: () => onSelect(i),
                  ),
                ),
            ],
          ),
        ),
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
    final t = context.immersivo;
    final scheme = Theme.of(context).colorScheme;
    final colore = selezionata
        ? scheme.primary
        : scheme.onSurface.withValues(alpha: 0.45);
    return Semantics(
      label: item.label,
      button: true,
      selected: selezionata,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.only(top: t.spacing.md, bottom: t.spacing.md - 2),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: selezionata ? scheme.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(item.icon, size: t.sizing.iconLg - 3, color: colore),
              SizedBox(height: t.spacing.xs + 3),
              Text(
                item.label.toUpperCase(),
                style: t.typography.eyebrow?.copyWith(
                  fontSize: _kNavLabelFontSize,
                  color: colore,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
