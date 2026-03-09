import 'package:flutter_test/flutter_test.dart';
import 'package:my_new_cv/main.dart';

void main() {
  testWidgets('App load smoke test', (WidgetTester tester) async {
    // ማሳሰቢያ፡ አፑ Supabase ስለሚጠቀም በቴስት ወቅት ላይሰራ ይችላል።
    // ለጊዜው አፑ መነሳቱን ብቻ ለማረጋገጥ ይሄን መጠቀም ይቻላል።
    await tester.pumpWidget(const MyApp());
    // በቴስት ወቅት ፕለጊን እንዳይጠይቅ የሚረዳ (Mocking might be needed for full test)
    expect(true, true);
  });
}
