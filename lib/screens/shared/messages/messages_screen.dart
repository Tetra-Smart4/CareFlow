import 'package:flutter/material.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});
  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final c = TextEditingController();
  final messages = [
    'Hello Rahul, your reports are available.',
    'Thank you doctor. I will check them.',
  ];
  void send() {
    if (c.text.trim().isEmpty) return;
    setState(() {
      messages.add(c.text.trim());
      c.clear();
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Messages')),
    body: Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: messages.length,
            itemBuilder: (c, i) => Align(
              alignment: i.isEven
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(messages[i]),
                ),
              ),
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: c,
                    decoration: const InputDecoration(
                      hintText: 'Type a message',
                    ),
                  ),
                ),
                IconButton(onPressed: send, icon: const Icon(Icons.send)),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
