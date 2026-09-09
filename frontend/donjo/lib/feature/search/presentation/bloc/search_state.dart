library;

import 'package:donjo/feature/search/data/models/search_models.dart';

enum SearchStatus {
  initial,
  searching,
  loaded,
  failure,
}

class SearchError {
  const SearchError({required this.message, this.fields = const {}});

  final String message;
  final Map<String, String> fields;
}

class SearchState {
  const SearchState({
    this.status = SearchStatus.initial,
    this.filters,
    this.result,
    this.error,
  });

  final SearchStatus status;
  final SearchFilters? filters;
  final SearchResult? result;
  final SearchError? error;

  bool get busy => status == SearchStatus.searching;
  int get total => result?.total ?? 0;
  List<SearchHit> get hits => result?.hits ?? const [];

  SearchState copyWith({
    SearchStatus? status,
    SearchFilters? filters,
    bool clearFilters = false,
    SearchResult? result,
    bool clearResult = false,
    SearchError? error,
    bool clearError = false,
  }) {
    return SearchState(
      status: status ?? this.status,
      filters: clearFilters ? null : filters ?? this.filters,
      result: clearResult ? null : result ?? this.result,
      error: clearError ? null : error ?? this.error,
    );
  }
}