
import 'package:flutter/material.dart';
import 'package:ibtc/main.dart';
import 'package:ibtc/reusable/utils.dart';

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
          ListTile(
            title: const Text('Backup'),
            onTap: () async{
              var result = await Utils.exportDatabase(context);
              if(result != null) {
                if(context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result),
                    ),
                  );
                }
              }
            },
          ),
          ListTile(
            title: const Text('Restore'),
            onTap: () async{
             var result =  await Utils.restoreDatabase(context);
              if(result != null) {
                if(context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) =>
                     const MyHomePage()), (Route<dynamic> route) => false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result),
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
