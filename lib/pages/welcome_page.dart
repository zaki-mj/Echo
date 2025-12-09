import 'dart:math';

import 'package:flutter/material.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  TextEditingController texto = TextEditingController();
  String lookatme = "";
  int iqtest = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Welcome to the ultimate IQ test', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            Text('Type your name here', style: TextStyle(fontSize: 16)),
            TextFormField(
              decoration: InputDecoration(labelText: 'Enter your name', border: OutlineInputBorder()),
              controller: texto,
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  lookatme = texto.text;
                  if (lookatme == "yacine" || lookatme == "sara" || lookatme == "sarra" || lookatme == "fatna") {
                    iqtest = 3;
                  } else {
                    iqtest = Random().nextInt(150);
                  }

                  print("$lookatme's IQ is $iqtest");
                });
              },
              child: Text('click me'),
            ),
            Text(lookatme + "'s IQ test is loading..." + iqtest.toString(), style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
