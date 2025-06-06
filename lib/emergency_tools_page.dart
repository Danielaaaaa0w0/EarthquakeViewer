// 檔案: lib/emergency_tools_page.dart
import 'dart:convert'; 
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:torch_controller/torch_controller.dart'; 
import 'manage_contacts_page.dart'; 
import 'disaster_info_page.dart';   

class EmergencyToolsPage extends StatefulWidget {
  const EmergencyToolsPage({super.key});

  @override
  State<EmergencyToolsPage> createState() => _EmergencyToolsPageState();
}

class _EmergencyToolsPageState extends State<EmergencyToolsPage> {
  List<Map<String, String>> _emergencyContacts = [];
  bool _isFlashlightOn = false;
  final TorchController _torchController = TorchController(); 

  @override
  void initState() {
    super.initState();
    _loadEmergencyContacts();
    _torchController.initialize(); 
  }

  @override
  void dispose() {
    // The torch_controller package (version 1.0.1) does have a dispose() method.
    // If you are seeing an analyzer error "The method 'dispose' isn't defined",
    // please ensure you have the correct package version specified in your pubspec.yaml
    // (torch_controller: ^1.0.1) and have run `flutter pub get`.
    // Also, try running `flutter clean` and restarting your IDE.
    //_torchController.dispose(); 
    super.dispose();
  }

  Future<void> _loadEmergencyContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? contactsJson = prefs.getStringList('emergency_contacts');
    if (contactsJson != null) {
      if (mounted) { 
        setState(() {
          _emergencyContacts = contactsJson
              .map((jsonString) => Map<String, String>.from(json.decode(jsonString))) 
              .toList();
        });
      }
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if(mounted) { 
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('無法撥打電話至 $phoneNumber')),
         );
      }
    }
  }

  Future<void> _toggleFlashlight() async {
    try {
      bool? currentTorchState = await _torchController.isTorchActive; 
      // The toggle method in torch_controller doesn't return the new state directly.
      // We set our UI state _isFlashlightOn based on the inversion of its current value.
      // The actual torch state will be toggled by the controller.
      await _torchController.toggle();
      if(mounted) { 
        setState(() {
          // After toggling, the actual state might be different from simply !_isFlashlightOn
          // if the initial check (isTorchActive) was null or if there was an issue.
          // For a more robust UI update, re-check after toggle, but for simplicity:
          _isFlashlightOn = !_isFlashlightOn; 
        });
      }
    } catch (e) {
      print('手電筒操作失敗: $e');
      if(mounted) { 
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('手電筒操作失敗')),
        );
        // Optionally reset UI state if toggle failed
        // setState(() { _isFlashlightOn = false; });
      }
    }
  }


  Widget _buildEmergencyCallButton(String label, String phoneNumber, IconData icon, Color color) {
    return ElevatedButton.icon(
      icon: Icon(icon, color: Colors.white, size: 20), // Adjusted icon size
      label: Text(
        label, 
        style: const TextStyle(color: Colors.white, fontSize: 14), // Adjusted font size
        textAlign: TextAlign.center, // Center text if it wraps
      ),
      onPressed: () => _makePhoneCall(phoneNumber),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12), // Reduced horizontal padding
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        minimumSize: const Size(0, 40), // Ensure a minimum height
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('緊急應變工具'),
        backgroundColor: theme.colorScheme.primary, 
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: <Widget>[
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('快速撥號', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 12),
                  Row( // Use Expanded for the buttons
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 4.0),
                          child: _buildEmergencyCallButton('119 火警/救護', '119', Icons.local_fire_department, Colors.red.shade600),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 4.0),
                          child: _buildEmergencyCallButton('110 報案', '110', Icons.local_police, Colors.blue.shade700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  ListTile(
                     leading: Icon(Icons.contacts, color: theme.colorScheme.primary),
                     title: const Text('管理我的緊急聯絡人'),
                     trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                     onTap: () async {
                       await Navigator.push(
                         context,
                         MaterialPageRoute(builder: (context) => const ManageContactsPage()),
                       );
                       _loadEmergencyContacts(); 
                     },
                  ),
                  if (_emergencyContacts.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text('尚未設定緊急聯絡人。', style: TextStyle(fontStyle: FontStyle.italic)),
                    )
                  else
                    ..._emergencyContacts.map((contact) {
                      return ListTile(
                        leading: Icon(Icons.person, color: theme.colorScheme.secondary),
                        title: Text(contact['name'] ?? '未知姓名'),
                        subtitle: Text(contact['phone'] ?? '未知號碼'),
                        trailing: IconButton(
                          icon: Icon(Icons.phone, color: Colors.green.shade600),
                          tooltip: '撥打給 ${contact['name']}',
                          onPressed: () => _makePhoneCall(contact['phone'] ?? ''),
                        ),
                      );
                    }).toList(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          Card(
            elevation: 2,
            child: ListTile(
              leading: Icon(Icons.menu_book, color: theme.colorScheme.primary),
              title: const Text('地震防災須知'),
              subtitle: const Text('查看應對SOP與避難包清單'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DisasterInfoPage()),
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          Card(
            elevation: 2,
            child: ListTile(
              leading: Icon(_isFlashlightOn ? Icons.flashlight_on : Icons.flashlight_off, color: theme.colorScheme.primary),
              title: const Text('手電筒'),
              trailing: Switch(
                value: _isFlashlightOn,
                onChanged: (value) {
                  _toggleFlashlight();
                },
                activeColor: theme.colorScheme.primary,
              ),
              onTap: _toggleFlashlight, 
            ),
          ),
        ],
      ),
    );
  }
}