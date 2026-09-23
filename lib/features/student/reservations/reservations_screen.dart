import 'package:flutter/material.dart';

import 'room_holds_tab.dart';
import 'visit_requests_tab.dart';

/// The single "Reservations" bottom-nav tab (Figure E7), holding both
/// entities as sub-tabs rather than merging them -- Room Holds
/// (`RoomRequests`) and Visit Requests (`VisitRequests`) stay separate
/// features/data sources, just sharing one nav destination.
class ReservationsScreen extends StatelessWidget {
  const ReservationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Room Holds'),
              Tab(text: 'Visit Requests'),
            ],
          ),
          const Expanded(
            child: TabBarView(
              children: [
                RoomHoldsTab(),
                VisitRequestsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
