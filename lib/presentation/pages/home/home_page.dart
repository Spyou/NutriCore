import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/home_controller.dart';
import '../../widgets/home/ai_insight_card.dart';
import '../../widgets/home/complete_profile_banner.dart';
import '../../widgets/home/home_header.dart';
import '../../widgets/home/today_meals_list.dart';
import '../../widgets/home/today_progress_ring.dart';
import '../../widgets/home/water_pill.dart';

class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: controller.refreshData,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const HomeHeader(),
                    const SizedBox(height: 24),
                    const CompleteProfileBanner(),
                    const TodayProgressRing(),
                    const SizedBox(height: 16),
                    const AiInsightCard(),
                    const SizedBox(height: 16),
                    const WaterPill(),
                    const SizedBox(height: 24),
                    const TodayMealsList(),
                    const SizedBox(height: 32),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
