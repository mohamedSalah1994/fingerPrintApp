import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Generic list cubit for admin CRUD screens.
class CrudListCubit<T> extends Cubit<CrudListState<T>> {
  CrudListCubit({
    required Stream<List<T>> Function() watch,
    required Future<void> Function(T item) save,
    required Future<void> Function(String id) remove,
    required String Function(T item) idOf,
  })  : _watch = watch,
        _save = save,
        _remove = remove,
        _idOf = idOf,
        super(const CrudListState.loading()) {
    _subscription = _watch().listen(
      (items) => emit(CrudListState.loaded(items)),
      onError: (Object e) => emit(CrudListState.error(e.toString())),
    );
  }

  final Stream<List<T>> Function() _watch;
  final Future<void> Function(T item) _save;
  final Future<void> Function(String id) _remove;
  final String Function(T item) _idOf;
  StreamSubscription<List<T>>? _subscription;

  Future<void> save(T item) async {
    try {
      await _save(item);
    } catch (e) {
      emit(CrudListState.error(e.toString()));
      final current = state;
      if (current.items != null) {
        emit(CrudListState.loaded(current.items!));
      }
    }
  }

  Future<void> delete(T item) async {
    try {
      await _remove(_idOf(item));
    } catch (e) {
      emit(CrudListState.error(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}

class CrudListState<T> extends Equatable {
  const CrudListState._({
    this.items,
    this.isLoading = false,
    this.errorMessage,
  });

  const CrudListState.loading() : this._(isLoading: true);

  const CrudListState.loaded(List<T> items) : this._(items: items);

  const CrudListState.error(String message) : this._(errorMessage: message);

  final List<T>? items;
  final bool isLoading;
  final String? errorMessage;

  @override
  List<Object?> get props => [items, isLoading, errorMessage];
}
