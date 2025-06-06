// 檔案：lib/services/earthquake_api_service.dart
// (與上一版相同，此處不再重複，僅為確保文件完整性)
import 'dart:convert';
import 'dart:async'; // For Timeout
import 'package:http/http.dart' as http;
import '../models/earthquake_event.dart';

class EarthquakeApiService {
  static const String _apiKey = 'CWA-03C1613D-3BE8-4AE5-A682-846FA76BB163'; // 您已填入的金鑰

  Future<List<EarthquakeEvent>> fetchEarthquakes({
    required String reportDataId, 
    int? limit,
    String? areaName,
    String? sort,
    String? timeFrom,
    String? timeTo,
  }) async {
    if (_apiKey == 'YOUR_CWA_API_KEY') { 
      print("警告：請替換 earthquake_api_service.dart 中的 API 金鑰！");
      return Future.value([
         EarthquakeEvent(location: "測試地點1（請填入API Key）", magnitude: 2.5, time: "2025-01-01T10:00:00", depth: "10.0", reportContent: "此為測試資料"),
         EarthquakeEvent(location: "測試地點2（請填入API Key）", magnitude: 4.5, time: "2025-01-01T12:00:00", depth: "25.5", reportContent: "此為另一筆測試資料", reportUrl: "https://example.com"),
      ]);
    }

    var uri = Uri.parse('https://opendata.cwa.gov.tw/api/v1/rest/datastore/$reportDataId');
    Map<String, dynamic> queryParameters = {
      'Authorization': _apiKey,
      'format': 'JSON',
    };

    if (limit != null) queryParameters['limit'] = limit.toString();
    if (areaName != null && areaName.isNotEmpty) queryParameters['AreaName'] = areaName;
    if (sort != null && sort.isNotEmpty) queryParameters['sort'] = sort;
    if (timeFrom != null && timeFrom.isNotEmpty) queryParameters['timeFrom'] = timeFrom;
    if (timeTo != null && timeTo.isNotEmpty) queryParameters['timeTo'] = timeTo;

    final fullUri = uri.replace(queryParameters: queryParameters);
    print('請求 API URL: $fullUri');

    try {
      final response = await http.get(fullUri).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> data = jsonDecode(decodedBody);
        return parseEarthquakeData(data);
      } else {
        print('API 請求失敗: ${response.statusCode}, Body: ${response.body}');
        throw Exception('載入地震資料失敗 (狀態碼: ${response.statusCode})');
      }
    } on TimeoutException catch (e) {
      print('網路請求超時: $e');
      throw Exception('網路請求超時，請稍後再試');
    } on http.ClientException catch (e) {
      print('網路客戶端錯誤: $e');
      throw Exception('網路連線錯誤，請檢查您的網路');
    } catch (e) {
      print('未知網路請求或解析錯誤: $e');
      throw Exception('發生未知錯誤: $e');
    }
  }

  List<EarthquakeEvent> parseEarthquakeData(Map<String, dynamic> jsonData) {
    final List<EarthquakeEvent> earthquakes = [];
    if (jsonData['success'] == 'true' && jsonData['records'] != null && 
        (jsonData['records']['Earthquake'] != null || jsonData['records']['earthquake'] != null) ) {
      
      final List<dynamic>? earthquakeRecords = jsonData['records']['Earthquake'] ?? jsonData['records']['earthquake'];

      if (earthquakeRecords == null) {
        print('找不到 "Earthquake" 或 "earthquake" 記錄列表');
        return earthquakes;
      }

      for (var record in earthquakeRecords) {
        try {
          final epicenter = record['EarthquakeInfo']?['Epicenter'];
          String location = epicenter?['Location'] ?? '未知地點';
          
          final magnitudeValue = record['EarthquakeInfo']?['EarthquakeMagnitude']?['MagnitudeValue']?.toString();
          double magnitude = double.tryParse(magnitudeValue ?? '0.0') ?? 0.0;
          
          String time = record['EarthquakeInfo']?['OriginTime'] ?? '未知時間';
          String? depth = record['EarthquakeInfo']?['FocalDepth']?.toString();
          if (depth != null) {
            double? depthValue = double.tryParse(depth);
            if (depthValue != null) depth = depthValue.toStringAsFixed(1);
          }

          String? reportContent = record['ReportContent'];
          String? reportUrl = record['Web'];
          String? reportImageURI = record['ReportImageURI'];

          String? shakingAreaSummary;
          if (record['Intensity']?['ShakingArea'] != null && record['Intensity']['ShakingArea'] is List) {
            List<String> summaries = [];
            for (var area in record['Intensity']['ShakingArea']) {
              if (area is Map && area['AreaDesc'] != null && area['AreaIntensity'] != null) {
                if ((area['AreaDesc'] as String).contains("最大震度")) {
                    summaries.add("${area['AreaDesc']}");
                } else if (area['CountyName'] != null) {
                    summaries.add("${area['CountyName']} ${area['AreaIntensity']}");
                }
              }
            }
            List<String> maxIntensitySummaries = summaries.where((s) => s.contains("最大震度")).toList();
            if (maxIntensitySummaries.isNotEmpty) {
                shakingAreaSummary = maxIntensitySummaries.join('；');
            } else if (summaries.isNotEmpty) {
                shakingAreaSummary = summaries.take(2).join('；'); 
            }
          }

          earthquakes.add(EarthquakeEvent(
            location: location,
            magnitude: magnitude,
            time: time,
            depth: depth,
            reportContent: reportContent,
            reportUrl: reportUrl,
            reportImageURI: reportImageURI,
            shakingAreaSummary: shakingAreaSummary,
          ));
        } catch (e, s) {
          print('解析單筆地震記錄錯誤: $record, 錯誤: $e');
          print('堆疊追蹤: $s');
        }
      }
    } else {
      print('JSON 資料格式不符預期，或請求未成功 (success=${jsonData['success']})');
      if (jsonData['records'] == null) print ('"records" 欄位不存在');
      if (jsonData['records']?['Earthquake'] == null && jsonData['records']?['earthquake'] == null) print ('"Earthquake/earthquake" 欄位不存在於 "records" 中');
    }
    return earthquakes;
  }
}