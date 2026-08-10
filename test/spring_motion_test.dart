import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/src/ui/widgets/spring_page_transition.dart';
import 'package:motor/motor.dart';

import 'package:gymflow/src/core/theme/expressive_tokens.dart';

void main() {
  group('US-036: Token di movimento e molle fisiche', () {
    test('i token esistono e la molla del mockup e Cubic(0.34, 1.56, 0.64, 1)',
        () {
      const motion = ExpressiveMotion();

      expect(motion.spring, equals(const Cubic(0.34, 1.56, 0.64, 1)));
      expect(motion.springSnappy, isA<SpringMotion>());
      expect(motion.springSmooth, isA<SpringMotion>());
      expect(motion.springExpressive, isA<SpringMotion>());

      // I tre token di molla fisica sono distinti fra loro per parametri
      expect(motion.springSnappy, isNot(equals(motion.springSmooth)));
      expect(motion.springSmooth, isNot(equals(motion.springExpressive)));
      expect(motion.springSnappy, isNot(equals(motion.springExpressive)));
    });

    testWidgets('i token sono leggibili da ThemeExtension (context.expressive.motion)',
        (tester) async {
      late ExpressiveMotion motion;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: const [ExpressiveTokens()],
          ),
          home: Builder(
            builder: (context) {
              motion = context.expressive.motion;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(motion.spring, equals(const Cubic(0.34, 1.56, 0.64, 1)));
      expect(motion.springSnappy, isA<SpringMotion>());
      expect(motion.springSmooth, isA<SpringMotion>());
      expect(motion.springExpressive, isA<SpringMotion>());
    });

    testWidgets(
        '⭐ Dimostrazione motor: un\'animazione interrotta a meta riparte da posizione e velocita correnti',
        (tester) async {
      late SingleMotionController controller;

      await tester.pumpWidget(
        MaterialApp(
          home: _MotionControllerTestWidget(
            onControllerCreated: (ctrl) {
              controller = ctrl;
            },
          ),
        ),
      );

      // Avvia animazione da 0 a 100 con springSmooth
      controller.animateTo(100.0);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final valueAtInterrupt = controller.value;
      final velocityAtInterrupt = controller.velocities.first;

      // L'animazione si trova a meta strada con velocita positiva
      expect(valueAtInterrupt, greaterThan(0.0));
      expect(valueAtInterrupt, lessThan(100.0));
      expect(velocityAtInterrupt, greaterThan(0.0));

      // Interrompi l'animazione cambiando target a 200.0
      controller.animateTo(200.0);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Al frame successivo, il valore e progredito rispetto alla posizione al momento dell'interruzione
      // e non e ripartito da zero
      expect(controller.value, greaterThan(valueAtInterrupt));
      expect(controller.value, lessThan(200.0));

      // Porta l'animazione a termine
      await tester.pump(const Duration(milliseconds: 2000));
    });

    // ⚠️ Questo test monta `_TransitionTestWidget`, **scritto qui sotto nel file
    // di test**, non `MainScreen`. Prova quindi che il token pilota una
    // `CurvedAnimation` e che il ramo `disableAnimations` esiste in un widget
    // fatto per la prova — non che la schermata vera si comporti cosi. Il file
    // vero e coperto dai test su `SpringPageTransition`, piu sotto.
    testWidgets(
        'il token motion.spring pilota una CurvedAnimation, e a animazioni spente il salto e immediato (su un widget di prova, non su MainScreen)',
        (tester) async {
      double animValueNormal = 0.0;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: const [ExpressiveTokens()],
          ),
          home: _TransitionTestWidget(
            onValue: (v) => animValueNormal = v,
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // A meta animazione, il valore si sta muovendo con la curva spring
      expect(animValueNormal, greaterThan(0.0));
      await tester.pump(const Duration(milliseconds: 1000));

      double animValueDisabled = 0.0;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            theme: ThemeData(
              extensions: const [ExpressiveTokens()],
            ),
            home: _TransitionTestWidget(
              onValue: (v) => animValueDisabled = v,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      // Con animazioni disattivate, il cambio e immediato
      expect(animValueDisabled, equals(1.0));
    });
  });

  group('SpringPageTransition — il file vero della barra', () {
    testWidgets(
        '⭐ cambiando voce il figlio NON viene ricostruito',
        (tester) async {
      // E il difetto trovato in review. La strada breve — avvolgere
      // l'`IndexedStack` in un `AnimatedSwitcher` con una chiave che cambia —
      // fa costruire un albero nuovo a ogni cambio voce: misurato, da **una**
      // creazione di `State` a **tre** su tre cambi. Sulle schermate vere vuol
      // dire rifare le query di Firestore e la lettura di Salute a ogni tocco
      // sulla barra, e perdere la posizione di scorrimento.
      _ContaCreazioni.creazioni = 0;

      Widget albero(int i) => MaterialApp(
            theme: ThemeData(extensions: const [ExpressiveTokens()]),
            home: SpringPageTransition(
              index: i,
              child: const _ContaCreazioni(),
            ),
          );

      await tester.pumpWidget(albero(0));
      await tester.pumpAndSettle();
      await tester.pumpWidget(albero(2));
      await tester.pumpAndSettle();
      await tester.pumpWidget(albero(0));
      await tester.pumpAndSettle();

      expect(
        _ContaCreazioni.creazioni,
        1,
        reason: 'il contenuto deve nascere una volta sola: tre cambi voce '
            'hanno prodotto ${_ContaCreazioni.creazioni} creazioni',
      );
    });

    testWidgets('a meta assestamento la trasformazione non e l identita',
        (tester) async {
      Widget albero(int i) => MaterialApp(
            theme: ThemeData(extensions: const [ExpressiveTokens()]),
            home: SpringPageTransition(index: i, child: const Text('contenuto')),
          );

      await tester.pumpWidget(albero(0));
      await tester.pumpAndSettle();

      // A riposo non trasforma niente.
      expect(_scalaCorrente(tester), closeTo(1.0, 0.0001));

      await tester.pumpWidget(albero(1));
      await tester.pump(const Duration(milliseconds: 40));

      expect(
        _scalaCorrente(tester),
        isNot(closeTo(1.0, 0.001)),
        reason: 'entrando, il contenuto deve assestarsi invece di comparire fermo',
      );

      await tester.pumpAndSettle();
      expect(
        _scalaCorrente(tester),
        closeTo(1.0, 0.0001),
        reason: 'e alla fine deve tornare esattamente a posto',
      );
    });

    testWidgets('con le animazioni di sistema spente non trasforma niente',
        (tester) async {
      Widget albero(int i) => MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: MaterialApp(
              theme: ThemeData(extensions: const [ExpressiveTokens()]),
              home:
                  SpringPageTransition(index: i, child: const Text('contenuto')),
            ),
          );

      await tester.pumpWidget(albero(0));
      await tester.pumpWidget(albero(1));
      await tester.pump();

      expect(
        find.byType(Transform),
        findsNothing,
        reason: 'a animazioni spente non deve restare nessuna trasformazione',
      );
      expect(find.text('contenuto'), findsOneWidget);
    });

    test('main_screen.dart usa SpringPageTransition e non AnimatedSwitcher', () {
      // Senza togliere i commenti il test conterebbe le menzioni dentro i
      // commenti che spiegano **perche** l AnimatedSwitcher non c e piu: e la
      // trappola che questo progetto ha gia visto, e il motivo per cui
      // design_system_usage_test.dart filtra le righe di commento.
      final sorgente = File('lib/src/ui/screens/main_screen.dart')
          .readAsLinesSync()
          .where((r) => !r.trimLeft().startsWith('//'))
          .join('\n');
      expect(sorgente, contains('SpringPageTransition'));
      expect(
        sorgente,
        isNot(contains('AnimatedSwitcher')),
        reason: 'un AnimatedSwitcher sopra l IndexedStack ricostruisce le tre '
            'schermate a ogni cambio voce',
      );
      expect(
        sorgente,
        contains('IndexedStack'),
        reason: 'l IndexedStack tiene in vita le tre schermate: non si toglie',
      );
    });
  });
}

/// Legge la scala orizzontale applicata dalle `Transform` dell albero.
///
/// ⚠️ **Non** `getMaxScaleOnAxis()`: quel metodo considera anche l asse Z, che in
/// una scala 2D resta 1, quindi per `Transform.scale(scale: 0.98)` restituisce
/// **1.0** e il test non vedrebbe mai niente muoversi. Si legge la cella (0,0)
/// della matrice, che e la scala su x.
double _scalaCorrente(WidgetTester tester) {
  for (final t in tester.widgetList<Transform>(find.byType(Transform))) {
    final s = t.transform.entry(0, 0);
    if ((s - 1.0).abs() > 1e-9) return s;
  }
  return 1.0;
}

/// Conta quante volte il suo `State` viene creato: se il contenuto viene
/// ricostruito, questo numero sale.
class _ContaCreazioni extends StatefulWidget {
  const _ContaCreazioni();
  static int creazioni = 0;

  @override
  State<_ContaCreazioni> createState() => _ContaCreazioniState();
}

class _ContaCreazioniState extends State<_ContaCreazioni> {
  @override
  void initState() {
    super.initState();
    _ContaCreazioni.creazioni++;
  }

  @override
  Widget build(BuildContext context) => const Text('contenuto');
}

class _MotionControllerTestWidget extends StatefulWidget {
  final ValueChanged<SingleMotionController> onControllerCreated;

  const _MotionControllerTestWidget({
    required this.onControllerCreated,
  });

  @override
  State<_MotionControllerTestWidget> createState() =>
      __MotionControllerTestWidgetState();
}

class __MotionControllerTestWidgetState
    extends State<_MotionControllerTestWidget>
    with SingleTickerProviderStateMixin {
  late SingleMotionController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SingleMotionController(
      motion: const ExpressiveMotion().springSmooth,
      vsync: this,
      initialValue: 0.0,
    );
    widget.onControllerCreated(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Text('Value: ${_controller.value}');
      },
    );
  }
}

class _TransitionTestWidget extends StatefulWidget {
  final ValueChanged<double> onValue;

  const _TransitionTestWidget({required this.onValue});

  @override
  State<_TransitionTestWidget> createState() => _TransitionTestWidgetState();
}

class _TransitionTestWidgetState extends State<_TransitionTestWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _toggle = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const ExpressiveMotion().emphasized,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: const ExpressiveMotion().spring,
    )..addListener(() {
        widget.onValue(_animation.value);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disable = MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            if (disable) {
              _controller.value = 1.0;
              widget.onValue(1.0);
            } else {
              setState(() {
                _toggle = !_toggle;
                if (_toggle) {
                  _controller.forward();
                } else {
                  _controller.reverse();
                }
              });
            }
          },
          child: Text(_toggle ? 'On' : 'Off'),
        ),
      ),
    );
  }
}
