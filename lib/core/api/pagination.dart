class Paginated<T> {
  final List<T> data;
  final int total;
  final int count;
  final int perPage;
  final int currentPage;
  final int totalPages;
  final Map<String, num>? pageTotals;
  final Map<String, num>? overallTotals;

  Paginated({
    required this.data,
    required this.total,
    required this.count,
    required this.perPage,
    required this.currentPage,
    required this.totalPages,
    this.pageTotals,
    this.overallTotals,
  });
}
