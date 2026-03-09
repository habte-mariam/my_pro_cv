import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final List<Map<String, dynamic>> _technicalFaqs = [
    {
      "q": "Can I use the app offline?",
      "a":
          "Most features work offline. However, you need an internet connection for the AI Assistant and to sync with Firebase.",
      "icon": Icons.wifi_off_outlined
    },
    {
      "q": "Where can I find my saved CV files?",
      "a":
          "You can find them in the 'Saved CVs' screen within the app, or in the 'Download' folder of your device's file manager.",
      "icon": Icons.folder_open_outlined
    },
    {
      "q": "Is my personal data safe?",
      "a":
          "Your data is stored locally on your device. We use industry-standard encryption for any data synced with our secure database.",
      "icon": Icons.security_outlined
    },
    {
      "q": "How does the AI Assistant help me?",
      "a":
          "The AI analyzes your rough drafts and rewrites them using professional industry keywords to improve your chances of getting hired.",
      "icon": Icons.auto_awesome_outlined
    },
    {
      "q": "How do I change the theme color of my CV?",
      "a":
          "Go to 'App Settings' and choose a 'Theme Color'. This color will be applied to headings and icons in your generated CV.",
      "icon": Icons.color_lens_outlined
    },
    {
      "q": "Will my data be lost if I uninstall the app?",
      "a":
          "Yes, since the database is local, uninstalling the app will remove your data. We recommend keeping a copy of your exported PDFs.",
      "icon": Icons.warning_amber_outlined
    },
  ];

  Future<void> _launchURL(String urlString) async {
    final Uri uri = Uri.parse(urlString);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw 'Could not launch $uri';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Could not open link: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text("Help & Support",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: CustomScrollView(
        slivers: [
          // Header Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Frequently Asked Questions",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A237E))),
                  const SizedBox(height: 5),
                  Text("Quick answers to technical questions",
                      style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // FAQ List
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: _buildHelpTile(_technicalFaqs[index]),
              ),
              childCount: _technicalFaqs.length,
            ),
          ),

          // Contact Section
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildContactCard(),
                  const SizedBox(height: 20),
                  Text("HabTech CV Builder Pro v1.0",
                      style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A237E),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.indigo.withValues(),
              blurRadius: 15,
              offset: const Offset(0, 8))
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.support_agent_rounded,
              color: Colors.white, size: 48),
          const SizedBox(height: 16),
          const Text("Still need help?",
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20)),
          const SizedBox(height: 8),
          const Text("Our technical team is available 24/7 to assist you.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildContactButton(
                    "Telegram",
                    Icons.send_rounded,
                    Colors.white,
                    const Color(0xFF1A237E),
                    () => _launchURL("https://t.me/hab7tech")),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildContactButton(
                    "Email",
                    Icons.email_rounded,
                    Colors.white.withValues(),
                    Colors.white,
                    () => _launchURL("mailto:habtiet96@gmail.com")),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildContactButton(String label, IconData icon, Color bgColor,
      Color textColor, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: textColor,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildHelpTile(Map<String, dynamic> faq) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: ExpansionTile(
        leading: Icon(faq["icon"], color: const Color(0xFF3F51B5)),
        title: Text(faq["q"],
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(faq["a"],
                style: const TextStyle(
                    color: Colors.black54, fontSize: 13, height: 1.5)),
          ),
        ],
      ),
    );
  }
}
