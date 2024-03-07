import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:download/download.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OpenAPI Spec Generator',
      theme: ThemeData(
        primarySwatch: Colors.grey, // Metallic dark color
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.grey,
          accentColor: Colors.grey,
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'OpenAPI Spec Generator'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  TextEditingController textEditingController = TextEditingController();
  String userInput = '';
  String openApiSpec = '';
  bool isTextButtonVisible = true;
  String samplePrompt =
      "Create component travel with attributes like id, origin, destination, departure date and origin date. Also provide paths for all the CRUD operations.";

  void _fetchOpenApiSpec()  async {
    print("User input - $userInput" );
    // Use the userInput in the OpenAPI spec
    final apiUrl = 'http://localhost:8088/openapi?message=$userInput';
    try {
      showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return Center(
              child: CircularProgressIndicator(),
            );
          },
        );
      final response = await http.get(Uri.parse(apiUrl));
      print("print ${response.body}");
      if (response.statusCode == 200) {
        Navigator.of(context).pop();
        final String yamlData = response.body;
        setState(() {
          openApiSpec = yamlData;
          textEditingController.text = '';
          userInput = '';
        });
        
      } else {
        Navigator.of(context).pop();
        _showErrorDialog('${response.body}');
      }
    } catch (error) {
      Navigator.of(context).pop();
      _showErrorDialog('Error fetching OpenAPI spec: $error');
    }
  }

  void _showErrorDialog(String errorMessage) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(errorMessage),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Try Again'),
            ),
          ],
        );
      },
    );
  }


  void _copySamplePromptToChatBox() {
    print("Copying sample prompt to chat box");
    setState(() {
      textEditingController.text = samplePrompt;
      userInput = samplePrompt;
      isTextButtonVisible = false;
    });
  }
  void _downloadOpenApiSpec() async {
    try {
      final stream = Stream.fromIterable(openApiSpec.codeUnits);
      await download(stream, 'openapi_spec.yaml');
    } catch (e) {
      _showErrorDialog("Could not download the OpenAPI Spec");
    }
  }

  void _copyToClipBoard() {
    Clipboard.setData(new ClipboardData(text: openApiSpec))
      .then((_) {
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Copied to your clipboard !')));
      }
    );
  }


  @override
  Widget build(BuildContext context) {
    print("Building widget");
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                     const Text(
                      'Generate OpenAPI Specification',
                      style: TextStyle(fontSize: 28, color: Colors.white),
                    ),
                    const SizedBox(height: 30),
                    if(isTextButtonVisible)
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: 500),
                        child: TextButton(
                        onPressed: _copySamplePromptToChatBox,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.all(12),
                          side: BorderSide(color: Colors.white),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          samplePrompt,
                          style: TextStyle(fontSize: 13, color: Colors.white),
                        ),
                      ),
                      ),
                    const SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white,
                      ),
                      constraints: BoxConstraints(maxWidth: 600),
                      child: Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: TextField(
                                controller: textEditingController,
                                onChanged: (value) {
                                  setState(() {
                                    userInput = value;
                                  });
                                },
                                maxLines: null,
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'Type here...',
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              _fetchOpenApiSpec();
                            },
                            icon: Icon(
                              Icons.file_copy, // You can use any desired custom icon
                              color: Theme.of(context).primaryColorDark, // You can adjust the icon color
                              size: 24, // You can adjust the icon size
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // const SizedBox(height: 20),
            if (openApiSpec.isNotEmpty)
              Expanded(
                child: Card(
                  elevation: 5, // Add a subtle shadow for depth
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  // color: Color.fromARGB(255, 169, 186, 194), // Adjust the background color
                  color: Theme.of(context).primaryColorDark,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(100,16,16,16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              onPressed: () {
                                _copyToClipBoard();
                              },
                              icon: Icon(
                                Icons.content_copy,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                            SizedBox(width: 16),
                            IconButton(
                              onPressed: () {
                                // Handle download action
                                _downloadOpenApiSpec();
                              },
                              icon: Icon(
                                Icons.download,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                          ],
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            // scrollDirection: Axis.horizontal,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 500),
                              child: Text(
                                openApiSpec,
                                style: TextStyle(
                                  fontSize: 24,
                                  color: Colors.white, // Adjust the text color
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  ),  
                ),
              ),
          ],
        ),
      ),
    );
  }
}
