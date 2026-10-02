import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/services/in_memory_workout_repository.dart';
import 'package:gymlog/ui/app.dart';

void main() {
  testWidgets('bottom nav switches between tabs', (tester) async {
    await tester.pumpWidget(
      GymLogApp(repository: InMemoryWorkoutRepository()),
    );
    await tester.pumpAndSettle();

    expect(find.text('GymLog'), findsOneWidget);
    expect(find.text('Start workout'), findsOneWidget);

    await tester.tap(find.text('Exercises'));
    await tester.pumpAndSettle();
    // The library is grouped alphabetically; scroll each into view.
    await tester.scrollUntilVisible(find.text('Bench Press'), 400);
    expect(find.text('Bench Press'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Deadlift'), 400);
    expect(find.text('Deadlift'), findsOneWidget);

    await tester.tap(find.text('Progress'));
    await tester.pumpAndSettle();
    expect(find.text('Estimated 1RM trend'), findsOneWidget);

    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(find.text('Personal records'), findsOneWidget);
  });

  testWidgets('starting a workout shows the set logger', (tester) async {
    await tester.pumpWidget(
      GymLogApp(repository: InMemoryWorkoutRepository()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start workout'));
    await tester.pumpAndSettle();

    expect(find.text('Log set'), findsOneWidget);
    expect(find.text('Finish workout'), findsOneWidget);
  });

  testWidgets('logging a set shows it in the session list', (tester) async {
    await tester.pumpWidget(
      GymLogApp(repository: InMemoryWorkoutRepository()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start workout'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log set'));
    await tester.pumpAndSettle();

    // Default 8 reps x 60 kg on Bench Press.
    expect(find.textContaining('8 reps'), findsOneWidget);
    expect(find.text('1 sets · 480 kg volume'), findsOneWidget);
  });
}
