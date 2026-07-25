import sys
import re

with open('finara/lib/features/accounts/presentation/screens/add_account_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Add imports
imports = """import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
"""

content = content.replace("import 'package:flutter/material.dart';", imports + "import 'package:flutter/material.dart';")

# Add state variables
state_vars = """  final _nameController = TextEditingController();
  final _balanceController = TextEditingController(text: '0');
  AccountType _accountType = AccountType.bank;
  int _selectedColor = AppColors.categoryPalette[0].toARGB32();
  bool _isEditing = false;
  
  String? _customIcon;
  List<Map<String, dynamic>> _logoSuggestions = [];
  Timer? _debounce;
"""

old_state = """  final _nameController = TextEditingController();
  final _balanceController = TextEditingController(text: '0');
  AccountType _accountType = AccountType.bank;
  int _selectedColor = AppColors.categoryPalette[0].toARGB32();
  bool _isEditing = false;"""

content = content.replace(old_state, state_vars)

# Add listener and fetcher
init_code_old = """  void initState() {
    super.initState();
    if (widget.editAccountId != null) {"""

init_code_new = """  void initState() {
    super.initState();
    _nameController.addListener(_onNameChanged);
    if (widget.editAccountId != null) {"""

content = content.replace(init_code_old, init_code_new)

fetcher_code = """
  void _onNameChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      final query = _nameController.text.trim();
      if (query.length > 2) {
        _fetchLogoSuggestions(query);
      } else {
        setState(() => _logoSuggestions = []);
      }
    });
  }

  Future<void> _fetchLogoSuggestions(String query) async {
    try {
      final res = await http.get(Uri.parse('https://autocomplete.clearbit.com/v1/companies/suggest?query=$query'));
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        setState(() {
          _logoSuggestions = data.cast<Map<String, dynamic>>();
        });
      }
    } catch (e) {
      debugPrint('Failed to fetch logos: $e');
    }
  }
"""

content = content.replace('  Future<void> _loadAccount() async {', fetcher_code + '\n  Future<void> _loadAccount() async {')

# update load account
load_acc_old = """        _accountType = AccountType.values.firstWhere(
          (t) => t.name == account.type,
          orElse: () => AccountType.bank,
        );
        _selectedColor = account.color;"""

load_acc_new = """        _accountType = AccountType.values.firstWhere(
          (t) => t.name == account.type,
          orElse: () => AccountType.bank,
        );
        _selectedColor = account.color;
        _customIcon = account.icon;"""

content = content.replace(load_acc_old, load_acc_new)

# update save
save_old = """      type: Value(_accountType.name),
      icon: Value(_accountType.icon),"""
save_new = """      type: Value(_accountType.name),
      icon: Value(_customIcon ?? _accountType.icon),"""
content = content.replace(save_old, save_new)

# add dispose
disp_old = """  void dispose() {
    _nameController.dispose();"""
disp_new = """  void dispose() {
    _debounce?.cancel();
    _nameController.dispose();"""
content = content.replace(disp_old, disp_new)

# Add UI for picking icons
ui_old = """          // Account name
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Account Name',
              hintText: 'e.g. HDFC Savings',
            ),
            textCapitalization: TextCapitalization.words,
            autofocus: !_isEditing,
          ),
          const SizedBox(height: 20),"""

ui_new = """          // Account icon and name
          Row(
            children: [
              GestureDetector(
                onTap: () async {
                  final newIcon = await showDialog<String>(
                    context: context,
                    builder: (ctx) {
                      final c = TextEditingController();
                      return AlertDialog(
                        title: const Text('Custom Emoji'),
                        content: TextField(
                          controller: c,
                          maxLength: 2,
                          decoration: const InputDecoration(hintText: 'Enter an emoji'),
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                          FilledButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: const Text('OK')),
                        ],
                      );
                    }
                  );
                  if (newIcon != null && newIcon.isNotEmpty) {
                    setState(() => _customIcon = newIcon);
                  }
                },
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Color(_selectedColor).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Builder(
                      builder: (ctx) {
                        final iconStr = _customIcon ?? _accountType.icon;
                        if (iconStr.startsWith('http')) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: iconStr,
                              width: 36, height: 36,
                              errorWidget: (c, u, e) => Text(_accountType.icon, style: const TextStyle(fontSize: 28)),
                            ),
                          );
                        }
                        return Text(iconStr, style: const TextStyle(fontSize: 28));
                      }
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Account Name',
                    hintText: 'e.g. HDFC Savings',
                  ),
                  textCapitalization: TextCapitalization.words,
                  autofocus: !_isEditing,
                ),
              ),
            ],
          ),
          if (_logoSuggestions.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _logoSuggestions.length,
                itemBuilder: (context, index) {
                  final comp = _logoSuggestions[index];
                  final logo = comp['logo'];
                  final name = comp['name'];
                  if (logo == null) return const SizedBox.shrink();
                  
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _customIcon = logo;
                        _logoSuggestions = [];
                      });
                      FocusScope.of(context).unfocus();
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Theme.of(context).dividerColor),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(imageUrl: logo, width: 32, height: 32),
                          ),
                          const SizedBox(width: 8),
                          Text(name ?? '', style: AppTypography.labelSmall),
                          const SizedBox(width: 4),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 20),"""

content = content.replace(ui_old, ui_new)

# handle AccountType selection reset icon
reset_icon_old = """onSelected: (_) => setState(() => _accountType = type),"""
reset_icon_new = """onSelected: (_) => setState(() {
                  _accountType = type;
                  _customIcon = null; // reset to default
                }),"""
content = content.replace(reset_icon_old, reset_icon_new)

with open('finara/lib/features/accounts/presentation/screens/add_account_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Done")
