import 'package:flutter/material.dart';

class LocationDetailPage extends StatelessWidget {
  final Map<String, dynamic> location;

  const LocationDetailPage({super.key, required this.location});

  // Fake data to be displayed regardless of the input
  final Map<String, dynamic> fakeData = const {
    'name': 'Vùng nông sản Đà Lạt - Lâm Đồng',
    'image': 'assets/vegetables.png', // Replace with your actual image path
    'productType': 'Rau củ quả',
    'shortDescription': 'Khu vực nổi tiếng với khí hậu mát mẻ, đất đai màu mỡ, thích hợp trồng rau củ, hoa trái như dâu tây, cà chua, bắp cải. Nông sản vùng này rất được ưa chuộng vì độ tươi ngon, chất lượng cao nhờ vị trí vùng cao và khí hậu.',
    'rating': 4.0,
    'reviewCount': 52,
    'rating5': 40,
    'rating4': 5,
    'rating3': 4,
    'rating2': 2,
    'rating1': 1,
    'comments': const [
      {
        'user': 'Cá Thơm',
        'text': 'Sản phẩm ngon, tươi xài ok',
        'time': '2 phút trước',
      },
    ],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(fakeData['name'] ?? 'Chi tiết địa điểm'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              child: Image.asset(
                fakeData['image'] ?? 'assets/placeholder.png',
                height: 250,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 20),
            // Short Description Section
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Text(
                'Loại nông sản: ${fakeData['productType'] ?? 'Chưa xác định'} - Mô tả ngắn: ${fakeData['shortDescription'] ?? 'Thông tin không có'}',
                style: TextStyle(fontSize: 16, color: Colors.green.shade800),
              ),
            ),
            const SizedBox(height: 20),
            // Rating Section with Star Breakdown
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Đánh giá: ${fakeData['rating']?.toString() ?? '0.0'} / 5',
                  style: const TextStyle(fontSize: 18, color: Colors.amber, fontWeight: FontWeight.bold),
                ),
                Text(
                  '(${fakeData['reviewCount'] ?? 0} đánh giá)',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRatingBar(5, fakeData['rating5'] ?? 0),
                _buildRatingBar(4, fakeData['rating4'] ?? 0),
                _buildRatingBar(3, fakeData['rating3'] ?? 0),
                _buildRatingBar(2, fakeData['rating2'] ?? 0),
                _buildRatingBar(1, fakeData['rating1'] ?? 0),
              ],
            ),
            const SizedBox(height: 20),
            // Comments Section
            Text(
              'Bình luận:',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: fakeData['comments']?.length ?? 0,
              itemBuilder: (context, index) {
                final comment = fakeData['comments'][index];
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(comment['user'][0] ?? '?'),
                  ),
                  title: Text(comment['user'] ?? 'Ẩn danh'),
                  subtitle: Text(comment['text'] ?? 'Không có bình luận'),
                  trailing: Text(comment['time'] ?? 'Vừa xong'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingBar(int stars, int count) {
    return Row(
      children: [
        Text('$stars ★', style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 10),
        SizedBox(
          width: 150,
          child: LinearProgressIndicator(
            value: count > 0 ? count / (fakeData['reviewCount'] ?? 1) : 0,
            backgroundColor: Colors.grey[300],
            color: Colors.amber,
          ),
        ),
        const SizedBox(width: 10),
        Text('$count', style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}