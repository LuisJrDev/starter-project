import 'package:flutter/material.dart';

/// Full-width "Publish Article" button pinned to the bottom of the publish screen.
class PublishArticleButton extends StatelessWidget {
  final bool isPublishing;
  final VoidCallback onPressed;

  const PublishArticleButton({super.key, required this.isPublishing, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: FilledButton.tonalIcon(
          onPressed: isPublishing ? null : onPressed,
          icon: isPublishing ? _buildProgressIndicator() : const Icon(Icons.login, size: 26),
          label: Text(isPublishing ? 'Publishing…' : 'Publish Article'),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(64),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.5));
  }
}
