import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/mission_provider.dart';
import 'mission_icon.dart';
import 'package:vanishingtictactoe/shared/widgets/login_dialog.dart';

class MissionIconButton extends StatefulWidget {
  const MissionIconButton({super.key});

  @override
  State<MissionIconButton> createState() => _MissionIconButtonState();
}

class _MissionIconButtonState extends State<MissionIconButton> {
  @override
  void initState() {
    super.initState();
    // Ensure missions are loaded when widget is created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeMissions();
    });
  }

  void _initializeMissions() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final missionProvider = Provider.of<MissionProvider>(context, listen: false);
    
    if (userProvider.isLoggedIn && userProvider.user != null) {
      // Initialize missions if needed
      missionProvider.initialize(userProvider.user!.id, forceRefresh: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      child: userProvider.isLoggedIn
          ? GestureDetector(
              onTap: () => _navigateToMissionsScreen(context),
              child: const SizedBox(
                width: 48,
                height: 48,
                child: MissionIcon(),
              ),
            )
          : GestureDetector(
              onTap: () => LoginDialog.show(context),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.assignment_outlined,
                    color: Colors.grey[600],
                    size: 24,
                  ),
                ),
              ),
            ),
    );
  }
  
  void _navigateToMissionsScreen(BuildContext context) {
    // Ensure mission provider is initialized before navigating
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final missionProvider = Provider.of<MissionProvider>(context, listen: false);
    
    if (userProvider.user != null) {
      // Initialize missions if needed - force refresh to ensure latest data
      missionProvider.initialize(userProvider.user!.id, forceRefresh: true);
    }
    
    Navigator.pushNamed(context, '/missions');
  }
  
}
