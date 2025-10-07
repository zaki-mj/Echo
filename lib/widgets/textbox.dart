import 'package:flutter/material.dart';

class MyTextForm extends StatefulWidget {
  const MyTextForm({super.key});

  @override
  State<MyTextForm> createState() => _MyTextFormState();
}

class _MyTextFormState extends State<MyTextForm> {
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      decoration: InputDecoration(
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            ),
      ),
    );
  }
}
