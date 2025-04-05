// lib/utils/token_parser.dart

/// Represents different types of tokens that can be parsed
enum TokenType { thinking, toolCall, codeBlock, plainText }

/// Represents a parsed token from the content
class ParsedToken {
  final TokenType type;
  final String content;
  final Map<String, String>? metadata;
  final int startIndex; // Store original start index for sorting
  final int endIndex; // Store original end index

  const ParsedToken({
    required this.type,
    required this.content,
    this.metadata,
    required this.startIndex,
    required this.endIndex,
  });
}

/// Abstract base class for token parsing strategies
abstract class TokenParser {
  List<ParsedToken> parse(String content, {bool isFinal = false});
}

/// Tracks parsing state across multiple parse() calls for partial content
class PartialParseState {
  String remainingContent = '';
  TokenType? lastPendingType;

  void reset() {
    remainingContent = '';
    lastPendingType = null;
  }
}

/// Improved implementation of token parsing with better code detection
class DefaultTokenParser implements TokenParser {
  PartialParseState _parseState =
      PartialParseState(); // Track state between calls

  @override
  List<ParsedToken> parse(String content, {bool isFinal = false}) {
    final List<_MatchInfo> allMatches = [];
    final List<ParsedToken> tokens = [];

    // Handle remaining content from previous partial parse
    if (_parseState.remainingContent.isNotEmpty) {
      content = _parseState.remainingContent + content;
      _parseState.remainingContent = '';
    }

    // Define regex patterns
    final thinkRegex = RegExp(r'(?:^|\s)(?:<think>)([\s\S]*?(?:<\/think>|$))');
    final toolRegex = RegExp(r'(?:^|\s)(?:<tool>)([\s\S]*?(?:<\/tool>|$))');
    final codeTagRegex = RegExp(
      r'(?:^|\s)(?:<code(?:\s+lang="([^"]*)")?>)([\s\S]*?(?:<\/code>|$))',
    );
    final markdownCodeRegex = RegExp(
      r'(?:^|\s)(?:```([a-z]*)?\n?)([\s\S]*?(?:```|$))',
    );

    // Find all matches and store info
    _findMatches(content, thinkRegex, TokenType.thinking, allMatches);
    _findMatches(content, toolRegex, TokenType.toolCall, allMatches);
    _findMatches(
      content,
      codeTagRegex,
      TokenType.codeBlock,
      allMatches,
      isCode: true,
    );
    _findMatches(
      content,
      markdownCodeRegex,
      TokenType.codeBlock,
      allMatches,
      isCode: true,
    );

    // Check for incomplete matches at the end
    if (!isFinal) {
      final lastChars =
          content.length > 20
              ? content.substring(content.length - 20)
              : content;
      if (lastChars.contains('<think>') && !lastChars.contains('</think>')) {
        _parseState.lastPendingType = TokenType.thinking;
      } else if (lastChars.contains('<tool>') &&
          !lastChars.contains('</tool>')) {
        _parseState.lastPendingType = TokenType.toolCall;
      } else if (lastChars.contains('<code') &&
          !lastChars.contains('</code>')) {
        _parseState.lastPendingType = TokenType.codeBlock;
      } else if (lastChars.contains('```') &&
          (lastChars.split('```').length - 1) % 2 != 0) {
        _parseState.lastPendingType = TokenType.codeBlock;
      }

      // Preserve unfinished content for next parse
      if (_parseState.lastPendingType != null) {
        final openingTag =
            _parseState.lastPendingType == TokenType.thinking
                ? '<think>'
                : _parseState.lastPendingType == TokenType.toolCall
                ? '<tool>'
                : _parseState.lastPendingType == TokenType.codeBlock
                ? lastChars.contains('<code')
                    ? '<code'
                    : '```'
                : '';

        if (openingTag.isNotEmpty) {
          final idx = content.lastIndexOf(openingTag);
          if (idx >= 0) {
            _parseState.remainingContent = content.substring(idx);
            content = content.substring(0, idx);
          }
        }
      }
    }

    // Sort matches by start index
    allMatches.sort((a, b) => a.startIndex.compareTo(b.startIndex));

    // Resolve overlapping matches (e.g., ``` inside <code>) - prefer longer match or specific tag
    final List<_MatchInfo> filteredMatches = _resolveOverlaps(allMatches);

    int currentPosition = 0;
    for (final matchInfo in filteredMatches) {
      // Add plain text before this match
      if (matchInfo.startIndex > currentPosition) {
        final plainText = content.substring(
          currentPosition,
          matchInfo.startIndex,
        );
        if (plainText.trim().isNotEmpty) {
          tokens.add(
            ParsedToken(
              type: TokenType.plainText,
              content: plainText,
              startIndex: currentPosition,
              endIndex: matchInfo.startIndex,
            ),
          );
        }
      }

      // Add the matched token
      tokens.add(matchInfo.toParsedToken());

      // Update current position
      currentPosition = matchInfo.endIndex;
    }

    // Add any remaining plain text after the last match
    if (currentPosition < content.length) {
      final plainText = content.substring(currentPosition);
      if (plainText.trim().isNotEmpty) {
        tokens.add(
          ParsedToken(
            type: TokenType.plainText,
            content: plainText,
            startIndex: currentPosition,
            endIndex: content.length,
          ),
        );
      }
    }

    return tokens;
  }

