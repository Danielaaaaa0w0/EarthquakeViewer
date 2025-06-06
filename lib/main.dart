// 檔案：lib/main.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services/earthquake_api_service.dart';
import 'models/earthquake_event.dart';
import 'emergency_tools_page.dart'; // 新增：緊急工具頁面

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

final GlobalKey<_MyAppState> myAppKey = GlobalKey();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  runApp(MyApp(key: myAppKey));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleThemeMode() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  static _MyAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>();

  @override
  Widget build(BuildContext context) {
    final blueColorScheme = ColorScheme.fromSeed(seedColor: Colors.blueAccent); //調整為藍色系
    final darkBlueColorScheme = ColorScheme.fromSeed(
        seedColor: Colors.blueAccent, brightness: Brightness.dark);

    final lightTheme = ThemeData(
      useMaterial3: true,
      colorScheme: blueColorScheme,
      appBarTheme: AppBarTheme(
        backgroundColor: blueColorScheme.primary,
        foregroundColor: blueColorScheme.onPrimary,
      ),
      cardTheme: CardTheme(
        elevation: 2.0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
      ),
      dialogTheme: DialogTheme(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      ),
      brightness: Brightness.light,
    );

    final darkTheme = ThemeData(
      useMaterial3: true,
      colorScheme: darkBlueColorScheme,
      appBarTheme: AppBarTheme(
        backgroundColor: darkBlueColorScheme.surface,
        foregroundColor: darkBlueColorScheme.onSurface,
      ),
       cardTheme: CardTheme(
        elevation: 2.0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
        color: darkBlueColorScheme.surfaceVariant,
      ),
      dialogTheme: DialogTheme(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
        backgroundColor: darkBlueColorScheme.surface,
      ),
      brightness: Brightness.dark,
    );

    return MaterialApp(
      title: '地震速報閱覽器',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: _themeMode,
      home: const EarthquakeListPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

enum ReportDataSource {
  significant('E-A0015-001', '顯著有感地震'),
  recent('E-A0016-001', '小區域有感地震');

  const ReportDataSource(this.dataId, this.displayName);
  final String dataId;
  final String displayName;
}

class EarthquakeListPage extends StatefulWidget {
  const EarthquakeListPage({super.key});

  @override
  State<EarthquakeListPage> createState() => _EarthquakeListPageState();
}

class _EarthquakeListPageState extends State<EarthquakeListPage> {
  late Future<List<EarthquakeEvent>> _earthquakeFuture;
  final EarthquakeApiService _apiService = EarthquakeApiService();
  final DateFormat _timeFormatter = DateFormat('yyyy-MM-dd HH:mm:ss');

  ReportDataSource _selectedDataSource = ReportDataSource.recent;
  int _currentLimit = 10;
  String? _currentAreaName;
  String? _currentTimeFrom;
  String? _currentTimeTo;

  static const String _lastEarthquakeTimeKey = 'last_earthquake_time_';


  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _loadEarthquakes();
  }

  Future<void> _requestPermissions() async {
    if (Theme.of(context).platform == TargetPlatform.iOS) {
       await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
    } else if (Theme.of(context).platform == TargetPlatform.android) {
        final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
            flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        final bool? granted = await androidImplementation?.requestNotificationsPermission();
        if (granted != null && !granted) {
            print("Android 通知權限未授予");
        }
    }
  }


  Future<void> _loadEarthquakes() async {
    setState(() {
      _earthquakeFuture = _apiService.fetchEarthquakes(
        reportDataId: _selectedDataSource.dataId,
        limit: _currentLimit,
        areaName: _currentAreaName,
        timeFrom: _currentTimeFrom,
        timeTo: _currentTimeTo,
      );
    });

    try {
      final earthquakes = await _earthquakeFuture;
      if (mounted && earthquakes.isNotEmpty) { // 檢查 mounted
        _checkAndNotifyNewEarthquake(earthquakes.first);
      }
    } catch (e) {
      print("Error during fetch for notification check: $e");
    }
  }

  Future<void> _checkAndNotifyNewEarthquake(EarthquakeEvent latestEarthquake) async {
    if (!mounted) return; // 如果 widget 已被 dispose，則不執行後續操作
    final prefs = await SharedPreferences.getInstance();
    final String? lastSeenTimeStr = prefs.getString(_lastEarthquakeTimeKey + _selectedDataSource.dataId);

    DateTime? lastSeenTime;
    if (lastSeenTimeStr != null) {
      lastSeenTime = DateTime.tryParse(lastSeenTimeStr);
    }

    DateTime currentEarthquakeTime = DateTime.now();
    try {
        if(latestEarthquake.time.contains('T')){
            currentEarthquakeTime = DateTime.parse(latestEarthquake.time);
        } else {
            currentEarthquakeTime = DateFormat("yyyy-MM-dd HH:mm:ss").parse(latestEarthquake.time);
        }
    } catch(e) {
        print("Error parsing currentEarthquakeTime for notification: ${latestEarthquake.time}");
        return;
    }

    if (lastSeenTime == null || currentEarthquakeTime.isAfter(lastSeenTime)) {
      if (lastSeenTime != null) {
        _showEarthquakeNotification(latestEarthquake);
      }
      await prefs.setString(_lastEarthquakeTimeKey + _selectedDataSource.dataId, currentEarthquakeTime.toIso8601String());
    }
  }

  Future<void> _showEarthquakeNotification(EarthquakeEvent earthquake) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'earthquake_channel_id',
      '地震速報',
      channelDescription: '接收最新的地震速報通知',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      playSound: true,
    );
    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
        );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics, iOS: iOSPlatformChannelSpecifics);

    String title = '新地震速報！';
    String body = '${earthquake.location} 發生規模 ${earthquake.magnitude.toStringAsFixed(1)} 地震';
    if (earthquake.reportContent != null && earthquake.reportContent!.isNotEmpty){
        body = earthquake.reportContent!;
    }

    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
      payload: 'earthquake_event_id_${earthquake.time}',
    );
  }


  void _showFilterDialog() async {
    TextEditingController limitController =
        TextEditingController(text: _currentLimit.toString());
    ReportDataSource? tempSelectedDataSource = _selectedDataSource;

    ReportDataSource? newDataSourceChoice = await showDialog<ReportDataSource>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
            builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('篩選與報告類型'),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  TextField(
                    controller: limitController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: '顯示最新幾筆'),
                  ),
                  const SizedBox(height: 20),
                  const Text("選擇報告類型:",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  RadioListTile<ReportDataSource>(
                    title: Text(ReportDataSource.recent.displayName),
                    value: ReportDataSource.recent,
                    groupValue: tempSelectedDataSource,
                    onChanged: (ReportDataSource? value) {
                      setDialogState(() {
                        tempSelectedDataSource = value;
                      });
                    },
                  ),
                  RadioListTile<ReportDataSource>(
                    title: Text(ReportDataSource.significant.displayName),
                    value: ReportDataSource.significant,
                    groupValue: tempSelectedDataSource,
                    onChanged: (ReportDataSource? value) {
                      setDialogState(() {
                        tempSelectedDataSource = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('取消'),
                onPressed: () => Navigator.of(context).pop(),
              ),
              TextButton(
                child: const Text('確定'),
                onPressed: () {
                  Navigator.of(context).pop(tempSelectedDataSource);
                },
              ),
            ],
          );
        });
      },
    );

    bool needsReload = false;
    if (newDataSourceChoice != null && newDataSourceChoice != _selectedDataSource) {
        setState(() {
            _selectedDataSource = newDataSourceChoice;
        });
        needsReload = true;
    }
    
    // 在 dialog dispose 之後安全地讀取 TextEditingController 的值
    WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return; 
        final String newLimitText = limitController.text; 
        final newLimit = int.tryParse(newLimitText);
        if (newLimit != null && newLimit > 0 && newLimit != _currentLimit) {
            setState(() {
                _currentLimit = newLimit;
            });
            needsReload = true; 
        }

        if (needsReload) {
            _loadEarthquakes();
        }
        limitController.dispose(); // 手動釋放 controller
    });
  }

  @override
  Widget build(BuildContext context) {
    final myAppState = _MyAppState.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('最新地震報告 (${_selectedDataSource.displayName})'),
        actions: [
           IconButton( 
            icon: const Icon(Icons.medical_services_outlined), 
            tooltip: '緊急工具',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EmergencyToolsPage()),
              );
            },
          ),
          IconButton(
            icon: Icon(myAppState?._themeMode == ThemeMode.light
                ? Icons.dark_mode_outlined
                : Icons.light_mode_outlined),
            tooltip: '切換主題模式',
            onPressed: () {
              myAppState?._toggleThemeMode();
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: '篩選/類型',
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '重新整理',
            onPressed: _loadEarthquakes,
          ),
        ],
      ),
      body: FutureBuilder<List<EarthquakeEvent>>(
        future: _earthquakeFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  '載入資料失敗: ${snapshot.error}\n請檢查網路連線及API金鑰。',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.error, fontSize: 16),
                ),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
                child: Text('目前沒有符合條件的地震報告', style: TextStyle(fontSize: 16)));
          } else {
            final earthquakes = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
              itemCount: earthquakes.length,
              itemBuilder: (context, index) {
                final earthquake = earthquakes[index];
                DateTime? originTime;
                try {
                  if (earthquake.time.contains('T')) {
                    originTime = DateTime.tryParse(earthquake.time)?.toLocal();
                  } else {
                    originTime = DateFormat("yyyy-MM-dd HH:mm:ss")
                        .tryParse(earthquake.time)
                        ?.toLocal();
                  }
                } catch (e) {
                  print("Error parsing time: ${earthquake.time} - $e");
                }
                final String displayTime =
                    originTime != null ? _timeFormatter.format(originTime) : earthquake.time;

                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getMagnitudeColor(earthquake.magnitude),
                      foregroundColor: Colors.white,
                      child: Text(
                        earthquake.magnitude.toStringAsFixed(1),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    title: Text(
                      earthquake.location,
                      style: const TextStyle(
                          fontWeight: FontWeight.w500, fontSize: 16),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('時間: $displayTime'),
                        Text('深度: ${earthquake.depth ?? '未知'} km'),
                        if (earthquake.reportContent != null &&
                            earthquake.reportContent!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              earthquake.reportContent!,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7)),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                    isThreeLine: earthquake.reportContent != null &&
                        earthquake.reportContent!.isNotEmpty,
                    trailing: earthquake.reportUrl != null &&
                            earthquake.reportUrl!.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.open_in_new,
                                color: Theme.of(context).colorScheme.secondary),
                            tooltip: '查看CWA報告網頁',
                            onPressed: () {
                              // _launchURL(earthquake.reportUrl); // 需要 url_launcher
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        '將開啟報告網頁: ${earthquake.reportUrl}')),
                              );
                            },
                          )
                        : null,
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(earthquake.location,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 18)),
                          contentPadding: const EdgeInsets.fromLTRB(
                              20.0, 16.0, 20.0, 10.0),
                          content: SingleChildScrollView(
                            child: ListBody(
                              children: <Widget>[
                                _buildDetailRow('規模:',
                                    earthquake.magnitude.toStringAsFixed(1)),
                                _buildDetailRow('時間:', displayTime),
                                _buildDetailRow(
                                    '深度:', '${earthquake.depth ?? '未知'} km'),
                                if (earthquake.reportContent != null &&
                                    earthquake.reportContent!.isNotEmpty)
                                  _buildDetailRow(
                                      '報告摘要:', earthquake.reportContent!),
                                if (earthquake.reportImageURI != null &&
                                    earthquake.reportImageURI!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text('地震報告圖:',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14)),
                                        const SizedBox(height: 6),
                                        GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => FullScreenImageViewer(
                                                  imageUrl: earthquake.reportImageURI!,
                                                  heroTag: 'earthquakeImage_${earthquake.time}_${earthquake.location.hashCode}', 
                                                ),
                                              ),
                                            );
                                          },
                                          child: Hero(
                                            tag: 'earthquakeImage_${earthquake.time}_${earthquake.location.hashCode}',
                                            child: Image.network(
                                              earthquake.reportImageURI!,
                                              fit: BoxFit.contain,
                                              loadingBuilder: (BuildContext
                                                      context,
                                                  Widget child,
                                                  ImageChunkEvent?
                                                      loadingProgress) {
                                                if (loadingProgress == null)
                                                  return child;
                                                return Center(
                                                  child:
                                                      CircularProgressIndicator(
                                                    value: loadingProgress
                                                                .expectedTotalBytes !=
                                                            null
                                                        ? loadingProgress
                                                                .cumulativeBytesLoaded /
                                                            loadingProgress
                                                                .expectedTotalBytes!
                                                        : null,
                                                  ),
                                                );
                                              },
                                              errorBuilder: (context, error,
                                                      stackTrace) =>
                                                  const Text('圖片載入失敗',
                                                      style: TextStyle(
                                                          fontSize: 13)),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (earthquake.shakingAreaSummary != null &&
                                    earthquake.shakingAreaSummary!.isNotEmpty)
                                  _buildDetailRow('主要影響地區:',
                                      earthquake.shakingAreaSummary!),
                              ],
                            ),
                          ),
                          actions: [
                            if (earthquake.reportUrl != null &&
                                earthquake.reportUrl!.isNotEmpty)
                              TextButton(
                                child: const Text('CWA詳細報告'),
                                onPressed: () {
                                  // _launchURL(earthquake.reportUrl);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            '將開啟報告網頁: ${earthquake.reportUrl}')),
                                  );
                                },
                              ),
                            TextButton(
                              child: const Text('關閉'),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(fontSize: 14), 
          children: <TextSpan>[
            TextSpan(
                text: '$label ',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            TextSpan(
                text: value,
                style: const TextStyle(fontWeight: FontWeight.normal)),
          ],
        ),
      ),
    );
  }

  Color _getMagnitudeColor(double magnitude) {
    if (magnitude < 0) return Colors.grey;
    if (magnitude < 3.0) return Colors.green.shade400;
    if (magnitude < 4.0) return Colors.lime.shade700;
    if (magnitude < 5.0) return Colors.orange.shade500;
    if (magnitude < 6.0) return Colors.deepOrange.shade600;
    return Colors.red.shade700;
  }
}

class FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;
  final String heroTag;

  const FullScreenImageViewer({super.key, required this.imageUrl, required this.heroTag});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Hero(
          tag: heroTag,
          child: PhotoView(
            imageProvider: NetworkImage(imageUrl),
            loadingBuilder: (context, event) => const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
            errorBuilder: (context, error, stackTrace) => const Center(
              child: Icon(Icons.error_outline, color: Colors.red, size: 48),
            ),
            minScale: PhotoViewComputedScale.contained * 0.8,
            maxScale: PhotoViewComputedScale.covered * 2.5,
            initialScale: PhotoViewComputedScale.contained,
            backgroundDecoration: const BoxDecoration(color: Colors.black),
          ),
        ),
      ),
    );
  }
}