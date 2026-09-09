library;

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:donjo/core/network/api_exception.dart';
import 'package:donjo/feature/search/data/repositories/search_repository.dart';
import 'package:donjo/feature/search/presentation/bloc/search_event.dart';
import 'package:donjo/feature/search/presentation/bloc/search_state.dart';

export 'search_event.dart';
export 'search_state.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  SearchBloc({required this.searchRepository}) : super(const SearchState()) {
    on<SearchStarted>(_onSearchStarted);
    on<SearchResultsCleared>(_onResultsCleared);
    on<SearchErrorCleared>(_onErrorCleared);
  }

  final SearchRepository searchRepository;

  Future<void> _onSearchStarted(
    SearchStarted event,
    Emitter<SearchState> emit,
  ) async {
    emit(
      state.copyWith(
        status: SearchStatus.searching,
        filters: event.filters,
        clearError: true,
      ),
    );

    try {
      final result = await searchRepository.search(event.filters);
      emit(
        state.copyWith(status: SearchStatus.loaded, result: result),
      );
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          status: SearchStatus.failure,
          error: SearchError(message: e.message, fields: e.fields),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: SearchStatus.failure,
          error: SearchError(message: e.toString()),
        ),
      );
    }
  }

  void _onResultsCleared(
    SearchResultsCleared event,
    Emitter<SearchState> emit,
  ) {
    emit(
      state.copyWith(
        status: SearchStatus.initial,
        clearResult: true,
        clearFilters: true,
        clearError: true,
      ),
    );
  }

  void _onErrorCleared(SearchErrorCleared event, Emitter<SearchState> emit) {
    emit(state.copyWith(clearError: true));
  }
}