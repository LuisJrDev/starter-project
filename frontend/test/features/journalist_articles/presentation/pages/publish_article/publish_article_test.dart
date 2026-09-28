import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/journalist_articles/domain/entities/article_draft.dart';
import 'package:news_app_clean_architecture/features/journalist_articles/domain/entities/article_thumbnail.dart';
import 'package:news_app_clean_architecture/features/journalist_articles/domain/usecases/get_saved_author_name.dart';
import 'package:news_app_clean_architecture/features/journalist_articles/domain/usecases/pick_thumbnail_from_gallery.dart';
import 'package:news_app_clean_architecture/features/journalist_articles/domain/usecases/publish_article.dart';
import 'package:news_app_clean_architecture/features/journalist_articles/presentation/bloc/publish_article/publish_article_cubit.dart';
import 'package:news_app_clean_architecture/features/journalist_articles/presentation/pages/publish_article/publish_article.dart';

const _contentHint = 'Add article here… Use the toolbar for **bold** text and ## subtitles.';

class MockPublishArticleUseCase extends Mock implements PublishArticleUseCase {}

class MockPickThumbnailFromGalleryUseCase extends Mock implements PickThumbnailFromGalleryUseCase {}

class MockGetSavedAuthorNameUseCase extends Mock implements GetSavedAuthorNameUseCase {}

void main() {
  late MockPublishArticleUseCase publishArticle;
  late MockPickThumbnailFromGalleryUseCase pickThumbnail;
  late MockGetSavedAuthorNameUseCase getSavedAuthorName;

  setUpAll(() => registerFallbackValue(const ArticleDraftEntity()));

  setUp(() {
    publishArticle = MockPublishArticleUseCase();
    pickThumbnail = MockPickThumbnailFromGalleryUseCase();
    getSavedAuthorName = MockGetSavedAuthorNameUseCase();
    when(() => getSavedAuthorName()).thenAnswer((_) async => const DataSuccess(null));
    when(() => pickThumbnail()).thenAnswer(
      (_) async => const DataSuccess(ArticleThumbnailEntity(localPath: '/gallery/photo.jpg', sizeInBytes: 1024)),
    );
  });

  /// Opens the publish form from a home screen and returns what the form popped with.
  Future<Future<Object?>> openPublishForm(WidgetTester tester) async {
    // A phone-sized surface, so the whole form is built without scrolling.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    late Future<Object?> result;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () => result = Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider(
                create: (_) => PublishArticleCubit(publishArticle, pickThumbnail, getSavedAuthorName)..loadSavedAuthorName(),
                child: const PublishArticleForm(),
              ),
            ),
          ),
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return result;
  }

  Future<void> fillInTheForm(WidgetTester tester) async {
    await tester.enterText(find.widgetWithText(TextField, 'Title'), 'Breaking News!');
    await tester.enterText(find.widgetWithText(TextField, 'Written by'), 'Daily News Staff');
    await tester.enterText(find.widgetWithText(TextField, _contentHint), 'This is **breaking** news.');
    await tester.tap(find.text('Attach Image'));
    await tester.pumpAndSettle();
  }

  Future<void> tapPublish(WidgetTester tester) async {
    await tester.tap(find.text('Publish Article').last);
    await tester.pump();
  }

  testWidgets('publishing an empty article shows what is missing in every field', (tester) async {
    await openPublishForm(tester);

    await tapPublish(tester);
    await tester.pumpAndSettle();

    expect(find.text('Add a title for your article.'), findsOneWidget);
    expect(find.text('Sign the article with your name.'), findsOneWidget);
    expect(find.text('Attach an image to illustrate your article.'), findsOneWidget);
    expect(find.text('Write your article before publishing it.'), findsOneWidget);
    verifyNever(() => publishArticle(params: any(named: 'params')));
  });

  testWidgets('prefills the signature of the previous article', (tester) async {
    when(() => getSavedAuthorName()).thenAnswer((_) async => const DataSuccess('Daily News Staff'));

    await openPublishForm(tester);

    expect(find.widgetWithText(TextField, 'Daily News Staff'), findsOneWidget);
  });

  testWidgets('the title counter counts an emoji as 2, like the backend', (tester) async {
    await openPublishForm(tester);

    await tester.enterText(find.widgetWithText(TextField, 'Title'), 'Hi 😀');
    await tester.pump();

    expect(find.text('5/100'), findsOneWidget);
  });

  testWidgets('attaching an image shows it instead of the button', (tester) async {
    await openPublishForm(tester);

    await tester.tap(find.text('Attach Image'));
    await tester.pumpAndSettle();

    expect(find.text('Change image'), findsOneWidget);
    expect(find.text('Attach Image'), findsNothing);
  });

  testWidgets('shows progress and blocks the button while publishing', (tester) async {
    final pendingPublish = Completer<DataState<void>>();
    when(() => publishArticle(params: any(named: 'params'))).thenAnswer((_) => pendingPublish.future);
    await openPublishForm(tester);
    await fillInTheForm(tester);

    await tapPublish(tester);

    expect(find.text('Publishing…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.text('Publishing…'));
    verify(() => publishArticle(params: any(named: 'params'))).called(1);
    pendingPublish.complete(const DataSuccess(null));
    await tester.pumpAndSettle();
  });

  testWidgets('goes back to the home screen with a success result once published', (tester) async {
    when(() => publishArticle(params: any(named: 'params'))).thenAnswer((_) async => const DataSuccess(null));
    final result = await openPublishForm(tester);
    await fillInTheForm(tester);

    await tapPublish(tester);
    await tester.pumpAndSettle();

    expect(await result, isTrue);
    expect(find.byType(PublishArticleForm), findsNothing);
  });

  testWidgets('offers to retry when publishing fails', (tester) async {
    when(() => publishArticle(params: any(named: 'params'))).thenAnswer((_) async => DataFailed(Exception('offline')));
    await openPublishForm(tester);
    await fillInTheForm(tester);

    await tapPublish(tester);
    await tester.pumpAndSettle();

    expect(find.textContaining('could not be published'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('asks before discarding a half-written article', (tester) async {
    await openPublishForm(tester);
    await tester.enterText(find.widgetWithText(TextField, 'Title'), 'Draft');
    await tester.pump();

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Discard this article?'), findsOneWidget);

    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(find.byType(PublishArticleForm), findsNothing);
  });
}
