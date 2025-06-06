// 檔案: lib/manage_contacts_page.dart
// (新增檔案)
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // For jsonEncode and jsonDecode

class ManageContactsPage extends StatefulWidget {
  const ManageContactsPage({super.key});

  @override
  State<ManageContactsPage> createState() => _ManageContactsPageState();
}

class _ManageContactsPageState extends State<ManageContactsPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  List<Map<String, String>> _emergencyContacts = [];
  int? _editingIndex; // 用於記錄正在編輯的聯絡人索引

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? contactsJson = prefs.getStringList('emergency_contacts');
    if (contactsJson != null) {
      if(mounted){
        setState(() {
          _emergencyContacts = contactsJson
              .map((jsonString) => Map<String, String>.from(json.decode(jsonString)))
              .toList();
        });
      }
    }
  }

  Future<void> _saveContacts() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> contactsJson =
        _emergencyContacts.map((contact) => json.encode(contact)).toList();
    await prefs.setStringList('emergency_contacts', contactsJson);
  }

  void _addOrUpdateContact() {
    if (_formKey.currentState!.validate()) {
      final newContact = {
        'name': _nameController.text,
        'phone': _phoneController.text,
      };
      if(mounted){
        setState(() {
          if (_editingIndex != null) {
            _emergencyContacts[_editingIndex!] = newContact;
            _editingIndex = null; // 重置編輯狀態
          } else {
            if (_emergencyContacts.length < 3) { // 最多3個聯絡人
              _emergencyContacts.add(newContact);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('最多只能新增3位緊急聯絡人')),
              );
              return; // 不新增也不清除輸入框
            }
          }
          _nameController.clear();
          _phoneController.clear();
        });
      }
      _saveContacts();
    }
  }

  void _editContact(int index) {
    if(mounted){
      setState(() {
        _editingIndex = index;
        _nameController.text = _emergencyContacts[index]['name']!;
        _phoneController.text = _emergencyContacts[index]['phone']!;
      });
    }
  }

  void _deleteContact(int index) {
    if(mounted){
      setState(() {
        _emergencyContacts.removeAt(index);
        if (_editingIndex == index) { // 如果正在編輯的被刪除了
            _editingIndex = null;
            _nameController.clear();
            _phoneController.clear();
        } else if (_editingIndex != null && _editingIndex! > index) { // 如果刪除了前面的，更新編輯索引
            _editingIndex = _editingIndex! - 1;
        }
      });
    }
    _saveContacts();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('管理緊急聯絡人'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: '姓名'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '請輸入姓名';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(labelText: '電話號碼'),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '請輸入電話號碼';
                      }
                      // 可以加入更嚴格的電話號碼格式驗證
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _addOrUpdateContact,
                    child: Text(_editingIndex != null ? '更新聯絡人' : '新增聯絡人'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Divider(),
            Text('已設定聯絡人 (最多3位)', style: theme.textTheme.titleMedium),
            Expanded(
              child: _emergencyContacts.isEmpty
                  ? const Center(child: Text('尚未新增任何緊急聯絡人。'))
                  : ListView.builder(
                      itemCount: _emergencyContacts.length,
                      itemBuilder: (context, index) {
                        final contact = _emergencyContacts[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4.0),
                          child: ListTile(
                            leading: Icon(Icons.person_outline, color: theme.colorScheme.secondary),
                            title: Text(contact['name']!),
                            subtitle: Text(contact['phone']!),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit, color: Colors.orange.shade700),
                                  onPressed: () => _editContact(index),
                                  tooltip: '編輯',
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red.shade700),
                                  onPressed: () => _deleteContact(index),
                                  tooltip: '刪除',
                                ),
                              ],
                            ),
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
}