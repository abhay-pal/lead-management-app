import 'package:flutter/material.dart';
import '../models/email_template.dart';
import '../services/email_service.dart';
import '../utils/seed_demo_data.dart';

class EmailSettingsScreen extends StatefulWidget {
  const EmailSettingsScreen({super.key});

  @override
  State<EmailSettingsScreen> createState() => _EmailSettingsScreenState();
}

class _EmailSettingsScreenState extends State<EmailSettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final EmailService _emailService = EmailService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Email Settings'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'SMTP', icon: Icon(Icons.settings)),
            Tab(text: 'Categories', icon: Icon(Icons.category)),
            Tab(text: 'Templates', icon: Icon(Icons.email)),
            Tab(text: 'Demo Data', icon: Icon(Icons.science)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _SmtpConfigTab(emailService: _emailService),
          _CategoriesTab(emailService: _emailService),
          _TemplatesTab(emailService: _emailService),
          const _DemoDataTab(),
        ],
      ),
    );
  }
}

// ============================================================================
// SMTP Configuration Tab
// ============================================================================

class _SmtpConfigTab extends StatefulWidget {
  final EmailService emailService;
  const _SmtpConfigTab({required this.emailService});

  @override
  State<_SmtpConfigTab> createState() => _SmtpConfigTabState();
}

