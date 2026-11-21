import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_colors.dart';

class ReportBugScreen extends StatefulWidget {
  const ReportBugScreen({super.key});

  @override
  State<ReportBugScreen> createState() => _ReportBugScreenState();
}

class _ReportBugScreenState extends State<ReportBugScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _stepsController = TextEditingController();
  final _deviceController = TextEditingController();

  @override
  void dispose() {
    _descriptionController.dispose();
    _stepsController.dispose();
    _deviceController.dispose();
    super.dispose();
  }

  // Send bug report via email
  Future<void> _sendEmail() async {
    if (!_formKey.currentState!.validate()) return;

    final subject = Uri.encodeComponent('Bug Report - The Vent App');
    final body = Uri.encodeComponent(
      'BUG DESCRIPTION:\n'
      '${_descriptionController.text}\n\n'
      'STEPS TO REPRODUCE:\n'
      '${_stepsController.text}\n\n'
      'DEVICE INFO:\n'
      '${_deviceController.text}\n\n'
      '---\n'
      'Sent from The Vent App',
    );

    final Uri emailUri = Uri.parse(
      'mailto:capsprout2001@proton.me?subject=$subject&body=$body',
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      if (mounted) {
        _showMessage('No email app found on your device.');
      }
    }
  }

  // Open GitHub Issues
  Future<void> _openGitHub() async {
    final Uri githubUri = Uri.parse(
      'https://github.com/mclovin22117/theventapp/issues/new',
    );

    if (await canLaunchUrl(githubUri)) {
      await launchUrl(githubUri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        _showMessage('Could not open GitHub. Please try again.');
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.surfaceHigh,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios,
            color: AppColors.textPrimary,
          ),
        ),
        title: const Text(
          'Report a Bug',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),

              // Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceRaised,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.accent.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.bug_report_outlined,
                        color: AppColors.accent,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Found a bug?',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Help us improve The Vent by reporting it via email or GitHub.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Bug Description
              _buildLabel(
                icon: Icons.description_outlined,
                label: 'Bug Description',
                required: true,
              ),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _descriptionController,
                hint: 'Describe the bug clearly...\ne.g. "The like button does not work when tapped"',
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please describe the bug';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Steps to Reproduce
              _buildLabel(
                icon: Icons.format_list_numbered_outlined,
                label: 'Steps to Reproduce',
                required: true,
              ),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _stepsController,
                hint: 'List the steps to reproduce the bug...\ne.g.\n1. Open the app\n2. Tap on a post\n3. Tap the like button\n4. Nothing happens',
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please provide steps to reproduce';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Device Info
              _buildLabel(
                icon: Icons.phone_android_outlined,
                label: 'Device Info',
                required: true,
              ),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _deviceController,
                hint: 'Your device details...\ne.g.\nDevice: Samsung Galaxy S21\nOS: Android 13\nApp Version: 1.0.0',
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please provide your device info';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Submit Buttons
              const Text(
                'Submit via',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),

              // Email Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _sendEmail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.onAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.mail_outline),
                  label: const Text(
                    'Send via Email',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // GitHub Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _openGitHub,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.surfaceRaised,
                    foregroundColor: AppColors.textPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(
                        color: AppColors.border,
                        width: 1,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.code),
                  label: const Text(
                    'Open GitHub Issues',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    ),
  ),
);
  }

  Widget _buildLabel({
    required IconData icon,
    required String label,
    bool required = false,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppColors.accent,
          size: 18,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (required)
          const Text(
            ' *',
            style: TextStyle(
              color: AppColors.danger,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required int maxLines,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: AppColors.textDisabled,
          fontSize: 13,
          height: 1.5,
        ),
        filled: true,
        fillColor: AppColors.surfaceRaised,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.border,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.border,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.accent,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.danger,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.danger,
            width: 1.5,
          ),
        ),
        errorStyle: const TextStyle(
          color: AppColors.danger,
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }
}