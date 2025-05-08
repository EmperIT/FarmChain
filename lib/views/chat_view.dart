import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class ChatMessage {
  final String type;
  final String senderRole;
  final String content;
  final String time;
  final bool isMine;

  ChatMessage({
    required this.type,
    required this.senderRole,
    required this.content,
    required this.time,
    required this.isMine,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json, String myRole) {
    return ChatMessage(
      type: json['type'] ?? 'chat',
      senderRole: json['senderRole'] ?? '',
      content: json['content'] ?? '',
      time: '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')} ${DateTime.now().hour >= 12 ? 'PM' : 'AM'}',
      isMine: json['senderRole'] == myRole,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'senderRole': senderRole,
      'content': content,
    };
  }
}

class ChatView extends StatefulWidget {
  final String role; // Buyer or seller
  const ChatView({super.key, required this.role});

  @override
  _ChatViewState createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _bidPriceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  WebSocketChannel? _channel;
  bool _isConnected = false;
  bool _roleInitialized = false;
  
  final List<ChatMessage> _messages = [
    // Initialize with example messages for better user experience
    ChatMessage(
      type: 'chat',
      senderRole: 'seller',
      content: 'Chào Anh/Chị, Đã Lấy Thu Hoạch 1 Tạ Tuyến Trái Đẹp, Ngọt. Khối lượng Đã Gửi Thẩm Khảo: 18.000Kg. Anh/Chị Cần Số Lượng Bao Nhiêu Để Em Báo Giá Tốt Hơn Nhạ',
      time: '10:00 AM',
      isMine: false,
    ),
    ChatMessage(
      type: 'chat',
      senderRole: 'buyer',
      content: 'Đã Nhận Được Đơn. Đủ 3 Tấn Thị Giá Tốt Nhất Em Đánh Giá Nhé?',
      time: '10:01 AM',
      isMine: false,
    ),
  ];
  
