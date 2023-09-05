import 'package:flutter/material.dart';

class IBTCDrawer extends StatelessWidget {
  const IBTCDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        // Important: Remove any padding from the ListView.
        padding: EdgeInsets.zero,
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.12,
            child: const DrawerHeader(
              decoration: BoxDecoration(
                color:  Color(0xff941751),
              ),
              child: Text('IBTC Menu',style: TextStyle(color: Colors.white, fontSize: 20),),
            ),
          ),
          ListTile(
            title: const Text('Products'),
            onTap: () {
              // Update the state of the app.
              // ...
            },
          ),
          ListTile(
            title: const Text('Customers'),
            onTap: () {
              // Update the state of the app.
              // ...
            },
          ),
        ],
      ),
    );
  }
}
