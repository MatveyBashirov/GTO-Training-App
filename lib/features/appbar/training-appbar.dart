  import 'package:flutter/material.dart';

  class TrainingAppBar extends StatelessWidget implements PreferredSizeWidget {
    const TrainingAppBar({
      super.key,
      required this.title,
    });

    final String title;

    @override
    Size get preferredSize => const Size.fromHeight(56.0);

    @override
    Widget build(BuildContext context) {
      final theme = Theme.of(context);
      return AppBar(
        iconTheme: theme.iconTheme,
        backgroundColor: theme.colorScheme.primary,
        title: Text(
        title,
        style: theme.textTheme.titleLarge!.copyWith(
          color: Colors.white,
        ),
        // Добавляем автоматическое уменьшение текста
        overflow: TextOverflow.ellipsis,
        softWrap: false,
      ),
      centerTitle: true,
      );
    }
  }