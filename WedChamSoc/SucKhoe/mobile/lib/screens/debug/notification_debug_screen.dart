import 'package:flutter/material.dart';
import '../../services/notification_service.dart';
import '../../services/reminder_service.dart';

class NotificationDebugScreen extends StatefulWidget {
  const NotificationDebugScreen({super.key});

  @override
  State<NotificationDebugScreen> createState() => _NotificationDebugScreenState();
}

class _NotificationDebugScreenState extends State<NotificationDebugScreen> {
  final NotificationService _notificationService = NotificationService();
  final ReminderService _reminderService = ReminderService();
  
  Map<String, dynamic>? _status;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    setState(() => _loading = true);
    try {
      final status = await _notificationService.getNotificationStatus();
      setState(() => _status = status);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading status: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _testImmediateNotification() async {
    try {
      await _notificationService.testNotification();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Test notification sent!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e')),
      );
    }
  }

  Future<void> _testAppointmentReminder() async {
    try {
      await _notificationService.testAppointmentReminder();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Test appointment reminder scheduled!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e')),
      );
    }
  }

  Future<void> _testScheduledNotification() async {
    try {
      await _notificationService.testScheduledNotification();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Scheduled notification for 5 seconds!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e')),
      );
    }
  }

  Future<void> _syncReminders() async {
    try {
      await _reminderService.forceSync();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Reminders synced!')),
      );
      _loadStatus(); // Refresh status
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e')),
      );
    }
  }

  Future<void> _openExactAlarmSettings() async {
    try {
      final opened = await _notificationService.openExactAlarmSettings();
      if (opened) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Opened exact alarm settings')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Could not open settings')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Debug'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Status Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Notification Status',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              onPressed: _loadStatus,
                              icon: const Icon(Icons.refresh),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (_status != null) ...[
                          _buildStatusItem('Initialized', _status!['initialized']),
                          _buildStatusItem('Platform', _status!['platform']),
                          if (_status!['hasExactAlarmPermission'] != null)
                            _buildStatusItem('Exact Alarm Permission', _status!['hasExactAlarmPermission']),
                          if (_status!['notificationPermission'] != null)
                            _buildStatusItem('Notification Permission', _status!['notificationPermission']),
                          _buildStatusItem('Pending Notifications', _status!['pendingNotificationsCount']),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Test Buttons
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Test Notifications',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _testImmediateNotification,
                            icon: const Icon(Icons.notifications),
                            label: const Text('Test Immediate Notification'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 8),
                        
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _testScheduledNotification,
                            icon: const Icon(Icons.schedule),
                            label: const Text('Test Scheduled Notification (5s)'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 8),
                        
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _testAppointmentReminder,
                            icon: const Icon(Icons.event),
                            label: const Text('Test Appointment Reminder'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 8),
                        
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _syncReminders,
                            icon: const Icon(Icons.sync),
                            label: const Text('Sync Reminders'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        
                        if (_status?['hasExactAlarmPermission'] == false) ...[
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _openExactAlarmSettings,
                              icon: const Icon(Icons.settings),
                              label: const Text('Open Exact Alarm Settings'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Pending Notifications
                if (_status?['pendingNotifications'] != null) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Pending Notifications',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if ((_status!['pendingNotifications'] as List).isEmpty)
                            const Text('No pending notifications')
                          else
                            ...(_status!['pendingNotifications'] as List).map((notification) {
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  title: Text(notification['title'] ?? 'No title'),
                                  subtitle: Text(notification['body'] ?? 'No body'),
                                  trailing: Text('ID: ${notification['id']}'),
                                ),
                              );
                            }).toList(),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Instructions
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Instructions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '1. Test immediate notification to check if notifications work\n'
                          '2. Test scheduled notification to check if scheduling works (5s delay)\n'
                          '3. Test appointment reminder to simulate real appointment scenario\n'
                          '4. If exact alarm permission is false, open settings to enable it\n'
                          '5. Sync reminders to schedule real medication/appointment reminders\n'
                          '6. Check pending notifications to see what\'s scheduled\n\n'
                          'Note: Appointment reminders with past reminder times will be scheduled immediately (10s delay)',
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatusItem(String label, dynamic value) {
    Color color = Colors.grey;
    if (value is bool) {
      color = value ? Colors.green : Colors.red;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: color),
            ),
            child: Text(
              value.toString(),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}