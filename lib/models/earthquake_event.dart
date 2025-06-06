// 檔案：lib/models/earthquake_event.dart
class EarthquakeEvent {
  final String location;
  final double magnitude;
  final String time;
  final String? depth;
  final String? reportContent;
  final String? reportUrl;
  final String? reportImageURI; // 新增：地震報告圖連結
  final String? shakingAreaSummary; // 新增：主要震度區域摘要

  EarthquakeEvent({
    required this.location,
    required this.magnitude,
    required this.time,
    this.depth,
    this.reportContent,
    this.reportUrl,
    this.reportImageURI,
    this.shakingAreaSummary,
  });
}