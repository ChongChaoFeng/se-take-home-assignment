import 'package:automated_cooking_bots/orderPage/model/order.dart';
import 'package:automated_cooking_bots/orderPage/model/bot.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class OrderPage extends StatefulWidget {
  const OrderPage({super.key, required this.title});

  final String title;

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  List<Order> pendingOrders = [];
  List<Order> completedOrders = [];
  List<Bot> bots = [];
  int orderId = 1;
  int botId = 1;

  void _newNormalOrder() {
    setState(() {
      pendingOrders.add(Order(orderId++, 1));
    });

    _assignBotToProcessOrder();
  }

  void _newVIPOrder() {
    setState(() {
      Order newVIPOrder = Order(orderId++, 2);
      int vipCount = pendingOrders.where((order) => order.type == 2).length;

      // If there are existing VIP orders, insert the new VIP order after the last VIP order
      if (vipCount > 0) {
        int lastVIPIndex =
            pendingOrders.lastIndexWhere((order) => order.type == 2);
        pendingOrders.insert(lastVIPIndex + 1, newVIPOrder);
      } else {
        // If no VIP orders exist, add the new VIP order at the front
        pendingOrders.insert(0, newVIPOrder);
      }
    });

    _assignBotToProcessOrder();
  }

  void _addBot() {
    setState(() {
      bots.add(Bot(botId++));
    });

    _assignBotToProcessOrder();
  }

  void _removeBot() {
    if (bots.isNotEmpty) {
      setState(() {
        Bot botToRemove = bots.removeLast();
        botId--;

        if (botToRemove.currentOrder != null) {
          botToRemove.timer?.cancel();
          botToRemove.currentOrder!.status = 1;
          botToRemove.currentOrder = null;
        }

        _assignBotToProcessOrder();
      });
    }
  }

  void _assignBotToProcessOrder() {
    for (var bot in bots) {
      // Check if the bot is idle and there are pending orders
      if (bot.currentOrder == null && pendingOrders.isNotEmpty) {
        // Find the first pending order
        int orderId = pendingOrders.indexWhere((order) => order.status == 1);

        // Process the order if a valid order is found
        if (orderId != -1) {
          Order orderToAssign = pendingOrders[orderId];
          _processOrder(bot, orderToAssign);
          orderToAssign.status = 2;
        }
      }
    }
  }

  void _processOrder(Bot bot, Order order) {
    setState(() {
      bot.currentOrder = order;
      bot.status = 2;
    });

    // Start a timer to decrement the order's processing time every second
    bot.timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (order.processingTime.inSeconds > 0) {
          // Decrease processing time by 1 second
          order.processingTime -= Duration(seconds: 1);
        }

        // When processing time reaches 0, move the order to completed Orders
        if (order.processingTime.inSeconds == 0) {
          order.status = 3;
          // Remove the order from pendingOrders
          pendingOrders.remove(order);
          completedOrders.add(order);

          // Make the bot idle and clear its current order
          bot.currentOrder = null;
          bot.status = 1;

          // Stop the timer when the order is completed
          timer.cancel();
          bot.timer = null;
          _assignBotToProcessOrder();
        }
      });
    });
  }

  // Convert Display Time as HH:MM:SS
  String formatProcessingTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));

    return '${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds';
  }

  Widget actionButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: ElevatedButton(
            onPressed: _newNormalOrder,
            child: Text(
              'New Order (Normal)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: ElevatedButton(
            onPressed: _newVIPOrder,
            child: Text(
              'New Order (VIP)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: ElevatedButton(
            onPressed: _addBot,
            child: Text(
              '+ Bot',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: ElevatedButton(
            onPressed: _removeBot,
            child: Text(
              '- Bot',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget pendingQueue() {
    return ListView.builder(
      itemCount: pendingOrders.length,
      itemBuilder: (context, index) {
        final order = pendingOrders[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 5),
          child: ListTile(
            title: Text(
                'Order (${order.type == 1 ? "Normal" : "VIP"}) #${order.id}'),
            subtitle: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(order.status == 1 ? "PENDING" : "PROCESSING"),
                ),
                Text(
                  formatProcessingTime(order.processingTime),
                  style: TextStyle(color: Colors.red),
                ),
              ],
            ),
            leading: Icon(
              order.type == 2 ? Icons.star : Icons.fastfood,
              color: order.type == 2 ? Colors.yellow : Colors.green,
            ),
          ),
        );
      },
    );
  }

  Widget completedQueue() {
    return ListView.builder(
      itemCount: completedOrders.length,
      itemBuilder: (context, index) {
        final order = completedOrders[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 5),
          child: ListTile(
              title: Text(
                  'Order (${order.type == 1 ? "Normal" : "VIP"}) #${order.id}'),
              subtitle: Text(order.status == 3 ? "COMPLETED" : ""),
              leading: Icon(
                Icons.done,
                color: Colors.green,
              )),
        );
      },
    );
  }

  Widget botList() {
    return ListView.builder(
      itemCount: bots.length,
      itemBuilder: (context, index) {
        final bot = bots[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 5),
          child: ListTile(
              title: Text(
                  'Bot #${bot.id} - ${bot.status == 1 ? 'IDLE' : 'WORKING'}'),
              leading: Icon(
                Icons.android,
                color: Colors.blue,
              )),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text('Food Ordering System'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              actionButton(),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PENDING:',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        SizedBox(height: 10),
                        Container(
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.of(context).size.height,
                            maxWidth: MediaQuery.of(context).size.width,
                          ),
                          child: pendingQueue(),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 20),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'COMPLETE:',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        SizedBox(height: 10),
                        Container(
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.of(context).size.height,
                            maxWidth: MediaQuery.of(context).size.width,
                          ),
                          child: completedQueue(),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 20),
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'My Bots',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        SizedBox(height: 10),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10.0),
                          color: const Color.fromARGB(255, 208, 193, 235),
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.of(context).size.height,
                            maxWidth: MediaQuery.of(context).size.width,
                          ),
                          child: botList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
