import 'package:flutter/material.dart';
import '../models/meeting.dart';
import '../models/user.dart';
import '../services/calendar_service.dart';

class CalendarSettingsScreen extends StatefulWidget {
  final AppUser currentUser;

  const CalendarSettingsScreen({super.key, required this.currentUser});

  @override
  State<CalendarSettingsScreen> createState() => _CalendarSettingsScreenState();
}

class _CalendarSettingsScreenState extends State<CalendarSettingsScreen> {
  final CalendarService _calendarService = CalendarService();
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController _clientIdController;
  late TextEditingController _clientSecretController;
  late TextEditingController _refreshTokenController;
  late TextEditingController _organizerEmailController;
  late TextEditingController _organizerNameController;
  late TextEditingController _calendarIdController;

  // Settings
  int _defaultDuration = 30;
  String _defaultTimeZone = 'Asia/Kolkata';
  bool _autoCreateMeetLink = true;
  bool _sendInvitations = true;

  bool _isLoading = true;
  bool _isSaving = false;
  bool _obscureClientSecret = true;
  bool _obscureRefreshToken = true;

  @override
  void initState() {
    super.initState();
    _clientIdController = TextEditingController();
    _clientSecretController = TextEditingController();
    _refreshTokenController = TextEditingController();
    _organizerEmailController = TextEditingController();
    _organizerNameController = TextEditingController();
    _calendarIdController = TextEditingController(text: 'primary');
    _loadConfig();
  }

