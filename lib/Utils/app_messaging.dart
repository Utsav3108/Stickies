import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';
import '../Theme/app_colors.dart';

class AppMessaging {
  static void showToast(String msg, {Color? color}) {
    Fluttertoast.showToast(
      msg: msg,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: color ?? AppColors.textHint,
      textColor: Colors.white,
      fontSize: 14.0,
    );
  }
}
