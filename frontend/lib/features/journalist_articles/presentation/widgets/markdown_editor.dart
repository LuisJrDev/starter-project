import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import 'length_counter.dart';
import 'markdown_formatting.dart';

/// Article body editor: a Markdown text area with a formatting toolbar and a live preview.
class MarkdownEditor extends StatefulWidget {
  final TextEditingController controller;
  final int maxLength;
  final ValueChanged<String> onChanged;
  final String? errorText;
  final bool enabled;

  const MarkdownEditor({
    super.key,
    required this.controller,
    required this.maxLength,
    required this.onChanged,
    this.errorText,
    this.enabled = true,
  });

  @override
  State<MarkdownEditor> createState() => _MarkdownEditorState();
}

class _MarkdownEditorState extends State<MarkdownEditor> {
  bool _isPreviewing = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildModeSelector(),
        if (!_isPreviewing) _buildFormattingToolbar(),
        const SizedBox(height: 8),
        _isPreviewing ? _buildPreview(context) : _buildTextArea(),
      ],
    );
  }

  Widget _buildModeSelector() {
    return SegmentedButton<bool>(
      segments: const [
        ButtonSegment(value: false, label: Text('Write'), icon: Icon(Icons.edit_outlined)),
        ButtonSegment(value: true, label: Text('Preview'), icon: Icon(Icons.visibility_outlined)),
      ],
      selected: {_isPreviewing},
      onSelectionChanged: (selection) => setState(() => _isPreviewing = selection.single),
      showSelectedIcon: false,
    );
  }

  Widget _buildFormattingToolbar() {
    final isEnabled = widget.enabled;
    return Row(
      children: [
        _FormatButton(icon: Icons.format_bold, tooltip: 'Bold', onPressed: isEnabled ? () => _wrap('**') : null),
        _FormatButton(icon: Icons.format_italic, tooltip: 'Italic', onPressed: isEnabled ? () => _wrap('*') : null),
        _FormatButton(icon: Icons.title, tooltip: 'Subtitle', onPressed: isEnabled ? () => _prefix('## ') : null),
        _FormatButton(
          icon: Icons.format_list_bulleted,
          tooltip: 'Bulleted list',
          onPressed: isEnabled ? () => _prefix('- ') : null,
        ),
      ],
    );
  }

  Widget _buildTextArea() {
    return TextField(
      controller: widget.controller,
      onChanged: widget.onChanged,
      enabled: widget.enabled,
      minLines: 10,
      maxLines: null,
      keyboardType: TextInputType.multiline,
      textCapitalization: TextCapitalization.sentences,
      style: const TextStyle(fontSize: 16, height: 1.5),
      decoration: InputDecoration(
        hintText: 'Add article here… Use the toolbar for **bold** text and ## subtitles.',
        errorText: widget.errorText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        counter: LengthCounter(controller: widget.controller, maxLength: widget.maxLength),
      ),
    );
  }

  Widget _buildPreview(BuildContext context) {
    final text = widget.controller.text.trim();
    return Container(
      constraints: const BoxConstraints(minHeight: 240),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(12),
      ),
      child: MarkdownBody(data: text.isEmpty ? '*Nothing to preview yet.*' : text),
    );
  }

  void _wrap(String marker) => _apply(wrapSelection(widget.controller.value, marker));

  void _prefix(String prefix) => _apply(prefixSelectedLines(widget.controller.value, prefix));

  void _apply(TextEditingValue value) {
    widget.controller.value = value;
    widget.onChanged(value.text);
  }
}

class _FormatButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  const _FormatButton({required this.icon, required this.tooltip, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(icon: Icon(icon), tooltip: tooltip, onPressed: onPressed);
  }
}