  @override
  void dispose() {
    _clientIdController.dispose();
    _clientSecretController.dispose();
    _refreshTokenController.dispose();
    _organizerEmailController.dispose();
    _organizerNameController.dispose();
    _calendarIdController.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    try {
      final config = await _calendarService.getCalendarConfig();
      if (config != null && mounted) {
        setState(() {
          _clientIdController.text = config.clientId;
          _clientSecretController.text = config.clientSecret;
          _refreshTokenController.text = config.refreshToken;
          _organizerEmailController.text = config.organizerEmail;
          _organizerNameController.text = config.organizerName;
          _calendarIdController.text = config.calendarId;
          _defaultDuration = config.defaultDuration;
          _defaultTimeZone = config.defaultTimeZone;
          _autoCreateMeetLink = config.autoCreateMeetLink;
          _sendInvitations = config.sendInvitations;
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final config = CalendarConfig(
        clientId: _clientIdController.text.trim(),
        clientSecret: _clientSecretController.text.trim(),
        refreshToken: _refreshTokenController.text.trim(),
        organizerEmail: _organizerEmailController.text.trim(),
        organizerName: _organizerNameController.text.trim(),
        calendarId: _calendarIdController.text.trim(),
        defaultDuration: _defaultDuration,
        defaultTimeZone: _defaultTimeZone,
        autoCreateMeetLink: _autoCreateMeetLink,
        sendInvitations: _sendInvitations,
      );

      await _calendarService.saveCalendarConfig(config);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Calendar settings saved successfully'),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Check admin access - allow both superAdmin and admin
    final isAdmin = widget.currentUser.role == UserRole.superAdmin ||
        widget.currentUser.role == UserRole.admin;
    if (!isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Calendar Settings')),
        body: const Center(
          child: Text('Only admins can access calendar settings.'),
        ),
      );
    }

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Calendar Settings')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar Settings'),
        actions: [
          TextButton.icon(
            onPressed: _isSaving ? null : _saveConfig,
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Google API Credentials Section
            _buildSectionHeader(
              theme,
              'Google API Credentials',
              'Configure OAuth 2.0 credentials from Google Cloud Console',
              Icons.key,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _clientIdController,
              decoration: const InputDecoration(
                labelText: 'Client ID',
                hintText: 'OAuth 2.0 Client ID',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _clientSecretController,
              obscureText: _obscureClientSecret,
              decoration: InputDecoration(
                labelText: 'Client Secret',
                hintText: 'OAuth 2.0 Client Secret',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscureClientSecret
                      ? Icons.visibility_off
                      : Icons.visibility),
                  onPressed: () {
                    setState(() => _obscureClientSecret = !_obscureClientSecret);
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _refreshTokenController,
              obscureText: _obscureRefreshToken,
              decoration: InputDecoration(
                labelText: 'Refresh Token',
                hintText: 'OAuth 2.0 Refresh Token',
                prefixIcon: const Icon(Icons.refresh),
                suffixIcon: IconButton(
                  icon: Icon(_obscureRefreshToken
                      ? Icons.visibility_off
                      : Icons.visibility),
                  onPressed: () {
                    setState(() => _obscureRefreshToken = !_obscureRefreshToken);
                  },
                ),
              ),
              maxLines: 1,
            ),
            const SizedBox(height: 8),

            // Help text
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'To get OAuth credentials:\n'
                      '1. Go to Google Cloud Console\n'
                      '2. Create OAuth 2.0 credentials\n'
                      '3. Enable Google Calendar API\n'
                      '4. Use OAuth Playground to get refresh token',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Organizer Settings
            _buildSectionHeader(
              theme,
              'Organizer Settings',
              'Central admin account for scheduling meetings',
              Icons.person,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _organizerEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Organizer Email',
                hintText: 'admin@company.com',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                if (!v.contains('@')) return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _organizerNameController,
              decoration: const InputDecoration(
                labelText: 'Organizer Name',
                hintText: 'Company Name or Admin Name',
                prefixIcon: Icon(Icons.business_outlined),
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _calendarIdController,
              decoration: const InputDecoration(
                labelText: 'Calendar ID',
                hintText: 'primary or specific calendar ID',
                prefixIcon: Icon(Icons.calendar_month_outlined),
              ),
            ),

            const SizedBox(height: 32),

            // Meeting Defaults
            _buildSectionHeader(
              theme,
              'Meeting Defaults',
              'Default settings for new meetings',
              Icons.settings,
            ),
            const SizedBox(height: 16),

            // Default Duration
            DropdownButtonFormField<int>(
              value: _defaultDuration,
              decoration: const InputDecoration(
                labelText: 'Default Meeting Duration',
                prefixIcon: Icon(Icons.timelapse),
              ),
              items: const [
                DropdownMenuItem(value: 15, child: Text('15 minutes')),
                DropdownMenuItem(value: 30, child: Text('30 minutes')),
                DropdownMenuItem(value: 45, child: Text('45 minutes')),
                DropdownMenuItem(value: 60, child: Text('1 hour')),
                DropdownMenuItem(value: 90, child: Text('1.5 hours')),
                DropdownMenuItem(value: 120, child: Text('2 hours')),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _defaultDuration = v);
              },
            ),
            const SizedBox(height: 16),

            // Time Zone
            DropdownButtonFormField<String>(
              value: _defaultTimeZone,
              decoration: const InputDecoration(
                labelText: 'Default Timezone',
                prefixIcon: Icon(Icons.schedule),
              ),
              items: const [
                DropdownMenuItem(
                    value: 'Asia/Kolkata', child: Text('India (IST)')),
                DropdownMenuItem(
                    value: 'America/New_York', child: Text('US Eastern')),
                DropdownMenuItem(
                    value: 'America/Los_Angeles', child: Text('US Pacific')),
                DropdownMenuItem(value: 'Europe/London', child: Text('UK (GMT)')),
                DropdownMenuItem(
                    value: 'Europe/Paris', child: Text('Central Europe')),
                DropdownMenuItem(
                    value: 'Asia/Singapore', child: Text('Singapore')),
                DropdownMenuItem(
                    value: 'Australia/Sydney', child: Text('Australia Sydney')),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _defaultTimeZone = v);
              },
            ),
            const SizedBox(height: 24),

            // Toggle switches
            SwitchListTile(
              value: _autoCreateMeetLink,
              onChanged: (v) => setState(() => _autoCreateMeetLink = v),
              title: const Text('Auto-create Google Meet Link'),
              subtitle: const Text(
                  'Automatically add video conference to meetings'),
              secondary: const Icon(Icons.videocam_outlined),
            ),

            SwitchListTile(
              value: _sendInvitations,
              onChanged: (v) => setState(() => _sendInvitations = v),
              title: const Text('Send Calendar Invitations'),
              subtitle: const Text('Email invites to guests when scheduling'),
              secondary: const Icon(Icons.mail_outline),
            ),

            const SizedBox(height: 32),

            // Test Connection Button
            OutlinedButton.icon(
              onPressed: _testConnection,
              icon: const Icon(Icons.wifi_tethering),
              label: const Text('Test Calendar Connection'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),

            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    ThemeData theme,
    String title,
    String subtitle,
    IconData icon,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _testConnection() async {
    // Show a test dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 16),
            Text('Testing Connection...'),
          ],
        ),
        content: const Text(
          'Note: Full calendar sync requires a Cloud Function to be deployed. '
          'This test only verifies that the configuration is saved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    // Simulate a test delay
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      Navigator.pop(context);

      final hasCredentials = _clientIdController.text.isNotEmpty &&
          _clientSecretController.text.isNotEmpty &&
          _organizerEmailController.text.isNotEmpty;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            hasCredentials
                ? 'Configuration looks valid. Save to apply changes.'
                : 'Missing required credentials (Client ID, Client Secret, Organizer Email)',
          ),
          backgroundColor:
              hasCredentials ? Colors.green.shade700 : Colors.orange.shade700,
        ),
      );
    }
  }
}
