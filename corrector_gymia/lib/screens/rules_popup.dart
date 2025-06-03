import 'package:flutter/material.dart';

class RulesPopup {
  static Future<void> show(
    BuildContext context,
    List<String> rules,
  ) => showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      title: Text('Reglas y Recomendaciones'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: rules.map((r) => Text('• $r')).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Entendido'),
        )
      ],
    ),
  );
}
