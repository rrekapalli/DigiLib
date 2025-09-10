import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

/// Provider for feedback service
final feedbackServiceProvider = Provider<FeedbackService>((ref) {
  return FeedbackService();
});

/// Service for collecting and managing user feedback
class FeedbackService {
  static const String _lastFeedbackDateKey = 'last_feedback_date';
  static const String _appUsageCountKey = 'app_usage_count';
  static const String _userRatingKey = 'user_rating';

  /// Check if feedback should be requested
  Future<bool> shouldRequestFeedback() async {
    final prefs = await SharedPreferences.getInstance();

    // Don't show if already shown recently
    final lastShown = prefs.getString(_lastFeedbackDateKey);
    if (lastShown != null) {
      final lastDate = DateTime.tryParse(lastShown);
      if (lastDate != null && DateTime.now().difference(lastDate).inDays < 30) {
        return false;
      }
    }

    // Show after certain usage count
    final usageCount = prefs.getInt(_appUsageCountKey) ?? 0;
    return usageCount >= 10; // Show after 10 app launches
  }

  /// Increment app usage count
  Future<void> incrementUsageCount() async {
    final prefs = await SharedPreferences.getInstance();
    final currentCount = prefs.getInt(_appUsageCountKey) ?? 0;
    await prefs.setInt(_appUsageCountKey, currentCount + 1);
  }

  /// Mark feedback as shown
  Future<void> markFeedbackShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _lastFeedbackDateKey,
      DateTime.now().toIso8601String(),
    );
  }

  /// Save user rating
  Future<void> saveUserRating(int rating) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_userRatingKey, rating);
  }

  /// Get user rating
  Future<int?> getUserRating() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userRatingKey);
  }

  /// Submit feedback (would typically send to backend)
  Future<bool> submitFeedback({
    required String feedback,
    required int rating,
    String? email,
    String? category,
  }) async {
    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));

      // In a real app, this would send to your backend
      debugPrint('Feedback submitted:');
      debugPrint('Rating: $rating');
      debugPrint('Category: $category');
      debugPrint('Email: $email');
      debugPrint('Feedback: $feedback');

      await saveUserRating(rating);
      await markFeedbackShown();

      return true;
    } catch (e) {
      debugPrint('Failed to submit feedback: $e');
      return false;
    }
  }
}

/// Feedback request dialog that appears periodically
class FeedbackRequestDialog extends ConsumerStatefulWidget {
  final VoidCallback? onDismiss;

  const FeedbackRequestDialog({super.key, this.onDismiss});

  @override
  ConsumerState<FeedbackRequestDialog> createState() =>
      _FeedbackRequestDialogState();
}

class _FeedbackRequestDialogState extends ConsumerState<FeedbackRequestDialog> {
  int _rating = 0;
  bool _showFeedbackForm = false;

  @override
  Widget build(BuildContext context) {
    if (_showFeedbackForm) {
      return _buildFeedbackForm();
    }

    return AlertDialog(
      icon: const Icon(Icons.star, color: Colors.amber, size: 32),
      title: const Text('How are we doing?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'We\'d love to hear your thoughts about the Digital Library app!',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.defaultPadding),

          // Star rating
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

          if (_rating > 0) ...[
            const SizedBox(height: 8),
            Text(
              _getRatingText(_rating),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            widget.onDismiss?.call();
          },
          child: const Text('Maybe Later'),
        ),
        if (_rating > 0)
          FilledButton(
            onPressed: _handleRatingSubmit,
            child: const Text('Continue'),
          ),
      ],
    );
  }

  Widget _buildFeedbackForm() {
    return DetailedFeedbackDialog(
      initialRating: _rating,
      onSubmit: (feedback, rating, email, category) async {
        final feedbackService = ref.read(feedbackServiceProvider);
        final success = await feedbackService.submitFeedback(
          feedback: feedback,
          rating: rating,
          email: email,
          category: category,
        );

        if (mounted && context.mounted) {
          Navigator.of(context).pop();

          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Thank you for your feedback!'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to submit feedback. Please try again.'),
                backgroundColor: Colors.red,
              ),
            );
          }

          widget.onDismiss?.call();
        }
      },
      onCancel: () {
        Navigator.of(context).pop();
        widget.onDismiss?.call();
      },
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return 'We can do better';
      case 2:
        return 'Room for improvement';
      case 3:
        return 'It\'s okay';
      case 4:
        return 'Pretty good!';
      case 5:
        return 'Excellent!';
      default:
        return '';
    }
  }

  void _handleRatingSubmit() {
    if (_rating >= 4) {
      // High rating - ask for app store review
      _showAppStoreReviewDialog();
    } else {
      // Lower rating - show detailed feedback form
      setState(() => _showFeedbackForm = true);
    }
  }

  void _showAppStoreReviewDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.favorite, color: Colors.red, size: 32),
        title: const Text('Thank you!'),
        content: const Text(
          'We\'re thrilled you\'re enjoying the app! Would you mind leaving a review on the app store?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
              widget.onDismiss?.call();
            },
            child: const Text('Not Now'),
          ),
          FilledButton(
            onPressed: () async {
              // In a real app, this would open the app store
              final feedbackService = ref.read(feedbackServiceProvider);
              await feedbackService.saveUserRating(_rating);
              await feedbackService.markFeedbackShown();

              if (context.mounted) {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Thank you for your support!'),
                    backgroundColor: Colors.green,
                  ),
                );
                widget.onDismiss?.call();
              }
            },
            child: const Text('Review App'),
          ),
        ],
      ),
    );
  }

  /// Show feedback request dialog if appropriate
  static Future<void> showIfAppropriate(BuildContext context) async {
    final feedbackService = FeedbackService();

    if (await feedbackService.shouldRequestFeedback()) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => FeedbackRequestDialog(
            onDismiss: () => feedbackService.markFeedbackShown(),
          ),
        );
      }
    }
  }
}

