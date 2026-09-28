import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/core/usecase/usecase.dart';

import '../repository/author_signature_repository.dart';

/// The signature of the last article published from this device, to prefill the next one.
class GetSavedAuthorNameUseCase implements UseCase<DataState<String?>, void> {
  final AuthorSignatureRepository _authorSignatureRepository;

  GetSavedAuthorNameUseCase(this._authorSignatureRepository);

  @override
  Future<DataState<String?>> call({void params}) {
    return _authorSignatureRepository.getSavedAuthorName();
  }
}
