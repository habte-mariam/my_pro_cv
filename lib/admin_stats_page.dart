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
  bool _isAccessDenied = false;
  List<Map<String, dynamic>> _userLogs = [];
  List<Map<String, dynamic>> _filteredLogs = [];
  final TextEditingController _searchController = TextEditingController();

  // 🎯 የአድሚን ኢሜይል
  final String _adminEmail = "habtiet96@gmail.com";

  @override
  void initState() {
    super.initState();
    _checkAccessAndFetchLogs();
  }

  Future<void> _checkAccessAndFetchLogs() async {
    final user = _supabase.auth.currentUser;
    if (user?.email != _adminEmail) {
      setState(() {
        _isAccessDenied = true;
        _isLoading = false;
      });
      return;
    }
    _fetchUserLogs();
  }

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
          _filteredLogs = _userLogs;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching logs: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _runFilter(String enteredKeyword) {
    List<Map<String, dynamic>> results = [];
    if (enteredKeyword.isEmpty) {
      results = _userLogs;
    } else {
      results = _userLogs
          .where((user) =>
              (user["email"] ?? "")
                  .toLowerCase()
                  .contains(enteredKeyword.toLowerCase()) ||
              (user["name"] ?? "")
                  .toLowerCase()
                  .contains(enteredKeyword.toLowerCase()) ||
              (user["model"] ?? "")
                  .toLowerCase()
                  .contains(enteredKeyword.toLowerCase()))
          .toList();
    }
    setState(() {
      _filteredLogs = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isAccessDenied) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 80, color: Colors.red),
              const SizedBox(height: 16),
              const Text("Access Denied",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const Text("Only Habtie can access this dashboard."),
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Go Back"))
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text("Admin Analytics",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.indigo[900],
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh), onPressed: _fetchUserLogs),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildSummaryHeader(_filteredLogs.length),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => _runFilter(value),
                    decoration: InputDecoration(
                      hintText: "Search user, email or device...",
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                    ),
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _fetchUserLogs,
                    child: _filteredLogs.isEmpty
                        ? const Center(child: Text("No users found."))
                        : ListView.builder(
                            itemCount: _filteredLogs.length,
                            padding: const EdgeInsets.only(bottom: 20),
                            itemBuilder: (context, index) {
                              var data = _filteredLogs[index];
                              String formattedDate =
                                  _formatDate(data['last_seen']);

                              return Card(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 6),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                child: ExpansionTile(
                                  leading: CircleAvatar(
                                    backgroundColor:
                                        data['email'] == 'guest_user'
                                            ? Colors.grey[300]
                                            : Colors.indigo[100],
                                    child: Icon(Icons.person,
                                        color: Colors.indigo[900]),
                                  ),
                                  title: Text(
                                    data['email'] == 'guest_user'
                                        ? "Guest User"
                                        : (data['email'] ?? "Unknown"),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text("Last Active: $formattedDate",
                                      style: const TextStyle(fontSize: 12)),
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      color: Colors.grey[50],
                                      child: Column(
                                        children: [
                                          _buildDetailHeader(
                                              "Location & Device"),
                                          _buildInfoRow(
                                              Icons.gps_fixed,
                                              "GPS:",
                                              data['real_gps_location'] ??
                                                  "Not Detected",
                                              Colors.green),
                                          _buildInfoRow(
                                              Icons.public,
                                              "IP/Location:",
                                              data['location'] ?? "N/A",
                                              Colors.blue),
                                          _buildInfoRow(
                                              Icons.phone_android,
                                              "Model:",
                                              data['model'] ?? "N/A",
                                              Colors.black87),
                                          _buildInfoRow(
                                              Icons.battery_std,
                                              "Battery:",
                                              data['battery'] ?? "N/A",
                                              Colors.orange),
                                          const SizedBox(height: 10),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              _smallBadge(
                                                  "OS: ${data['os_version'] ?? 'N/A'}"),
                                              _smallBadge(
                                                  "App Ver: ${data['app_version'] ?? 'N/A'}"),
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
                ),
              ],
            ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return "Unknown";
    try {
      DateTime date = DateTime.parse(dateStr).toLocal();
      return DateFormat('MMM d, hh:mm a').format(date);
    } catch (e) {
      return "Invalid Date";
    }
  }

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
          const Icon(Icons.analytics, color: Colors.white, size: 28),
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
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 10),
          Text(label,
              style: const TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(width: 5),
          Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.right)),
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
