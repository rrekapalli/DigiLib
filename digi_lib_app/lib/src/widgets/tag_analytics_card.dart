import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/tag_provider.dart';

/// Card widget displaying tag usage analytics and statistics
class TagAnalyticsCard extends ConsumerWidget {
  const TagAnalyticsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagState = ref.watch(tagProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Tag Analytics',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            if (tagState.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (tagState.error != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: colorScheme.error,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load analytics',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        tagState.error!,
                        style: theme.textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              _buildAnalyticsContent(context, tagState.tags),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsContent(BuildContext context, List tags) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Mock analytics data - in real implementation, this would come from the service
    final totalTags = tags.length;
    final usedTags = (totalTags * 0.8).round(); // Mock: 80% of tags are used
    final unusedTags = totalTags - usedTags;
    final totalUsage = totalTags * 3; // Mock: average 3 uses per tag
    final averageUsage = totalTags > 0 ? totalUsage / totalTags : 0.0;

    return Column(
      children: [
        // Overview statistics
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                'Total Tags',
                totalTags.toString(),
                Icons.label,
                colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                'Used Tags',
                usedTags.toString(),
                Icons.check_circle,
                Colors.green,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                'Unused Tags',
                unusedTags.toString(),
                Icons.remove_circle,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                'Total Usage',
                totalUsage.toString(),
                Icons.trending_up,
                colorScheme.secondary,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // Usage distribution
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Usage Distribution',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              
              // Usage bar
              if (totalTags > 0) ...[
                Row(
                  children: [
                    Text(
                      'Used',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: usedTags / totalTags,
                        backgroundColor: colorScheme.outline.withValues(alpha: 0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${((usedTags / totalTags) * 100).round()}%',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'Unused',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: unusedTags / totalTags,
                        backgroundColor: colorScheme.outline.withValues(alpha: 0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${((unusedTags / totalTags) * 100).round()}%',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ] else
                Text(
                  'No tags to analyze',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              
              const SizedBox(height: 16),
              
              // Average usage
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Average usage per tag:',
                    style: theme.textTheme.bodyMedium,
                  ),
                  Text(
                    '${averageUsage.toStringAsFixed(1)} documents',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Most popular tags (mock data)
        if (totalTags > 0) ...[
          Text(
            'Most Popular Tags',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          
          ...tags.take(5).map<Widget>((tag) {
            final mockUsage = (tag.name.hashCode.abs() % 10) + 1;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getTagColor(tag.name).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getTagColor(tag.name).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      tag.name,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _getTagColor(tag.name),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$mockUsage documents',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 20,
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Color _getTagColor(String tagName) {
    final hash = tagName.hashCode;
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];
    return colors[hash.abs() % colors.length];
  }
}