  void _findMatches(
    String content,
    RegExp regex,
    TokenType type,
    List<_MatchInfo> matches, {
    bool isCode = false,
  }) {
    for (final match in regex.allMatches(content)) {
      String extractedContent;
      Map<String, String>? metadata;
      final fullMatchContent = match.group(0)!; // The entire matched string

      if (isCode) {
        // Group 2 is code content, Group 1 is optional language
        extractedContent = match.group(2) ?? '';
        final language = match.group(1);
        if (language != null && language.isNotEmpty) {
          metadata = {'language': language};
        }
      } else {
        // Group 1 is the content for think/tool
        extractedContent = match.group(1) ?? '';
      }

      if (extractedContent.isNotEmpty) {
        matches.add(
          _MatchInfo(
            type: type,
            content: extractedContent,
            metadata: metadata,
            startIndex: match.start,
            endIndex: match.end,
            isCodeTag:
                isCode &&
                fullMatchContent.startsWith(
                  '<code',
                ), // Flag if it's a specific <code> tag
          ),
        );
      }
    }
  }

  List<_MatchInfo> _resolveOverlaps(List<_MatchInfo> matches) {
    if (matches.isEmpty) return [];

    List<_MatchInfo> resolved = [];
    resolved.add(matches.first);

    for (int i = 1; i < matches.length; i++) {
      _MatchInfo current = matches[i];
      _MatchInfo lastResolved = resolved.last;

      // Check for overlap
      if (current.startIndex < lastResolved.endIndex) {
        // Overlap detected! Decide which one to keep.
        // Priority:
        // 1. Specific <code> tag over markdown ```
        // 2. Longer match if types are otherwise equal
        // 3. Keep the one that started earlier if lengths and types are equal (already handled by sort)

        bool keepCurrent = false;
        if (current.isCodeTag &&
            !lastResolved.isCodeTag &&
            lastResolved.type == TokenType.codeBlock) {
          // Current is <code>, last was ``` -> Keep current
          keepCurrent = true;
        } else if (!current.isCodeTag &&
            lastResolved.isCodeTag &&
            current.type == TokenType.codeBlock) {
          // Current is ```, last was <code> -> Keep last (do nothing here)
          continue; // Skip adding current
        } else if ((current.endIndex - current.startIndex) >
            (lastResolved.endIndex - lastResolved.startIndex)) {
          // Current is longer
          keepCurrent = true;
        }
        // Add more sophisticated rules if needed

        if (keepCurrent) {
          resolved.removeLast(); // Remove the last one
          resolved.add(current); // Add the current one
        }
        // else: Keep the lastResolved one (implicitly by not adding current)
      } else {
        // No overlap, just add the current match
        resolved.add(current);
      }
    }
    return resolved;
  }
}

// Helper class to store match info before creating ParsedToken
class _MatchInfo {
  final TokenType type;
  final String content;
  final Map<String, String>? metadata;
  final int startIndex;
  final int endIndex;
  final bool isCodeTag; // To differentiate <code> from ```

  _MatchInfo({
    required this.type,
    required this.content,
    this.metadata,
    required this.startIndex,
    required this.endIndex,
    this.isCodeTag = false,
  });

  ParsedToken toParsedToken() {
    return ParsedToken(
      type: type,
      content: content,
      metadata: metadata,
      startIndex: startIndex,
      endIndex: endIndex,
    );
  }
}
