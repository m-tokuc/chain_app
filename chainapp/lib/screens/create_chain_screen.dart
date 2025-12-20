import 'package:flutter/material.dart';
import '../services/chain_service.dart';
import '../services/firebase_auth_service.dart';
import 'invite_code_screen.dart';

class CreateChainScreen extends StatefulWidget {
  const CreateChainScreen({super.key});

  @override
  State<CreateChainScreen> createState() => _CreateChainScreenState();
}

class _CreateChainScreenState extends State<CreateChainScreen> {
  final _chainService = ChainService();
  final _authService = FirebaseAuthService();

  final nameController = TextEditingController();
  final descriptionController = TextEditingController();

  String selectedPeriod = "daily";
  final List<String> selectedDays = [];

  final List<String> weekDays = [
    "Mon",
    "Tue",
    "Wed",
    "Thu",
    "Fri",
    "Sat",
    "Sun",
  ];

  bool isLoading = false;

  void toggleDay(String day) {
    setState(() {
      if (selectedDays.contains(day)) {
        selectedDays.remove(day);
      } else {
        selectedDays.add(day);
      }
    });
  }

  Future<void> createChain() async {
    final userId = _authService.currentUserId();
    if (userId == null) return;

    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Chain name is required")),
      );
      return;
    }

    if (selectedPeriod == "weekly" && selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select at least one day")),
      );
      return;
    }

    setState(() => isLoading = true);

    final inviteCode = await _chainService.createChain(
      name: nameController.text.trim(),
      description: descriptionController.text.trim(),
      period: selectedPeriod,
      members: [userId],
      days: selectedPeriod == "weekly" ? selectedDays : [],
    );

    setState(() => isLoading = false);

    if (inviteCode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to create chain")),
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => InviteCodeScreen(inviteCode: inviteCode),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Chain"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Chain Name"),
            const SizedBox(height: 6),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "e.g. Read every day",
              ),
            ),
            const SizedBox(height: 16),
            const Text("Description"),
            const SizedBox(height: 6),
            TextField(
              controller: descriptionController,
              maxLines: 2,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Optional description",
              ),
            ),
            const SizedBox(height: 20),
            const Text("Period"),
            RadioListTile(
              title: const Text("Daily"),
              value: "daily",
              groupValue: selectedPeriod,
              onChanged: (v) {
                setState(() {
                  selectedPeriod = v!;
                  selectedDays.clear();
                });
              },
            ),
            RadioListTile(
              title: const Text("Weekly"),
              value: "weekly",
              groupValue: selectedPeriod,
              onChanged: (v) {
                setState(() => selectedPeriod = v!);
              },
            ),
            if (selectedPeriod == "weekly") ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: weekDays.map((day) {
                  final isSelected = selectedDays.contains(day);
                  return ChoiceChip(
                    label: Text(day),
                    selected: isSelected,
                    onSelected: (_) => toggleDay(day),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isLoading ? null : createChain,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Create Chain",
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
