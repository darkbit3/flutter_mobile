import 'dart:async' show unawaited;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/theme/app_theme.dart';

class _ChatPerson {
  final String id;
  final String name;
  final String role;
  final String status;
  final String avatar;
  final Color color;

  const _ChatPerson({
    required this.id,
    required this.name,
    required this.role,
    required this.status,
    required this.avatar,
    required this.color,
  });

  factory _ChatPerson.fromJson(Map<String, dynamic> json) {
    final name = (json['name'] ?? 'Unknown').toString();
    final initials = name.split(RegExp(r'\s+')).where((part) => part.isNotEmpty).map((part) => part[0]).take(2).join().toUpperCase();
    return _ChatPerson(
      id: (json['id'] ?? '').toString(),
      name: name,
      role: (json['role'] ?? 'User').toString(),
      status: (json['status'] ?? 'Active').toString(),
      avatar: (json['avatar'] ?? initials).toString(),
      color: const Color(0xFF7C3AED),
    );
  }
}

class _ChatMessage {
  final String id;
  final String sender;
  final String text;
  final String time;

  const _ChatMessage({
    required this.id,
    required this.sender,
    required this.text,
    required this.time,
  });
}

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  bool _loadingPeople = true;
  bool _loadingMessages = false;
  String? _selectedPersonId;
  final List<_ChatPerson> _people = [];
  final Map<String, List<_ChatMessage>> _conversations = {};

  List<_ChatPerson> get _filteredPeople {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _people;
    return _people.where((person) {
      final haystack = '${person.name} ${person.role}'.toLowerCase();
      return haystack.contains(query);
    }).toList();
  }

  _ChatPerson? get _selectedPerson {
    if (_people.isEmpty) return null;
    if (_selectedPersonId == null) return _people.first;
    final found = _people.where((p) => p.id == _selectedPersonId);
    return found.isNotEmpty ? found.first : _people.first;
  }

  List<_ChatMessage> get _selectedMessages => _conversations[_selectedPersonId] ?? const [];

  @override
  void initState() {
    super.initState();
    _loadPeople();
  }

  Future<void> _loadPeople({String? search}) async {
    try {
      setState(() => _loadingPeople = true);
      final dio = ref.read(dioProvider);
      final res = await dio.get(
        ApiConstants.chatPeople,
        queryParameters: search == null || search.trim().isEmpty ? null : {'search': search.trim()},
      );
      final items = (res.data['data'] as List?) ?? const [];
      final nextPeople = items.map((item) => _ChatPerson.fromJson(item as Map<String, dynamic>)).toList();
      _people
        ..clear()
        ..addAll(nextPeople);
      if (_selectedPersonId == null && nextPeople.isNotEmpty) {
        _selectedPersonId = nextPeople.first.id;
      }
      if (_selectedPersonId != null && !nextPeople.any((person) => person.id == _selectedPersonId)) {
        _selectedPersonId = nextPeople.isNotEmpty ? nextPeople.first.id : null;
      }
      if (_selectedPersonId != null) {
        unawaited(_loadMessages(_selectedPersonId!));
      }
    } catch (_) {
      _people.clear();
      _selectedPersonId = null;
    } finally {
      if (mounted) setState(() => _loadingPeople = false);
    }
  }

  Future<void> _loadMessages(String personId) async {
    try {
      setState(() => _loadingMessages = true);
      final dio = ref.read(dioProvider);
      final res = await dio.get('${ApiConstants.chatMessages}/$personId');
      final items = (res.data['data'] as List?) ?? const [];
      final messages = <_ChatMessage>[];
      for (final item in items) {
        final message = item as Map<String, dynamic>;
        messages.add(_ChatMessage(
          id: (message['id'] ?? DateTime.now().millisecondsSinceEpoch.toString()).toString(),
          sender: (message['isMine'] == true) ? 'me' : 'them',
          text: (message['message'] ?? '').toString(),
          time: _formatDate(message['createdAt']),
        ));
      }
      _conversations[personId] = messages;
    } catch (_) {
      _conversations[personId] = const [];
    } finally {
      if (mounted) setState(() => _loadingMessages = false);
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    final person = _selectedPerson;
    if (message.isEmpty || person == null) return;

    try {
      final dio = ref.read(dioProvider);
      await dio.post(
        ApiConstants.chatSend,
        data: {'receiverId': person.id, 'message': message},
      );
      _messageController.clear();
      await _loadMessages(person.id);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send message. Please try again.')),
      );
    }
  }

  String _formatDate(dynamic value) {
    if (value == null || value.toString().isEmpty) return 'Now';
    final date = DateTime.tryParse(value.toString());
    if (date == null) return value.toString();
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _searchController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedPerson = _selectedPerson;
    final filteredPeople = _filteredPeople;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.dark,
        foregroundColor: AppColors.cream,
        elevation: 0,
        title: const Text('Chat'),
        centerTitle: false,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final useDesktop = constraints.maxWidth >= 900;

          return Row(
            children: [
              Container(
                width: useDesktop ? 320 : double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  border: Border(
                    right: useDesktop ? BorderSide(color: AppColors.border) : BorderSide.none,
                  ),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'People',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.dark,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.gold.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.search,
                              color: AppColors.gold,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          _loadPeople(search: value);
                        },
                        decoration: InputDecoration(
                          hintText: 'Search people',
                          prefixIcon: Icon(Icons.search, color: AppColors.textMid),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.gold),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    Expanded(
                      child: _loadingPeople
                          ? const Center(child: CircularProgressIndicator())
                          : filteredPeople.isEmpty
                              ? const Center(child: Text('No people found'))
                              : ListView.builder(
                                  itemCount: filteredPeople.length,
                                  itemBuilder: (context, index) {
                                    final person = filteredPeople[index];
                                    final isSelected = person.id == selectedPerson?.id;

                                    return InkWell(
                                      onTap: () {
                                        setState(() => _selectedPersonId = person.id);
                                        _loadMessages(person.id);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: isSelected ? AppColors.gold.withValues(alpha: 0.12) : Colors.transparent,
                                          border: Border(bottom: BorderSide(color: AppColors.border)),
                                        ),
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 22,
                                              backgroundColor: person.color,
                                              child: Text(
                                                person.avatar,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          person.name,
                                                          style: TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                            color: AppColors.dark,
                                                          ),
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                      Text(
                                                        person.status,
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          color: person.status == 'Active' || person.status == 'Online'
                                                              ? Colors.green.shade700
                                                              : AppColors.textMid,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    person.role,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: AppColors.textMid,
                                                    ),
                                                  ),
                                                ],
                                              ),
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

              Expanded(
                child: selectedPerson == null
                    ? const Center(child: Text('Select a person to start chatting'))
                    : Container(
                        color: Colors.white,
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              decoration: BoxDecoration(
                                border: Border(bottom: BorderSide(color: AppColors.border)),
                                color: Colors.white,
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: selectedPerson.color,
                                    child: Text(
                                      selectedPerson.avatar,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          selectedPerson.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.dark,
                                            fontSize: 18,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          selectedPerson.role,
                                          style: TextStyle(
                                            color: AppColors.textMid,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: selectedPerson.status == 'Active' || selectedPerson.status == 'Online'
                                          ? Colors.green.withValues(alpha: 0.12)
                                          : AppColors.background,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      selectedPerson.status,
                                      style: TextStyle(
                                        color: selectedPerson.status == 'Active' || selectedPerson.status == 'Online'
                                            ? Colors.green.shade700
                                            : AppColors.textMid,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            Expanded(
                              child: _loadingMessages
                                  ? const Center(child: CircularProgressIndicator())
                                  : ListView(
                                      padding: const EdgeInsets.all(16),
                                      children: [
                                        for (final message in _selectedMessages)
                                          Align(
                                            alignment: message.sender == 'me' ? Alignment.centerRight : Alignment.centerLeft,
                                            child: Container(
                                              margin: const EdgeInsets.only(bottom: 12),
                                              constraints: const BoxConstraints(maxWidth: 320),
                                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                              decoration: BoxDecoration(
                                                color: message.sender == 'me' ? AppColors.gold : AppColors.background,
                                                borderRadius: BorderRadius.only(
                                                  topLeft: const Radius.circular(16),
                                                  topRight: const Radius.circular(16),
                                                  bottomLeft: Radius.circular(message.sender == 'me' ? 16 : 4),
                                                  bottomRight: Radius.circular(message.sender == 'me' ? 4 : 16),
                                                ),
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    message.text,
                                                    style: TextStyle(
                                                      color: message.sender == 'me' ? Colors.white : AppColors.dark,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    message.time,
                                                    style: TextStyle(
                                                      color: message.sender == 'me' ? Colors.white70 : AppColors.textMid,
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                            ),

                            Container(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                              decoration: BoxDecoration(
                                border: Border(top: BorderSide(color: AppColors.border)),
                                color: Colors.white,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _messageController,
                                      decoration: InputDecoration(
                                        hintText: 'Type a message...',
                                        filled: true,
                                        fillColor: AppColors.background,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(14),
                                          borderSide: BorderSide(color: AppColors.border),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(14),
                                          borderSide: BorderSide(color: AppColors.border),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(14),
                                          borderSide: BorderSide(color: AppColors.gold),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  ElevatedButton(
                                    onPressed: _sendMessage,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.gold,
                                      foregroundColor: AppColors.dark,
                                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: const Text('Send'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
