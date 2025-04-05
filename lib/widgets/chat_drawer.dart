import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vaarta/providers/chat_list_provider.dart';
import 'package:vaarta/router/app_router.dart';
import 'package:vaarta/services/database_helper.dart';
import 'package:vaarta/services/database/chat_repository.dart';
import 'package:vaarta/services/database/message_repository.dart';
import 'package:vaarta/theme/theme_extensions.dart';
import 'package:vaarta/utils/dialog_utils.dart';
import 'package:vaarta/utils/date_utils.dart';
import 'package:vaarta/widgets/shared/loading_indicator.dart';
import 'package:vaarta/widgets/shared/error_message_widget.dart';
// import 'package:flutter_slidable/flutter_slidable.dart'; // Moved to ChatListItem
import 'dart:math'
    as math; // Keep for message sublist logic if needed elsewhere
// import 'package:vaarta/models/messages/chat_message.dart'; // Moved to ChatTitleService
import 'package:vaarta/providers/llm_client_provider.dart'; // Keep for now, might be removed if service handles all LLM
// import 'package:vaarta/services/llm_client.dart'; // Moved to ChatTitleService
import 'dart:async';
import 'chat/chat_list_item.dart'; // Import the new list item widget

// import 'package:vaarta/services/chat/chat_title_service.dart'; // TODO: Uncomment when service is created
// import 'package:vaarta/providers/chat_title_service_provider.dart'; // TODO: Uncomment when provider is created
class ChatDrawer extends ConsumerStatefulWidget {
  final String currentChatId;
  final VoidCallback onNewChat;

  const ChatDrawer({
    super.key,
    required this.currentChatId,
    required this.onNewChat,
  });

  @override
  ConsumerState<ChatDrawer> createState() => _ChatDrawerState();
}

class _ChatDrawerState extends ConsumerState<ChatDrawer> {
  // Old state now managed by provider
  Set<String> _selectedChats = {};
  bool _isMultiSelectMode = false;
  late final ChatRepository _chatRepository;
  late final MessageRepository _messageRepository;

  // State for auto-rename UI feedback
  final Set<String> _renamingChatIds = {};
  Timer? _spinnerTimer;
  int _spinnerIndex = 0;
  final List<String> _spinnerChars = const [
    '⣾',
    '⣽',
    '⣻',
    '⢿',
    '⡿',
    '⣟',
    '⣯',
    '⣷',
  ];

  @override
  void initState() {
    super.initState();
    _chatRepository = ChatRepository(DatabaseHelper.instance);
    _messageRepository = MessageRepository(DatabaseHelper.instance);
  }

