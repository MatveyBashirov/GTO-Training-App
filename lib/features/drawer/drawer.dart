import 'package:flutter/material.dart';

class MainDrawer extends StatelessWidget {
  const MainDrawer(
      {super.key, required this.drawerItems, required this.drawerRoutes});

  final List<String> drawerItems;
  final List<String> drawerRoutes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Drawer(
      backgroundColor: theme.colorScheme.primary,
      shape: RoundedRectangleBorder(),
      child: Column(
        children: [
          SizedBox(
            height: 150.0,
            width: double.infinity,
            child: Image.asset(
              "assets/img/drawer_img.jpg",
              fit: BoxFit.cover,
            ),
          ),
          Expanded(
              child: ListView.builder(
            itemCount: drawerItems.length,
            itemBuilder: (context, index) {
              return Column(
                children: [
                  ListTile(
                    title: Text(
                        style: theme.textTheme.titleMedium, drawerItems[index]),
                    onTap: () {
                      Navigator.pushNamed(
                          context, drawerRoutes[index]); // Переход по маршруту
                    },
                  ),
                  Divider()
                ],
              );
            },
          ))
        ],
      ),
    );
  }
}
