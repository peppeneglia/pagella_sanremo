import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:pagella_sanremo/config/theme/app_theme.dart';
import 'package:pagella_sanremo/features/auth/providers/auth_providers.dart';
import 'package:pagella_sanremo/features/voting/presentation/screens/voting_page.dart';
import 'package:pagella_sanremo/features/rankings/presentation/screens/personal_ranking_page.dart';
import 'package:pagella_sanremo/features/rankings/presentation/screens/community_ranking_page.dart';
import 'package:pagella_sanremo/features/groups/presentation/screens/groups_list_page.dart';
import 'package:pagella_sanremo/features/auth/presentation/screens/profile_page.dart';

class MainScaffold extends ConsumerStatefulWidget {
  const MainScaffold({super.key});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  int _currentIndex = 0;

  static const List<({IconData icon, String label})> _navigationItems = [
    (icon: FeatherIcons.star, label: 'I miei voti'),
    (icon: FeatherIcons.barChart2, label: 'La mia classifica'),
    (icon: FeatherIcons.globe, label: 'Community'),
    (icon: FeatherIcons.users, label: 'Gruppi'),
  ];

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = ref.watch(isLoggedInProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'PAGELLA SANREMO',
          style: TextStyle(
            color: AppColors.blueDark,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            fontStyle: FontStyle.italic,
            fontFamily: 'PlusJakartaSans',
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isLoggedIn ? Icons.account_circle : Icons.account_circle_outlined,
              color: AppColors.blueDark,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfilePage()),
              );
            },
          ),
        ],
      ),

      // IndexedStack mantiene tutte le pagine in memoria per preservarne lo stato
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          VotingPage(),
          PersonalRankingPage(),
          CommunityRankingPage(),
          GroupsListPage(),
        ],
      ),

      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          boxShadow: [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 10,
              spreadRadius: 0,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                _navigationItems.length,
                (index) => _buildNavItem(
                  index,
                  _navigationItems[index].icon,
                  _navigationItems[index].label,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentIndex = index),
        behavior: HitTestBehavior.opaque,
        child: Tooltip(
          message: label,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.blueDarkLight : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: AnimatedScale(
              duration: const Duration(milliseconds: 200),
              scale: isSelected ? 1.1 : 1.0,
              child: Icon(
                icon,
                size: 22,
                color: AppColors.blueDark,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
