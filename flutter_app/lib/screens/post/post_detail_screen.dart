import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart'; 

class PostDetailScreen extends StatefulWidget {
  final Map<String, dynamic> postData; // รับข้อมูลโพสต์เข้ามา

  const PostDetailScreen({super.key, required this.postData});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _supabase = Supabase.instance.client;
  final TextEditingController _commentController = TextEditingController();
  
  // State variables
  bool _isLiked = false;
  int _likeCount = 0;
  bool _isLoadingLike = true;

  @override
  void initState() {
    super.initState();
    _fetchLikeStatus();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // 1. เช็คสถานะ Like และนับจำนวน
  Future<void> _fetchLikeStatus() async {
    final userId = _supabase.auth.currentUser!.id;
    final postId = widget.postData['id'];

    // นับจำนวนไลค์ทั้งหมด
    final countResponse = await _supabase
        .from('likes')
        .count(CountOption.exact)
        .eq('post_id', postId);

    // เช็คว่าเราเคยไลค์ไหม
    final myLike = await _supabase
        .from('likes')
        .select()
        .eq('post_id', postId)
        .eq('user_id', userId)
        .maybeSingle();

    if (mounted) {
      setState(() {
        _likeCount = countResponse;
        _isLiked = myLike != null;
        _isLoadingLike = false;
      });
    }
  }

  // 2. กดปุ่ม Like / Unlike
  Future<void> _toggleLike() async {
    final userId = _supabase.auth.currentUser!.id;
    final postId = widget.postData['id'];

    setState(() {
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });

    try {
      if (_isLiked) {
        await _supabase.from('likes').insert({'user_id': userId, 'post_id': postId});
      } else {
        await _supabase.from('likes').delete().eq('user_id', userId).eq('post_id', postId);
      }
    } catch (e) {
      // ถ้า Error ให้ Revert state กลับ
      setState(() {
        _isLiked = !_isLiked;
        _likeCount += _isLiked ? 1 : -1;
      });
      print('Error liking post: $e');
    }
  }

  // 3. ส่งคอมเมนต์
  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty) return;

    final content = _commentController.text.trim();
    _commentController.clear(); // เคลียร์ช่องพิมพ์ทันทีเพื่อให้ดูลื่นไหล

    try {
      await _supabase.from('comments').insert({
        'user_id': _supabase.auth.currentUser!.id,
        'post_id': widget.postData['id'],
        'content': content,
      });
      // ไม่ต้อง setState เพราะเราใช้ StreamBuilder ดึงข้อมูล Realtime ด้านล่าง
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // แปลงวันที่ให้สวยงาม
  String _formatDate(String dateString) {
    final date = DateTime.parse(dateString);
    return DateFormat('dd MMM yyyy, HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.postData;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF5CD), // Cream theme
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Post Details', style: GoogleFonts.luckiestGuy(color: Colors.black)),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- ส่วนรูปภาพ ---
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxHeight: 400),
                    child: Image.network(
                      post['image_url'],
                      fit: BoxFit.cover,
                    ),
                  ),

                  // --- ส่วน Action (Like) & Caption ---
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: _toggleLike,
                              icon: Icon(
                                _isLiked ? Icons.favorite : Icons.favorite_border,
                                color: _isLiked ? const Color(0xFFEA5B6F) : Colors.grey,
                                size: 30,
                              ),
                            ),
                            Text(
                              '$_likeCount Likes',
                              style: GoogleFonts.itim(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const Spacer(),
                            Text(
                              _formatDate(post['created_at']),
                              style: GoogleFonts.itim(color: Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Caption
                        if (post['caption'] != null && post['caption'] != '')
                          Text(
                            post['caption'],
                            style: GoogleFonts.itim(fontSize: 18),
                          ),
                        const SizedBox(height: 20),
                        const Divider(),
                        Text('Comments', style: GoogleFonts.luckiestGuy(fontSize: 18)),
                      ],
                    ),
                  ),

                  // --- ส่วนรายการคอมเมนต์ (Real-time) ---
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _supabase
                        .from('comments')
                        .stream(primaryKey: ['id'])
                        .eq('post_id', post['id'])
                        .order('created_at', ascending: true),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final comments = snapshot.data!;
                      if (comments.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text('ยังไม่มีความคิดเห็น เป็นคนแรกเลย!', style: GoogleFonts.itim(color: Colors.grey)),
                        );
                      }
                      return ListView.builder(
                        shrinkWrap: true, // สำคัญเมื่ออยู่ใน SingleChildScrollView
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          final comment = comments[index];
                          return ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFF0D92F4), // Sky color
                              child: Icon(Icons.person, color: Colors.white),
                            ),
                            title: Text(comment['content'], style: GoogleFonts.itim()),
                            // ถ้าอยากโชว์ชื่อคนคอมเมนต์ ต้องทำ Join Table หรือเก็บชื่อใน comment (แบบง่าย)
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 80), // เผื่อพื้นที่ให้ช่องพิมพ์ด้านล่าง
                ],
              ),
            ),
          ),
          
          // --- ช่องพิมพ์คอมเมนต์ (ติดด้านล่าง) ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, -2))],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: 'แสดงความคิดเห็น...',
                        hintStyle: GoogleFonts.itim(color: Colors.grey),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _submitComment,
                    icon: const Icon(Icons.send, color: Color(0xFF0D92F4)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}