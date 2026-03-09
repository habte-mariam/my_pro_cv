import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class AdminStatsPage extends StatefulWidget {
  const AdminStatsPage({super.key});

  @override
  State<AdminStatsPage> createState() => _AdminStatsPageState();
}

class _AdminStatsPageState extends State<AdminStatsPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _userLogs = [];

  @override
  void initState() {
    super.initState();
    _fetchUserLogs();
  }

  // ከ Supabase 'user_logs' ቴብል ዳታ ማምጣት
  Future<void> _fetchUserLogs() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final List<dynamic> response = await _supabase
          .from('user_logs')
          .select()
          .order('last_seen', ascending: false);

      if (mounted) {
        setState(() {
          _userLogs = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching logs: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Error fetching data: $e"),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text("User Analytics Dashboard",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.indigo[900],
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchUserLogs,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchUserLogs,
              child: _userLogs.isEmpty
                  ? const Center(child: Text("No users registered yet."))
                  : Column(
                      children: [
                        _buildSummaryHeader(_userLogs.length),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _userLogs.length,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            itemBuilder: (context, index) {
                              var data = _userLogs[index];

                              // ቀን አቀራረብ ከጥንቃቄ ጋር
                              String formattedDate = "Unknown";
                              try {
                                if (data['last_seen'] != null) {
                                  DateTime date =
                                      DateTime.parse(data['last_seen']);
                                  formattedDate =
                                      DateFormat('MMM d, hh:mm a').format(date);
                                }
                              } catch (e) {
                                formattedDate = "Invalid Date";
                              }

                              return Card(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 6),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                child: ExpansionTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.indigo[50],
                                    child: Icon(Icons.person,
                                        color: Colors.indigo[900]),
                                  ),
                                  title: Text(data['name'] ?? "Guest User",
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  subtitle: Text("Last Active: $formattedDate",
                                      style: const TextStyle(fontSize: 12)),
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      color: Colors.grey[50],
                                      child: Column(
                                        children: [
                                          _buildDetailHeader(
                                              "Location Analytics"),
                                          _buildInfoRow(
                                              Icons.gps_fixed,
                                              "GPS Location:",
                                              data['real_gps_location'] ??
                                                  "Not Detected",
                                              Colors.green),
                                          _buildInfoRow(
                                              Icons.edit_location_alt,
                                              "CV Address:",
                                              data['cv_profile_address'] ??
                                                  "Not Filled",
                                              Colors.orange),
                                          _buildInfoRow(
                                              Icons.public,
                                              "System IP:",
                                              data['location'] ?? "N/A",
                                              Colors.blue),
                                          const Divider(height: 25),
                                          _buildDetailHeader(
                                              "Device Information"),
                                          _buildInfoRow(
                                              Icons.phone_android,
                                              "Model:",
                                              data['model'] ?? "N/A",
                                              Colors.black87),
                                          _buildInfoRow(
                                              Icons.battery_std,
                                              "Battery:",
                                              data['battery'] ?? "N/A",
                                              Colors.black87),
                                          _buildInfoRow(
                                              Icons.wifi,
                                              "Network:",
                                              data['internet'] ?? "N/A",
                                              Colors.black87),
                                          const SizedBox(height: 10),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              _smallBadge(
                                                  "OS: ${data['os_version'] ?? 'N/A'}"),
                                              _smallBadge(
                                                  "Ver: ${data['app_version'] ?? 'N/A'}"),
                                            ],
                                          )
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
            ),
    );
  }

  // --- ዲዛይን ሰሪዎች (Helper Widgets) ---

  Widget _buildSummaryHeader(int count) {
    return Container(
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.indigo[900],
        borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.group, color: Colors.white, size: 28),
          const SizedBox(width: 15),
          Text("Total Active Users: $count",
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildDetailHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Text(title,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.indigo[900])),
      ),
    );
  }

  Widget _buildInfoRow(
      IconData icon, String label, String value, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 10),
          Text(label,
              style: const TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(width: 5),
          Expanded(
            child: Text(value,
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }

  Widget _smallBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          color: Colors.indigo[100], borderRadius: BorderRadius.circular(8)),
      child: Text(text,
          style: TextStyle(
              fontSize: 10,
              color: Colors.indigo[900],
              fontWeight: FontWeight.bold)),
    );
  }
}
