// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'paginated_issues.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Pagination {

 int get page; int get limit; int get totalItems; int get totalPages;
/// Create a copy of Pagination
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PaginationCopyWith<Pagination> get copyWith => _$PaginationCopyWithImpl<Pagination>(this as Pagination, _$identity);

  /// Serializes this Pagination to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Pagination;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Pagination&&(identical(other.page, _this.page) || other.page == _this.page)&&(identical(other.limit, _this.limit) || other.limit == _this.limit)&&(identical(other.totalItems, _this.totalItems) || other.totalItems == _this.totalItems)&&(identical(other.totalPages, _this.totalPages) || other.totalPages == _this.totalPages));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Pagination;
  return Object.hash(runtimeType,_this.page,_this.limit,_this.totalItems,_this.totalPages);
}

@override
String toString() {
  final _this = this as Pagination;
  return 'Pagination(page: ${_this.page}, limit: ${_this.limit}, totalItems: ${_this.totalItems}, totalPages: ${_this.totalPages})';
}


}

/// @nodoc
abstract mixin class $PaginationCopyWith<$Res>  {
  factory $PaginationCopyWith(Pagination value, $Res Function(Pagination) _then) = _$PaginationCopyWithImpl;
@useResult
$Res call({
 int page, int limit, int totalItems, int totalPages
});




}
/// @nodoc
class _$PaginationCopyWithImpl<$Res>
    implements $PaginationCopyWith<$Res> {
  _$PaginationCopyWithImpl(this._self, this._then);

  final Pagination _self;
  final $Res Function(Pagination) _then;

/// Create a copy of Pagination
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? page = null,Object? limit = null,Object? totalItems = null,Object? totalPages = null,}) {
  return _then(Pagination(
page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,limit: null == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as int,totalItems: null == totalItems ? _self.totalItems : totalItems // ignore: cast_nullable_to_non_nullable
as int,totalPages: null == totalPages ? _self.totalPages : totalPages // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [Pagination].
extension PaginationPatterns on Pagination {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Pagination value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Pagination() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Pagination value)  $default,){
final _that = this;
switch (_that) {
case _Pagination():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Pagination value)?  $default,){
final _that = this;
switch (_that) {
case _Pagination() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int page,  int limit,  int totalItems,  int totalPages)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Pagination() when $default != null:
return $default(_that.page,_that.limit,_that.totalItems,_that.totalPages);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int page,  int limit,  int totalItems,  int totalPages)  $default,) {final _that = this;
switch (_that) {
case _Pagination():
return $default(_that.page,_that.limit,_that.totalItems,_that.totalPages);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int page,  int limit,  int totalItems,  int totalPages)?  $default,) {final _that = this;
switch (_that) {
case _Pagination() when $default != null:
return $default(_that.page,_that.limit,_that.totalItems,_that.totalPages);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Pagination extends Pagination {
  const _Pagination({required this.page, required this.limit, required this.totalItems, required this.totalPages}): super._();
  factory _Pagination.fromJson(Map<String, dynamic> json) => _$PaginationFromJson(json);

@override final  int page;
@override final  int limit;
@override final  int totalItems;
@override final  int totalPages;

/// Create a copy of Pagination
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PaginationCopyWith<_Pagination> get copyWith => __$PaginationCopyWithImpl<_Pagination>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PaginationToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Pagination&&(identical(other.page, page) || other.page == page)&&(identical(other.limit, limit) || other.limit == limit)&&(identical(other.totalItems, totalItems) || other.totalItems == totalItems)&&(identical(other.totalPages, totalPages) || other.totalPages == totalPages));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,page,limit,totalItems,totalPages);
}

@override
String toString() {
    return 'Pagination(page: $page, limit: $limit, totalItems: $totalItems, totalPages: $totalPages)';
}


}

