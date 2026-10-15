import 'package:flutter_test/flutter_test.dart';
import 'package:todolist/main.dart';

void main() {
  testWidgets('TaskFlow app loads successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const TaskFlowApp());

    expect(find.text('TaskFlow'), findsOneWidget);
    expect(find.text('Make today'), findsOneWidget);
    expect(find.text('My Tasks'), findsOneWidget);
  });
}
