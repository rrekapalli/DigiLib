import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// Help system for providing tutorials and documentation
class HelpSystem {
  static HelpSystem? _instance;
  static HelpSystem get instance => _instance ??= HelpSystem._();
  
  HelpSystem._();

  /// Show help dialog for a specific feature
  Future<void> showHelp(
    BuildContext context, {
    required String title,
    required String content,
    List<HelpStep>? steps,
    List<HelpAction>? actions,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => HelpDialog(
        title: title,
        content: content,
        steps: steps,
        actions: actions,
      ),
    );
  }

  /// Show tutorial overlay for onboarding
  void showTutorial(
    BuildContext context, {
    required List<TutorialStep> steps,
    VoidCallback? onComplete,
  }) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, animation, secondaryAnimation) => TutorialOverlay(
          steps: steps,
          onComplete: onComplete,
        ),
      ),
    );
  }

  /// Show quick tip
  void showQuickTip(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 4),
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    
    entry = OverlayEntry(
      builder: (context) => QuickTip(
        message: message,
        duration: duration,
        onDismiss: () => entry.remove(),
      ),
    );

    overlay.insert(entry);
  }
}

/// Help dialog widget
class HelpDialog extends StatelessWidget {
  final String title;
  final String content;
  final List<HelpStep>? steps;
  final List<HelpAction>? actions;

  const HelpDialog({
    super.key,
    required this.title,
    required this.content,
    this.steps,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.help_outline, color: Colors.blue, size: 32),
      title: Text(title),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              content,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (steps != null && steps!.isNotEmpty) ...[
              const SizedBox(height: AppConstants.defaultPadding),
              Text(
                'Steps:',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              ...steps!.asMap().entries.map((entry) {
                final index = entry.key;
                final step = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              step.title,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            if (step.description != null)
                              Text(
                                step.description!,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
      actions: [
        ...?actions?.map((action) => TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            action.onPressed();
          },
          child: Text(action.label),
        )),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Got it'),
        ),
      ],
    );
  }
}

/// Tutorial overlay for guided onboarding
class TutorialOverlay extends StatefulWidget {
  final List<TutorialStep> steps;
  final VoidCallback? onComplete;

  const TutorialOverlay({
    super.key,
    required this.steps,
    this.onComplete,
  });

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay> {
  int _currentStep = 0;
  
  @override
  Widget build(BuildContext context) {
    if (_currentStep >= widget.steps.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pop();
        widget.onComplete?.call();
      });
      return const SizedBox.shrink();
    }

    final step = widget.steps[_currentStep];
    
