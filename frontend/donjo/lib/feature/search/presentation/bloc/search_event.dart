library;

import 'package:donjo/feature/search/data/models/search_models.dart';

sealed class SearchEvent {
  const SearchEvent();
}

/// Execute a search with the given filters.
final class SearchStarted extends SearchEvent {
  const SearchStarted({required this.filters});
  final SearchFilters filters;
}

final class SearchResultsCleared extends SearchEvent {
  const SearchResultsCleared();
}

final class SearchErrorCleared extends SearchEvent {
  const SearchErrorCleared();
}