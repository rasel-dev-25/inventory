import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildHarness({bool withContainer = true, bool withViewInsets = false}) {
    return MaterialApp(
      home: Scaffold(
        body: Stack(
          children: [
            const Positioned.fill(child: ColoredBox(color: Colors.grey)),
            Builder(
              builder: (context) => AnimatedPositioned(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
                bottom: 0,
                left: 0,
                right: 0,
                child: withContainer
                    ? Container(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.8,
                        ),
                        child: SingleChildScrollView(
                          padding: EdgeInsets.only(
                            bottom: withViewInsets ? 300 : 12,
                          ),
                          child: const _TallForm(),
                        ),
                      )
                    : const SingleChildScrollView(
                        child: _TallForm(),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildNestedHarness() {
    return MaterialApp(
      home: Scaffold(
        body: Scaffold(
          body: Stack(
            children: [
              const Positioned.fill(child: ColoredBox(color: Colors.grey)),
              Builder(
                builder: (context) => AnimatedPositioned(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutCubic,
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.8,
                    ),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom + 12,
                      ),
                      child: const _TallForm(),
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

  testWidgets('form scrolls when Container constraint present', (tester) async {
    await tester.pumpWidget(buildHarness());
    await tester.pumpAndSettle();

    final scrollable = tester.state<ScrollableState>(
      find.descendant(
        of: find.byType(SingleChildScrollView),
        matching: find.byType(Scrollable),
      ),
    );
    final position = scrollable.position;
    expect(position.maxScrollExtent, greaterThan(0),
        reason: 'with bounded container the form must scroll');
  });

  testWidgets('form does NOT scroll without constraint (original bug)',
      (tester) async {
    await tester.pumpWidget(buildHarness(withContainer: false));
    await tester.pumpAndSettle();

    final scrollable = tester.state<ScrollableState>(
      find.descendant(
        of: find.byType(SingleChildScrollView),
        matching: find.byType(Scrollable),
      ),
    );
    final position = scrollable.position;
    expect(position.maxScrollExtent, 0,
        reason: 'without a bounded constraint the SingleChildScrollView '
            'grows to its content and never scrolls');
  });

  testWidgets('keyboard open: form scrolls and bottom reachable',
      (tester) async {
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetViewInsets);

    await tester.pumpWidget(buildHarness());
    await tester.pumpAndSettle();

    final scrollable = tester.state<ScrollableState>(
      find.descendant(
        of: find.byType(SingleChildScrollView),
        matching: find.byType(Scrollable),
      ),
    );
    final position = scrollable.position;
    expect(position.maxScrollExtent, greaterThan(0),
        reason: 'form must remain scrollable while keyboard is open');

    position.jumpTo(position.maxScrollExtent);
    await tester.pumpAndSettle();

    final bottomField = tester.getRect(
      find.text('field C'),
    );
    expect(bottomField.bottom, lessThanOrEqualTo(800 - 300 + 1),
        reason: 'after scrolling to the end, the last field must sit above '
            'the keyboard top');
  });

  testWidgets('nested scaffolds: form bottom stays above keyboard',
      (tester) async {
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetViewInsets);

    await tester.pumpWidget(buildNestedHarness());
    await tester.pumpAndSettle();

    final scrollable = tester.state<ScrollableState>(
      find.descendant(
        of: find.byType(SingleChildScrollView),
        matching: find.byType(Scrollable),
      ),
    );
    final position = scrollable.position;
    expect(position.maxScrollExtent, greaterThan(0));

    final scrollRect = tester.getRect(find.byType(SingleChildScrollView));
    expect(scrollRect.bottom, lessThanOrEqualTo(800 - 300 + 1),
        reason: 'with nested scaffolds the form viewport bottom must not sit '
            'behind the keyboard');

    position.jumpTo(position.maxScrollExtent);
    await tester.pumpAndSettle();
    final bottomField = tester.getRect(find.text('field C'));
    expect(bottomField.bottom, lessThanOrEqualTo(800 - 300 + 1));
  });
}

class _TallForm extends StatelessWidget {
  const _TallForm();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 800,
      color: Colors.white,
      child: const Column(
        children: [
          SizedBox(height: 300, child: Text('field A')),
          SizedBox(height: 300, child: Text('field B')),
          SizedBox(height: 200, child: Text('field C')),
        ],
      ),
    );
  }
}
