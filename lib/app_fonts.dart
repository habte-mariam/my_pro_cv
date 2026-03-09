import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/foundation.dart';

class AppFonts {
  static Map<String, pw.Font> fontMap = {};
  // ለ Isolate ስራ እንዲመች ፎንቶቹን በባይት መልክ የምንይዝበት
  static Map<String, Uint8List> fontBytesMap = {};

  static final List<String> availableFamilies = [
    "JetBrains Mono",
    "Poppins",
    "Arimo",
    "Times",
    "NotoSerif",
    "Abyssinica"
  ];

  /// 1. ይህ ፋንክሽን በ UI Thread (Preview Screen) ላይ አንድ ጊዜ ብቻ ይጠራል
  /// ሁሉንም ፎንቶች ከ assets ወደ Uint8List (Bytes) ይቀይራል
  static Future<void> loadAllFontBytes() async {
    if (fontBytesMap.isNotEmpty) return;

    final Map<String, String> fontsToLoad = {
      'Amharic': "assets/fonts/AbyssinicaSIL-Regular.ttf",
      'Times-Regular': "assets/fonts/times_regular.ttf",
      'Times-Bold': "assets/fonts/times_bold.ttf",
      'JetBrains Mono-Regular': "assets/fonts/JetBrainsMono-Regular.ttf",
      'JetBrains Mono-Bold': "assets/fonts/JetBrainsMono-Bold.ttf",
      'JetBrains Mono-Italic': "assets/fonts/JetBrainsMono-Italic.ttf",
      'Poppins-Regular': "assets/fonts/Poppins-Regular.ttf",
      'Poppins-Bold': "assets/fonts/Poppins-Bold.ttf",
      'Arimo-Regular': "assets/fonts/Arimo-Regular.ttf",
      'Arimo-Bold': "assets/fonts/Arimo-Bold.ttf",
      'Arimo-Italic': "assets/fonts/Arimo-Italic.ttf",
      'NotoSerif-Regular': "assets/fonts/NotoSerif-Regular.ttf",
      'NotoSerif-Bold': "assets/fonts/NotoSerif-Bold.ttf",
      'NotoSerif-Italic': "assets/fonts/NotoSerif-Italic.ttf",
    };

    for (var entry in fontsToLoad.entries) {
      try {
        final ByteData data = await rootBundle.load(entry.value);
        fontBytesMap[entry.key] = data.buffer.asUint8List();
      } catch (e) {
        debugPrint("Error loading bytes for ${entry.key}: $e");
      }
    }
  }

  /// 2. ይህ ፋንክሽን በ Isolate ውስጥ የሚጠራ ሲሆን ከባይት ወደ pw.Font ይቀይራል
  /// ምንም አይነት rootBundle.load ስለማይጠቀም Binding Error አይፈጥርም
  static void initFromBytes(Map<String, Uint8List> bytes) {
    fontMap.clear();
    bytes.forEach((key, value) {
      fontMap[key] = pw.Font.ttf(ByteData.view(value.buffer));
    });

    // ዲፎልት ፎንቶችን ማረጋገጫ (Fallback)
    if (!fontMap.containsKey('Amharic')) {
      fontMap['Amharic'] = pw.Font.times();
    }
    if (!fontMap.containsKey('JetBrains Mono-Regular')) {
      fontMap['JetBrains Mono-Regular'] = fontMap['Amharic']!;
    }
  }

  static pw.TextStyle getStyle({
    double size = 10,
    PdfColor color = PdfColors.black,
    bool isBold = false,
    bool isItalic = false,
    String? preferredFamily,
    required String text,
  }) {
    bool hasEthiopic(String text) {
      return text.codeUnits.any((u) => u >= 0x1200 && u <= 0x139F);
    }

    pw.Font? selectedFont;
    bool isAmharic = hasEthiopic(text);
    String family = preferredFamily ?? 'JetBrains Mono';

    if (isAmharic) {
      selectedFont = fontMap['Amharic'];
    } else {
      String key = "$family-Regular";
      if (isBold) key = "$family-Bold";
      if (isItalic) key = "$family-Italic";

      selectedFont = fontMap[key] ??
          fontMap["$family-Regular"] ??
          fontMap['JetBrains Mono-Regular'] ??
          fontMap['Amharic'];
    }

    final amharicFallback = fontMap['Amharic'];

    return pw.TextStyle(
      font: selectedFont ?? pw.Font.times(),
      fontSize: size,
      color: color,
      fontStyle: isItalic ? pw.FontStyle.italic : pw.FontStyle.normal,
      fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
      fontFallback:
          (amharicFallback != null && !isAmharic) ? [amharicFallback] : [],
    );
  }
}
