import 'package:flutter/material.dart';
import '../services/connection_service.dart';
import '../services/service_locator.dart';

class ConnectionStatusWidget extends StatefulWidget {
  final Widget child;
  
  const ConnectionStatusWidget({
    super.key,
    required this.child,
  });

  @override
  State<ConnectionStatusWidget> createState() => _ConnectionStatusWidgetState();
}

class _ConnectionStatusWidgetState extends State<ConnectionStatusWidget> {
  late ConnectionService _connectionService;
  bool _isConnected = true;
  bool _showStatus = false;

  @override
  void initState() {
    super.initState();
    _connectionService = getIt.get<ConnectionService>();
    _connectionService.startMonitoring();
    
    _connectionService.connectionStream.listen((connected) {
      if (mounted) {
        setState(() {
          _isConnected = connected;
          _showStatus = !connected; // Only show when disconnected
        });
      }
    });
    
    // Test connection immediately
    _connectionService.testConnectionOnce();
  }

  @override
  void dispose() {
    _connectionService.stopMonitoring();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_showStatus)
          Positioned(
            top: MediaQuery.of(context).padding.top,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: _isConnected ? Colors.green : Colors.red,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isConnected ? Icons.wifi : Icons.wifi_off,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isConnected ? 'Connected' : 'Connection Lost - Check Backend',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (!_isConnected) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        _connectionService.testConnectionOnce();
                      },
                      child: const Icon(
                        Icons.refresh,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}