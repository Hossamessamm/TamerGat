import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../services/api_debug_service.dart';
import 'token_refresh_test_widget.dart';

class DebugLogViewer extends StatelessWidget {
  const DebugLogViewer({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Debug Logs'),
        backgroundColor: const Color(0xFF38026B),
        foregroundColor: Colors.white,
        actions: [
          if (kDebugMode)
            IconButton(
              icon: const Icon(Icons.security),
              tooltip: 'Test Token Refresh',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const TokenRefreshTestWidget(),
                  ),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              context.read<ApiDebugService>().clearLogs();
            },
          ),
        ],
      ),
      body: Consumer<ApiDebugService>(
        builder: (context, debugService, child) {
          if (debugService.logs.isEmpty) {
            return const Center(
              child: Text(
                'No API calls yet',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            itemCount: debugService.logs.length,
            padding: const EdgeInsets.all(8),
            itemBuilder: (context, index) {
              final log = debugService.logs[index];
              return _buildLogCard(log);
            },
          );
        },
      ),
    );
  }

  Widget _buildLogCard(ApiLog log) {
    final hasResponse = log.statusCode != null;
    final hasError = log.error != null;
    
    Color statusColor;
    if (hasError) {
      statusColor = Colors.red;
    } else if (hasResponse) {
      statusColor = log.statusCode! >= 200 && log.statusCode! < 300
          ? Colors.green
          : Colors.orange;
    } else {
      statusColor = Colors.blue;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Container(
          width: 60,
          height: 30,
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: Text(
            log.method,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        title: Text(
          _getUrlPath(log.url),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Row(
          children: [
            Text(
              _formatTime(log.timestamp),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            if (hasResponse) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${log.statusCode}',
                  style: TextStyle(
                    fontSize: 11,
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSection('URL', log.url),
                if (log.headers != null) _buildSection('Headers', log.headers.toString()),
                if (log.requestBody != null) _buildSection('Request Body', log.requestBody!),
                if (log.statusCode != null) _buildSection('Status Code', '${log.statusCode}'),
                if (log.responseBody != null) _buildSection('Response Body', log.responseBody!),
                if (log.error != null) _buildSection('Error', log.error!, isError: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content, {bool isError = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: isError ? Colors.red : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isError ? Colors.red[50] : Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: SelectableText(
              content,
              style: TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                color: isError ? Colors.red[900] : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getUrlPath(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.path;
    } catch (e) {
      return url;
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
  }
}
