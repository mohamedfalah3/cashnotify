import 'package:cashnotify/screens/adding_screen.dart';
import 'package:cashnotify/screens/chart_screen.dart';
import 'package:cashnotify/screens/payment_table.dart';
import 'package:flutter/material.dart';
import 'package:sidebarx/sidebarx.dart';

import 'notification_screen.dart';

class SidebarXExampleApp extends StatelessWidget {
  SidebarXExampleApp({super.key});

  final _controller = SidebarXController(selectedIndex: 0, extended: false);
  final _key = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SidebarX Example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color.fromARGB(255, 0, 122, 255),
        canvasColor: Colors.white,
        scaffoldBackgroundColor: Colors.white,
        textTheme: const TextTheme(
          headlineSmall: TextStyle(
            color: Colors.white,
            fontSize: 46,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      home: Builder(
        builder: (context) {
          final isSmallScreen = MediaQuery.of(context).size.width < 600;
          return Scaffold(
            key: _key,
            drawer: ExampleSidebarX(controller: _controller),
            body: Row(
              children: [
                if (!isSmallScreen) ExampleSidebarX(controller: _controller),
                Expanded(
                  child: Center(
                    child: _ScreensExample(
                      controller: _controller,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class ExampleSidebarX extends StatelessWidget {
  const ExampleSidebarX({
    super.key,
    required SidebarXController controller,
  }) : _controller = controller;

  final SidebarXController _controller;

  @override
  Widget build(BuildContext context) {
    return SidebarX(
      controller: _controller,
      theme: SidebarXTheme(
        margin: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 0, 122, 255),
          borderRadius: BorderRadius.circular(20),
        ),
        hoverColor: const Color.fromARGB(255, 0, 122, 255),
        textStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
        selectedTextStyle: const TextStyle(color: Colors.white),
        hoverTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
        itemTextPadding: const EdgeInsets.only(left: 30),
        selectedItemTextPadding: const EdgeInsets.only(left: 30),
        itemDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Color.fromARGB(255, 0, 122, 255)),
        ),
        selectedItemDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.deepPurple.withOpacity(0.37),
          ),
          gradient: const LinearGradient(
            colors: [
              Color.fromARGB(255, 0, 122, 255),
              Color.fromARGB(255, 0, 122, 255)
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.28),
              blurRadius: 30,
            )
          ],
        ),
        iconTheme: IconThemeData(
          color: Colors.white.withOpacity(0.7),
          size: 20,
        ),
        selectedIconTheme: const IconThemeData(
          color: Colors.white,
          size: 20,
        ),
      ),
      extendedTheme: const SidebarXTheme(
        width: 200,
        decoration: BoxDecoration(
          color: Color.fromARGB(255, 0, 122, 255),
        ),
      ),
      footerDivider: divider,
      items: [
        SidebarXItem(
          icon: Icons.home,
          label: 'Home',
          onTap: () {
            // navigationProvider.updateIndex(0);
          },
        ),
        SidebarXItem(
            icon: Icons.add,
            label: 'Add',
            onTap: () {
              // navigationProvider.updateIndex(1);
            }),
        SidebarXItem(
            icon: Icons.bar_chart,
            label: 'Chart',
            onTap: () {
              // navigationProvider.updateIndex(1);
            }),
        SidebarXItem(
            icon: Icons.notifications,
            label: 'Notify',
            onTap: () {
              // navigationProvider.updateIndex(2);
            }),
      ],
    );
  }
}

class _ScreensExample extends StatelessWidget {
  const _ScreensExample({
    required this.controller,
  });

  final SidebarXController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final pageTitle = _getTitleByIndex(controller.selectedIndex);
        switch (controller.selectedIndex) {
          case 0:
            return const PaymentTable();
          case 1:
            return const AddCustomerScreen();
          case 2:
            return CollectedVsExpectedScreen();
          case 3:
            return const UnpaidRemindersScreen();
          default:
            return Text(
              pageTitle,
              style: theme.textTheme.headlineSmall,
            );
        }
      },
    );
  }
}

String _getTitleByIndex(int index) {
  switch (index) {
    case 0:
      return 'Home';
    case 1:
      return 'Add rows';
    case 2:
      return 'Chart';
    case 3:
      return 'Notifications';
    default:
      return 'Not found page';
  }
}

final divider = Divider(color: Colors.white.withOpacity(0.3), height: 1);
