import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// アラートフォームウィジェット
class AlertForm extends StatefulWidget {
  final String symbol;
  final Function(double? upperLimit, double? lowerLimit) onSubmit;

  const AlertForm({
    super.key,
    required this.symbol,
    required this.onSubmit,
  });

  @override
  State<AlertForm> createState() => _AlertFormState();
}

class _AlertFormState extends State<AlertForm> {
  final _formKey = GlobalKey<FormState>();
  final _upperLimitController = TextEditingController();
  final _lowerLimitController = TextEditingController();

  @override
  void dispose() {
    _upperLimitController.dispose();
    _lowerLimitController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final upperLimit = _upperLimitController.text.isNotEmpty
          ? double.tryParse(_upperLimitController.text)
          : null;
      final lowerLimit = _lowerLimitController.text.isNotEmpty
          ? double.tryParse(_lowerLimitController.text)
          : null;

      if (upperLimit == null && lowerLimit == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('上限価格または下限価格のいずれかを入力してください'),
          ),
        );
        return;
      }

      widget.onSubmit(upperLimit, lowerLimit);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${widget.symbol} のアラート設定',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _upperLimitController,
            decoration: const InputDecoration(
              labelText: '上限価格',
              labelStyle: TextStyle(color: Colors.grey),
              hintText: '例: 50000',
              hintStyle: TextStyle(color: Colors.grey),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
              ),
            ),
            style: const TextStyle(color: Colors.white),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,8}')),
            ],
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                final number = double.tryParse(value);
                if (number == null || number <= 0) {
                  return '正の数値を入力してください';
                }
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _lowerLimitController,
            decoration: const InputDecoration(
              labelText: '下限価格',
              labelStyle: TextStyle(color: Colors.grey),
              hintText: '例: 30000',
              hintStyle: TextStyle(color: Colors.grey),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
              ),
            ),
            style: const TextStyle(color: Colors.white),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,8}')),
            ],
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                final number = double.tryParse(value);
                if (number == null || number <= 0) {
                  return '正の数値を入力してください';
                }
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text(
              'アラートを設定',
              style: TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }
}
