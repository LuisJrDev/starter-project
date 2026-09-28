import 'package:equatable/equatable.dart';

sealed class ArticleNarrationState extends Equatable {
  const ArticleNarrationState();

  @override
  List<Object?> get props => [];
}

final class ArticleNarrationIdle extends ArticleNarrationState {
  const ArticleNarrationIdle();
}

final class ArticleNarrationReading extends ArticleNarrationState {
  const ArticleNarrationReading();
}

/// The device has no usable text-to-speech engine.
final class ArticleNarrationUnavailable extends ArticleNarrationState {
  const ArticleNarrationUnavailable();
}
