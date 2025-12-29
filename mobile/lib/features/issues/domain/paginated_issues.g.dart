// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'paginated_issues.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Pagination _$PaginationFromJson(Map<String, dynamic> json) => _Pagination(
  page: (json['page'] as num).toInt(),
  limit: (json['limit'] as num).toInt(),
  totalItems: (json['totalItems'] as num).toInt(),
  totalPages: (json['totalPages'] as num).toInt(),
);

Map<String, dynamic> _$PaginationToJson(_Pagination instance) =>
    <String, dynamic>{
      'page': instance.page,
      'limit': instance.limit,
      'totalItems': instance.totalItems,
      'totalPages': instance.totalPages,
    };

_PaginatedIssueSummaries _$PaginatedIssueSummariesFromJson(
  Map<String, dynamic> json,
) => _PaginatedIssueSummaries(
  items: (json['items'] as List<dynamic>)
      .map((e) => IssueSummary.fromJson(e as Map<String, dynamic>))
      .toList(),
  pagination: Pagination.fromJson(json['pagination'] as Map<String, dynamic>),
);

Map<String, dynamic> _$PaginatedIssueSummariesToJson(
  _PaginatedIssueSummaries instance,
) => <String, dynamic>{
  'items': instance.items.map((e) => e.toJson()).toList(),
  'pagination': instance.pagination.toJson(),
};

_PaginatedIssues _$PaginatedIssuesFromJson(Map<String, dynamic> json) =>
    _PaginatedIssues(
      items: (json['items'] as List<dynamic>)
          .map((e) => Issue.fromJson(e as Map<String, dynamic>))
          .toList(),
      pagination: Pagination.fromJson(
        json['pagination'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$PaginatedIssuesToJson(_PaginatedIssues instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'pagination': instance.pagination.toJson(),
    };
