import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/localization/language_provider.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/notifications/local_notification_service.dart';
import '../../../core/theme/app_theme.dart';

class _ChatPerson {
  const _ChatPerson({required this.id, required this.name, required this.role, required this.status, required this.avatar});
  final String id;
  final String name;
  final String role;
  final String status;
  final String avatar;

  factory _ChatPerson.fromJson(Map<String, dynamic> json) {
    final name = (json['name'] ?? 'Unknown').toString();
    final avatar = name.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).map((p) => p[0]).take(2).join().toUpperCase();
    return _ChatPerson(
      id: (json['id'] ?? '').toString(),
      name: name,
      role: (json['role'] ?? 'User').toString(),
      status: (json['status'] ?? 'Active').toString(),
      avatar: avatar.isEmpty ? 'U' : avatar,
    );
  }
}

String _displayBusinessRole(String role) {
  if (role == 'Manufacturer') return 'Garment and Boutique';
  if (role == 'Reseller') return 'Textile and Accessory';
  return role;
}

class _ChatCategory {
  const _ChatCategory({required this.id, required this.name, this.imageUrl});
  final String id;
  final String name;
  final String? imageUrl;

  factory _ChatCategory.fromJson(Map<String, dynamic> json) => _ChatCategory(
        id: (json['id'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
        imageUrl: json['image_url']?.toString(),
      );
}

class _ChatGroup {
  const _ChatGroup({required this.id, required this.name, required this.description, required this.memberCount, required this.categories});
  final String id;
  final String name;
  final String description;
  final int memberCount;
  final List<_ChatCategory> categories;

  factory _ChatGroup.fromJson(Map<String, dynamic> json) => _ChatGroup(
        id: (json['id'] ?? '').toString(),
        name: (json['name'] ?? 'Group').toString(),
        description: (json['description'] ?? '').toString(),
        memberCount: int.tryParse('${json['memberCount'] ?? 0}') ?? 0,
        categories: ((json['categories'] as List?) ?? [])
            .map((c) => _ChatCategory.fromJson(c as Map<String, dynamic>))
            .toList(),
      );
}

class _ChatMessage {
  const _ChatMessage({
    required this.id,
    required this.sender,
    required this.text,
    required this.time,
    this.senderRole,
    this.imageUrl,
    this.phoneNumber,
  });
  final String id;
  final String sender;
  final String text;
  final String time;
  final String? senderRole;
  final String? imageUrl;
  final String? phoneNumber;
}

enum _ChatTab { people, groups }

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _searchController = TextEditingController();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatPerson> _people = [];
  final List<_ChatGroup> _groups = [];
  final Map<String, List<_ChatMessage>> _messages = {};
  final Set<String> _initializedConversations = {};
  _ChatTab _tab = _ChatTab.people;
  String? _selectedPersonId;
  String? _selectedGroupId;
  bool _loadingList = true;
  bool _loadingMessages = false;
  bool _sending = false;
  bool _picking = false;
  bool _showConversation = false;
  File? _pendingImage;        // image picked but not yet sent
  final _phoneNumberCtr = TextEditingController(); // phone for image post
  Timer? _poller;

  _ChatPerson? get _person => _people.where((item) => item.id == _selectedPersonId).firstOrNull;
  _ChatGroup? get _group => _groups.where((item) => item.id == _selectedGroupId).firstOrNull;
  String? get _selectedId => _selectedGroupId ?? _selectedPersonId;
  List<_ChatMessage> get _activeMessages => _messages[_selectedId] ?? const [];

  @override
  void initState() {
    super.initState();
    _loadPeople();
    _loadGroups();
    _poller = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadPeople();
      _loadGroups();
      if (_selectedGroupId != null) _loadGroupMessages(_selectedGroupId!);
      if (_selectedPersonId != null) _loadPersonMessages(_selectedPersonId!);
    });
  }

  Future<void> _loadPeople() async {
    try {
      if (mounted) setState(() => _loadingList = true);
      final res = await ref.read(dioProvider).get(ApiConstants.chatPeople);
      final items = (res.data['data'] as List?) ?? const [];
      _people
        ..clear()
        ..addAll(items.map((item) => _ChatPerson.fromJson(item as Map<String, dynamic>)));
      if (_selectedPersonId != null && !_people.any((person) => person.id == _selectedPersonId)) {
        _selectedPersonId = null;
        _messages.removeWhere((key, _) => key != _selectedGroupId);
        _showConversation = false;
      }
      if (_selectedPersonId == null && _selectedGroupId == null && _people.isNotEmpty) {
        _selectedPersonId = _people.first.id;
      }
    } catch (_) {
      _people.clear();
    } finally {
      if (mounted) setState(() => _loadingList = false);
    }
  }

  Future<void> _loadGroups() async {
    try {
      final res = await ref.read(dioProvider).get(ApiConstants.chatGroups);
      final items = (res.data['data'] as List?) ?? const [];
      _groups
        ..clear()
        ..addAll(items.map((item) => _ChatGroup.fromJson(item as Map<String, dynamic>)));
      if (_selectedGroupId != null && !_groups.any((group) => group.id == _selectedGroupId)) {
        _selectedGroupId = null;
        _messages.removeWhere((key, _) => key != _selectedPersonId);
        _showConversation = false;
      }
    } catch (_) {
      _groups.clear();
    } finally {
      if (mounted) setState(() {});
    }
  }

  Future<void> _loadPersonMessages(String personId) async {
    try {
      if (mounted) setState(() => _loadingMessages = true);
      final res = await ref.read(dioProvider).get('${ApiConstants.chatMessages}/$personId');
      final previous = _messages[personId] ?? const <_ChatMessage>[];
      final messages = _parseMessages(res.data['data'] as List?);
      _notifyForNewMessages(
        conversationId: personId,
        previous: previous,
        messages: messages,
        senderName: _person?.name ?? 'your contact',
      );
      _messages[personId] = messages;
    } catch (_) {
      // Keep the last successful response so a temporary network failure does
      // not make the next poll treat the whole conversation as new.
    } finally {
      if (mounted) setState(() => _loadingMessages = false);
    }
  }

  Future<void> _loadGroupMessages(String groupId) async {
    try {
      if (mounted) setState(() => _loadingMessages = true);
      final res = await ref.read(dioProvider).get('${ApiConstants.chatGroups}/$groupId/messages');
      final previous = _messages[groupId] ?? const <_ChatMessage>[];
      final messages = _parseMessages(res.data['data'] as List?);
      _notifyForNewMessages(
        conversationId: groupId,
        previous: previous,
        messages: messages,
        senderName: _group?.name ?? 'your group',
      );
      _messages[groupId] = messages;
    } catch (_) {
      // Keep the last successful response so a temporary network failure does
      // not make the next poll treat the whole conversation as new.
    } finally {
      if (mounted) setState(() => _loadingMessages = false);
    }
  }

  void _notifyForNewMessages({
    required String conversationId,
    required List<_ChatMessage> previous,
    required List<_ChatMessage> messages,
    required String senderName,
  }) {
    if (!_initializedConversations.contains(conversationId)) {
      _initializedConversations.add(conversationId);
      return;
    }

    final previousIds = previous.map((message) => message.id).toSet();
    for (final message in messages) {
      if (message.sender != 'me' && !previousIds.contains(message.id)) {
        unawaited(LocalNotificationService.instance.showChatMessage(
          sender: senderName,
          message: message.text,
        ));
      }
    }
  }

  List<_ChatMessage> _parseMessages(List? raw) => (raw ?? const []).map((item) {
        final message = item as Map<String, dynamic>;
        return _ChatMessage(
          id: (message['id'] ?? DateTime.now().microsecondsSinceEpoch).toString(),
          sender: message['isMine'] == true ? 'me' : 'them',
          text: (message['message'] ?? '').toString(),
          time: _formatTime(message['createdAt']),
          senderRole: message['senderRole']?.toString(),
          imageUrl: message['imageUrl']?.toString(),
          phoneNumber: message['phoneNumber']?.toString(),
        );
      }).toList();

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    final person = _person;
    final group = _group;
    final image = _pendingImage;
    final phone = _phoneNumberCtr.text.trim();

    // Must have text OR image
    if ((text.isEmpty && image == null) || _sending || (person == null && group == null)) return;

    final id = group?.id ?? person!.id;
    _messageController.clear();

    // Convert image to base64 data URL if present
    String? imageUrl;
    if (image != null) {
      final bytes = await image.readAsBytes();
      final b64 = base64Encode(bytes);
      final ext = image.path.split('.').last.toLowerCase();
      final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
      imageUrl = 'data:$mime;base64,$b64';
    }

    setState(() {
      _sending = true;
      _pendingImage = null;
      _phoneNumberCtr.clear();
      _messages[id] = [
        ...(_activeMessages),
        _ChatMessage(
          id: 'temp-${DateTime.now().microsecondsSinceEpoch}',
          sender: 'me',
          text: text,
          time: _formatTime(DateTime.now().toIso8601String()),
          imageUrl: imageUrl,
          phoneNumber: phone.isEmpty ? null : phone,
        ),
      ];
    });

    try {
      if (group != null) {
        await ref.read(dioProvider).post(
          '${ApiConstants.chatGroups}/${group.id}/send',
          data: {
            'message': text,
            if (imageUrl != null) 'image_url': imageUrl,
            if (phone.isNotEmpty) 'phone_number': phone,
          },
        );
        await _loadGroupMessages(group.id);
      } else {
        await ref.read(dioProvider).post(
          ApiConstants.chatSend,
          data: {'receiverId': person!.id, 'message': text},
        );
        await _loadPersonMessages(person.id);
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Message could not be sent.')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _pickImage() async {
    setState(() => _picking = true);
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70, maxWidth: 1024);
      if (picked == null) return;
      setState(() => _pendingImage = File(picked.path));
      // Show phone number dialog for group context
      if (_group != null && mounted) {
        _showPhoneNumberDialog();
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  void _showPhoneNumberDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Phone Number', style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: _phoneNumberCtr,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            hintText: 'e.g. 0912345678 (optional)',
            prefixIcon: Icon(Icons.phone_outlined),
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () { _phoneNumberCtr.clear(); Navigator.of(ctx).pop(); },
            child: const Text('Skip'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  String _formatTime(dynamic value) {
    final date = DateTime.tryParse('${value ?? ''}');
    if (date == null) return 'Now';
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _selectPerson(String id) {
    setState(() {
      _selectedPersonId = id;
      _selectedGroupId = null;
      _showConversation = true;
    });
    unawaited(_loadPersonMessages(id));
  }

  void _selectGroup(String id) {
    setState(() {
      _selectedGroupId = id;
      _selectedPersonId = null;
      _showConversation = true;
    });
    unawaited(_loadGroupMessages(id));
  }

  @override
  void dispose() {
    _poller?.cancel();
    _searchController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    _phoneNumberCtr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = AppText(ref.watch(languageProvider));
    final isDesktop = MediaQuery.sizeOf(context).width >= 850;
    final selectedName = _group?.name ?? _person?.name;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(text.chat),
        backgroundColor: AppColors.dark,
        foregroundColor: AppColors.cream,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: isDesktop
            ? Row(children: [SizedBox(width: 330, child: _listPanel(text)), const SizedBox(width: 12), Expanded(child: _conversationPanel(text, selectedName))])
            : (_showConversation ? _conversationPanel(text, selectedName) : _listPanel(text)),
      ),
    );
  }

  Widget _listPanel(AppText text) {
    final query = _searchController.text.toLowerCase();
    final people = _people.where((p) => '${p.name} ${p.role}'.toLowerCase().contains(query)).toList();
    final groups = _groups.where((g) => '${g.name} ${g.description}'.toLowerCase().contains(query)).toList();
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.border)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Row(children: [Expanded(child: Text(text.chat, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.dark))), IconButton(onPressed: _loadGroups, icon: const Icon(Icons.refresh_rounded, color: AppColors.gold))]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(hintText: text.isAmharic ? 'ፈልግ' : 'Search people or groups', prefixIcon: const Icon(Icons.search), suffixIcon: _searchController.text.isEmpty ? null : IconButton(onPressed: () { _searchController.clear(); setState(() {}); }, icon: const Icon(Icons.clear))),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<_ChatTab>(
              segments: [ButtonSegment(value: _ChatTab.people, label: Text(text.isAmharic ? 'ሰዎች' : 'People'), icon: const Icon(Icons.person_outline)), ButtonSegment(value: _ChatTab.groups, label: Text(text.isAmharic ? 'ቡድኖች' : 'Groups'), icon: const Icon(Icons.groups_outlined))],
              selected: {_tab},
              onSelectionChanged: (value) => setState(() => _tab = value.first),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loadingList
                ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
                : _tab == _ChatTab.people
                    ? (people.isEmpty ? _empty(text.isAmharic ? 'ሰው አልተገኘም' : 'No people found') : ListView(children: people.map(_personTile).toList()))
                    : (groups.isEmpty ? _empty(text.isAmharic ? 'የተመዘገበ ቡድን የለም' : 'No available groups') : ListView(children: groups.map(_groupTile).toList())),
          ),
        ],
      ),
    );
  }

  Widget _personTile(_ChatPerson person) => ListTile(
        selected: person.id == _selectedPersonId,
        selectedTileColor: AppColors.goldLight,
        leading: CircleAvatar(backgroundColor: AppColors.dark, child: Text(person.avatar, style: const TextStyle(color: Colors.white, fontSize: 12))),
        title: Row(
          children: [
            Expanded(
              child: Text(person.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            if (person.role == 'Manufacturer' || person.role == 'Reseller') ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: person.role == 'Manufacturer'
                      ? AppColors.gold.withValues(alpha: 0.16)
                      : AppColors.success.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  person.role == 'Manufacturer' ? 'MA' : 'RE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: person.role == 'Manufacturer' ? AppColors.gold : AppColors.success,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(_displayBusinessRole(person.role)),
        trailing: Icon(person.status == 'Active' ? Icons.circle : Icons.circle_outlined, size: 10, color: person.status == 'Active' ? AppColors.success : AppColors.textLight),
        onTap: () => _selectPerson(person.id),
      );

  Widget _groupTile(_ChatGroup group) => ListTile(
        selected: group.id == _selectedGroupId,
        selectedTileColor: const Color(0xFFECFDF5),
        leading: const CircleAvatar(backgroundColor: AppColors.success, child: Icon(Icons.groups_rounded, color: Colors.white)),
        title: Text(group.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          group.categories.isNotEmpty
              ? '${group.categories.length} categor${group.categories.length == 1 ? 'y' : 'ies'}'
              : group.description.isEmpty ? '${group.memberCount} members' : group.description,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text('${group.memberCount}', style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
        onTap: () => _selectGroup(group.id),
      );

  Widget _empty(String label) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(label, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMid))));

  Widget _conversationPanel(AppText text, String? name) {
    final group = _group;
    final person = _person;
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.border)),
      child: Column(
        children: [
          if (!MediaQuery.sizeOf(context).width.isFinite || MediaQuery.sizeOf(context).width < 850)
            Align(alignment: Alignment.centerLeft, child: IconButton(onPressed: () => setState(() => _showConversation = false), icon: const Icon(Icons.arrow_back))),
          if (name == null)
            Expanded(child: _empty(text.isAmharic ? 'ውይይት ለመጀመር ቡድን ወይም ሰው ይምረጡ' : 'Select a person or group to start chatting'))
          else ...[
            ListTile(
              leading: CircleAvatar(backgroundColor: group != null ? AppColors.success : AppColors.dark, child: Icon(group != null ? Icons.groups_rounded : Icons.person, color: Colors.white)),
              title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(group != null ? '${group.memberCount} members' : person?.role ?? ''),
            ),
            const Divider(height: 1),
            // Category chips (read-only, for groups)
            if (group != null && group.categories.isNotEmpty)
              Container(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                decoration: const BoxDecoration(
                  color: Color(0xFFF0FDF4),
                  border: Border(bottom: BorderSide(color: Color(0xFFD1FAE5))),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: group.categories.map((cat) => Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFD1FAE5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (cat.imageUrl != null)
                            Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: ClipOval(
                                child: Image.network(
                                  cat.imageUrl!,
                                  width: 14,
                                  height: 14,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                                ),
                              ),
                            ),
                          Text(cat.name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF047857))),
                        ],
                      ),
                    )).toList(),
                  ),
                ),
              ),
            Expanded(
              child: _loadingMessages
                  ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
                  : _activeMessages.isEmpty
                      ? _empty(text.isAmharic ? 'ውይይቱን ይጀምሩ' : 'Start the conversation')
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: _activeMessages.length,
                          itemBuilder: (_, index) {
                            final message = _activeMessages[index];
                            final mine = message.sender == 'me';
                            final hasImage = message.imageUrl != null && message.imageUrl!.isNotEmpty;
                            final hasPhone = message.phoneNumber != null && message.phoneNumber!.isNotEmpty;
                            final hasText = message.text.isNotEmpty;
                            return Align(
                              alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                              child: Container(
                                constraints: const BoxConstraints(maxWidth: 300),
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: mine ? AppColors.dark : AppColors.background,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // sender label in group
                                    if (group != null && !mine)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 4),
                                        child: Text(
                                          message.senderRole ?? 'Member',
                                          style: const TextStyle(fontSize: 10, color: AppColors.textMid),
                                        ),
                                      ),
                                    // image
                                    if (hasImage) ...[
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: message.imageUrl!.startsWith('data:')
                                            ? Image.memory(
                                                base64Decode(message.imageUrl!.split(',').last),
                                                width: 220,
                                                fit: BoxFit.cover,
                                              )
                                            : Image.network(
                                                message.imageUrl!,
                                                width: 220,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                                              ),
                                      ),
                                      const SizedBox(height: 6),
                                    ],
                                    // phone number badge
                                    if (hasPhone)
                                      Container(
                                        margin: const EdgeInsets.only(bottom: 4),
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: mine
                                              ? Colors.white.withValues(alpha: 0.15)
                                              : AppColors.gold.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.phone_outlined,
                                              size: 11,
                                              color: mine ? Colors.white70 : AppColors.gold,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              message.phoneNumber!,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: mine ? Colors.white : AppColors.gold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    // text
                                    if (hasText)
                                      Text(
                                        message.text,
                                        style: TextStyle(color: mine ? Colors.white : AppColors.dark),
                                      ),
                                    const SizedBox(height: 4),
                                    Text(
                                      message.time,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: mine ? Colors.white70 : AppColors.textMid,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Pending image preview ───────────────────────────────
                  if (_pendingImage != null && group != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.goldLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(_pendingImage!, width: 56, height: 56, fit: BoxFit.cover),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Image ready to send', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                if (_phoneNumberCtr.text.isNotEmpty)
                                  Text(_phoneNumberCtr.text, style: const TextStyle(fontSize: 11, color: AppColors.textMid)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18, color: Colors.red),
                            onPressed: () => setState(() { _pendingImage = null; _phoneNumberCtr.clear(); }),
                          ),
                        ],
                      ),
                    ),
                  // ── Input row ───────────────────────────────────────────
                  Row(
                    children: [
                      if (group != null)
                        IconButton(
                          icon: const Icon(Icons.image_outlined, color: AppColors.gold),
                          tooltip: 'Send image with phone number',
                          onPressed: _picking ? null : _pickImage,
                        ),
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          textInputAction: TextInputAction.newline,
                          minLines: 1,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: text.isAmharic ? 'መልዕክት ይጻፉ...' : 'Type a message...',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: _sending ? null : _sendMessage,
                        icon: _sending
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.send_rounded),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
