import 'package:flutter/material.dart';
import 'package:vaarta/theme/theme_extensions.dart';

class ErrorMessageWidget extends StatelessWidget {
  final String message;
  final String? details;
  final VoidCallback? onRetry;

  const ErrorMessageWidget({
    super.key,
    required this.message,
    this.details,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.spacing.medium),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: context.colors.error),
            SizedBox(height: context.spacing.medium),
            Text(
              message,
              style: context.typography.h6.copyWith(
                color: context.colors.error,
              ),
              textAlign: TextAlign.center,
            ),
            if (details != null) ...[
              SizedBox(height: context.spacing.small),
              Text(
                details!,
                style: context.typography.body2,
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              SizedBox(height: context.spacing.large),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: Icon(Icons.refresh),
                label: Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.colors.error,
                  foregroundColor: context.colors.onError,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
