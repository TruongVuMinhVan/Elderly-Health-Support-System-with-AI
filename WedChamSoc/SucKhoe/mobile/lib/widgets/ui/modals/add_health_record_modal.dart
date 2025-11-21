import 'package:flutter/material.dart';

class AddHealthRecordModal extends StatefulWidget {
  const AddHealthRecordModal({super.key});

  @override
  State<AddHealthRecordModal> createState() => _AddHealthRecordModalState();
}

class _AddHealthRecordModalState extends State<AddHealthRecordModal> {
  final _formKey = GlobalKey<FormState>();
  final _noteController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Thêm ghi chép sức khỏe",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noteController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: "Ghi chú sức khỏe",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Hủy"),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text("Lưu"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
