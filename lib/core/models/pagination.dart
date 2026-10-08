import 'package:equatable/equatable.dart';

/// Generic pagination request parameters.
/// Use this for any list-fetching API.
class PaginationParams extends Equatable {
  final int page;
  final int limit;
  final String? search;
  final String? sort;
  final Map<String, dynamic>? filters;

  const PaginationParams({
    this.page = 1,
    this.limit = 20,
    this.search,
    this.sort,
    this.filters,
  });

  Map<String, dynamic> toQueryParameters() {
    return {
      'page': page,
      'limit': limit,
      if (search != null && search!.isNotEmpty) 'search': search,
      if (sort != null) 'sort': sort,
      if (filters != null) ...filters!,
    };
  }

  PaginationParams copyWith({
    int? page,
    int? limit,
    String? search,
    String? sort,
    Map<String, dynamic>? filters,
  }) {
    return PaginationParams(
      page: page ?? this.page,
      limit: limit ?? this.limit,
      search: search ?? this.search,
      sort: sort ?? this.sort,
      filters: filters ?? this.filters,
    );
  }

  @override
  List<Object?> get props => [page, limit, search, sort, filters];
}

/// Generic paginated response model.
class PaginatedResponse<T> {
  final List<T> items;
  final int currentPage;
  final int totalPages;
  final int totalCount;
  final bool hasMore;

  const PaginatedResponse({
    required this.items,
    required this.currentPage,
    required this.totalPages,
    required this.totalCount,
    required this.hasMore,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonItem,
  ) {
    final rawItems = json['items'] as List<dynamic>? ??
        json['data'] as List<dynamic>? ??
        [];
    final pagination = json['pagination'] as Map<String, dynamic>?;

    return PaginatedResponse<T>(
      items: rawItems
          .map((item) => fromJsonItem(item as Map<String, dynamic>))
          .toList(),
      currentPage: pagination?['currentPage'] as int? ?? 1,
      totalPages: pagination?['totalPages'] as int? ?? 1,
      totalCount: pagination?['totalCount'] as int? ?? rawItems.length,
      hasMore: pagination?['hasMore'] as bool? ?? false,
    );
  }

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;
  bool get isFirstPage => currentPage == 1;
  bool get isLastPage => currentPage >= totalPages;
}