  @override
  Widget build(BuildContext context) {
    // Access the chat list provider
    final chatListAsync = ref.watch(chatListProvider);

    return Drawer(
      backgroundColor: context.colors.background,
      child: Column(
        children: [
          _buildDrawerHeader(context),
          // Use AsyncValue widget to handle loading/error/data states
          chatListAsync.when(
            loading: () => const Expanded(child: LoadingIndicator()),
            error:
                (err, stack) => Expanded(
                  child: ErrorMessageWidget(
                    message: 'Error loading chats',
                    details: err.toString(),
                  ),
                ),
            data: (chatList) {
              if (chatList.isEmpty) {
                return _buildEmptyState(context);
              } else {
                return Expanded(
                  child: _buildChatList(context, chatList),
                ); // Pass chatList
              }
            },
          ),
          _buildDrawerFooter(context),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader(BuildContext context) {
    return DrawerHeader(
      decoration: BoxDecoration(color: context.colors.primary),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Chats',
                style: context.typography.h5.copyWith(
                  color: context.colors.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_isMultiSelectMode)
                IconButton(
                  icon: Icon(Icons.close, color: context.colors.onPrimary),
                  onPressed: () {
                    setState(() {
                      _isMultiSelectMode = false;
                      _selectedChats.clear();
                    });
                  },
                ),
            ],
          ),
          const Spacer(),
          if (_isMultiSelectMode && _selectedChats.isNotEmpty)
            ElevatedButton.icon(
              onPressed: _deleteSelectedChats,
              icon: const Icon(Icons.delete),
              label: Text('Delete (${_selectedChats.length})'),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colors.error,
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: context.colors.onBackground.withOpacity(0.4),
            ),
            SizedBox(height: context.spacing.medium),
            Text(
              "No chats yet",
              style: context.typography.body1.copyWith(
                color: context.colors.onBackground.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatList(
    BuildContext context,
    List<Map<String, dynamic>> chatList,
  ) {
    // Added chatList param
    return ListView.builder(
      itemCount: chatList.length, // Use passed chatList
      padding: EdgeInsets.all(context.spacing.small),
      itemBuilder: (context, index) {
        final chatMetadata = chatList[index];
        final chatId = chatMetadata[DatabaseHelper.chatColumnChatId];
        final isSelected = _selectedChats.contains(chatId);
        final isCurrentChat = chatId == widget.currentChatId;
        final isRenaming = _renamingChatIds.contains(chatId);
        final spinnerChar =
            isRenaming
                ? _spinnerChars[_spinnerIndex % _spinnerChars.length]
                : null;

        return ChatListItem(
          key: ValueKey(chatId), // Ensure key is passed
          chatMetadata: chatMetadata,
          isSelected: isSelected,
          isCurrentChat: isCurrentChat,
          isMultiSelectMode: _isMultiSelectMode,
          isRenaming: isRenaming,
          spinnerChar: spinnerChar,
          onTap: () => _handleItemTap(chatId, isSelected),
          onLongPress: () => _handleItemLongPress(chatId),
          onDelete: () => _confirmAndDeleteChat(context, chatId),
          onManualRename: () {
            final currentName =
                chatMetadata[DatabaseHelper.chatColumnChatName] ?? 'Chat';
            _showManualRenameDialog(context, chatId, currentName);
          },
          onAutoRename: () => _performAutoRename(context, chatId),
        );
      },
    );
  }

  // --- Helper methods for ChatListItem callbacks ---

  void _handleItemTap(String chatId, bool isSelected) {
    if (_isMultiSelectMode) {
      setState(() {
        if (isSelected) {
          _selectedChats.remove(chatId);
        } else {
          _selectedChats.add(chatId);
        }
        if (_selectedChats.isEmpty) {
          _isMultiSelectMode = false;
        }
      });
    } else {
      // Navigate to the chat
      context.go(AppRouter.chatPath(chatId));
      // Optionally close the drawer after navigation
      // Navigator.pop(context);
    }
  }

  void _handleItemLongPress(String chatId) {
    setState(() {
      _isMultiSelectMode = true;
      _selectedChats.add(chatId);
    });
  }

  Widget _buildDrawerFooter(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.spacing.medium),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton.icon(
            onPressed: () {
              widget.onNewChat();
              Navigator.pop(context); // Close drawer
            },
            icon: const Icon(Icons.add),
            label: const Text('New Chat'),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colors.primary,
              foregroundColor: context.colors.onPrimary,
            ),
          ),
          IconButton(
            icon: Icon(Icons.settings, color: context.colors.primary),
            onPressed: () {
              Navigator.pop(context); // Close drawer
              context.push(AppRouter.settings);
            },
          ),
        ],
      ),
    );
  }

  void _deleteSelectedChats() async {
    // Show confirmation dialog using utility
    bool confirm =
        await showConfirmationDialog(
          context: context,
          title: 'Delete Chats',
          content:
              'Are you sure you want to delete ${_selectedChats.length} ${_selectedChats.length == 1 ? "chat" : "chats"}?',
          confirmText: 'Delete',
          confirmColor: context.colors.error,
        ) ??
        false;

    if (!confirm) return;

    // Handle case when current chat is being deleted
    final currentChatDeleted = _selectedChats.contains(widget.currentChatId);
    final currentChatList = await ref.read(
      chatListProvider.future,
    ); // Get current list before deleting

    // Delete the selected chats
    for (final chatId in _selectedChats) {
      await _chatRepository.deleteChat(chatId);
      await _messageRepository.deleteMessagesByChatId(chatId);
    }

    // Refresh the provider to reload the chat list
    ref.invalidate(chatListProvider);

    // No need to call _loadChats() anymore

    if (mounted) {
      // Check if widget is still mounted before calling setState
      setState(() {
        _selectedChats.clear();
        _isMultiSelectMode = false;
      });
    }

    // If current chat was deleted, navigate to another chat or create a new one
    if (currentChatDeleted && context.mounted) {
      final remainingChats =
          currentChatList
              .where(
                (chat) =>
                    !_selectedChats.contains(
                      chat[DatabaseHelper.chatColumnChatId],
                    ),
              )
              .toList();

      if (remainingChats.isNotEmpty) {
        // Navigate to the first remaining chat
        context.go(
          AppRouter.chatPath(
            remainingChats.first[DatabaseHelper.chatColumnChatId],
          ),
        );
      } else {
        // No chats left, navigate to create a new one
        AppRouter.navigateToNewChat(context);
      }

      // Pop only if still mounted after async operations and navigation
      if (context.mounted) {
        Navigator.pop(context); // Close drawer
      }
    }
    // List refreshes automatically via provider watch in build()
  }

  // Added _toggleSelection method required by onLongPress in ListTile
  void _toggleSelection(String chatId) {
    setState(() {
      if (_isMultiSelectMode) {
        if (_selectedChats.contains(chatId)) {
          _selectedChats.remove(chatId);
        } else {
          _selectedChats.add(chatId);
        }
        if (_selectedChats.isEmpty) {
          _isMultiSelectMode = false;
        }
      } else {
        _isMultiSelectMode = true;
        _selectedChats.add(chatId);
      }
    });
  }

  void _confirmAndDeleteChat(
    BuildContext context,
    String chatIdToDelete,
  ) async {
    final dbHelper = DatabaseHelper.instance;

    // Show confirmation dialog using utility
    bool confirm =
        await showConfirmationDialog(
          context: context,
          title: 'Delete Chat',
          content: 'Are you sure you want to delete this chat?',
          confirmText: 'Delete',
          confirmColor: context.colors.error,
        ) ??
        false;

    // Check confirmation first.
    if (!confirm) {
      return; // Exit if not confirmed
    }

    // Now check if the State is still mounted *after* the dialog await.
    // Use the 'mounted' property of the State.
    if (!mounted) {
      return; // Exit if state is unmounted after dialog
    }

    // Access widget directly since method is now inside the State class
    final bool wasCurrentChat = chatIdToDelete == widget.currentChatId;
    // Get the list *before* deletion for navigation logic
    final currentList = await ref.read(chatListProvider.future);

    // Logs inside DatabaseHelper will show progress if enabled there
    try {
      // Delete the chat from the database
      // Logs inside DatabaseHelper will show progress
      await _chatRepository.deleteChat(chatIdToDelete);
      await _messageRepository.deleteMessagesByChatId(chatIdToDelete);

      // Invalidate the provider to trigger a reload via watch() in build()
      ref.invalidate(chatListProvider);

      // Wait a short moment to allow the provider/UI to potentially update
      // Might not be strictly necessary but can help in some race conditions.
      // Consider removing if it doesn't solve the issue.
      await Future.delayed(const Duration(milliseconds: 50));

      // Handle navigation if the *current* chat was deleted
      // Check State's mounted property before navigation
      if (wasCurrentChat && mounted) {
        // Find the next chat from the list *before* deletion
        final remainingChats =
            currentList
                .where(
                  (chat) =>
                      chat[DatabaseHelper.chatColumnChatId] != chatIdToDelete,
                )
                .toList();

        if (remainingChats.isNotEmpty) {
          // Navigate to the first remaining chat
          final nextChatId =
              remainingChats.first[DatabaseHelper.chatColumnChatId];
          // Use the State's context for navigation
          GoRouter.of(this.context).go(AppRouter.chatPath(nextChatId));
        } else {
          // Use the State's context for navigation
          AppRouter.navigateToNewChat(this.context);
        }

        // Close the drawer only if navigation happened (current chat deleted)
        // Check State's mounted property before popping
        if (mounted) {
          // Use the State's context to pop the drawer
          Navigator.pop(this.context);
        }
      }
      // If it wasn't the current chat, the list updates via the provider `watch`
      // in the `build` method, and no explicit navigation or drawer pop is needed here.
    } catch (e, stackTrace) {
      // Keep stackTrace for potential future debugging if needed
      // Handle potential errors
      // Check if State is mounted before showing Snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error deleting chat: $e',
              style: context.typography.body2,
            ),
            backgroundColor: context.colors.error,
          ),
        );
      } else {
        // State was unmounted when error occurred.
      }
    } // This closes the try-catch block
  } // This closes the _confirmAndDeleteChat method

  Future<void> _showManualRenameDialog(
    BuildContext context,
    String chatId,
    String currentName,
  ) async {
    final dbHelper = DatabaseHelper.instance;

    final newName = await showTextInputDialog(
      context: context,
      title: 'Rename Chat',
      hintText: 'Enter new chat name',
      initialValue: currentName,
    );

    if (newName != null && newName.isNotEmpty && newName != currentName) {
      try {
        await _chatRepository.updateChatName(chatId, newName);
        if (mounted) {
          ref.invalidate(chatListProvider);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error renaming chat: $e',
                style: context.typography.body2,
              ),
              backgroundColor: context.colors.error,
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _spinnerTimer?.cancel(); // Cancel timer on dispose
    super.dispose();
  }

  // --- Animation Timer Management ---

  void _startSpinnerAnimation() {
    if (_spinnerTimer == null || !_spinnerTimer!.isActive) {
      _spinnerTimer = Timer.periodic(const Duration(milliseconds: 100), (
        timer,
      ) {
        if (!mounted) {
          timer.cancel(); // Ensure timer is cancelled if widget is disposed
          _spinnerTimer = null;
          return;
        }
        setState(() {
          _spinnerIndex++; // Update spinner index for animation
        });
      });
    }
  }

  void _stopSpinnerAnimation() {
    // Stop timer only if no chats are being renamed
    if (_renamingChatIds.isEmpty &&
        _spinnerTimer != null &&
        _spinnerTimer!.isActive) {
      _spinnerTimer!.cancel();
      _spinnerTimer = null;
    }
  }

  Future<void> _performAutoRename(BuildContext context, String chatId) async {
    // Initial mounted check is still useful to prevent starting if already disposed
    if (!mounted) return;

    // Prevent starting rename if already in progress for this chat
    if (_renamingChatIds.contains(chatId)) return;

    // --- UI Update Start ---
    setState(() {
      _renamingChatIds.add(chatId);
      _startSpinnerAnimation(); // Start animation if not already running
    });
    // --- UI Update End ---

    // final dbHelper = DatabaseHelper.instance; // No longer needed directly
    // Obtain ProviderContainer *before* any async gaps to safely refresh provider later.
    // final container = ProviderScope.containerOf(context, listen: false); // Not needed if service handles refresh

    // TODO: Get ChatTitleService instance when provider exists
    // final chatTitleService = ref.read(chatTitleServiceProvider);

    // Fetch messages outside try-catch initially to handle empty case cleanly
    // --- Call ChatTitleService ---
    // --- Call ChatTitleService (Placeholder) ---
    try {
      // TODO: Replace with actual service call when implemented
      print('TODO: Call ChatTitleService.regenerateTitle for chat $chatId');
      // await chatTitleService.regenerateTitle(chatId); // Commented out usage
      // Simulate a delay as the service would take time
      await Future.delayed(const Duration(seconds: 1));
      // ref.invalidate(chatListProvider); // Or handle refresh within service
    } catch (e, stackTrace) {
      print('Error calling ChatTitleService for chat $chatId: $e\n$stackTrace');
      // Handle error appropriately, maybe show a snackbar if mounted
    } finally {
      // --- UI Update Finish ---
      // This block runs whether the try/catch succeeded or failed.
      // Ensure the UI state is always reset, but *only* if the widget is still mounted.
      if (mounted) {
        setState(() {
          _renamingChatIds.remove(chatId);
          _stopSpinnerAnimation(); // Stop animation if this was the last one
        });
      } else {
        // If not mounted, manually remove from the set so a future rebuild
        // doesn't incorrectly show it as renaming.
        _renamingChatIds.remove(chatId);
      }
    }
    // --- End Placeholder ---
  } // End of _performAutoRename method
}
