import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';

class _ChatPerson {
  final int id;
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

  final List<_ChatPerson> _people = const [
    _ChatPerson(
      id: 1,
      name: 'Nadia Rahman',
      role: 'Manufacturer',
      status: 'Online',
      avatar: 'NR',
      color: AppColors.gold,
    ),
    _ChatPerson(
      id: 2,
      name: 'Samuel Bekele',
      role: 'Cashier',
      status: 'Away',
      avatar: 'SB',
      color: Color(0xFF7C5E4B),
    ),
    _ChatPerson(
      id: 3,
      name: 'Mihret Yisak',
      role: 'Reseller',
      status: 'Online',
      avatar: 'MY',
      color: Color(0xFF4D7C6A),
    ),
    _ChatPerson(
      id: 4,
      name: 'Selam Hailu',
      role: 'Admin',
      status: 'Offline',
      avatar: 'SH',
      color: Color(0xFF7B8FA1),
    ),
    _ChatPerson(
      id: 5,
      name: 'Abel Tadesse',
      role: 'Support',
      status: 'Online',
      avatar: 'AT',
      color: Color(0xFFA56A6A),
    ),
  ];

  final Map<int, List<_ChatMessage>> _conversations = const {
    1: [
      _ChatMessage(id: '1', sender: 'them', text: 'Hi, can we confirm the leather order for tomorrow?', time: '09:12 AM'),
      _ChatMessage(id: '2', sender: 'me', text: 'Yes, we have 4 rolls ready for dispatch.', time: '09:14 AM'),
      _ChatMessage(id: '3', sender: 'them', text: 'Perfect, I will send the driver details shortly.', time: '09:15 AM'),
    ],
    2: [
      _ChatMessage(id: '1', sender: 'them', text: 'The sales report has been uploaded.', time: '08:40 AM'),
      _ChatMessage(id: '2', sender: 'me', text: 'Thanks, I will review it before lunch.', time: '08:41 AM'),
    ],
    3: [
      _ChatMessage(id: '1', sender: 'them', text: 'We are running low on packaging materials.', time: 'Yesterday'),
      _ChatMessage(id: '2', sender: 'me', text: 'I will check the stock level and update you.', time: 'Yesterday'),
    ],
    4: [
      _ChatMessage(id: '1', sender: 'them', text: 'Please review the monthly inventory summary.', time: 'Mon'),
    ],
    5: [
      _ChatMessage(id: '1', sender: 'them', text: 'The customer issue is now resolved.', time: 'Sun'),
      _ChatMessage(id: '2', sender: 'me', text: 'Great, thanks for the quick follow-up.', time: 'Sun'),
    ],
  };

  int _selectedPersonId = 1;

  List<_ChatPerson> get _filteredPeople {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _people;
    return _people.where((person) {
      final haystack = '${person.name} ${person.role}'.toLowerCase();
      return haystack.contains(query);
    }).toList();
  }

  _ChatPerson get _selectedPerson {
    final list = _filteredPeople;
    for (final person in list) {
      if (person.id == _selectedPersonId) return person;
    }
    return _people.firstWhere((person) => person.id == _selectedPersonId, orElse: () => _people.first);
  }

  List<_ChatMessage> get _selectedMessages => _conversations[_selectedPerson.id] ?? const [];

  @override
  void dispose() {
    _searchController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    final current = [..._selectedMessages, _ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sender: 'me',
      text: message,
      time: 'Now',
    )];

    _messageController.clear();
    setState(() {
      _conversations[_selectedPerson.id] = current;
    });
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
                        onChanged: (_) => setState(() {}),
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
                      child: filteredPeople.isEmpty
                          ? const Center(
                              child: Text('No people found'),
                            )
                          : ListView.builder(
                              itemCount: filteredPeople.length,
                              itemBuilder: (context, index) {
                                final person = filteredPeople[index];
                                final isSelected = person.id == selectedPerson.id;

                                return InkWell(
                                  onTap: () {
                                    setState(() => _selectedPersonId = person.id);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: isSelected ? AppColors.gold.withValues(alpha: 0.12) : Colors.transparent,
                                      border: Border(
                                        bottom: BorderSide(color: AppColors.border),
                                      ),
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
                                                      color: person.status == 'Online'
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
                child: Container(
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
                                color: selectedPerson.status == 'Online'
                                    ? Colors.green.withValues(alpha: 0.12)
                                    : AppColors.background,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                selectedPerson.status,
                                style: TextStyle(
                                  color: selectedPerson.status == 'Online' ? Colors.green.shade700 : AppColors.textMid,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      Expanded(
                        child: ListView(
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
                                    color: message.sender == 'me'
                                        ? AppColors.gold
                                        : AppColors.background,
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
