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
  final TextEditingController _priceController = TextEditingController();
  WebSocketChannel? _channel;
  bool _isConnected = false;
  bool _roleInitialized = false;
  String _currentPrice = '60.000';
  
  final List<ChatMessage> _messages = [];
  
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
    _currentPrice = _product['price'];
  }

  void _connectWebSocket() {
    try {
      // Update the WebSocket connection URL based on your deployment environment
      final wsUrl = 'ws://70ad-2402-9d80-348-260f-546c-fde6-7478-5c9e.ngrok-free.app/ws/chat';
      
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
    final String content = _messageController.text;
    
      // Regular chat message
      final message = {
        'type': 'message',
        'role': widget.role,
        'content': content,
      };
      _channel?.sink.add(jsonEncode(message));
      print('Sent message: $content');
      
      // Add message to local list for immediate display
      setState(() {
        _messages.add(
          ChatMessage(
            type: 'chat',
            senderRole: widget.role,
            content: content,
            time: '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')} ${DateTime.now().hour >= 12 ? 'PM' : 'AM'}',
            isMine: true,
          ),
        );
      });
    
    _messageController.clear();
  }
  
  void _sendPriceMessage() {
    final String priceText = _priceController.text.trim();
    if (priceText.isNotEmpty) {
      if (_isConnected && _channel != null) {
        if (!_roleInitialized) {
          _sendRoleMessage();
          Future.delayed(const Duration(milliseconds: 500), () {
            _sendPriceContent(priceText);
          });
        } else {
          _sendPriceContent(priceText);
        }
      } else {
        _showErrorMessage('Mất kết nối, đang thử kết nối lại...');
        _connectWebSocket();
      }
    }
  }

  void _sendPriceContent(String price) {
    final message = {
      'type': 'price_update',
      'role': widget.role,
      'content': price,  // Fixed: Ensure we're sending the price as content
      'price': price,    // Include price field for backward compatibility
      'senderRole': widget.role  // Fixed: Include senderRole field
    };
    _channel?.sink.add(jsonEncode(message));
    print('📤 Sent price update: $price');
    
    // Fixed: Update the current price in the UI
    setState(() {
      _currentPrice = price;
    });
    
    // Clear the price input field after sending
    _priceController.clear();
    
    // Add a message to indicate price change (optional)
    setState(() {
      _messages.add(
        ChatMessage(
          type: 'chat',
          senderRole: widget.role,
          content: 'Đã cập nhật giá: $price đ/kg',
          time: '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')} ${DateTime.now().hour >= 12 ? 'PM' : 'AM'}',
          isMine: true,
        ),
      );
    });
  }

  void _sendPriceFromChat(String priceStr) {
    final message = {
      'type': 'price',
      'role': widget.role,
      'content': priceStr,
      'senderRole': widget.role
    };
    _channel?.sink.add(jsonEncode(message));
    print('📤 Sent price from chat: $priceStr');
    
    // Add message to local list for immediate display
    setState(() {
      _messages.add(
        ChatMessage(
          type: 'chat',
          senderRole: widget.role,
          content: '$priceStr đ/kg',
          time: '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')} ${DateTime.now().hour >= 12 ? 'PM' : 'AM'}',
          isMine: true,
        ),
      );
    });
    
    // Update current price if seller
    if (widget.role == 'seller') {
      setState(() {
        _currentPrice = priceStr;
      });
    }
  }

  
  void _handlePurchase() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xác nhận mua hàng'),
          content: Text('Bạn muốn mua sản phẩm ${_product["name"]} với giá $_currentPrice đ/kg?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _confirmPurchase();
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Xác nhận'),
            ),
          ],
        );
      },
    );
  }
  
  void _confirmPurchase() {
    // Send purchase confirmation message
    final message = {
      'type': 'purchase',
      'role': widget.role,
      'content': _currentPrice,
      'senderRole': widget.role
    };
    _channel?.sink.add(jsonEncode(message));
    
    // Add confirmation message to chat
    setState(() {
      _messages.add(
        ChatMessage(
          type: 'chat',
          senderRole: widget.role,
          content: 'Đã mua hàng với giá $_currentPrice đ/kg',
          time: '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')} ${DateTime.now().hour >= 12 ? 'PM' : 'AM'}',
          isMine: true,
        ),
      );
    });
    
    // Show success message
    _showSuccessMessage('Đã mua hàng thành công với giá $_currentPrice đ/kg');
  }

  void _handleIncomingMessage(Map<String, dynamic> data) {
    print('📥 Received message: $data');
    
    // Skip messages that were sent by the current user (already displayed locally)
    if ((data['type'] == 'chat' || data['type'] == 'price' || data['type'] == 'purchase') && 
        data['senderRole'] == widget.role) {
      print('Skipping message from self (already displayed locally)');
      return;
    }
    
    if (data['type'] == 'chat') {
      setState(() {
        _messages.add(
          ChatMessage.fromJson(data, widget.role),
        );
      });
    } else if (data['type'] == 'price_update' || data['type'] == 'price_sell') {
      // Fixed: Handle price update messages and update current price
      setState(() {
        if (data['content'] != null && data['content'].toString().isNotEmpty) {
          _currentPrice = data['content'].toString();
        } else if (data['price'] != null && data['price'].toString().isNotEmpty) {
          _currentPrice = data['price'].toString();
        }
        
        // Add informational message about price update
        if(data['senderRole']!=widget.role){
          _messages.add(
          ChatMessage(
            type: 'chat',
            senderRole: data['senderRole'] ?? '',
            content: 'Đã cập nhật giá: $_currentPrice đ/kg',
            time: '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')} ${DateTime.now().hour >= 12 ? 'PM' : 'AM'}',
            isMine: false,
          ),
        );
        } 
      });
    } else if (data['type'] == 'ai_response') {
      _handleAIResponse(data);
    } else if (data['type'] == 'purchase') {
      // Handle purchase confirmation from other user
      setState(() {
        _messages.add(
          ChatMessage(
            type: 'chat',
            senderRole: data['senderRole'] ?? '',
            content: 'Đã mua hàng với giá ${data['content']} đ/kg',
            time: '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')} ${DateTime.now().hour >= 12 ? 'PM' : 'AM'}',
            isMine: false,
          ),
        );
      });
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

  @override
  void dispose() {
    _messageController.dispose();
    _priceController.dispose();
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
                    // Name and current price
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
                          'Giá hiện tại: $_currentPrice đ/kg',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Price and action section based on role
                    widget.role == 'seller' 
                        ? _buildSellerPriceControls()
                        : _buildBuyerControls(),
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
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Đặt giá mới: ',
              style: TextStyle(fontSize: 14, color: Colors.black),
            ),
            SizedBox(
              width: 80,
              height: 30,
              child: TextField(
                controller: _priceController,
                decoration: InputDecoration(
                  hintText: '50000',
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
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: _roleInitialized ? _sendPriceMessage : () {
            _sendRoleMessage();
            Future.delayed(const Duration(milliseconds: 500), _sendPriceMessage);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            minimumSize: Size(100, 35),
          ),
          child: const Text(
            'Cập nhật giá',
            style: TextStyle(color: Colors.white, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildBuyerControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ElevatedButton(
          onPressed: _roleInitialized ? _handlePurchase : () {
            _sendRoleMessage();
            Future.delayed(const Duration(milliseconds: 500), _handlePurchase);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
          child: const Text(
            'Mua hàng',
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
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