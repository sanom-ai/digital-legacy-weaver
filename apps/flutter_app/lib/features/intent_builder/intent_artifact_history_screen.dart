import 'package:digital_legacy_weaver/features/intent_builder/intent_artifact_compare_screen.dart';
import 'package:digital_legacy_weaver/features/intent_builder/intent_artifact_review_screen.dart';
import 'package:digital_legacy_weaver/features/intent_builder/intent_canonical_artifact_model.dart';
import 'package:flutter/material.dart';

typedef ArtifactHistoryAction =
    Future<void> Function(IntentCanonicalArtifactModel artifact);

class IntentArtifactHistoryScreen extends StatefulWidget {
  const IntentArtifactHistoryScreen({
    super.key,
    required this.currentArtifact,
    required this.artifactHistory,
    required this.onPromote,
    required this.onRemove,
  });

  final IntentCanonicalArtifactModel? currentArtifact;
  final List<IntentCanonicalArtifactModel> artifactHistory;
  final ArtifactHistoryAction onPromote;
  final ArtifactHistoryAction onRemove;

  @override
  State<IntentArtifactHistoryScreen> createState() =>
      _IntentArtifactHistoryScreenState();
}

class _IntentArtifactHistoryScreenState
    extends State<IntentArtifactHistoryScreen> {
  String _historyFilter = 'all';
  String _historySort = 'newest';

  Future<bool> _confirmPromote(IntentCanonicalArtifactModel artifact) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Copy as latest version"),
        content: Text(
          "Create a fresh exported version from ${artifact.artifactId}? The original history entry stays unchanged.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancel"),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Copy"),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<bool> _confirmRemove(IntentCanonicalArtifactModel artifact) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Remove version"),
        content: Text(
          "Remove ${artifact.artifactId} from local version history on this device?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancel"),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Remove"),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  List<String> _artifactBadges(IntentCanonicalArtifactModel artifact) {
    final badges = <String>[];
    if (widget.currentArtifact != null &&
        artifact.artifactId == widget.currentArtifact!.artifactId) {
      badges.add("Latest");
    }
    if (artifact.promotedFromArtifactId != null &&
        artifact.promotedFromArtifactId!.isNotEmpty) {
      badges.add("Copied");
    }
    if (artifact.artifactState == IntentArtifactState.ready) {
      badges.add("Ready");
    } else if (artifact.artifactState == IntentArtifactState.reviewed) {
      badges.add("Reviewed");
    }
    if (artifact.report.errorCount > 0) {
      badges.add("Has issues");
    }
    return badges;
  }

  List<IntentCanonicalArtifactModel> _visibleArtifactHistory() {
    final filtered = widget.artifactHistory.where((artifact) {
      switch (_historyFilter) {
        case 'ready':
          return artifact.artifactState == IntentArtifactState.ready;
        case 'promoted':
          return artifact.promotedFromArtifactId != null &&
              artifact.promotedFromArtifactId!.isNotEmpty;
        case 'issues':
          return artifact.report.errorCount > 0;
        default:
          return true;
      }
    }).toList();

    filtered.sort((left, right) {
      switch (_historySort) {
        case 'oldest':
          return left.generatedAt.compareTo(right.generatedAt);
        case 'state':
          return left.artifactState.name.compareTo(right.artifactState.name);
        default:
          return right.generatedAt.compareTo(left.generatedAt);
      }
    });
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final visibleArtifactHistory = _visibleArtifactHistory();
    return Scaffold(
      appBar: AppBar(title: const Text("Exported Version History")),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Full version history",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text("Stored versions: ${widget.artifactHistory.length}"),
                  if (widget.currentArtifact != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      "Latest pinned version: ${widget.currentArtifact!.artifactId} | ${widget.currentArtifact!.artifactState.name}",
                    ),
                  ],
                  const SizedBox(height: 8),
                  const Text(
                    "Review, compare, and copy actions happen locally on this device. Older versions stay until you remove them.",
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ChoiceChip(
                        label: const Text("All"),
                        selected: _historyFilter == 'all',
                        onSelected: (_) =>
                            setState(() => _historyFilter = 'all'),
                      ),
                      ChoiceChip(
                        label: const Text("Ready"),
                        selected: _historyFilter == 'ready',
                        onSelected: (_) =>
                            setState(() => _historyFilter = 'ready'),
                      ),
                      ChoiceChip(
                        label: const Text("Copied"),
                        selected: _historyFilter == 'promoted',
                        onSelected: (_) =>
                            setState(() => _historyFilter = 'promoted'),
                      ),
                      ChoiceChip(
                        label: const Text("Has issues"),
                        selected: _historyFilter == 'issues',
                        onSelected: (_) =>
                            setState(() => _historyFilter = 'issues'),
                      ),
                      DropdownButton<String>(
                        value: _historySort,
                        items: const [
                          DropdownMenuItem(
                            value: 'newest',
                            child: Text("Newest first"),
                          ),
                          DropdownMenuItem(
                            value: 'oldest',
                            child: Text("Oldest first"),
                          ),
                          DropdownMenuItem(
                            value: 'state',
                            child: Text("Sort by state"),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          setState(() => _historySort = value);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (visibleArtifactHistory.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text("No versions match the current history filter."),
              ),
            ),
          ...visibleArtifactHistory.map(
            (artifact) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                child: ListTile(
                  title: Text(
                    "${artifact.generatedAt.toLocal()} | ${artifact.artifactState.name}",
                  ),
                  subtitle: Text(
                    "Version ${artifact.artifactId} | ${artifact.activeEntryCount} active routes",
                  ),
                  isThreeLine: _artifactBadges(artifact).isNotEmpty,
                  leading: _artifactBadges(artifact).isEmpty
                      ? null
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _artifactBadges(artifact)
                              .take(2)
                              .map(
                                (badge) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: _HistoryPill(label: badge),
                                ),
                              )
                              .toList(),
                        ),
                  trailing: Wrap(
                    spacing: 8,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => IntentArtifactReviewScreen(
                                artifact: artifact,
                              ),
                            ),
                          );
                        },
                        child: const Text("Review"),
                      ),
                      TextButton(
                        onPressed:
                            widget.currentArtifact != null &&
                                artifact.artifactId !=
                                    widget.currentArtifact!.artifactId
                            ? () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => IntentArtifactCompareScreen(
                                      currentArtifact: widget.currentArtifact!,
                                      compareArtifact: artifact,
                                    ),
                                  ),
                                );
                              }
                            : null,
                        child: const Text("Compare"),
                      ),
                      TextButton(
                        onPressed:
                            widget.currentArtifact != null &&
                                artifact.artifactId !=
                                    widget.currentArtifact!.artifactId
                            ? () async {
                                final messenger = ScaffoldMessenger.of(context);
                                final navigator = Navigator.of(context);
                                final confirmed = await _confirmPromote(
                                  artifact,
                                );
                                if (!confirmed) {
                                  return;
                                }
                                await widget.onPromote(artifact);
                                if (!mounted) return;
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Historical version copied into a fresh exported version.",
                                    ),
                                  ),
                                );
                                navigator.pop();
                              }
                            : null,
                        child: const Text("Copy"),
                      ),
                      TextButton(
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final navigator = Navigator.of(context);
                          final confirmed = await _confirmRemove(artifact);
                          if (!confirmed) {
                            return;
                          }
                          await widget.onRemove(artifact);
                          if (!mounted) return;
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Version removed from local history.",
                              ),
                            ),
                          );
                          navigator.pop();
                        },
                        child: const Text("Remove"),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryPill extends StatelessWidget {
  const _HistoryPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: const Color(0xFFE5D7C5),
      ),
      child: Text(label),
    );
  }
}
