import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import '../utils/app_logger.dart';

class ConnectivityService extends GetxService {
  final Connectivity _connectivity = Connectivity();
  final RxBool isOnline = true.obs;
  late final StreamSubscription<List<ConnectivityResult>> _sub;

  Future<ConnectivityService> init() async {
    final results = await _connectivity.checkConnectivity();
    _updateStatus(results);

    _sub = _connectivity.onConnectivityChanged.listen(_updateStatus);
    return this;
  }

  void _updateStatus(List<ConnectivityResult> results) {
    final online = results.any((r) => r != ConnectivityResult.none);
    isOnline.value = online;
    AppLogger.d('Network status changed: online=$online');
  }

  Future<bool> checkNow() async {
    final results = await _connectivity.checkConnectivity();
    final online = results.any((r) => r != ConnectivityResult.none);
    isOnline.value = online;
    return online;
  }

  @override
  void onClose() {
    _sub.cancel();
    super.onClose();
  }
}
