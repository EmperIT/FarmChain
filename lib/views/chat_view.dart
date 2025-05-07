import 'package:flutter/material.dart';

class ChatView extends StatefulWidget {
  const ChatView({super.key});

  @override
  _ChatViewState createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _bidPriceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();

  final List<Map<String, dynamic>> _messages = [
    {
      'text': 'Chào Anh/Chị, Đã Lấy Thu Hoạch 1 Tạ Tuyến Trái Đẹp, Ngọt. Khối lượng Đã Gửi Thẩm Khảo: 18.000Kg. Anh/Chị Cần Số Lượng Bao Nhiêu Để Em Báo Giá Tốt Hơn Nhạ Al',
      'time': '10:00 AM',
      'isSender': false,
      'avatar': 'assets/avt.jpg',
    },
    {
      'text': 'Đã Nhận Được Đơn. Đủ 3 Tấn Thị Giá Tốt Nhất Em Đánh Giá Nhé?',
      'time': '10:01 AM',
      'isSender': true,
      'avatar': null,
    },
    {
      'text': 'Chào Em Tôi Chốt A.',
      'time': '10:02 AM',
      'isSender': false,
      'avatar': 'assets/avt.jpg',
    },
    {
      'text': 'Ok, Chốt Giá 17 Ngan. Chiều Em Chở Xe Giao Nhé.',
      'time': '10:03 AM',
      'isSender': true,
      'avatar': null,
    },
  ];

  final List<Map<String, dynamic>> _products = [
    {
      'name': 'Cà chua',
      'price': '60.000 đ/kg',
      'image': 'assets/avt.jpg',
    },
  ];

  void _sendMessage() {
    if (_messageController.text.isNotEmpty) {
      setState(() {
        _messages.add({
          'text': _messageController.text,
          'time': '${DateTime.now().hour}:${DateTime.now().minute} ${DateTime.now().hour >= 12 ? 'PM' : 'AM'}',
          'isSender': true,
          'avatar': null,
        });
        _messageController.clear();
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _bidPriceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Center(
          child: Text(
            'Live Chat',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Phần sản phẩm (đã sửa lại layout để tránh overflow)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border.all(color: Colors.grey[300]!, width: 1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 5),
                  child: Text(
                    'Bạn đang hỏi về mặt hàng này',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hình ảnh sản phẩm
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        _products[0]['image'],
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.error, color: Colors.red);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Thông tin sản phẩm và các trường nhập liệu
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Tên và giá gốc
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Vải thánh Hà',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.black,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      'Chú Sáu',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.red[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                'Giá gốc: ${_products[0]['price']}',
                                style: TextStyle(
                                  color: Colors.green[700],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // Giá thầu và số lượng (chuyển sang ngang)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'Giá thay đổi: ',
                                    style: TextStyle(fontSize: 14, color: Colors.black),
                                  ),
                                  SizedBox(
                                    width: 80,
                                    height: 30, // Giảm chiều rộng ô nhập
                                    child: TextField(
                                      controller: _bidPriceController,
                                      decoration: InputDecoration(
                                        hintText: '50.000',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10), // Bo tròn nhỏ hơn
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // Giảm padding
                                      ),
                                      keyboardType: TextInputType.number,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  const Text('đ', style: TextStyle(fontSize: 14)),
                                ],
                              ),
                              Row(
                                children: [
                                  const Text(
                                    'Sl:  ',
                                    style: TextStyle(fontSize: 14, color: Colors.black),
                                  ),
                                  SizedBox(
                                    width: 50,
                                    height: 30, // Giảm chiều rộng ô nhập
                                    child: TextField(
                                      controller: _quantityController,
                                      decoration: InputDecoration(
                                        hintText: '10',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10), // Bo tròn nhỏ hơn
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // Giảm padding
                                      ),
                                      keyboardType: TextInputType.number,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  const Text('kg', style: TextStyle(fontSize: 14)),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              ),
                              child: const Text(
                                'Áp dụng',
                                style: TextStyle(color: Colors.white, fontSize: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Danh sách tin nhắn
          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: const EdgeInsets.all(10),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[_messages.length - 1 - index];
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: message['isSender']
                      ? MainAxisAlignment.end
                      : MainAxisAlignment.start,
                  children: [
                    if (!message['isSender'])
                      CircleAvatar(
                        backgroundImage: AssetImage(message['avatar']),
                        radius: 20,
                      ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        decoration: BoxDecoration(
                          color: message['isSender']
                              ? Colors.green[100]
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 3,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message['text'],
                              style: TextStyle(
                                color: message['isSender']
                                    ? Colors.black87
                                    : Colors.black,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              message['time'],
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          // Ô nhập tin nhắn
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type message here...',
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.sentiment_satisfied, color: Colors.grey),
                          onPressed: () {},
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}