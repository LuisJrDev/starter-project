import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../../injection_container.dart';
import '../../../domain/entities/article_draft.dart';
import '../../bloc/publish_article/publish_article_cubit.dart';
import '../../bloc/publish_article/publish_article_state.dart';
import '../../widgets/add_thumbnail.dart';
import '../../widgets/article_draft_error_messages.dart';
import '../../widgets/limited_text_field.dart';
import '../../widgets/markdown_editor.dart';
import '../../widgets/publish_article_button.dart';

/// Screen where a journalist writes and publishes an article.
/// Pops with `true` once the article has been published.
class PublishArticleView extends StatelessWidget {
  const PublishArticleView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<PublishArticleCubit>()..loadSavedAuthorName(),
      child: const PublishArticleForm(),
    );
  }
}

class _FormControllers {
  final TextEditingController title;
  final TextEditingController author;
  final TextEditingController content;

  const _FormControllers({required this.title, required this.author, required this.content});
}

/// What every form field needs from the current state.
class _FormBinding {
  final PublishArticleCubit cubit;
  final ArticleDraftErrorMessages errors;
  final bool isEditable;

  const _FormBinding({required this.cubit, required this.errors, required this.isEditable});
}

/// The publish form. Expects a [PublishArticleCubit] above it.
class PublishArticleForm extends HookWidget {
  const PublishArticleForm({super.key});

  @override
  Widget build(BuildContext context) {
    final controllers = _FormControllers(
      title: useTextEditingController(),
      author: useTextEditingController(),
      content: useTextEditingController(),
    );
    return BlocConsumer<PublishArticleCubit, PublishArticleState>(
      listener: (context, state) {
        _prefillAuthor(controllers.author, state);
        _onStateChanged(context, state);
      },
      builder: (context, state) => PopScope(
        canPop: _canLeaveWithoutConfirmation(state),
        onPopInvokedWithResult: (didPop, _) => _onLeaveBlocked(context, didPop),
        child: Scaffold(
          appBar: _buildAppBar(context),
          body: _buildForm(state, controllers),
          bottomNavigationBar: PublishArticleButton(
            isPublishing: state is PublishArticlePublishing,
            onPressed: () => _onPublishPressed(context),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      leading: IconButton(
        tooltip: 'Back',
        icon: const Icon(Ionicons.chevron_back, color: Colors.black),
        onPressed: () => Navigator.maybePop(context),
      ),
      title: const Text('Publish Article', style: TextStyle(color: Colors.black)),
    );
  }

  Widget _buildForm(PublishArticleState state, _FormControllers controllers) {
    return Builder(builder: (context) {
      final binding = _FormBinding(
        cubit: context.read<PublishArticleCubit>(),
        errors: ArticleDraftErrorMessages(state.visibleErrors),
        isEditable: state is! PublishArticlePublishing,
      );
      return ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          _padded(_buildTitleField(binding, controllers.title)),
          const SizedBox(height: 12),
          _padded(_buildAuthorField(binding, controllers.author)),
          const SizedBox(height: 20),
          _buildThumbnail(binding, state),
          const SizedBox(height: 20),
          _padded(_buildContentEditor(binding, controllers.content)),
        ],
      );
    });
  }

  Widget _buildTitleField(_FormBinding binding, TextEditingController controller) {
    return LimitedTextField(
      controller: controller,
      label: 'Title',
      hintText: 'Write your title here…',
      maxLength: ArticleDraftEntity.titleMaxLength,
      maxLines: null,
      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
      errorText: binding.errors.title,
      enabled: binding.isEditable,
      onChanged: binding.cubit.changeTitle,
    );
  }

  Widget _buildAuthorField(_FormBinding binding, TextEditingController controller) {
    return LimitedTextField(
      controller: controller,
      label: 'Written by',
      hintText: 'Your name',
      maxLength: ArticleDraftEntity.authorMaxLength,
      errorText: binding.errors.author,
      enabled: binding.isEditable,
      onChanged: binding.cubit.changeAuthor,
    );
  }

  Widget _buildThumbnail(_FormBinding binding, PublishArticleState state) {
    return AddThumbnail(
      imagePath: state.draft.thumbnail?.localPath,
      errorText: binding.errors.thumbnail,
      onPickImage: binding.isEditable ? binding.cubit.pickThumbnail : null,
    );
  }

  Widget _buildContentEditor(_FormBinding binding, TextEditingController controller) {
    return MarkdownEditor(
      controller: controller,
      maxLength: ArticleDraftEntity.contentMaxLength,
      errorText: binding.errors.content,
      enabled: binding.isEditable,
      onChanged: binding.cubit.changeContent,
    );
  }

  Widget _padded(Widget child) {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: child);
  }

  bool _canLeaveWithoutConfirmation(PublishArticleState state) {
    return state is! PublishArticlePublishing && !state.hasUnsavedChanges;
  }

  void _onPublishPressed(BuildContext context) {
    FocusScope.of(context).unfocus();
    context.read<PublishArticleCubit>().publish();
  }

  void _prefillAuthor(TextEditingController authorController, PublishArticleState state) {
    if (authorController.text.isEmpty && state.draft.author.isNotEmpty) {
      authorController.text = state.draft.author;
    }
  }

  void _onStateChanged(BuildContext context, PublishArticleState state) {
    if (state is PublishArticleSuccess) {
      Navigator.pop(context, true);
    } else if (state is PublishArticleFailure) {
      _showFailure(context, state.reason);
    }
  }

  void _showFailure(BuildContext context, PublishArticleFailureReason reason) {
    final isPublishFailure = reason == PublishArticleFailureReason.publishFailed;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(isPublishFailure
            ? 'Your article could not be published. Check your connection and try again.'
            : 'The gallery could not be opened. Check the app permissions and try again.'),
        action: isPublishFailure
            ? SnackBarAction(label: 'Retry', onPressed: context.read<PublishArticleCubit>().publish)
            : null,
      ));
  }

  Future<void> _onLeaveBlocked(BuildContext context, bool didPop) async {
    final cubit = context.read<PublishArticleCubit>();
    if (didPop || cubit.state is PublishArticlePublishing) return;
    final shouldDiscard = await _confirmDiscard(context);
    if (shouldDiscard && context.mounted) Navigator.pop(context);
  }

  Future<bool> _confirmDiscard(BuildContext context) async {
    final shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Discard this article?'),
        content: const Text('What you have written will be lost.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Keep writing')),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Discard')),
        ],
      ),
    );
    return shouldDiscard ?? false;
  }
}