/// Detailed feedback dialog for collecting comprehensive feedback
class DetailedFeedbackDialog extends StatefulWidget {
  final int initialRating;
  final Function(String feedback, int rating, String? email, String? category)
  onSubmit;
  final VoidCallback onCancel;

  const DetailedFeedbackDialog({
    super.key,
    required this.initialRating,
    required this.onSubmit,
    required this.onCancel,
  });

  @override
  State<DetailedFeedbackDialog> createState() => _DetailedFeedbackDialogState();
}

class _DetailedFeedbackDialogState extends State<DetailedFeedbackDialog> {
  final _feedbackController = TextEditingController();
  final _emailController = TextEditingController();
  late int _rating;
  String? _selectedCategory;
  bool _isSubmitting = false;

  final List<String> _categories = [
    'Bug Report',
    'Feature Request',
    'Performance Issue',
    'User Interface',
    'Documentation',
    'General Feedback',
  ];

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating;
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tell us more'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rating display
            Row(
              children: [
                Text(
                  'Your rating: ',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                ...List.generate(5, (index) {
                  return Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 20,
                  );
                }),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => _showRatingDialog(),
                  child: const Text('Change'),
                ),
              ],
            ),

            const SizedBox(height: AppConstants.defaultPadding),

            // Category selection
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                hintText: 'Select feedback category',
              ),
              items: _categories.map((category) {
                return DropdownMenuItem(value: category, child: Text(category));
              }).toList(),
              onChanged: (value) => setState(() => _selectedCategory = value),
            ),

            const SizedBox(height: AppConstants.defaultPadding),

            // Email field
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email (optional)',
                hintText: 'your.email@example.com',
                helperText: 'We may contact you for follow-up',
              ),
              keyboardType: TextInputType.emailAddress,
            ),

            const SizedBox(height: AppConstants.defaultPadding),

            // Feedback text
            TextField(
              controller: _feedbackController,
              decoration: const InputDecoration(
                labelText: 'Your feedback',
                hintText:
                    'Please share your thoughts, suggestions, or issues...',
              ),
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : widget.onCancel,
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _submitFeedback,
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Submit'),
        ),
      ],
    );
  }

  void _showRatingDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Rating'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('How would you rate your experience?'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  onPressed: () {
                    setState(() => _rating = index + 1);
                    Navigator.of(context).pop();
                  },
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 32,
                  ),
                );
              }),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitFeedback() async {
    if (_feedbackController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your feedback'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await widget.onSubmit(
        _feedbackController.text.trim(),
        _rating,
        _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        _selectedCategory,
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}

/// Widget that shows feedback prompts based on user actions
class FeedbackPromptWidget extends ConsumerWidget {
  final Widget child;

  const FeedbackPromptWidget({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Increment usage count when widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final feedbackService = ref.read(feedbackServiceProvider);
      feedbackService.incrementUsageCount();
    });

    return child;
  }
}

/// In-app rating widget for quick feedback
class InAppRatingWidget extends ConsumerStatefulWidget {
  final String title;
  final String subtitle;
  final Function(int rating)? onRatingChanged;

  const InAppRatingWidget({
    super.key,
    this.title = 'Rate your experience',
    this.subtitle = 'How was your experience with this feature?',
    this.onRatingChanged,
  });

  @override
  ConsumerState<InAppRatingWidget> createState() => _InAppRatingWidgetState();
}

class _InAppRatingWidgetState extends ConsumerState<InAppRatingWidget> {
  int _rating = 0;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              widget.subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppConstants.defaultPadding),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  onPressed: () {
                    setState(() => _rating = index + 1);
                    widget.onRatingChanged?.call(_rating);

                    // Save rating
                    final feedbackService = ref.read(feedbackServiceProvider);
                    feedbackService.saveUserRating(_rating);
                  },
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 28,
                  ),
                );
              }),
            ),

            if (_rating > 0) ...[
              const SizedBox(height: 8),
              Text(
                'Thank you for your feedback!',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Extension to add feedback methods to BuildContext
extension FeedbackContext on BuildContext {
  /// Show feedback request dialog
  Future<void> requestFeedback() async {
    return showDialog(
      context: this,
      builder: (context) => AlertDialog(
        title: const Text('Feedback'),
        content: const Text('How is your experience with the app?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Later'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Good'),
          ),
        ],
      ),
    );
  }

  /// Show detailed feedback dialog
  Future<void> showDetailedFeedback({
    int initialRating = 5,
    Function(String feedback, int rating, String? email, String? category)?
    onSubmit,
  }) {
    return showDialog<void>(
      context: this,
      builder: (context) => DetailedFeedbackDialog(
        initialRating: initialRating,
        onSubmit:
            onSubmit ??
            (feedback, rating, email, category) {
              debugPrint('Feedback: $feedback, Rating: $rating');
            },
        onCancel: () => Navigator.of(context).pop(),
      ),
    );
  }
}
