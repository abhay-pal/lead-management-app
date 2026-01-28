import 'package:flutter/material.dart';
import '../models/meeting.dart';
import '../models/user.dart';
import '../services/calendar_service.dart';
import '../widgets/schedule_meeting_dialog.dart';

class CalendarScreen extends StatefulWidget {
  final AppUser currentUser;

  const CalendarScreen({super.key, required this.currentUser});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen>
    with SingleTickerProviderStateMixin {
  final CalendarService _calendarService = CalendarService();
  late TabController _tabController;

  DateTime _selectedDate = DateTime.now();
  List<Meeting> _meetings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadMeetings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMeetings() async {
    setState(() => _isLoading = true);
    try {
      final meetings = await _calendarService.getAllMeetings();
      if (mounted) {
        setState(() {
          _meetings = meetings;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Meeting> get _filteredMeetings {
    final now = DateTime.now();
    switch (_tabController.index) {
      case 0: // Today
        return _meetings.where((m) {
          return m.startTime.year == now.year &&
              m.startTime.month == now.month &&
              m.startTime.day == now.day;
        }).toList();
      case 1: // This Week
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 7));
        return _meetings.where((m) {
          return m.startTime.isAfter(weekStart.subtract(const Duration(days: 1))) &&
              m.startTime.isBefore(weekEnd);
        }).toList();
      case 2: // All
      default:
        return _meetings;
    }
  }

  void _openScheduleDialog() {
    showDialog(
      context: context,
      builder: (ctx) => ScheduleMeetingDialog(
        currentUser: widget.currentUser,
        onMeetingCreated: _loadMeetings,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        bottom: TabBar(
          controller: _tabController,
          onTap: (_) => setState(() {}),
          tabs: const [
            Tab(text: 'Today'),
            Tab(text: 'This Week'),
            Tab(text: 'All'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMeetings,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredMeetings.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.event_available,
                        size: 64,
                        color: cs.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No meetings scheduled',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: cs.outline,
                        ),
                      ),
                      const SizedBox(height: 8),
                      FilledButton.icon(
                        onPressed: _openScheduleDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Schedule Meeting'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadMeetings,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredMeetings.length,
                    itemBuilder: (ctx, index) {
                      final meeting = _filteredMeetings[index];
                      return _MeetingCard(
                        meeting: meeting,
                        onStatusChange: (status) async {
                          await _calendarService.updateMeetingStatus(
                              meeting.id, status);
                          _loadMeetings();
                        },
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openScheduleDialog,
        icon: const Icon(Icons.add),
        label: const Text('New Meeting'),
      ),
    );
  }
}

class _MeetingCard extends StatelessWidget {
  final Meeting meeting;
  final Function(MeetingStatus) onStatusChange;

  const _MeetingCard({
    required this.meeting,
    required this.onStatusChange,
  });

  Color _getStatusColor(MeetingStatus status, ColorScheme cs) {
    switch (status) {
      case MeetingStatus.scheduled:
        return Colors.blue;
      case MeetingStatus.confirmed:
        return Colors.green;
      case MeetingStatus.inProgress:
        return Colors.orange;
      case MeetingStatus.completed:
        return Colors.grey;
      case MeetingStatus.cancelled:
        return Colors.red;
      case MeetingStatus.rescheduled:
        return Colors.purple;
      case MeetingStatus.noShow:
        return Colors.brown;
    }
  }

  IconData _getTypeIcon(MeetingType type) {
    switch (type) {
      case MeetingType.googleMeet:
        return Icons.videocam;
      case MeetingType.phoneCall:
        return Icons.phone;
      case MeetingType.inPerson:
        return Icons.people;
      case MeetingType.other:
        return Icons.event;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final statusColor = _getStatusColor(meeting.status, cs);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Show meeting details
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getTypeIcon(meeting.type),
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          meeting.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (meeting.leadName != null)
                          Text(
                            'Lead: ${meeting.leadName}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.outline,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      meeting.status.label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: cs.outline),
                  const SizedBox(width: 4),
                  Text(
                    '${meeting.startTime.day}/${meeting.startTime.month}/${meeting.startTime.year}',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.access_time, size: 16, color: cs.outline),
                  const SizedBox(width: 4),
                  Text(
                    '${meeting.startTime.hour.toString().padLeft(2, '0')}:${meeting.startTime.minute.toString().padLeft(2, '0')} - ${meeting.endTime.hour.toString().padLeft(2, '0')}:${meeting.endTime.minute.toString().padLeft(2, '0')}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              if (meeting.guests.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.people_outline, size: 16, color: cs.outline),
                    const SizedBox(width: 4),
                    Text(
                      '${meeting.guests.length} guest${meeting.guests.length > 1 ? 's' : ''}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.outline,
                      ),
                    ),
                  ],
                ),
              ],
              if (meeting.meetLink != null) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () {
                    // Open meet link
                  },
                  icon: const Icon(Icons.videocam, size: 18),
                  label: const Text('Join Meeting'),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (meeting.status == MeetingStatus.scheduled) ...[
                    TextButton(
                      onPressed: () => onStatusChange(MeetingStatus.confirmed),
                      child: const Text('Confirm'),
                    ),
                    TextButton(
                      onPressed: () => onStatusChange(MeetingStatus.cancelled),
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ],
                  if (meeting.status == MeetingStatus.confirmed) ...[
                    TextButton(
                      onPressed: () => onStatusChange(MeetingStatus.inProgress),
                      child: const Text('Start'),
                    ),
                  ],
                  if (meeting.status == MeetingStatus.inProgress) ...[
                    TextButton(
                      onPressed: () => onStatusChange(MeetingStatus.completed),
                      child: const Text('Complete'),
                    ),
                    TextButton(
                      onPressed: () => onStatusChange(MeetingStatus.noShow),
                      child: const Text('No Show'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