/// @nodoc
abstract mixin class _$PaginationCopyWith<$Res> implements $PaginationCopyWith<$Res> {
  factory _$PaginationCopyWith(_Pagination value, $Res Function(_Pagination) _then) = __$PaginationCopyWithImpl;
@override @useResult
$Res call({
 int page, int limit, int totalItems, int totalPages
});




}
/// @nodoc
class __$PaginationCopyWithImpl<$Res>
    implements _$PaginationCopyWith<$Res> {
  __$PaginationCopyWithImpl(this._self, this._then);

  final _Pagination _self;
  final $Res Function(_Pagination) _then;

/// Create a copy of Pagination
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? page = null,Object? limit = null,Object? totalItems = null,Object? totalPages = null,}) {
  return _then(_Pagination(
page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,limit: null == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as int,totalItems: null == totalItems ? _self.totalItems : totalItems // ignore: cast_nullable_to_non_nullable
as int,totalPages: null == totalPages ? _self.totalPages : totalPages // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$PaginatedIssueSummaries {

 List<IssueSummary> get items; Pagination get pagination;
/// Create a copy of PaginatedIssueSummaries
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PaginatedIssueSummariesCopyWith<PaginatedIssueSummaries> get copyWith => _$PaginatedIssueSummariesCopyWithImpl<PaginatedIssueSummaries>(this as PaginatedIssueSummaries, _$identity);

  /// Serializes this PaginatedIssueSummaries to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PaginatedIssueSummaries;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PaginatedIssueSummaries&&const DeepCollectionEquality().equals(other.items, _this.items)&&(identical(other.pagination, _this.pagination) || other.pagination == _this.pagination));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PaginatedIssueSummaries;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.items),_this.pagination);
}

@override
String toString() {
  final _this = this as PaginatedIssueSummaries;
  return 'PaginatedIssueSummaries(items: ${_this.items}, pagination: ${_this.pagination})';
}


}

/// @nodoc
abstract mixin class $PaginatedIssueSummariesCopyWith<$Res>  {
  factory $PaginatedIssueSummariesCopyWith(PaginatedIssueSummaries value, $Res Function(PaginatedIssueSummaries) _then) = _$PaginatedIssueSummariesCopyWithImpl;
@useResult
$Res call({
 List<IssueSummary> items, Pagination pagination
});


$PaginationCopyWith<$Res> get pagination;

}
/// @nodoc
class _$PaginatedIssueSummariesCopyWithImpl<$Res>
    implements $PaginatedIssueSummariesCopyWith<$Res> {
  _$PaginatedIssueSummariesCopyWithImpl(this._self, this._then);

  final PaginatedIssueSummaries _self;
  final $Res Function(PaginatedIssueSummaries) _then;

/// Create a copy of PaginatedIssueSummaries
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? pagination = null,}) {
  return _then(PaginatedIssueSummaries(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<IssueSummary>,pagination: null == pagination ? _self.pagination : pagination // ignore: cast_nullable_to_non_nullable
as Pagination,
  ));
}
/// Create a copy of PaginatedIssueSummaries
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PaginationCopyWith<$Res> get pagination {
  
  return $PaginationCopyWith<$Res>(_self.pagination, (value) {
    return _then(_self.copyWith(pagination: value));
  });
}
}


