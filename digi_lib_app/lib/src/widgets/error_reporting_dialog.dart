import 'package:flutter/material.dart';
import '../models/ui/error_state.dart';
import '../utils/constants.dart';

/// Dialog for reporting errors and collecting user feedback
class ErrorReportingDialog extends StatefulWidget {
  final ErrorState errorState;
  final Function(String feedback, bool includeDetails)? onSubmit;

  const ErrorReportingDialog({
    super.key,
    required this.errorState,
    this.onSubmit,
  });

  @override
  State<ErrorReportingDialog> createState() => _ErrorReportingDialogState();
}

class _ErrorReportingDialogState extends State<ErrorReportingDialog> {
  final _feedbackController = TextEditingController();
  final _emailController = TextEditingController();
  bool _includeDetails = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _feedbackController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.bug_report, color: Colors.orange),
          SizedBox(width: 8),
          Text('Report Error'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Help us improve the app by reporting this error. Your feedback is valuable!',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            
            // Error summary
            Container(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Error Summary',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.errorState.message,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                  if (widget.errorState.context != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Context: ${widget.errorState.context}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: AppConstants.defaultPadding),
            
            // Email field (optional)
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email (optional)',
                hintText: 'your.email@example.com',
                prefixIcon: Icon(Icons.email_outlined),
                helperText: 'We may contact you for more information',
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            
            const SizedBox(height: AppConstants.defaultPadding),
            
            // Feedback field
            TextField(
              controller: _feedbackController,
              decoration: const InputDecoration(
                labelText: 'Describe what you were doing',
                hintText: 'What were you trying to do when this error occurred?',
                prefixIcon: Icon(Icons.comment_outlined),
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            
            const SizedBox(height: AppConstants.defaultPadding),
            
            // Include technical details checkbox
            CheckboxListTile(
              value: _includeDetails,
              onChanged: (value) => setState(() => _includeDetails = value ?? true),
              title: const Text('Include technical details'),
              subtitle: const Text('Helps developers diagnose the issue'),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            
            if (_includeDetails) ...[
              const SizedBox(height: AppConstants.defaultPadding / 2),
              ExpansionTile(
                title: const Text('Technical Details Preview'),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppConstants.defaultPadding),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                    ),
                    child: Text(
                      _buildTechnicalDetails(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _isSubmitting ? null : _submitReport,
          icon: _isSubmitting 
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send),
          label: Text(_isSubmitting ? 'Sending...' : 'Send Report'),
        ),
      ],
    );
  }

  String _buildTechnicalDetails() {
    final buffer = StringBuffer();
    buffer.writeln('Error Type: ${widget.errorState.type}');
    buffer.writeln('Severity: ${widget.errorState.severity}');
    buffer.writeln('Message: ${widget.errorState.message}');
    if (widget.errorState.code != null) {
      buffer.writeln('Code: ${widget.errorState.code}');
    }
    if (widget.errorState.context != null) {
      buffer.writeln('Context: ${widget.errorState.context}');
    }
    buffer.writeln('Timestamp: ${widget.errorState.timestamp}');
    if (widget.errorState.details != null) {
      buffer.writeln('Details: ${widget.errorState.details}');
    }
    return buffer.toString().trim();
  }

  Future<void> _submitReport() async {
    setState(() => _isSubmitting = true);
    
    try {
      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 1));
      
      final feedback = _feedbackController.text.trim();
      widget.onSubmit?.call(feedback, _includeDetails);
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error report sent successfully. Thank you for your feedback!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send error report. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  /// Show error reporting dialog
  static Future<void> show(
    BuildContext context,
    ErrorState errorState, {
    Function(String feedback, bool includeDetails)? onSubmit,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => ErrorReportingDialog(
        errorState: errorState,
        onSubmit: onSubmit,
      ),
    );
  }
}

/// A simple feedback dialog for general app feedback
class FeedbackDialog extends StatefulWidget {
  final Function(String feedback, int rating)? onSubmit;

  const FeedbackDialog({
    super.key,
    this.onSubmit,
  });

  @override
  State<FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends State<FeedbackDialog> {
  final _feedbackController = TextEditingController();
  int _rating = 5;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.feedback, color: Colors.blue),
          SizedBox(width: 8),
          Text('Send Feedback'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'We\'d love to hear your thoughts about the app!',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppConstants.defaultPadding),
          
          // Rating
          Text(
            'How would you rate your experience?',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return IconButton(
                onPressed: () => setState(() => _rating = index + 1),
                icon: Icon(
                  index < _rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 32,
                ),
              );
            }),
          ),
          
          const SizedBox(height: AppConstants.defaultPadding),
          
          // Feedback text
          TextField(
            controller: _feedbackController,
            decoration: const InputDecoration(
              labelText: 'Your feedback',
              hintText: 'Tell us what you think...',
              prefixIcon: Icon(Icons.comment_outlined),
            ),
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _isSubmitting ? null : _submitFeedback,
          icon: _isSubmitting 
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send),
          label: Text(_isSubmitting ? 'Sending...' : 'Send'),
        ),
      ],
    );
  }

  Future<void> _submitFeedback() async {
    setState(() => _isSubmitting = true);
    
    try {
      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 1));
      
      final feedback = _feedbackController.text.trim();
      widget.onSubmit?.call(feedback, _rating);
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Feedback sent successfully. Thank you!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send feedback. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  /// Show feedback dialog
  static Future<void> show(
    BuildContext context, {
    Function(String feedback, int rating)? onSubmit,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => FeedbackDialog(onSubmit: onSubmit),
    );
  }
}