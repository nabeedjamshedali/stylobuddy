class WearEvent {
  const WearEvent({
    required this.id,
    required this.outfitId,
    required this.name,
    required this.occasion,
    required this.items,
    required this.timestamp,
  });

  final int id;
  final int outfitId;
  final String name;
  final String occasion;
  final List<String> items;
  final DateTime timestamp;
}