/// Adds pattern-matching-related methods to [PaginatedIssueSummaries].
extension PaginatedIssueSummariesPatterns on PaginatedIssueSummaries {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PaginatedIssueSummaries value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PaginatedIssueSummaries() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PaginatedIssueSummaries value)  $default,){
final _that = this;
switch (_that) {
case _PaginatedIssueSummaries():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PaginatedIssueSummaries value)?  $default,){
final _that = this;
switch (_that) {
case _PaginatedIssueSummaries() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<IssueSummary> items,  Pagination pagination)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PaginatedIssueSummaries() when $default != null:
return $default(_that.items,_that.pagination);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<IssueSummary> items,  Pagination pagination)  $default,) {final _that = this;
switch (_that) {
case _PaginatedIssueSummaries():
return $default(_that.items,_that.pagination);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<IssueSummary> items,  Pagination pagination)?  $default,) {final _that = this;
switch (_that) {
case _PaginatedIssueSummaries() when $default != null:
return $default(_that.items,_that.pagination);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PaginatedIssueSummaries implements PaginatedIssueSummaries {
  const _PaginatedIssueSummaries({required  List<IssueSummary> items, required this.pagination}): _items = items;
  factory _PaginatedIssueSummaries.fromJson(Map<String, dynamic> json) => _$PaginatedIssueSummariesFromJson(json);

 final  List<IssueSummary> _items;
@override List<IssueSummary> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override final  Pagination pagination;

/// Create a copy of PaginatedIssueSummaries
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PaginatedIssueSummariesCopyWith<_PaginatedIssueSummaries> get copyWith => __$PaginatedIssueSummariesCopyWithImpl<_PaginatedIssueSummaries>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PaginatedIssueSummariesToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PaginatedIssueSummaries&&const DeepCollectionEquality().equals(other.items, _items)&&(identical(other.pagination, pagination) || other.pagination == pagination));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),pagination);
}

@override
String toString() {
    return 'PaginatedIssueSummaries(items: $items, pagination: $pagination)';
}


}

/// @nodoc
abstract mixin class _$PaginatedIssueSummariesCopyWith<$Res> implements $PaginatedIssueSummariesCopyWith<$Res> {
  factory _$PaginatedIssueSummariesCopyWith(_PaginatedIssueSummaries value, $Res Function(_PaginatedIssueSummaries) _then) = __$PaginatedIssueSummariesCopyWithImpl;
@override @useResult
$Res call({
 List<IssueSummary> items, Pagination pagination
});


@override $PaginationCopyWith<$Res> get pagination;

}
/// @nodoc
class __$PaginatedIssueSummariesCopyWithImpl<$Res>
    implements _$PaginatedIssueSummariesCopyWith<$Res> {
  __$PaginatedIssueSummariesCopyWithImpl(this._self, this._then);

  final _PaginatedIssueSummaries _self;
  final $Res Function(_PaginatedIssueSummaries) _then;

/// Create a copy of PaginatedIssueSummaries
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? pagination = null,}) {
  return _then(_PaginatedIssueSummaries(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<IssueSummary>,pagination: null == pagination ? _self.pagination : pagination // ignore: cast_nullable_to_non_nullable
as Pagination,
  ));
}

/// Create a copy of PaginatedIssueSummaries
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PaginationCopyWith<$Res> get pagination {
  
  return $PaginationCopyWith<$Res>(_self.pagination, (value) {
    return _then(_self.copyWith(pagination: value));
  });
}
}


/// @nodoc
mixin _$PaginatedIssues {

 List<Issue> get items; Pagination get pagination;
/// Create a copy of PaginatedIssues
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PaginatedIssuesCopyWith<PaginatedIssues> get copyWith => _$PaginatedIssuesCopyWithImpl<PaginatedIssues>(this as PaginatedIssues, _$identity);

  /// Serializes this PaginatedIssues to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PaginatedIssues;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PaginatedIssues&&const DeepCollectionEquality().equals(other.items, _this.items)&&(identical(other.pagination, _this.pagination) || other.pagination == _this.pagination));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PaginatedIssues;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.items),_this.pagination);
}

@override
String toString() {
  final _this = this as PaginatedIssues;
  return 'PaginatedIssues(items: ${_this.items}, pagination: ${_this.pagination})';
}


}

