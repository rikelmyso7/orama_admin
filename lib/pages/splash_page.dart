import 'dart:async';
import 'package:flutter/material.dart';
import 'package:orama_admin/pages/admin_page.dart';
import 'package:orama_admin/utils/checkuptades.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  //final CheckUpdates checkUpdates = CheckUpdates();
  //final FlutterAppInstaller flutterAppInstaller = FlutterAppInstaller();
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _controller.forward();

    _startUpdateCheck();
  }

  Future<void> _startUpdateCheck() async {
    //bool shouldNavigate = await checkUpdates.checkForUpdate(context);
    //if (shouldNavigate) {
    Timer(Duration(seconds: 5), _navigateToHome);
    
  }

  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => AdminPage()),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
          child: FadeTransition(
              opacity: _animation,
              child: Container(
                  height: double.infinity,
                  width: double.infinity,
                  color: Color(0xff006764),
                child: Center(
                  child: Image.asset(
                    'lib/images/splash_page.png',
                  ),
                ),
              ))),
    );
  }
}
