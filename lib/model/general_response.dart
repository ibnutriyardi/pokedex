class GeneralResponse {
  final String name;
  final String url;

  GeneralResponse({required this.name, required this.url});

  factory GeneralResponse.fromJson(Map<String, dynamic> json) {
    return GeneralResponse(name: json['name'], url: json['url']);
  }
}