/// @nodoc
abstract mixin class $PaginatedIssuesCopyWith<$Res>  {
  factory $PaginatedIssuesCopyWith(PaginatedIssues value, $Res Function(PaginatedIssues) _then) = _$PaginatedIssuesCopyWithImpl;
@useResult
$Res call({
 List<Issue> items, Pagination pagination
});


$PaginationCopyWith<$Res> get pagination;

}
/// @nodoc
class _$PaginatedIssuesCopyWithImpl<$Res>
    implements $PaginatedIssuesCopyWith<$Res> {
  _$PaginatedIssuesCopyWithImpl(this._self, this._then);

  final PaginatedIssues _self;
  final $Res Function(PaginatedIssues) _then;

/// Create a copy of PaginatedIssues
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? pagination = null,}) {
  return _then(PaginatedIssues(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<Issue>,pagination: null == pagination ? _self.pagination : pagination // ignore: cast_nullable_to_non_nullable
as Pagination,
  ));
}
/// Create a copy of PaginatedIssues
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PaginationCopyWith<$Res> get pagination {
  
  return $PaginationCopyWith<$Res>(_self.pagination, (value) {
    return _then(_self.copyWith(pagination: value));
  });
}
}


/// Adds pattern-matching-related methods to [PaginatedIssues].
extension PaginatedIssuesPatterns on PaginatedIssues {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PaginatedIssues value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PaginatedIssues() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PaginatedIssues value)  $default,){
final _that = this;
switch (_that) {
case _PaginatedIssues():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PaginatedIssues value)?  $default,){
final _that = this;
switch (_that) {
case _PaginatedIssues() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<Issue> items,  Pagination pagination)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PaginatedIssues() when $default != null:
return $default(_that.items,_that.pagination);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<Issue> items,  Pagination pagination)  $default,) {final _that = this;
switch (_that) {
case _PaginatedIssues():
return $default(_that.items,_that.pagination);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<Issue> items,  Pagination pagination)?  $default,) {final _that = this;
switch (_that) {
case _PaginatedIssues() when $default != null:
return $default(_that.items,_that.pagination);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PaginatedIssues implements PaginatedIssues {
  const _PaginatedIssues({required  List<Issue> items, required this.pagination}): _items = items;
  factory _PaginatedIssues.fromJson(Map<String, dynamic> json) => _$PaginatedIssuesFromJson(json);

 final  List<Issue> _items;
@override List<Issue> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override final  Pagination pagination;

/// Create a copy of PaginatedIssues
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PaginatedIssuesCopyWith<_PaginatedIssues> get copyWith => __$PaginatedIssuesCopyWithImpl<_PaginatedIssues>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PaginatedIssuesToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PaginatedIssues&&const DeepCollectionEquality().equals(other.items, _items)&&(identical(other.pagination, pagination) || other.pagination == pagination));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),pagination);
}

@override
String toString() {
    return 'PaginatedIssues(items: $items, pagination: $pagination)';
}


}

/// @nodoc
abstract mixin class _$PaginatedIssuesCopyWith<$Res> implements $PaginatedIssuesCopyWith<$Res> {
  factory _$PaginatedIssuesCopyWith(_PaginatedIssues value, $Res Function(_PaginatedIssues) _then) = __$PaginatedIssuesCopyWithImpl;
@override @useResult
$Res call({
 List<Issue> items, Pagination pagination
});


@override $PaginationCopyWith<$Res> get pagination;

}
/// @nodoc
class __$PaginatedIssuesCopyWithImpl<$Res>
    implements _$PaginatedIssuesCopyWith<$Res> {
  __$PaginatedIssuesCopyWithImpl(this._self, this._then);

  final _PaginatedIssues _self;
  final $Res Function(_PaginatedIssues) _then;

/// Create a copy of PaginatedIssues
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? pagination = null,}) {
  return _then(_PaginatedIssues(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<Issue>,pagination: null == pagination ? _self.pagination : pagination // ignore: cast_nullable_to_non_nullable
as Pagination,
  ));
}

/// Create a copy of PaginatedIssues
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PaginationCopyWith<$Res> get pagination {
  
  return $PaginationCopyWith<$Res>(_self.pagination, (value) {
    return _then(_self.copyWith(pagination: value));
  });
}
}

// dart format on
