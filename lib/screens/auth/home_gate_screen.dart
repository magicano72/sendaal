import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/router/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_session_service.dart';
import '../main_shell.dart';

class HomeGateScreen extends ConsumerStatefulWidget {
  const HomeGateScreen({super.key});

  @override
  ConsumerState<HomeGateScreen> createState() => _HomeGateScreenState();
}

class _HomeGateScreenState extends ConsumerState<HomeGateScreen> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _guardAccess();
  }

  Future<void> _guardAccess() async {
    if (ref.read(authProvider).user != null) {
      if (!mounted) {
        return;
      }
      setState(() => _ready = true);
      return;
    }

    final route = await AuthSessionService.instance.getInitialRoute();
    if (!mounted) {
      return;
    }

    Navigator.pushNamedAndRemoveUntil(context, route, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return const MainShell();
  }
}
