import 'package:flutter/material.dart';
import '../core/storage/hive_storage.dart';
import '../services/auth_service.dart';

class MessMenuView extends StatefulWidget {
  const MessMenuView({Key? key}) : super(key: key);

  @override
  State<MessMenuView> createState() => _MessMenuViewState();
}

class _MessMenuViewState extends State<MessMenuView> with TickerProviderStateMixin {
  int _selectedDay = DateTime.now().weekday % 7; // 0=Sun, 1=Mon, etc.
  late PageController _pageController;
  late AnimationController _rotationController;
  
  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedDay);
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    _rotationController.dispose();
    super.dispose();
  }
  
  final List<String> _days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  
  final Map<String, Map<String, Map<String, dynamic>>> _weeklyMenu = {
    'Sun': {
      'Breakfast': {
        'time': '7:00 - 9:00 AM',
        'items': ['Masala Dosa, Sambar, Chutney', 'Bread, Butter, Jam, Tea']
      },
      'Lunch': {
        'time': '12:00 - 2:00 PM', 
        'items': ['Rice, Roti, Dal, Mixed Boiled Veg', 'Egg Curry, Mix Veg Masala', 'Salad, Fries']
      },
      'Snacks': {
        'time': '4:00 - 6:00 PM',
        'items': ['Dahi Papdi Chaat, Coffee']
      },
      'Dinner': {
        'time': '7:00 - 9:00 PM',
        'items': ['Rice, Roti, Dal, Mixed Boiled Veg', 'Chicken Kadai, Paneer Kadai', 'Rice Kheer']
      },
    },
    'Mon': {
      'Breakfast': {
        'time': '7:00 - 9:00 AM',
        'items': ['Puri Ghuguni, Corn Flakes, Milk, Banana, Tea']
      },
      'Lunch': {
        'time': '12:00 - 2:00 PM', 
        'items': ['Rice, Roti, Dal, Mixed Boiled Veg', 'Vegetable Korma, French Fries', 'Pampad (Sriram), Curd']
      },
      'Snacks': {
        'time': '4:00 - 6:00 PM',
        'items': ['Sweet Corn / Rusk, Tea']
      },
      'Dinner': {
        'time': '7:00 - 9:00 PM',
        'items': ['Rice, Roti, Dal, Mixed Boiled Veg', 'Gobi Aloo Mutter Masala, Seasonal Bhaji', 'Gulab Jamun']
      },
    },
    'Tue': {
      'Breakfast': {
        'time': '7:00 - 9:00 AM',
        'items': ['Pav Bhaji / Chole Bhature', 'Bread, Butter, Jam', 'Boiled Egg, Coffee']
      },
      'Lunch': {
        'time': '12:00 - 2:00 PM', 
        'items': ['Rice, Roti, Dal, Mixed Boiled Veg', 'Matar Paneer, French Fries, Salad']
      },
      'Snacks': {
        'time': '4:00 - 6:00 PM',
        'items': ['Red Pasta (with Onion & Tomato)', 'Lemon Tea']
      },
      'Dinner': {
        'time': '7:00 - 9:00 PM',
        'items': ['Rice, Roti, Dal, Mixed Boiled Veg', 'Soyabin Aloo Masala, Crispy Veg Chips', 'Semai Kheer']
      },
    },
    'Wed': {
      'Breakfast': {
        'time': '7:00 - 9:00 AM',
        'items': ['Egg Omelette, Veg Cutlet', 'Bread, Butter, Jam, Tea']
      },
      'Lunch': {
        'time': '12:00 - 2:00 PM', 
        'items': ['Rice, Roti, Dal, Mixed Boiled Veg', 'Cabbage Aloo Masala, Fish Masala', 'Fries, Salad']
      },
      'Snacks': {
        'time': '4:00 - 6:00 PM',
        'items': ['Veg Hakka Noodles, Coffee']
      },
      'Dinner': {
        'time': '7:00 - 9:00 PM',
        'items': ['Rice, Roti, Dal, Mixed Boiled Veg', 'Chicken Masala, Paneer Masala', 'Rasgulla']
      },
    },
    'Thu': {
      'Breakfast': {
        'time': '7:00 - 9:00 AM',
        'items': ['Dahi Bada, Aloo Dum, Ghuguni', 'Bread, Butter, Jam, Tea']
      },
      'Lunch': {
        'time': '12:00 - 2:00 PM', 
        'items': ['Rice, Roti, Dal, Mixed Boiled Veg', 'Muncherian, Aloo Capsicum Dry', 'Papad (Sriram), Curd']
      },
      'Snacks': {
        'time': '4:00 - 6:00 PM',
        'items': ['Masala Maggi, Coffee']
      },
      'Dinner': {
        'time': '7:00 - 9:00 PM',
        'items': ['Rice, Roti, Dal, Mixed Boiled Veg', 'Paneer Hyderabadi, Egg Curry (Dry)', 'Gulab Jamun']
      },
    },
    'Fri': {
      'Breakfast': {
        'time': '7:00 - 9:00 AM',
        'items': ['Bread, Butter, Jam', 'Boiled Egg, Veg Noodles, Ketchup, Tea']
      },
      'Lunch': {
        'time': '12:00 - 2:00 PM', 
        'items': ['Rice, Roti, Dal, Mixed Boiled Veg', 'Fish Masala, Besan Aloo Curry', 'Seasonal Bhaji, Nalli (Fries)']
      },
      'Snacks': {
        'time': '4:00 - 6:00 PM',
        'items': ['Chicken Soup / Veg Soup']
      },
      'Dinner': {
        'time': '7:00 - 9:00 PM',
        'items': ['Mix Veg Biryani / Chicken Biryani', 'Raita']
      },
    },
    'Sat': {
      'Breakfast': {
        'time': '7:00 - 9:00 AM',
        'items': ['Paratha, Aloo Bhaja', 'Corn Flakes, Milk, Banana, Tea']
      },
      'Lunch': {
        'time': '12:00 - 2:00 PM', 
        'items': ['Rice, Roti, Dal, Mixed Boiled Veg', 'Egg Masala, Chana Masala', 'Seasonal Bhaji, Papad (Sriram)']
      },
      'Snacks': {
        'time': '4:00 - 6:00 PM',
        'items': ['Good Day Biscuit, Tea']
      },
      'Dinner': {
        'time': '7:00 - 9:00 PM',
        'items': ['Rice, Roti, Dal, Mixed Boiled Veg', 'Chicken Butter Masala, Paneer Butter Masala', 'Rasgulla']
      },
    },
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF000000), Color(0xFF1A1A1A), Color(0xFF2D2D2D)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              _buildDaySelector(),
              Expanded(child: _buildMealCards()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Mess Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Weekly Meal Schedule',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
              ),
            ],
          ),
          Icon(
            Icons.restaurant_menu,
            color: Colors.grey[400],
            size: 28,
          ),
        ],
      ),
    );
  }

  Widget _buildDaySelector() {
    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(_days.length, (index) {
          final isSelected = index == _selectedDay;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedDay = index);
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
              _rotationController.forward().then((_) => _rotationController.reset());
            },
            child: AnimatedBuilder(
              animation: _rotationController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _rotationController.value * 2 * 3.14159,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF4CAF50) : Colors.transparent,
                      border: Border.all(
                        color: const Color(0xFF4CAF50),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _days[index],
                      style: TextStyle(
                        color: isSelected ? Colors.black : const Color(0xFF4CAF50),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        }),
      ),
    );
  }

  Widget _buildMealCards() {
    return PageView.builder(
      itemCount: _days.length,
      controller: _pageController,
      onPageChanged: (index) => setState(() => _selectedDay = index),
      itemBuilder: (context, index) {
        final day = _days[index];
        final dayMenu = _weeklyMenu[day]!;
        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: dayMenu.entries.map((entry) => _buildMealCard(
            entry.key,
            entry.value['time'],
            entry.value['items'],
          )).toList(),
        );
      },
    );
  }

  Widget _buildMealCard(String title, String time, List<String> items) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        border: Border.all(
          color: const Color(0xFF4CAF50).withOpacity(0.4),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                time,
                style: const TextStyle(
                  color: Color(0xFF4CAF50),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 4,
                    height: 4,
                    margin: const EdgeInsets.only(top: 8, right: 12),
                    decoration: const BoxDecoration(
                      color: Color(0xFF4CAF50),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        color: Color(0xFFE0E0E0),
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }
}