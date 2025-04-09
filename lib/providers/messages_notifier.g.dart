// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'messages_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$messagesNotifierHash() => r'e42f384abc41fb0f10fdac615c8f85719b6b8816';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

abstract class _$MessagesNotifier
    extends BuildlessAutoDisposeNotifier<List<ChatMessage>> {
  late final String chatId;

  List<ChatMessage> build(String chatId);
}

/// See also [MessagesNotifier].
@ProviderFor(MessagesNotifier)
const messagesNotifierProvider = MessagesNotifierFamily();

/// See also [MessagesNotifier].
class MessagesNotifierFamily extends Family<List<ChatMessage>> {
  /// See also [MessagesNotifier].
  const MessagesNotifierFamily();

  /// See also [MessagesNotifier].
  MessagesNotifierProvider call(String chatId) {
    return MessagesNotifierProvider(chatId);
  }

  @override
  MessagesNotifierProvider getProviderOverride(
    covariant MessagesNotifierProvider provider,
  ) {
    return call(provider.chatId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'messagesNotifierProvider';
}

/// See also [MessagesNotifier].
class MessagesNotifierProvider
    extends
        AutoDisposeNotifierProviderImpl<MessagesNotifier, List<ChatMessage>> {
  /// See also [MessagesNotifier].
  MessagesNotifierProvider(String chatId)
    : this._internal(
        () => MessagesNotifier()..chatId = chatId,
        from: messagesNotifierProvider,
        name: r'messagesNotifierProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$messagesNotifierHash,
        dependencies: MessagesNotifierFamily._dependencies,
        allTransitiveDependencies:
            MessagesNotifierFamily._allTransitiveDependencies,
        chatId: chatId,
      );

  MessagesNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.chatId,
  }) : super.internal();

  final String chatId;

  @override
  List<ChatMessage> runNotifierBuild(covariant MessagesNotifier notifier) {
    return notifier.build(chatId);
  }

  @override
  Override overrideWith(MessagesNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: MessagesNotifierProvider._internal(
        () => create()..chatId = chatId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        chatId: chatId,
      ),
    );
  }

  @override
  AutoDisposeNotifierProviderElement<MessagesNotifier, List<ChatMessage>>
  createElement() {
    return _MessagesNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is MessagesNotifierProvider && other.chatId == chatId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, chatId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin MessagesNotifierRef on AutoDisposeNotifierProviderRef<List<ChatMessage>> {
  /// The parameter `chatId` of this provider.
  String get chatId;
}

class _MessagesNotifierProviderElement
    extends
        AutoDisposeNotifierProviderElement<MessagesNotifier, List<ChatMessage>>
    with MessagesNotifierRef {
  _MessagesNotifierProviderElement(super.provider);

  @override
  String get chatId => (origin as MessagesNotifierProvider).chatId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
