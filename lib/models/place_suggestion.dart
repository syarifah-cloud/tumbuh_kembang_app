class PlaceSuggestion {
  final String displayName;
  final double lat;
  final double lon;

  PlaceSuggestion({
    required this.displayName,
    required this.lat,
    required this.lon,
  });

  factory PlaceSuggestion.fromJson(Map<String, dynamic> json) {
    return PlaceSuggestion(
      displayName: json['display_name'] ?? 'Nama tidak tersedia',
      lat: double.parse(json['lat']),
      lon: double.parse(json['lon']),
    );
  }
}