class _SmtpConfigTabState extends State<_SmtpConfigTab> {
  final _formKey = GlobalKey<FormState>();
  final _hostController = TextEditingController();
  final _portController = TextEditingController(text: '587');
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fromEmailController = TextEditingController();
  final _fromNameController = TextEditingController();
  bool _useTls = true;
  bool _useSsl = false;
  bool _loading = true;
  bool _saving = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final config = await widget.emailService.getSmtpConfig();
    if (config != null) {
      _hostController.text = config.host;
      _portController.text = config.port.toString();
      _usernameController.text = config.username;
      _passwordController.text = config.password;
      _fromEmailController.text = config.fromEmail;
      _fromNameController.text = config.fromName;
      _useTls = config.useTls;
      _useSsl = config.useSsl;
    }
    setState(() => _loading = false);
  }

  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final config = SmtpConfig(
        host: _hostController.text.trim(),
        port: int.tryParse(_portController.text) ?? 587,
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        fromEmail: _fromEmailController.text.trim(),
        fromName: _fromNameController.text.trim(),
        useTls: _useTls,
        useSsl: _useSsl,
      );
      await widget.emailService.saveSmtpConfig(config);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('SMTP settings saved!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'SMTP Server Configuration',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Configure the central email account that will send all emails.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _hostController,
              decoration: const InputDecoration(
                labelText: 'SMTP Host',
                hintText: 'e.g., smtp.gmail.com',
                prefixIcon: Icon(Icons.dns),
              ),
              validator: (v) => v?.isEmpty == true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _portController,
              decoration: const InputDecoration(
                labelText: 'Port',
                hintText: '587 for TLS, 465 for SSL',
                prefixIcon: Icon(Icons.numbers),
              ),
              keyboardType: TextInputType.number,
              validator: (v) => v?.isEmpty == true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username / Email',
                prefixIcon: Icon(Icons.person),
              ),
              validator: (v) => v?.isEmpty == true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password / App Password',
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword
                      ? Icons.visibility
                      : Icons.visibility_off),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              obscureText: _obscurePassword,
              validator: (v) => v?.isEmpty == true ? 'Required' : null,
            ),
            const SizedBox(height: 24),
            const Text(
              'From Address',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _fromEmailController,
              decoration: const InputDecoration(
                labelText: 'From Email',
                prefixIcon: Icon(Icons.email),
              ),
              validator: (v) => v?.isEmpty == true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _fromNameController,
              decoration: const InputDecoration(
                labelText: 'From Name',
                hintText: 'e.g., Xtrazcon Sales',
                prefixIcon: Icon(Icons.badge),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CheckboxListTile(
                    title: const Text('Use TLS'),
                    value: _useTls,
                    onChanged: (v) => setState(() => _useTls = v ?? true),
                  ),
                ),
                Expanded(
                  child: CheckboxListTile(
                    title: const Text('Use SSL'),
                    value: _useSsl,
                    onChanged: (v) => setState(() => _useSsl = v ?? false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _saving ? null : _saveConfig,
                icon: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(_saving ? 'Saving...' : 'Save SMTP Settings'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Business Categories Tab
// ============================================================================

class _CategoriesTab extends StatelessWidget {
  final EmailService emailService;
  const _CategoriesTab({required this.emailService});

  void _showAddCategoryDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Category'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Category Name',
            hintText: 'e.g., CityFinSol',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await emailService.addCategory(controller.text.trim());
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Business Categories',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              FilledButton.icon(
                onPressed: () => _showAddCategoryDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('Add'),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<BusinessCategory>>(
            stream: emailService.streamCategories(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final categories = snapshot.data!;
              if (categories.isEmpty) {
                return const Center(
                  child: Text('No categories yet. Add one to get started.'),
                );
              }
              return ListView.builder(
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  return ListTile(
                    leading: const Icon(Icons.folder),
                    title: Text(cat.name),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete Category?'),
                            content: Text(
                                'Delete "${cat.name}"? Templates in this category will become orphaned.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await emailService.deleteCategory(cat.id);
                        }
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// Email Templates Tab
// ============================================================================

class _TemplatesTab extends StatefulWidget {
  final EmailService emailService;
  const _TemplatesTab({required this.emailService});

  @override
  State<_TemplatesTab> createState() => _TemplatesTabState();
}

class _TemplatesTabState extends State<_TemplatesTab> {
  String? _selectedCategoryId;

  void _showTemplateEditor(BuildContext context, EmailTemplate? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => _TemplateEditorSheet(
        emailService: widget.emailService,
        existing: existing,
        categoryId: _selectedCategoryId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Category filter
        StreamBuilder<List<BusinessCategory>>(
          stream: widget.emailService.streamCategories(),
          builder: (context, catSnap) {
            final categories = catSnap.data ?? [];
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      value: _selectedCategoryId,
                      decoration: const InputDecoration(
                        labelText: 'Filter by Category',
                        prefixIcon: Icon(Icons.filter_list),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('All Categories'),
                        ),
                        ...categories.map((c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(c.name),
                            )),
                      ],
                      onChanged: (v) => setState(() => _selectedCategoryId = v),
                    ),
                  ),
                  const SizedBox(width: 16),
                  FilledButton.icon(
                    onPressed: () => _showTemplateEditor(context, null),
                    icon: const Icon(Icons.add),
                    label: const Text('Add'),
                  ),
                ],
              ),
            );
          },
        ),
        // Templates list
        Expanded(
          child: StreamBuilder<List<EmailTemplate>>(
            stream: widget.emailService
                .streamTemplates(categoryId: _selectedCategoryId),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final templates = snapshot.data!;
              if (templates.isEmpty) {
                return const Center(
                  child: Text('No templates. Add one to get started.'),
                );
              }
              return ListView.builder(
                itemCount: templates.length,
                itemBuilder: (context, index) {
                  final tpl = templates[index];
                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      leading: Icon(_getTemplateIcon(tpl.type)),
                      title: Text(tpl.type.label),
                      subtitle: Text(
                        tpl.subject,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _showTemplateEditor(context, tpl),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Delete Template?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: const Text('Cancel'),
                                    ),
                                    FilledButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await widget.emailService.deleteTemplate(tpl.id);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  IconData _getTemplateIcon(EmailTemplateType type) {
    switch (type) {
      case EmailTemplateType.followUp:
        return Icons.refresh;
      case EmailTemplateType.offerPlan:
        return Icons.local_offer;
      case EmailTemplateType.demoConfirmation:
        return Icons.event_available;
      case EmailTemplateType.proposal:
        return Icons.description;
      case EmailTemplateType.reminder:
        return Icons.notifications;
      case EmailTemplateType.paymentRequest:
        return Icons.payment;
    }
  }
}

// ============================================================================
// Template Editor Sheet
// ============================================================================

class _TemplateEditorSheet extends StatefulWidget {
  final EmailService emailService;
  final EmailTemplate? existing;
  final String? categoryId;

  const _TemplateEditorSheet({
    required this.emailService,
    this.existing,
    this.categoryId,
  });

  @override
  State<_TemplateEditorSheet> createState() => _TemplateEditorSheetState();
}

class _TemplateEditorSheetState extends State<_TemplateEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late String _categoryId;
  late EmailTemplateType _type;
  final _subjectController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _categoryId = widget.existing?.categoryId ?? widget.categoryId ?? '';
    _type = widget.existing?.type ?? EmailTemplateType.followUp;
    _subjectController.text = widget.existing?.subject ?? '';
    _bodyController.text = widget.existing?.body ?? '';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoryId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final template = EmailTemplate(
        id: widget.existing?.id ?? '',
        categoryId: _categoryId,
        type: _type,
        subject: _subjectController.text.trim(),
        body: _bodyController.text.trim(),
      );
      await widget.emailService.saveTemplate(template);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => SingleChildScrollView(
        controller: scrollController,
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                widget.existing == null ? 'New Template' : 'Edit Template',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              // Category dropdown
              StreamBuilder<List<BusinessCategory>>(
                stream: widget.emailService.streamCategories(),
                builder: (context, snapshot) {
                  final categories = snapshot.data ?? [];
                  return DropdownButtonFormField<String>(
                    value: _categoryId.isEmpty ? null : _categoryId,
                    decoration: const InputDecoration(
                      labelText: 'Business Category',
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: categories
                        .map((c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(c.name),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _categoryId = v ?? ''),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                  );
                },
              ),
              const SizedBox(height: 16),
              // Template type dropdown
              DropdownButtonFormField<EmailTemplateType>(
                value: _type,
                decoration: const InputDecoration(
                  labelText: 'Template Type',
                  prefixIcon: Icon(Icons.style),
                ),
                items: EmailTemplateType.values
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(t.label),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _type = v!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _subjectController,
                decoration: const InputDecoration(
                  labelText: 'Email Subject',
                  hintText: 'e.g., Demo Confirmation - {{client_name}}',
                  prefixIcon: Icon(Icons.subject),
                ),
                validator: (v) => v?.isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bodyController,
                decoration: const InputDecoration(
                  labelText: 'Email Body',
                  hintText: 'Use {{placeholders}} for dynamic content',
                  alignLabelWithHint: true,
                ),
                maxLines: 10,
                validator: (v) => v?.isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              // Placeholder help
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Available Placeholders:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Chip(label: Text('{{client_name}}')),
                          Chip(label: Text('{{business_name}}')),
                          Chip(label: Text('{{client_email}}')),
                          Chip(label: Text('{{meeting_date}}')),
                          Chip(label: Text('{{meeting_time}}')),
                          Chip(label: Text('{{meeting_link}}')),
                          Chip(label: Text('{{product_name}}')),
                          Chip(label: Text('{{next_follow_up}}')),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(_saving ? 'Saving...' : 'Save Template'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Demo Data Tab - For Testing
// ============================================================================

class _DemoDataTab extends StatefulWidget {
  const _DemoDataTab();

  @override
  State<_DemoDataTab> createState() => _DemoDataTabState();
}

class _DemoDataTabState extends State<_DemoDataTab> {
  bool _seedingLeads = false;
  bool _seedingTemplates = false;
  String _status = '';

  Future<void> _seedDemoLeads() async {
    setState(() {
      _seedingLeads = true;
      _status = 'Creating 100 demo leads with history...';
    });

    try {
      final seeder = DemoDataSeeder();
      await seeder.seedLeads(count: 100, createdBy: 'demo@test.com');
      if (mounted) {
        setState(() {
          _status = '100 demo leads created successfully!';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('100 demo leads created with history logs!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _status = 'Error: $e';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating leads: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _seedingLeads = false);
      }
    }
  }

  Future<void> _seedEmailTemplates() async {
    setState(() {
      _seedingTemplates = true;
      _status = 'Creating email categories and templates...';
    });

    try {
      final seeder = DemoDataSeeder();
      await seeder.seedEmailTemplates();
      if (mounted) {
        setState(() {
          _status = 'Email templates created successfully!';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email categories and templates created!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _status = 'Error: $e';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating templates: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _seedingTemplates = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Demo Data for Testing',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Generate sample data to test the application features.',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),

          // Demo Leads Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.people, color: Colors.blue),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Demo Leads',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                            Text('Create 100 sample leads with history',
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'This will create 100 demo leads with:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Chip(
                        label: const Text('Random names'),
                        backgroundColor: Colors.blue.shade50,
                      ),
                      Chip(
                        label: const Text('Random stages'),
                        backgroundColor: Colors.blue.shade50,
                      ),
                      Chip(
                        label: const Text('History logs'),
                        backgroundColor: Colors.blue.shade50,
                      ),
                      Chip(
                        label: const Text('Follow-ups'),
                        backgroundColor: Colors.blue.shade50,
                      ),
                      Chip(
                        label: const Text('Meetings'),
                        backgroundColor: Colors.blue.shade50,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _seedingLeads ? null : _seedDemoLeads,
                      icon: _seedingLeads
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.add),
                      label: Text(
                          _seedingLeads ? 'Creating...' : 'Create 100 Demo Leads'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Email Templates Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.email, color: Colors.purple),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Email Templates',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                            Text('Create sample categories & templates',
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'This will create categories and templates for:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Chip(
                        label: const Text('CityFinSol Services'),
                        backgroundColor: Colors.purple.shade50,
                      ),
                      Chip(
                        label: const Text('SaaS Products'),
                        backgroundColor: Colors.purple.shade50,
                      ),
                      Chip(
                        label: const Text('Digital Marketing'),
                        backgroundColor: Colors.purple.shade50,
                      ),
                      Chip(
                        label: const Text('Custom Development'),
                        backgroundColor: Colors.purple.shade50,
                      ),
                      Chip(
                        label: const Text('Education'),
                        backgroundColor: Colors.purple.shade50,
                      ),
                      Chip(
                        label: const Text('General Communication'),
                        backgroundColor: Colors.purple.shade50,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _seedingTemplates ? null : _seedEmailTemplates,
                      icon: _seedingTemplates
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.add),
                      label: Text(_seedingTemplates
                          ? 'Creating...'
                          : 'Create Email Templates'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Status message
          if (_status.isNotEmpty)
            Card(
              color: _status.contains('Error')
                  ? Colors.red.shade50
                  : Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(
                      _status.contains('Error')
                          ? Icons.error_outline
                          : Icons.check_circle_outline,
                      color: _status.contains('Error')
                          ? Colors.red
                          : Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _status,
                        style: TextStyle(
                          color: _status.contains('Error')
                              ? Colors.red.shade700
                              : Colors.green.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 24),
          // Warning
          Card(
            color: Colors.orange.shade50,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Demo data is for testing only. You can delete it from Firebase console if needed.',
                      style: TextStyle(color: Colors.orange.shade700, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
