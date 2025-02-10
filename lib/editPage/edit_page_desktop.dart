import 'package:flutter/material.dart';
import 'edit_page.dart';

class EditPageDesktop extends EditPage {
  const EditPageDesktop({super.key});

  @override
  EditPageDesktopState createState() => EditPageDesktopState();
}

class EditPageDesktopState extends EditPageState<EditPageDesktop> {
  @override
  Widget buildLayout(
      BuildContext context, Widget formWidget, Widget listWidget) {
    // デスクトップ向けは横並び（Row）で表示
    return Row(
      children: [
        Expanded(child: formWidget),
        const SizedBox(width: 8),
        Expanded(child: listWidget),
      ],
    );
  }
}
