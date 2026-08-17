import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_spacing.dart';
import 'package:tutora/core/constants/app_text_styles.dart';
import 'package:tutora/features/parent/presentation/providers/parent_chat_provider.dart';
import 'package:tutora/features/parent/presentation/screens/parent_chat_page.dart';
import 'package:tutora/features/parent/presentation/shell/parent_shell.dart';
import 'package:tutora/features/tutor/data/models/chat_models.dart';
import 'package:tutora/shared/widgets/user_avatar.dart';

class ParentMessagesScreen extends ConsumerStatefulWidget {
  const ParentMessagesScreen({super.key});

  @override
  ConsumerState<ParentMessagesScreen> createState() =>
      _ParentMessagesScreenState();
}

class _ParentMessagesScreenState extends ConsumerState<ParentMessagesScreen>
    with ParentScrollToTopMixin {
  final _scrollController = ScrollController();
  String _search = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      listenScrollToTop(context, 3, _scrollController);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _openChat(ChatChannelDto channel) {
    unawaited(
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute<void>(
          builder: (_) => ParentChatPage(channel: channel),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(parentChannelListProvider);
    final bottomPad = MediaQuery.of(context).padding.bottom;

    final filtered = state.channels.where((c) {
      if (_search.isEmpty) return true;
      final q = _search.toLowerCase();
      return c.otherUserName.toLowerCase().contains(q) ||
          c.lastMessagePreview.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Expanded(child: Text('Tin nhắn', style: AppTextStyles.h2())),
                  GestureDetector(
                    onTap: () =>
                        ref.read(parentChannelListProvider.notifier).load(),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.paper,
                        border: Border.all(color: AppColors.line),
                      ),
                      child: const Icon(
                        Icons.refresh_rounded,
                        size: 16,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.cream2,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.search_rounded,
                      size: 16,
                      color: AppColors.ink4,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        onChanged: (v) => setState(() => _search = v),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.ink,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          hintText: 'Tìm kiếm hội thoại...',
                          hintStyle: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.ink4,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
              child: Row(
                children: [
                  Text('GẦN ĐÂY', style: AppTextStyles.eyebrow()),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Divider(color: AppColors.line, height: 1),
                  ),
                ],
              ),
            ),

            // Body
            Expanded(
              child: state.isLoading && state.channels.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : state.error != null && state.channels.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.wifi_off_rounded,
                            size: 40,
                            color: AppColors.ink4,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Không tải được tin nhắn',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.ink3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => ref
                                .read(parentChannelListProvider.notifier)
                                .load(),
                            child: Text(
                              'Thử lại',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.oxblood,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/images/common/empty_mesages.png',
                            width: 200,
                          ),
                          Text(
                            _search.isEmpty
                                ? 'Chưa có cuộc trò chuyện nào'
                                : 'Không tìm thấy kết quả',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.ink3,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () =>
                          ref.read(parentChannelListProvider.notifier).load(),
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.only(
                          bottom: bottomPad + AppSpacing.xxl,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) {
                          final channel = filtered[i];
                          return _ConvoItem(
                            key: ValueKey(channel.channelId),
                            channel: channel,
                            onTap: () => _openChat(channel),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConvoItem extends StatelessWidget {
  const _ConvoItem({required this.channel, required this.onTap, super.key});

  final ChatChannelDto channel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: const BoxDecoration(
          color: AppColors.cream,
          border: Border(
            bottom: BorderSide(color: AppColors.line, width: 0.8),
          ),
        ),
        child: Row(
          children: [
            UserAvatar(
              name: channel.otherUserName,
              imageUrl: channel.otherUserAvatarUrl,
              size: 54,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          channel.otherUserName,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                      Text(
                        channel.formattedTime,
                        style: GoogleFonts.ibmPlexMono(
                          fontSize: 10,
                          color: AppColors.ink4,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    channel.displayPreview,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: AppColors.ink4,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
