import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/teacher_service.dart';
import '../services/auth_service.dart';

class ConnectTeacherDialog extends StatefulWidget {
  final String token;
  final Function() onSuccess;

  const ConnectTeacherDialog({
    super.key,
    required this.token,
    required this.onSuccess,
  });

  @override
  State<ConnectTeacherDialog> createState() => _ConnectTeacherDialogState();
}

class _ConnectTeacherDialogState extends State<ConnectTeacherDialog> {
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final authService = Provider.of<AuthService>(context, listen: false);
      final error = await TeacherService.enterTeacherCode(
        teacherCode: int.parse(_codeController.text),
        token: widget.token,
        authService: authService,
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (error == null) {
        // Success
        Navigator.of(context).pop();
        widget.onSuccess();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully connected to teacher!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.link,
              size: 60,
              color: Color(0xFF38026B),
            ),
            const SizedBox(height: 16),
            const Text(
              'Connect with Teacher',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1F36),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter the teacher code to connect',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF8F92A1),
              ),
            ),
            const SizedBox(height: 24),
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  hintText: 'Enter teacher code',
                  prefixIcon: const Icon(Icons.code, color: Color(0xFF8F92A1)),
                  filled: true,
                  fillColor: const Color(0xFFF5F6FA),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a teacher code';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF38026B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Connect'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
