import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../../injection_container.dart';
import '../../../domain/entities/published_article.dart';
import '../../bloc/article_narration/article_narration_cubit.dart';
import '../../bloc/article_narration/article_narration_state.dart';
import '../../widgets/listen_button.dart';
import '../../widgets/published_article_tile.dart';

/// Full article written by a journalist, with its Markdown content rendered.
class PublishedArticleDetailView extends StatelessWidget {
  final PublishedArticleEntity article;

  const PublishedArticleDetailView({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ArticleNarrationCubit>(),
      child: PublishedArticleDetail(article: article),
    );
  }
}

/// The article screen. Expects an [ArticleNarrationCubit] above it.
class PublishedArticleDetail extends StatelessWidget {
  final PublishedArticleEntity article;

  const PublishedArticleDetail({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Ionicons.chevron_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          _buildHeader(),
          _buildThumbnail(),
          _buildContent(context),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(article.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, height: 1.25)),
          const SizedBox(height: 12),
          PublishedArticleByline(article: article),
          const SizedBox(height: 16),
          _buildListenButton(),
        ],
      ),
    );
  }

  Widget _buildListenButton() {
    return BlocConsumer<ArticleNarrationCubit, ArticleNarrationState>(
      listener: _showWhenUnavailable,
      builder: (context, state) => ListenButton(
        isReading: state is ArticleNarrationReading,
        onPressed: () => context.read<ArticleNarrationCubit>().toggleReading(article),
      ),
    );
  }

  void _showWhenUnavailable(BuildContext context, ArticleNarrationState state) {
    if (state is! ArticleNarrationUnavailable) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      duration: Duration(seconds: 8),
      content: Text('This device cannot read aloud. Check the text-to-speech settings of your phone.'),
    ));
  }

  Widget _buildThumbnail() {
    return Hero(
      tag: publishedArticleHeroTag(article),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: CachedNetworkImage(imageUrl: article.thumbnailUrl, fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
      child: MarkdownBody(
        data: article.content,
        selectable: true,
        styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
          p: textTheme.bodyLarge?.copyWith(fontSize: 17, height: 1.6),
          h2: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          h3: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          listBullet: textTheme.bodyLarge?.copyWith(fontSize: 17),
        ),
      ),
    );
  }
}