    return Material(
      color: Colors.black.withValues(alpha: 0.7),
      child: Stack(
        children: [
          // Highlight area
          if (step.targetKey != null)
            _buildHighlight(step.targetKey!),
          
          // Tutorial content
          Positioned(
            left: 20,
            right: 20,
            bottom: 100,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(step.icon, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            step.title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        Text(
                          '${_currentStep + 1}/${widget.steps.length}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      step.description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppConstants.defaultPadding),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: _currentStep > 0 ? _previousStep : null,
                          child: const Text('Previous'),
                        ),
                        Row(
                          children: [
                            TextButton(
                              onPressed: _skipTutorial,
                              child: const Text('Skip'),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(
                              onPressed: _nextStep,
                              child: Text(_currentStep == widget.steps.length - 1 ? 'Finish' : 'Next'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlight(GlobalKey targetKey) {
    // This would typically use the target key to position the highlight
    // For now, we'll show a simple circular highlight in the center
    return const Center(
      child: CircleAvatar(
        radius: 50,
        backgroundColor: Colors.white,
      ),
    );
  }

  void _nextStep() {
    if (_currentStep < widget.steps.length - 1) {
      setState(() => _currentStep++);
    } else {
      Navigator.of(context).pop();
      widget.onComplete?.call();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  void _skipTutorial() {
    Navigator.of(context).pop();
    widget.onComplete?.call();
  }
}

/// Quick tip widget
class QuickTip extends StatefulWidget {
  final String message;
  final Duration duration;
  final VoidCallback onDismiss;

  const QuickTip({
    super.key,
    required this.message,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<QuickTip> createState() => _QuickTipState();
}

class _QuickTipState extends State<QuickTip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_controller);

    _controller.forward();

    // Auto dismiss after duration
    Future.delayed(widget.duration, () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() async {
    await _controller.reverse();
    if (mounted) {
      widget.onDismiss();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 60,
      left: 20,
      right: 20,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
          child: Container(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline, color: Colors.blue.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _dismiss,
                  icon: Icon(Icons.close, color: Colors.blue.shade700, size: 20),
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Help screen with comprehensive documentation
class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  int _selectedIndex = 0;
  
  final List<HelpCategory> _categories = [
    HelpCategory(
      title: 'Getting Started',
      icon: Icons.play_arrow,
      topics: [
        HelpTopic(
          title: 'Welcome to Digital Library',
          content: 'Learn the basics of using the Digital Library app to manage and read your documents.',
          steps: [
            HelpStep(title: 'Sign in to your account', description: 'Use OAuth2 to authenticate'),
            HelpStep(title: 'Add your first library', description: 'Connect local folders or cloud storage'),
            HelpStep(title: 'Browse your documents', description: 'Navigate through your collection'),
          ],
        ),
        HelpTopic(
          title: 'Adding Libraries',
          content: 'Connect different sources to build your digital library collection.',
        ),
      ],
    ),
    HelpCategory(
      title: 'Reading Documents',
      icon: Icons.menu_book,
      topics: [
        HelpTopic(
          title: 'Document Reader',
          content: 'Learn how to use the document reader with all its features.',
        ),
        HelpTopic(
          title: 'Annotations & Bookmarks',
          content: 'Add bookmarks, highlights, and comments to your documents.',
        ),
      ],
    ),
    HelpCategory(
      title: 'Organization',
      icon: Icons.folder_outlined,
      topics: [
        HelpTopic(
          title: 'Tags & Categories',
          content: 'Organize your documents with tags and categories.',
        ),
        HelpTopic(
          title: 'Search & Filters',
          content: 'Find documents quickly using search and filtering options.',
        ),
      ],
    ),
    HelpCategory(
      title: 'Sync & Sharing',
      icon: Icons.sync,
      topics: [
        HelpTopic(
          title: 'Cross-Device Sync',
          content: 'Keep your library synchronized across all your devices.',
        ),
        HelpTopic(
          title: 'Sharing Documents',
          content: 'Share documents and collaborate with others.',
        ),
      ],
    ),
    HelpCategory(
      title: 'Troubleshooting',
      icon: Icons.help_outline,
      topics: [
        HelpTopic(
          title: 'Common Issues',
          content: 'Solutions to frequently encountered problems.',
        ),
        HelpTopic(
          title: 'Offline Mode',
          content: 'Understanding how the app works when offline.',
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        actions: [
          IconButton(
            onPressed: () => _showFeedbackDialog(),
            icon: const Icon(Icons.feedback),
            tooltip: 'Send Feedback',
          ),
        ],
      ),
      body: Row(
        children: [
          // Categories sidebar
          SizedBox(
            width: 200,
            child: ListView.builder(
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = index == _selectedIndex;
                
                return ListTile(
                  leading: Icon(
                    category.icon,
                    color: isSelected 
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  title: Text(
                    category.title,
                    style: TextStyle(
                      color: isSelected 
                          ? Theme.of(context).colorScheme.primary
                          : null,
                      fontWeight: isSelected ? FontWeight.w600 : null,
                    ),
                  ),
                  selected: isSelected,
                  onTap: () => setState(() => _selectedIndex = index),
                );
              },
            ),
          ),
          
          const VerticalDivider(width: 1),
          
          // Content area
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final category = _categories[_selectedIndex];
    
    return ListView(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      children: [
        Text(
          category.title,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: AppConstants.defaultPadding),
        
        ...category.topics.map((topic) => Card(
          margin: const EdgeInsets.only(bottom: AppConstants.defaultPadding),
          child: ExpansionTile(
            title: Text(topic.title),
            children: [
              Padding(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      topic.content,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (topic.steps != null && topic.steps!.isNotEmpty) ...[
                      const SizedBox(height: AppConstants.defaultPadding),
                      Text(
                        'Steps:',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      ...topic.steps!.asMap().entries.map((entry) {
                        final index = entry.key;
                        final step = entry.value;
                        return ListTile(
                          leading: CircleAvatar(
                            radius: 12,
                            child: Text('${index + 1}'),
                          ),
                          title: Text(step.title),
                          subtitle: step.description != null ? Text(step.description!) : null,
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  void _showFeedbackDialog() {
    // This would show the feedback dialog from error_reporting_dialog.dart
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Feedback'),
        content: const Text('Would you like to send feedback about the app?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Show feedback dialog
            },
            child: const Text('Send Feedback'),
          ),
        ],
      ),
    );
  }
}

/// Data models for help system
class HelpStep {
  final String title;
  final String? description;

  const HelpStep({
    required this.title,
    this.description,
  });
}

class HelpAction {
  final String label;
  final VoidCallback onPressed;

  const HelpAction({
    required this.label,
    required this.onPressed,
  });
}

class TutorialStep {
  final String title;
  final String description;
  final IconData icon;
  final GlobalKey? targetKey;

  const TutorialStep({
    required this.title,
    required this.description,
    this.icon = Icons.info,
    this.targetKey,
  });
}

class HelpTopic {
  final String title;
  final String content;
  final List<HelpStep>? steps;

  const HelpTopic({
    required this.title,
    required this.content,
    this.steps,
  });
}

class HelpCategory {
  final String title;
  final IconData icon;
  final List<HelpTopic> topics;

  const HelpCategory({
    required this.title,
    required this.icon,
    required this.topics,
  });
}

/// Extension to add help methods to BuildContext
extension HelpContext on BuildContext {
  /// Show help for a specific feature
  Future<void> showHelp({
    required String title,
    required String content,
    List<HelpStep>? steps,
    List<HelpAction>? actions,
  }) {
    return HelpSystem.instance.showHelp(
      this,
      title: title,
      content: content,
      steps: steps,
      actions: actions,
    );
  }

  /// Show tutorial overlay
  void showTutorial({
    required List<TutorialStep> steps,
    VoidCallback? onComplete,
  }) {
    HelpSystem.instance.showTutorial(
      this,
      steps: steps,
      onComplete: onComplete,
    );
  }

  /// Show quick tip
  void showQuickTip(String message, {
    Duration duration = const Duration(seconds: 4),
  }) {
    HelpSystem.instance.showQuickTip(
      this,
      message: message,
      duration: duration,
    );
  }
}