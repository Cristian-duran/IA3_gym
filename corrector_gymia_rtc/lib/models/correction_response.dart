class Keypoint {
  final double x;
  final double y;
  final double score;
  Keypoint({required this.x, required this.y, required this.score});
  factory Keypoint.fromJson(Map<String, dynamic> j) => Keypoint(
    x: j['x'], y: j['y'], score: j['score']
  );
}

class CorrectionResponse {
  final String clase;
  final double confianza;
  final List<Keypoint> keypoints;
  CorrectionResponse({
    required this.clase,
    required this.confianza,
    required this.keypoints,
  });
  factory CorrectionResponse.fromJson(Map<String, dynamic> j) => CorrectionResponse(
    clase: j['clase'],
    confianza: (j['confianza'] as num).toDouble(),
    keypoints: (j['keypoints'] as List)
      .map((e) => Keypoint.fromJson(e))
      .toList(),
  );
}
