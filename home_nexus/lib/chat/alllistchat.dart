import 'package:flutter/material.dart';

import 'chat.dart';

class ChatList extends StatefulWidget {
  @override
  _ChatList createState() => _ChatList();
}

class _ChatList extends State<ChatList> {
  // Sample chat data
  final List<Map<String, String>> chats = [
    {
      "name": "John Doe",
      "message": "Hey, how are you?",
      "time": "10:45 AM",
      "imageUrl": "https://via.placeholder.com/150"
    },
    {
      "name": "Jane Smith",
      "message": "Are you coming to the meeting?",
      "time": "9:30 AM",
      "imageUrl": "https://via.placeholder.com/150"
    },
    {
      "name": "David Brown",
      "message": "Let’s catch up soon!",
      "time": "Yesterday",
      "imageUrl": "https://via.placeholder.com/150"
    },
    {
      "name": "Sophia Johnson",
      "message": "Can you share the document?",
      "time": "Yesterday",
      "imageUrl": "https://via.placeholder.com/150"
    },
    {
      "name": "Michael Lee",
      "message": "Thank you!",
      "time": "2 days ago",
      "imageUrl": "https://via.placeholder.com/150"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text(
          "Chats",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(icon: Icon(Icons.search), onPressed: () {}),
          IconButton(icon: Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: ListView.builder(
        itemCount: chats.length,
        itemBuilder: (context, index) {
          final chat = chats[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(chat['imageUrl']!),
              radius: 25,
            ),
            title: Text(
              chat['name']!,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Text(
              chat['message']!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            trailing: Text(
              chat['time']!,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            onTap: () {
              // Navigate to chat screen or perform an action
              Navigator.push(context, MaterialPageRoute(builder: (context)=>Chat()));
            },
          );
        },
      ),
    );
  }
}
