import 'package:flutter/material.dart';
import 'edit_page.dart';

class EditPageMobile extends EditPage {
  const EditPageMobile({super.key});

  @override
  EditPageMobileState createState() => EditPageMobileState();
}

class EditPageMobileState extends EditPageState<EditPageMobile> {
  @override
  Widget buildLayout(BuildContext context, Widget formWidget, Widget listWidget) {
    // モバイル向けは縦並び（Column）で表示
    return Column(
      children: [
        formWidget,
        const SizedBox(height: 16),
        listWidget,
      ],
    );
  }
}