  final Map<String, dynamic> _product = {
    'name': 'Vải thánh Hà',
    'seller': 'Chú Sáu',
    'price': '60.000',
    'image': 'assets/avt.jpg',
  };

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
  }

  void _connectWebSocket() {
    try {
      // Update the WebSocket connection URL based on your deployment environment
      final wsUrl = 'ws://fa3a-113-185-94-241.ngrok-free.app/ws/chat';
      
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      
      // Listen for incoming messages
      _channel?.stream.listen(
        (message) {
          try {
            final data = jsonDecode(message);
            _handleIncomingMessage(data);
          } catch (e) {
            print('❌ Error parsing message: $e');
          }
        },
        onDone: () {
          setState(() {
            _isConnected = false;
            _roleInitialized = false;
          });
          _showDisconnectMessage();
        },
        onError: (error) {
          print('❌ WebSocket error: $error');
          setState(() {
            _isConnected = false;
            _roleInitialized = false;
          });
          _showDisconnectMessage();
        },
      );
      
      setState(() {
        _isConnected = true;
      });
      
      // Send role message once connected
      Future.delayed(const Duration(milliseconds: 500), () {
        _sendRoleMessage();
      });
    } catch (e) {
      print('❌ Failed to connect to WebSocket: $e');
      _showErrorMessage('Không thể kết nối đến máy chủ');
    }
  }

  void _sendRoleMessage() {
    if (_isConnected && _channel != null) {
      final message = {
        'type': 'role',
        'role': widget.role,
      };
      _channel?.sink.add(jsonEncode(message));
      print('📤 Sent role message: ${widget.role}');
      
      setState(() {
        _roleInitialized = true;
      });
      
      _showSuccessMessage('Đã kết nối thành công với vai trò: ${widget.role == 'buyer' ? 'Người mua' : 'Người bán'}');
    } else {
      print('❌ Cannot send role message: not connected');
      Future.delayed(const Duration(seconds: 2), _connectWebSocket);
    }
  }

  void _sendMessage() {
    if (_messageController.text.isNotEmpty) {
      if (_isConnected && _channel != null) {
        if (!_roleInitialized) {
          _sendRoleMessage();
          Future.delayed(const Duration(milliseconds: 500), () {
            _sendMessageContent();
          });
        } else {
          _sendMessageContent();
        }
      } else {
        _showErrorMessage('Mất kết nối, đang thử kết nối lại...');
        _connectWebSocket();
      }
    }
  }
  
  void _sendMessageContent() {
    // Check if the message is a number/price
    final String content = _messageController.text;
    bool isNumeric = double.tryParse(content.replaceAll(',', '.')) != null;
    
    final message = {
      'type': 'message',
      'role': widget.role,
      'content': content,
    };
    _channel?.sink.add(jsonEncode(message));
    print('📤 Sent message: $content');
    
    // Add message to local list for immediate display
    setState(() {
      _messages.add(
        ChatMessage(
          type: 'chat',
          senderRole: widget.role,
          content: isNumeric ? '$content đ/kg' : content,
          time: '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')} ${DateTime.now().hour >= 12 ? 'PM' : 'AM'}',
          isMine: true,
        ),
      );
    });
    
    _messageController.clear();
  }

  void _sendPriceMessage() {
    if (_bidPriceController.text.isNotEmpty) {
      if (_isConnected && _channel != null) {
        if (!_roleInitialized) {
          _sendRoleMessage();
          Future.delayed(const Duration(milliseconds: 500), () {
            _sendPriceContent();
          });
        } else {
          _sendPriceContent();
        }
      } else {
        _showErrorMessage('Mất kết nối, đang thử kết nối lại...');
        _connectWebSocket();
      }
    } else {
      _showErrorMessage('Vui lòng nhập giá');
    }
  }
  
  void _sendPriceContent() {
    final message = {
      'type': 'message',
      'role': widget.role,
      'content': _bidPriceController.text,
    };
    _channel?.sink.add(jsonEncode(message));
    print('📤 Sent price: ${_bidPriceController.text}');
    
    // Add message to local list for immediate display
    setState(() {
      _messages.add(
        ChatMessage(
          type: 'chat',
          senderRole: widget.role,
          content: '${_bidPriceController.text} đ/kg',
          time: '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')} ${DateTime.now().hour >= 12 ? 'PM' : 'AM'}',
          isMine: true,
        ),
      );
    });
    
    _showSuccessMessage('Đã gửi giá thành công');
    
    // Clear price field after sending
    _bidPriceController.clear();
  }

  void _handleIncomingMessage(Map<String, dynamic> data) {
    print('📥 Received message: $data');
    
    if (data['type'] == 'chat') {
      // Check if the content is a number/price
      final String content = data['content'] ?? '';
      bool isNumeric = double.tryParse(content.replaceAll(',', '.')) != null;
      
      // If it's a number and not from current user, format as price
      if (isNumeric && data['senderRole'] != widget.role) {
        setState(() {
          _messages.add(
            ChatMessage(
              type: 'chat',
              senderRole: data['senderRole'] ?? '',
              content: '$content đ/kg',
              time: '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')} ${DateTime.now().hour >= 12 ? 'PM' : 'AM'}',
              isMine: false,
            ),
          );
        });
      } else {
        setState(() {
          _messages.add(
            ChatMessage.fromJson(data, widget.role),
          );
        });
      }
    } else if (data['type'] == 'ai_response') {
      _handleAIResponse(data);
    } else if (data['error'] != null) {
      _showErrorMessage(data['error']);
    }
  }

  void _handleAIResponse(Map<String, dynamic> data) {
    setState(() {
      _messages.add(
        ChatMessage(
          type: 'ai_response',
          senderRole: 'ai',
          content: 'Giá hợp lý: ${data['fair_price']} đ/kg\n${data['suggestion']}',
          time: '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')} ${DateTime.now().hour >= 12 ? 'PM' : 'AM'}',
          isMine: false,
        ),
      );
    });
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showDisconnectMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã mất kết nối với máy chủ, đang thử kết nối lại...'),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 5),
      ),
    );
    // Try to reconnect
    Future.delayed(const Duration(seconds: 3), _connectWebSocket);
  }

  void _handleSubmitOffer() {
    if (_bidPriceController.text.isNotEmpty) {
      _sendPriceMessage();
    } else {
      _showErrorMessage('Vui lòng nhập giá');
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _bidPriceController.dispose();
    _quantityController.dispose();
    _channel?.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Center(
          child: Text(
            'Live Chat - ${widget.role == 'buyer' ? 'Người mua' : 'Người bán'}',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isConnected ? (_roleInitialized ? Colors.green : Colors.yellow) : Colors.red,
            ),
          )
        ],
      ),
      body: Column(
        children: [
          // Product section
          _buildProductCard(),
          
          // Connection status banner
          if (!_roleInitialized && _isConnected)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: Colors.yellow[100],
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Đang khởi tạo vai trò ${widget.role == 'buyer' ? 'người mua' : 'người bán'}...',
                      style: TextStyle(color: Colors.orange[800]),
                    ),
                  ),
                ],
              ),
            ),
          
          // Messages list
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Text(
                      'Chưa có tin nhắn nào.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return _buildMessageBubble(message);
                    },
                  ),
          ),
          
          // Message input
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildProductCard() {
    return Container(
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
              // Product image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  _product['image'],
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image_not_supported, color: Colors.grey),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              // Product info and input fields
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name and original price
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _product['name'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.black,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 5),
                              Text(
                                _product['seller'],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.red[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'Giá gốc: ${_product['price']} đ/kg',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Price and quantity section based on role
                    widget.role == 'seller' 
                        ? _buildSellerPriceControls()
                        : _buildBuyerPriceView(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSellerPriceControls() {
    return Column(
      children: [
        Row(
          children: [
            const Text(
              'Giá thay đổi: ',
              style: TextStyle(fontSize: 14, color: Colors.black),
            ),
            SizedBox(
              width: 80,
              height: 30,
              child: TextField(
                controller: _bidPriceController,
                decoration: InputDecoration(
                  hintText: '50.000',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 5),
            const Text('đ/kg', style: TextStyle(fontSize: 14)),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text(
                  'Sl: ',
                  style: TextStyle(fontSize: 14, color: Colors.black),
                ),
                SizedBox(
                  width: 50,
                  height: 30,
                  child: TextField(
                    controller: _quantityController,
                    decoration: InputDecoration(
                      hintText: '10',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 5),
                const Text('kg', style: TextStyle(fontSize: 14)),
              ],
            ),
            ElevatedButton(
              onPressed: _roleInitialized ? _handleSubmitOffer : () {
                _sendRoleMessage();
                Future.delayed(const Duration(milliseconds: 500), _handleSubmitOffer);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: const Text(
                'Gửi Giá',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBuyerPriceView() {
    return Column(
      children: [
        Row(
          children: [
            const Text(
              'Đề nghị giá: ',
              style: TextStyle(fontSize: 14, color: Colors.black),
            ),
            SizedBox(
              width: 80,
              height: 30,
              child: TextField(
                controller: _bidPriceController,
                decoration: InputDecoration(
                  hintText: '45.000',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 5),
            const Text('đ/kg', style: TextStyle(fontSize: 14)),
            const Spacer(),
            ElevatedButton(
              onPressed: _roleInitialized ? _handleSubmitOffer : () {
                _sendRoleMessage();
                Future.delayed(const Duration(milliseconds: 500), _handleSubmitOffer);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: const Text(
                'Gửi Giá',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final bool isAI = message.senderRole == 'ai';
    final bool isSender = message.isMine;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: isSender ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (!isSender && !isAI)
          CircleAvatar(
            backgroundColor: Colors.grey[400],
            child: Icon(Icons.person, color: Colors.white),
            radius: 20,
          ),
        if (isAI) 
          CircleAvatar(
            backgroundColor: Colors.blue,
            child: Icon(Icons.smart_toy, color: Colors.white),
            radius: 20,
          ),
        const SizedBox(width: 10),
        Flexible(
          child: Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.symmetric(vertical: 5),
            decoration: BoxDecoration(
              color: isAI 
                  ? Colors.blue[100]
                  : (isSender ? Colors.green[100] : Colors.grey[200]),
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
                if (isAI)
                  const Text(
                    'Trợ lý AI',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.blue,
                    ),
                  ),
                if (!isAI && !isSender)
                  Text(
                    message.senderRole == 'buyer' ? 'Người mua' : 'Người bán',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  message.content,
                  style: TextStyle(
                    color: isAI ? Colors.blue[800] : (isSender ? Colors.black87 : Colors.black),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message.time,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
      ],
    );
  }

  Widget _buildMessageInput() {
    return Container(
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
                  hintText: 'Nhập tin nhắn...',
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
    );
  }
}