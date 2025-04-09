import 'package:flutter/material.dart';

class MyDrawer extends StatelessWidget {
  final String title;
  final List<DrawerMenuItem> menuItems;

  const MyDrawer({
    required this.title,
    required this.menuItems,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width / 1.4,
      child: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Cabeçalho do Drawer
            Container(
              padding: EdgeInsets.only(top: 20),
              width: double.infinity,
              height: 100,
              decoration: const BoxDecoration(
                color: Color(0xff60C03D),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    color: Colors.white,
                    iconSize: 26,
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 26,
                    ),
                  ),
                ],
              ),
            ),
            // Itens do Menu
            ...menuItems.map((item) => Column(
                  children: [
                    ListTile(
                      title: Align(
                        alignment: Alignment.bottomLeft,
                        child: Row(
                          children: [
                            Text(
                              item.label,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Icon(item.icon),
                          ],
                        ),
                      ),
                      onTap: item.onTap,
                    ),
                    const Divider(),
                  ],
                )),
          ],
        ),
      ),
    );
  }
}

class DrawerMenuItem {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  DrawerMenuItem({
    required this.label,
    required this.icon,
    required this.onTap,
  });
}
