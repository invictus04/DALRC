class GetDocumentModel {
  final bool success;
  final String message;
  final List<Document> documents;
  final Pagination pagination;
  final Filters filters;

  GetDocumentModel({
    required this.success,
    required this.message,
    required this.documents,
    required this.pagination,
    required this.filters,
  });

  factory GetDocumentModel.fromJson(Map<String, dynamic> json) {
    return GetDocumentModel(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      documents: (json['documents'] as List?)?.map((e) => Document.fromJson(e)).toList() ?? [],
      pagination: Pagination.fromJson(json['pagination'] ?? {}),
      filters: Filters.fromJson(json['filters'] ?? {}),
    );
  }
}

class Document {
  final String id;
  final String title;
  final String fileType;
  final int fileSize;
  final String ipfsCid;
  final bool encrypted;
  final String uploadedBy;
  final DateTime createdAt;

  Document({
    required this.id,
    required this.title,
    required this.fileType,
    required this.fileSize,
    required this.ipfsCid,
    required this.encrypted,
    required this.uploadedBy,
    required this.createdAt,
  });

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      fileType: json['fileType'] ?? '',
      fileSize: json['fileSize'] ?? 0,
      ipfsCid: json['ipfsCid'] ?? '',
      encrypted: json['encrypted'] ?? false,
      uploadedBy: json['uploadedBy'] ?? json['uploader'] ?? '',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    );
  }
}

class Filters {
  final dynamic search;
  final String filterType;
  final String accessFilter;
  final String sortBy;

  Filters({
    required this.search,
    required this.filterType,
    required this.accessFilter,
    required this.sortBy,
  });

  factory Filters.fromJson(Map<String, dynamic> json) {
    return Filters(
      search: json['search'],
      filterType: json['filterType'] ?? 'all',
      accessFilter: json['accessFilter'] ?? 'all',
      sortBy: json['sortBy'] ?? 'newest',
    );
  }
}

class Pagination {
  final int totalDocs;
  final int currentPage;
  final int limit;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPrevPage;

  Pagination({
    required this.totalDocs,
    required this.currentPage,
    required this.limit,
    required this.totalPages,
    required this.hasNextPage,
    required this.hasPrevPage,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      totalDocs: json['totalDocs'] ?? 0,
      currentPage: json['currentPage'] ?? 1,
      limit: json['limit'] ?? 10,
      totalPages: json['totalPages'] ?? 1,
      hasNextPage: json['hasNextPage'] ?? false,
      hasPrevPage: json['hasPrevPage'] ?? false,
    );
  }
}
