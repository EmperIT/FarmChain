import 'package:flutter/material.dart';
import 'components/bottom_navbar.dart'; // Đảm bảo tên file đúng
import 'views/home_view.dart';
// import 'views/chat_view.dart';
import 'views/map_view.dart';
import 'views/order_view.dart';
import 'views/role_selection_view.dart'; // Nhập file mới

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FarmChain());
}

class FarmChain extends StatelessWidget {
  const FarmChain({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FarmChain',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 2; // Mặc định là Map (chỉ mục 2)

  // Danh sách các màn hình
  static final List<Widget> _widgetOptions = <Widget>[
    const HomeView(),
    const RoleSelectionView(), // Sử dụng file riêng
    MapView(),
    const OrderView(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onAddButtonPressed() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Nút + được nhấn!')),
    );
    // Thêm logic cho nút "+" (ví dụ: thêm marker nếu đang ở MapView)
    if (_selectedIndex == 2) {
      // Logic cho MapView (nếu cần)
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
        onAddButtonPressed: _onAddButtonPressed,
      ),
    );
  }
}