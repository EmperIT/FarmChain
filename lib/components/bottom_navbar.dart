import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemTapped;
  final VoidCallback onAddButtonPressed;

  const CustomBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
    required this.onAddButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: Colors.white,
      shape: const CircularNotchedRectangle(),
      notchMargin: 6.0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: const Icon(Icons.home),
            color: selectedIndex == 0 ? Colors.green : Colors.grey,
            onPressed: () => onItemTapped(0),
            tooltip: 'Home',
          ),
          IconButton(
            icon: const Icon(Icons.chat),
            color: selectedIndex == 1 ? Colors.green : Colors.grey,
            onPressed: () => onItemTapped(1),
            tooltip: 'Chat',
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 10.0), // Điều chỉnh vị trí nút
            child: FloatingActionButton(
              onPressed: onAddButtonPressed,
              backgroundColor: Colors.green,
              elevation: 4.0,
              mini: true, // Làm nút nhỏ hơn để vừa với notch
              child: const Icon(Icons.add, size: 30),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.map),
            color: selectedIndex == 2 ? Colors.green : Colors.grey,
            onPressed: () => onItemTapped(2),
            tooltip: 'Map',
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            color: selectedIndex == 3 ? Colors.green : Colors.grey,
            onPressed: () => onItemTapped(3),
            tooltip: 'Order',
          ),
        ],
      ),
    );
  }
}