import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

class _CalendarScreenState extends State<CalendarScreen> {
  final CalendarService _calendarService = CalendarService();

  DateTime _currentMonth = DateTime.now();
  DateTime? _selectedDate;
  List<Meeting> _meetings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _loadMeetings();
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

  List<Meeting> _getMeetingsForDate(DateTime date) {
    return _meetings.where((m) {
      return m.startTime.year == date.year &&
          m.startTime.month == date.month &&
          m.startTime.day == date.day;
    }).toList();
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    });
  }

  void _goToToday() {
    setState(() {
      _currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
      _selectedDate = DateTime.now();
    });
  }

  void _openScheduleDialog({DateTime? preselectedDate}) {
    showDialog(
      context: context,
      builder: (ctx) => ScheduleMeetingDialog(
        currentUser: widget.currentUser,
        onMeetingCreated: _loadMeetings,
        preselectedDate: preselectedDate,
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
        actions: [
          TextButton.icon(
            onPressed: _goToToday,
            icon: const Icon(Icons.today),
            label: const Text('Today'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMeetings,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Month navigation header
                _buildMonthHeader(cs),
                // Calendar grid
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Calendar view
                      Expanded(
                        flex: 3,
                        child: _buildCalendarGrid(cs),
                      ),
                      // Selected day panel (on wide screens)
                      if (MediaQuery.of(context).size.width > 800)
                        Container(
                          width: 320,
                          decoration: BoxDecoration(
                            border: Border(
                              left: BorderSide(color: Colors.grey.shade200),
                            ),
                          ),
                          child: _buildSelectedDayPanel(cs),
                        ),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openScheduleDialog(preselectedDate: _selectedDate),
        icon: const Icon(Icons.add),
        label: const Text('New Meeting'),
      ),
    );
  }

  Widget _buildMonthHeader(ColorScheme cs) {
    final monthYear = DateFormat('MMMM yyyy').format(_currentMonth);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _previousMonth,
            tooltip: 'Previous month',
          ),
          Expanded(
            child: Text(
              monthYear,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _nextMonth,
            tooltip: 'Next month',
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(ColorScheme cs) {
    final daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final startingWeekday = firstDayOfMonth.weekday; // 1 = Monday, 7 = Sunday

    // Calculate previous month days to show
    final previousMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    final daysInPreviousMonth = DateTime(previousMonth.year, previousMonth.month + 1, 0).day;

    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final today = DateTime.now();

    return Column(
      children: [
        // Weekday headers
        Container(
          color: cs.primaryContainer.withOpacity(0.3),
          child: Row(
            children: weekdays.map((day) {
              final isWeekend = day == 'Sat' || day == 'Sun';
              return Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    day,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: isWeekend ? Colors.red.shade400 : cs.onSurface,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        // Calendar days grid
        Expanded(
          child: GridView.builder(
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.0,
            ),
            itemCount: 42, // 6 weeks
            itemBuilder: (context, index) {
              int dayNumber;
              bool isCurrentMonth = true;
              bool isPreviousMonth = false;

              if (index < startingWeekday - 1) {
                // Previous month
                dayNumber = daysInPreviousMonth - (startingWeekday - 2 - index);
                isCurrentMonth = false;
                isPreviousMonth = true;
              } else if (index - startingWeekday + 2 > daysInMonth) {
                // Next month
                dayNumber = index - startingWeekday + 2 - daysInMonth;
                isCurrentMonth = false;
              } else {
                // Current month
                dayNumber = index - startingWeekday + 2;
              }

              DateTime date;
              if (isPreviousMonth) {
                date = DateTime(previousMonth.year, previousMonth.month, dayNumber);
              } else if (!isCurrentMonth) {
                date = DateTime(_currentMonth.year, _currentMonth.month + 1, dayNumber);
              } else {
                date = DateTime(_currentMonth.year, _currentMonth.month, dayNumber);
              }

              final isToday = isCurrentMonth &&
                  date.year == today.year &&
                  date.month == today.month &&
                  date.day == today.day;
              final isSelected = _selectedDate != null &&
                  date.year == _selectedDate!.year &&
                  date.month == _selectedDate!.month &&
                  date.day == _selectedDate!.day;
              final isWeekend = index % 7 == 5 || index % 7 == 6;
              final meetingsForDay = _getMeetingsForDate(date);

              return _buildDayCell(
                date,
                dayNumber,
                isCurrentMonth,
                isToday,
                isSelected,
                isWeekend,
                meetingsForDay,
                cs,
              );
            },
          ),
        ),
        // Selected day meetings (on narrow screens)
        if (MediaQuery.of(context).size.width <= 800 && _selectedDate != null)
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(
                top: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: _buildSelectedDayPanel(cs),
          ),
      ],
    );
  }

  Widget _buildDayCell(
    DateTime date,
    int dayNumber,
    bool isCurrentMonth,
    bool isToday,
    bool isSelected,
    bool isWeekend,
    List<Meeting> meetings,
    ColorScheme cs,
  ) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedDate = date;
        });
      },
      onDoubleTap: () {
        _openScheduleDialog(preselectedDate: date);
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? cs.primaryContainer.withOpacity(0.5)
              : isToday
                  ? cs.primary.withOpacity(0.1)
                  : null,
          border: Border.all(
            color: isSelected
                ? cs.primary
                : Colors.grey.shade200,
            width: isSelected ? 2 : 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Day number
            Padding(
              padding: const EdgeInsets.all(4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isToday ? cs.primary : null,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$dayNumber',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                        color: isToday
                            ? Colors.white
                            : !isCurrentMonth
                                ? Colors.grey.shade400
                                : isWeekend
                                    ? Colors.red.shade400
                                    : null,
                      ),
                    ),
                  ),
                  if (meetings.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: cs.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${meetings.length}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: cs.primary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Meeting previews
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: meetings.take(3).map((meeting) {
                    return _buildMeetingChip(meeting);
                  }).toList(),
                ),
              ),
            ),
            if (meetings.length > 3)
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 2),
                child: Text(
                  '+${meetings.length - 3} more',
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeetingChip(Meeting meeting) {
    final statusColor = _getStatusColor(meeting.status);
    final timeStr = DateFormat('HH:mm').format(meeting.startTime);

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border(
          left: BorderSide(color: statusColor, width: 3),
        ),
      ),
      child: Row(
        children: [
          Text(
            timeStr,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              meeting.title,
              style: const TextStyle(fontSize: 9),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedDayPanel(ColorScheme cs) {
    if (_selectedDate == null) {
      return const Center(child: Text('Select a date'));
    }

    final meetings = _getMeetingsForDate(_selectedDate!);
    final dateStr = DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate!);

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [cs.primaryContainer.withOpacity(0.5), Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dateStr,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${meetings.length} meeting${meetings.length == 1 ? '' : 's'}',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        // Meetings list
        Expanded(
          child: meetings.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.event_available,
                          size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 8),
                      Text(
                        'No meetings',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () =>
                            _openScheduleDialog(preselectedDate: _selectedDate),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Meeting'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: meetings.length,
                  itemBuilder: (context, index) {
                    final meeting = meetings[index];
                    return _MeetingDetailCard(
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
      ],
    );
  }

  Color _getStatusColor(MeetingStatus status) {
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
}

class _MeetingDetailCard extends StatelessWidget {
  final Meeting meeting;
  final Function(MeetingStatus) onStatusChange;

  const _MeetingDetailCard({
    required this.meeting,
    required this.onStatusChange,
  });

  Color _getStatusColor(MeetingStatus status) {
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
    final statusColor = _getStatusColor(meeting.status);
    final timeStr =
        '${meeting.startTime.hour.toString().padLeft(2, '0')}:${meeting.startTime.minute.toString().padLeft(2, '0')} - ${meeting.endTime.hour.toString().padLeft(2, '0')}:${meeting.endTime.minute.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    _getTypeIcon(meeting.type),
                    color: statusColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meeting.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        timeStr,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    meeting.status.label,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (meeting.leadName != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.person_outline, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    meeting.leadName!,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
            if (meeting.meetLink != null && meeting.meetLink!.isNotEmpty && meeting.meetLink != 'pending') ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Open meet link
                  },
                  icon: const Icon(Icons.video_call, size: 16),
                  label: const Text('Join Meeting'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
            // Action buttons
            if (meeting.status != MeetingStatus.completed &&
                meeting.status != MeetingStatus.cancelled) ...[
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (meeting.status == MeetingStatus.scheduled) ...[
                    TextButton(
                      onPressed: () => onStatusChange(MeetingStatus.confirmed),
                      child: const Text('Confirm', style: TextStyle(fontSize: 12)),
                    ),
                    TextButton(
                      onPressed: () => onStatusChange(MeetingStatus.cancelled),
                      child: Text('Cancel',
                          style: TextStyle(fontSize: 12, color: Colors.red.shade700)),
                    ),
                  ],
                  if (meeting.status == MeetingStatus.confirmed) ...[
                    TextButton(
                      onPressed: () => onStatusChange(MeetingStatus.inProgress),
                      child: const Text('Start', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                  if (meeting.status == MeetingStatus.inProgress) ...[
                    TextButton(
                      onPressed: () => onStatusChange(MeetingStatus.completed),
                      child: const Text('Complete', style: TextStyle(fontSize: 12)),
                    ),
                    TextButton(
                      onPressed: () => onStatusChange(MeetingStatus.noShow),
                      child: const Text('No Show', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
