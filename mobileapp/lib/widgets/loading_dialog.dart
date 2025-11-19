import 'package:flutter/material.dart';
import 'package:mobileapp/theme.dart'; // Import theme constants

void showLoadingDialog(BuildContext context, String message) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return Dialog(
        backgroundColor: kPrimaryDark, // Use new dark theme color
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: const BorderSide(color: Colors.white10), // Subtle border
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(kPrimaryGold), // Use gold spinner
              ),
              const SizedBox(width: 20),
              Flexible(
                child: Text(
                  message, 
                  style: const TextStyle(color: Colors.white), // White text
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}