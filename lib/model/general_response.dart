/// Represents a general response from the API, typically used for lists
/// where each item has a name and a URL pointing to more detailed information.
class GeneralResponse {
  /// The name of the resource.
  final String name;

  /// The URL to fetch more detailed information about the resource.
  final String url;

  /// Creates a [GeneralResponse] instance.
  ///
  /// Requires [name] and [url].
  GeneralResponse({required this.name, required this.url});

  /// Creates a [GeneralResponse] instance from a JSON map.
  ///
  /// This factory constructor is used to deserialize the JSON data
  /// received from the API into a [GeneralResponse] object.
  /// Defaults `name` and `url` to an empty string if they are null in the JSON.
  ///
  /// Throws a [TypeError] if the 'name' or 'url' fields are not
  /// strings (and not null) in the JSON map.
  factory GeneralResponse.fromJson(Map<String, dynamic> json) {
    return GeneralResponse(
      name: json['name'] as String? ?? '',
      url: json['url'] as String? ?? ''
    );
  }
}
