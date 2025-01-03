import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const platform = MethodChannel('kore.botsdk/chatbot');
  var botConfig = {
    "clientId": "cs-58a260f2-8a77-58e2-8996-ade60df3f9f2",
    "clientSecret": "nRzHSD9YSpeo/GD13vHPLM5Qv4GGEb+JuKTwZw7ff7o=",
    "botId": "st-e17a5093-277d-5cf2-ac99-be251e5605c1",
    "chatBotName": "SDKBot",
    "identity": "example@kore.com",
    "jwt_server_url":
        "https://mk2r2rmj21.execute-api.us-east-1.amazonaws.com/dev/",
    "server_url": "https://uae-bots.kore.ai",
    "isReconnect": false,
    "jwtToken": "",
    "custom_data": {"age": 39, "gender": "M"}
  };
  var searchConfig = {
    "botId": "st-953e931b-1fe5-5bcc-9bb7-1b9bd4226947",
    "indexName": "tedbaker-test",
    "namespace": "tedbaker-gender-v1",
    "stage": "dev",
    "retail_server_url": "https://retailassist-poc.kore.ai/"
  };

  final myController = TextEditingController();
  final searchTxtfield = TextEditingController();

  Future<void> connectToBot() async {
    platform.setMethodCallHandler((handler) async {
      if (handler.method == 'Callbacks') {
        // Do your logic here.
        debugPrint("Event from native ${handler.arguments}");
      }
    });

    try {
      final String result =
          await platform.invokeMethod('getChatWindow', botConfig);
    } on PlatformException catch (e) {}
  }

  Future<void> _callSendmethod(msg) async {
    platform.setMethodCallHandler((handler) async {
      if (handler.method == 'Callbacks') {
        // Do your logic here.
        debugPrint("Event from native ${handler.arguments}");
      }
    });

    try {
      final String result =
          await platform.invokeMethod('sendMessage', {"message": msg});
    } on PlatformException catch (e) {}
  }

  Future<void> botInitialize() async {
    platform.setMethodCallHandler((handler) async {
      if (handler.method == 'Callbacks') {
        // Do your logic here.
        debugPrint("Event from native ${handler.arguments}");
      }
    });

    try {
      final String config =
          await platform.invokeMethod('initialize', searchConfig);
    } on PlatformException catch (e) {}
  }

  Future<void> getSearchResults(searchQuery) async {
    platform.setMethodCallHandler((handler) async {
      if (handler.method == 'Callbacks') {
        // Do your logic here.
        debugPrint("Event from native ${handler.arguments}");
      }
    });

    try {
      final String config = await platform.invokeMethod('getSearchResults', {
        "searchQuery": searchQuery,
        "context_data": {"color": "Black", "gender": "M"}
      });
    } on PlatformException catch (e) {}
  }

  Future<void> getHistoryResults(offset, limit) async {
    platform.setMethodCallHandler((handler) async {
      if (handler.method == 'Callbacks') {
        // Do your logic here.
        debugPrint("Event from native ${handler.arguments}");
      }
    });

    try {
      final String config = await platform.invokeMethod(
          'getHistoryResults', {"offset": offset, "limit": limit});
    } on PlatformException catch (e) {}
  }

  Future<void> closeBot() async {
    platform.setMethodCallHandler((handler) async {
      if (handler.method == 'Callbacks') {
        // Do your logic here.
        debugPrint("Event from native ${handler.arguments}");
      }
    });

    try {
      final String config = await platform.invokeMethod('closeBot');
    } on PlatformException catch (e) {}
  }

  Future<void> isSocketConnected() async {
    platform.setMethodCallHandler((handler) async {
      if (handler.method == 'Callbacks') {
        // Do your logic here.
        debugPrint("Event from native ${handler.arguments}");
      }
    });

    try {
      final String socketConnection =
          await platform.invokeMethod('isSocketConnected');
    } on PlatformException catch (e) {}
  }

  Future<void> updateCustomData(customData) async {
    platform.setMethodCallHandler((handler) async {
      if (handler.method == 'Callbacks') {
        // Do your logic here.
        debugPrint("Event from native ${handler.arguments}");
      }
    });

    try {
      final String custom = await platform
          .invokeMethod('updateCustomData', {"custom_data": customData});
    } on PlatformException catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    botInitialize();
    return Material(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
              child: ElevatedButton(
                onPressed: connectToBot,
                child: const Text('Bot Connect'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
              child: ElevatedButton(
                onPressed: isSocketConnected,
                child: const Text('Bot Connect status'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              child: TextFormField(
                controller: myController,
                decoration: const InputDecoration(
                  border: UnderlineInputBorder(),
                  labelText: 'Enter your message',
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              child: ElevatedButton(
                  onPressed: () => {_callSendmethod(myController.text)},
                  child: const Text('Send Message')),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              child: ElevatedButton(
                  onPressed: () => {
                        updateCustomData({
                          "size": 40,
                          "gender": "F",
                          "color": "blue",
                          "age": 38,
                          "outfit": "T-shirt"
                        })
                      },
                  child: const Text('Update Custom Data')),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              child: TextFormField(
                controller: searchTxtfield,
                decoration: const InputDecoration(
                  border: UnderlineInputBorder(),
                  labelText: 'Search query',
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              child: ElevatedButton(
                  onPressed: () => {getSearchResults(searchTxtfield.text)},
                  child: const Text('Search Query')),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              child: ElevatedButton(
                  onPressed: () => {getHistoryResults(0, 10)},
                  child: const Text('Get History')),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              child: ElevatedButton(
                  onPressed: closeBot, child: const Text('Close Bot')),
            ),
          ],
        ),
      ),
    );
  }
}
