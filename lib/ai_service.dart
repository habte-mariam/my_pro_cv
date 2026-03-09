import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AIService {
  // --- API Keys ---
  static const String _geminiKey = 'AIzaSyDtboIxgsjmgd7M1VqJ8cu-XejfvVOMvW4';
  static const String _groqKey =
      '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';
  static const String _hfKey = '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';
  static const String _openAIKey =
      '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';

  static const String _systemInstruction =
      "You are an expert Human Career Consultant. Your goal is to rewrite the input into a natural, "
      "human-sounding professional narrative. "
      "CRITICAL RULES: "
      "HUMAN-CENTRIC LANGUAGE: Avoid robotic AI clichés (e.g., avoid overusing 'spearheaded', 'leveraged', 'synergy', 'passionate'). "
      "Use clear, strong, and grounded verbs that a real professional would use. "
      "You are a professional career architect and narrative writer. Your task is to transform raw input "
      "into a sophisticated, personal, and descriptive professional story. CRITICAL RULES: "
      "First, never copy input text directly; instead, describe the user's background using high-impact, "
      "original professional language. Second, for the Professional Summary section, generate a single, "
      "compelling paragraph of exactly 5 to 7 lines that synthesizes the user's overall value proposition. "
      "For Work Experience (Description or Achievements): You MUST be extremely concise. Craft a powerful description of ONLY 2 to 3 lines in total. "
      "Even if multiple points are requested, synthesize them so they do not exceed this 3-line limit. "
      "focusing on personal contributions and strategic impact. Fourth, maintain a strictly formal and "
      "ATS-optimized tone throughout. Output ONLY the final polished text, excluding any conversational "
      "intro, labels, or 'Here is your text' style remarks.";

  static Future<String> askAI(String contextData,
      {String? customPrompt,
      bool isAmharic = false,
      int styleIndex = 0}) async {
    String variation = _getStyleVariation(styleIndex, isAmharic);
    String finalPrompt = "$customPrompt\n\nRequirement: $variation";

    // 1. First Priority: Groq
    try {
      debugPrint("Attempting Groq (Llama 3.1)...");
      return await _callGroq(contextData, finalPrompt, isAmharic);
    } catch (e) {
      debugPrint("Groq Failed: $e\nSwitching to Gemini...");

      // 2. Second Priority: Gemini
      try {
        return await _callGemini(contextData, finalPrompt, isAmharic);
      } catch (e) {
        debugPrint("Gemini Failed: $e\nSwitching to OpenAI...");

        // 3. Third Priority: OpenAI
        try {
          return await _callOpenAI(contextData, finalPrompt, isAmharic);
        } catch (e) {
          debugPrint("OpenAI Failed: $e\nSwitching to Hugging Face...");

          // 4. Fourth Priority: Hugging Face
          try {
            return await _callHuggingFace(contextData, finalPrompt, isAmharic);
          } catch (e) {
            debugPrint("Hugging Face Failed: $e");
            return isAmharic
                ? "ይቅርታ፣ የ AI አገልግሎቶች ለጊዜው ስራ በዝቶባቸዋል። እባክዎ ኢንተርኔትዎን አረጋግጠው ጥቂት ቆይተው ይሞክሩ።"
                : "All AI services are currently busy or offline. Please check your internet connection and try again.";
          }
        }
      }
    }
  }

  // --- የተለያየ የአጻጻፍ ስታይል ለማመንጨት (Fixed Braces) ---
  static String _getStyleVariation(int index, bool isAmharic) {
    if (isAmharic) {
      if (index % 3 == 0) {
        return "በጣም ፕሮፌሽናል እና ማራኪ በሆነ የአማርኛ ቃላት ተጠቀም።";
      }
      if (index % 3 == 1) {
        return "አጭር፣ ግልጽ እና ቀጥታ ወደ ዋናው ሃሳብ የሚገባ ጽሁፍ አዘጋጅ።";
      }
      return "በስራው ላይ ያለውን የሊደርሺፕ እና የውጤታማነት ክህሎት በሚያሳይ መልኩ ጻፍ።";
    } else {
      if (index % 3 == 0) {
        return "Focus on leadership, strategic impact, and quantifiable results.";
      }
      if (index % 3 == 1) {
        return "Keep it highly concise, punchy, and action-oriented.";
      }
      return "Emphasize professional growth and technical expertise.";
    }
  }

  // --- 1. Gemini Implementation (Fixed Braces) ---
  static Future<String> _callGemini(
      String data, String prompt, bool amharic) async {
    final model = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: _geminiKey,
      systemInstruction: Content.system(_systemInstruction +
          (amharic ? " Ensure the output is in professional Amharic." : "")),
    );
    final content = [
      Content.text(
          "${amharic ? "በአማርኛ ጻፍ (Professional Amharic):" : ""} \nTask: $prompt \n\nContext Data: $data")
    ];
    final response = await model
        .generateContent(content)
        .timeout(const Duration(seconds: 15));
    if (response.text == null || response.text!.isEmpty) {
      throw Exception("Empty response from Gemini");
    }
    return _cleanResponse(response.text!);
  }

  // --- 2. Groq Implementation (Llama 3) ---
  static Future<String> _callGroq(
      String data, String prompt, bool amharic) async {
    final response = await http
        .post(
          Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
          headers: {
            'Authorization': 'Bearer $_groqKey',
            'Content-Type': 'application/json'
          },
          body: jsonEncode({
            "model": "llama-3.1-8b-instant",
            "temperature": 0.7,
            "messages": [
              {"role": "system", "content": _systemInstruction},
              {
                "role": "user",
                "content":
                    "${amharic ? "Write in highly professional Amharic:" : ""} \nTask: $prompt \n\nContext Data: $data"
              }
            ]
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      return _cleanResponse(
          jsonDecode(response.body)['choices'][0]['message']['content']);
    }
    throw Exception("Groq Error ${response.statusCode}");
  }

  // --- 3. OpenAI Implementation ---
  static Future<String> _callOpenAI(
      String data, String prompt, bool amharic) async {
    final response = await http
        .post(
          Uri.parse('https://api.openai.com/v1/chat/completions'),
          headers: {
            'Authorization': 'Bearer $_openAIKey',
            'Content-Type': 'application/json'
          },
          body: jsonEncode({
            "model": "gpt-4o-mini",
            "temperature": 0.7,
            "messages": [
              {"role": "system", "content": _systemInstruction},
              {
                "role": "user",
                "content":
                    "${amharic ? "Write in highly professional Amharic:" : ""} \nTask: $prompt \n\nContext Data: $data"
              }
            ]
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      return _cleanResponse(
          jsonDecode(response.body)['choices'][0]['message']['content']);
    }
    throw Exception("OpenAI Error ${response.statusCode}");
  }

  // --- 4. Hugging Face Implementation ---
  static Future<String> _callHuggingFace(
      String data, String prompt, bool amharic) async {
    String hfPrompt =
        "<s>[INST] $_systemInstruction \n\n ${amharic ? 'Write in Amharic.' : ''} Task: $prompt \n Context Data: $data [/INST]";

    final response = await http
        .post(
          Uri.parse(
              'https://router.huggingface.co/hf-inference/models/mistralai/Mistral-7B-Instruct-v0.2'),
          headers: {
            'Authorization': 'Bearer $_hfKey',
            'Content-Type': 'application/json'
          },
          body: jsonEncode({
            "inputs": hfPrompt,
            "parameters": {
              "max_new_tokens": 250,
              "temperature": 0.7,
              "return_full_text": false
            }
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      String text = decoded is List
          ? decoded[0]['generated_text']
          : decoded['generated_text'];
      return _cleanResponse(text);
    }
    throw Exception("HF Error ${response.statusCode}");
  }

  // የተበላሹ ቃላቶችንና መግቢያዎችን ማጽጃ
  static String _cleanResponse(String text) {
    return text
        .replaceFirst(
            RegExp(r'^.*?(?:here is|certainly|summary|ማጠቃለያ|here are).*?:\n*',
                caseSensitive: false),
            '')
        .replaceFirst(RegExp(r'^(?:\s*[-*•]?\s*)*'), '')
        .replaceAll('"', '')
        .replaceAll("'", "")
        .replaceAll(RegExp(r'\*\*'), '')
        .trim();
  }
}
