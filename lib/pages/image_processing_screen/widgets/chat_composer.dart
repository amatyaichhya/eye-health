import 'package:eye_health/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Bottom bar for typing a question, attaching photos, and sending.
class ChatComposer extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool inputEnabled;
  final bool sendEnabled;
  final bool attachEnabled;
  final bool isAttaching;
  final bool isTab;
  final VoidCallback onSend;
  final VoidCallback onAttach;

  const ChatComposer({
    super.key,
    required this.controller,
    required this.hintText,
    required this.inputEnabled,
    required this.sendEnabled,
    required this.attachEnabled,
    required this.isAttaching,
    required this.isTab,
    required this.onSend,
    required this.onAttach,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, isTab ? 8 : 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 12,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        bottom: !isTab,
        child: Padding(
          padding: EdgeInsets.only(bottom: isTab ? 72 : 0),
          child: Row(
            children: [
              _AttachButton(
                enabled: attachEnabled,
                isLoading: isAttaching,
                onPressed: onAttach,
              ),
              const SizedBox(width: 8),
              Expanded(child: _MessageField(
                controller: controller,
                hintText: hintText,
                enabled: inputEnabled,
                onSubmit: onSend,
              )),
              const SizedBox(width: 12),
              _SendButton(enabled: sendEnabled, onPressed: onSend),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool enabled;
  final VoidCallback onSubmit;

  const _MessageField({
    required this.controller,
    required this.hintText,
    required this.enabled,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey.shade500),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ),
        ),
        onSubmitted: (_) => enabled ? onSubmit() : null,
        maxLines: null,
        textCapitalization: TextCapitalization.sentences,
      ),
    );
  }
}

class _AttachButton extends StatelessWidget {
  final bool enabled;
  final bool isLoading;
  final VoidCallback onPressed;

  const _AttachButton({
    required this.enabled,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: enabled ? AppColors.primarySoft : Colors.grey.shade300,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child:
          isLoading
              ? const Padding(
                padding: EdgeInsets.all(10),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              )
              : IconButton(
                onPressed: enabled ? onPressed : null,
                tooltip: 'Upload fundus photos',
                icon: Icon(
                  Icons.add,
                  color: enabled ? AppColors.primaryDark : Colors.grey,
                  size: 22,
                ),
              ),
    );
  }
}

class _SendButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onPressed;

  const _SendButton({required this.enabled, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: enabled ? AppColors.primary : Colors.grey,
        shape: BoxShape.circle,
      ),
      child:
          enabled
              ? IconButton(
                onPressed: onPressed,
                icon: const Icon(Icons.send, color: Colors.white, size: 20),
              )
              : const Padding(
                padding: EdgeInsets.all(12.0),
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
    );
  }
}
