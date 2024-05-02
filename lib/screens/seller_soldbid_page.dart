import 'package:fish_link/screens/buyer_rating.dart';
import 'package:fish_link/screens/chat.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fish_link/utils/api.dart';
import 'package:intl/intl.dart';

class SoldBidPage extends StatefulWidget {
  final String catchId;
  final String buyerId;
  final Map<String, dynamic> catchDetails;

  const SoldBidPage(
      {Key? key,
      required this.catchId,
      required this.buyerId,
      required this.catchDetails})
      : super(key: key);

  @override
  _SoldBidPageState createState() => _SoldBidPageState();
}

class _SoldBidPageState extends State<SoldBidPage> {
  Map<String, dynamic> userProfile = {};
  bool isCatchDetailsExpanded = false;
  List<dynamic> buyerRatings = [];
  bool isLoadingRatings = false;

  @override
  void initState() {
    super.initState();
    fetchUserProfile();
    _getBuyerRatings();
  }

  Future<void> fetchUserProfile() async {
    try {
      final response = await http
          .get(Uri.parse('${Api.userProfileUrl}/user/${widget.buyerId}'));
      if (response.statusCode == 200) {
        setState(() {
          userProfile = json.decode(response.body);
        });
      } else {
        throw Exception('Failed to load user profile');
      }
    } catch (error) {
      print('Error fetching user profile: ${widget.buyerId}');
    }
  }

  Future<void> _getBuyerRatings() async {
    setState(() {
      isLoadingRatings = true;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('userId');

      if (userId != null) {
        final response = await http.get(
          Uri.parse(
              '${Api.getRatingsByCatchIdUrl}/${widget.buyerId}/${widget.catchId}'),
          headers: {'Content-Type': 'application/json'},
        );
        if (response.statusCode == 200) {
          setState(() {
            buyerRatings = jsonDecode(response.body);
            isLoadingRatings = false;
          });
        } else {
          print('Failed to fetch seller ratings: ${response.statusCode}');
          setState(() {
            isLoadingRatings = false;
          });
        }
      } else {
        print('User ID is null');
        setState(() {
          isLoadingRatings = false;
        });
      }
    } catch (error) {
      print('Error fetching seller ratings: $error');
      setState(() {
        isLoadingRatings = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Win Details'),
        backgroundColor: Colors.transparent,
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue, Colors.green],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildDetailsCard(),
              _buildProfileCard(),
              _buildRatingsCard(),
              _buildChatCard(),
              if (isLoadingRatings) _buildLoadingIndicator(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsCard() {
    return Card(
      color: Colors.white, // Set background color to white
      child: ExpansionTile(
        leading: const Icon(Icons.details,
            color: Colors.orange), // Added color to the icon
        title: const Text(
          'Catch Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        initiallyExpanded: isCatchDetailsExpanded,
        onExpansionChanged: (expanded) {
          setState(() {
            isCatchDetailsExpanded = expanded;
          });
        },
        backgroundColor: isCatchDetailsExpanded
            ? Colors.grey[200]
            : null, // Change background color when expanded
        children: <Widget>[
          if (widget.catchDetails.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: widget.catchDetails['images'].length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Image.network(
                            Api.baseUrl + widget.catchDetails['images'][index],
                            width: 200,
                            height: 200,
                            fit: BoxFit.cover,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('Location: ',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('${widget.catchDetails['location']}'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Base Price: ',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('${widget.catchDetails['basePrice']}'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Quantity: ',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('${widget.catchDetails['quantity']}'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Winning Price: ',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('${widget.catchDetails['currentBid']}'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Bid Start Time: ',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        DateFormat.yMMMd().add_jm().format(
                            DateTime.parse(widget.catchDetails['startTime'])),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Bid End Time: ',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        DateFormat.yMMMd().add_jm().format(
                            DateTime.parse(widget.catchDetails['endTime'])),
                      ),
                    ],
                  ),
                ],
              ),
            )
          else
            const ListTile(
              title: Text('Loading Catch Details...'),
            )
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return Card(
      color: Colors.white, // Set background color to white
      child: ExpansionTile(
        leading: const Icon(Icons.person,
            color: Colors.blue), // Added color to the icon
        title: const Text(
          'Buyer Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        children: <Widget>[
          if (userProfile.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CircleAvatar(
                        radius: 80,
                        backgroundImage: userProfile['profilePic'] != null &&
                                userProfile['profilePic'] != ''
                            ? NetworkImage(
                                Api.baseUrl + userProfile['profilePic'])
                            : const AssetImage('assets/default_profile_pic.png')
                                as ImageProvider,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('Name: ',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('${userProfile['name']}'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Email: ',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('${userProfile['email']}'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Phone: ',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('${userProfile['phone']}'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Bio: ',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('${userProfile['bio'] ?? ''}'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Harbour: ',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('${userProfile['harbour'] ?? ''}'),
                    ],
                  ),
                ],
              ),
            )
          else
            const ListTile(
              title: Text('Loading Buyer Profile...'),
            )
        ],
      ),
    );
  }

  Widget _buildRatingsCard() {
    return Card(
      color: Colors.white, // Set background color to white
      child: ExpansionTile(
        leading: const Icon(Icons.star,
            color: Colors.yellow), // Added color to the icon
        title: const Text(
          'Buyer Rating',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        children: <Widget>[
          if (!isLoadingRatings)
            if (widget.catchDetails['buyerRated'] == true)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: buyerRatings.map((rating) {
                    return ListTile(
                      title: Text(
                        'Rating: ${rating['rating']}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Comment: ${rating['comment'] ?? 'No comment'}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    );
                  }).toList(),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => WinnerPage(
                              catchDetails: widget.catchDetails,
                            ),
                          ),
                        );
                      },
                      child: const Text('Please rate the Buyer'),
                    ),
                  ],
                ),
              )
          else
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }

  Widget _buildChatCard() {
    return Card(
      color: Colors.white, // Set background color to white
      child: ListTile(
        leading: const Icon(Icons.chat,
            color: Colors.green), // Added color to the icon
        title: const Text(
          'Chat with Seller',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        onTap: () {
          print(widget.catchId);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatPage(
                catchId: widget.catchId,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}