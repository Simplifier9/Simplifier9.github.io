
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../addproduct/arview.dart';

class showreview extends StatefulWidget {
  const showreview({super.key});

  @override
  State<showreview> createState() => _showreviewState();
}

class _showreviewState extends State<showreview> {
  final List<Review> reviews = [
    Review(username: 'John', reviewText: 'Great app!', rating: 4.5),
    Review(username: 'Jane', reviewText: 'Needs improvement.', rating: 3.0),
    Review(username: 'Alex', reviewText: 'Loved it!', rating: 5.0),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('User Reviews'),backgroundColor: Colors.blue,),
      body: ListView.builder(
        itemCount: reviews.length,
        itemBuilder: (context, index) {
          final review = reviews[index];
          return GestureDetector(
            onTap: () => _showReviewDetails(context, review),
            child: Card(
              margin: EdgeInsets.all(8.0),
              child: ListTile(
                title: Text(review.username),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.reviewText),
                    SizedBox(height: 4),
                    Row(
                      children: List.generate(5, (i) {
                        return Icon(
                          i < review.rating.round() ? Icons.star : Icons
                              .star_border,
                          color: Colors.amber,
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(onPressed: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => AddReviewPage()));
      },
        child: Icon(Icons.add),

      ),
    );
  }
}
  class Review {
  final String username;
  final String reviewText;
  final double rating;

  Review({required this.username, required this.reviewText, required this.rating});
}

void _showReviewDetails(BuildContext context, Review review) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Review by ${review.username}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: List.generate(5, (i) {
                return Icon(
                  i < review.rating.round() ? Icons.star : Icons
                      .star_border,
                  color: Colors.amber,
                );
              }),
            ),
            SizedBox(height: 8),
            Text('Review:'),
            SizedBox(height: 4),
            Text(review.reviewText, style: TextStyle(fontSize: 16)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
        ],
      );
    },
  );
}