// ignore_for_file: library_private_types_in_public_api, prefer_final_fields, avoid_print, unnecessary_string_interpolations, prefer_const_constructors, unnecessary_new

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:async';
import 'package:dart_sentiment/dart_sentiment.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Virtual Assistant',
      theme: ThemeData(
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const VirtualAssistant(),
    );
  }
}

class VirtualAssistant extends StatefulWidget {
  const VirtualAssistant({super.key});

  @override
  _VirtualAssistantState createState() => _VirtualAssistantState();
}

class _VirtualAssistantState extends State<VirtualAssistant> {
  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;
  bool _isListening = false;
  String _text = 'Press the button and start talking';
  List<Map<String, dynamic>> _conversation = [];
  Timer? _debounce;
  final TextEditingController _textController = TextEditingController();
  final Sentiment _sentiment = Sentiment();

  final List<String> _indonesianPositiveWords = [
    "baik",
    "senang",
    "bahagia",
  ];

  final List<String> _indonesianNegativeWords = [
    "sedih",
    "kesal",
    "marah",
  ];

  final Map<String, Map<String, String>> _commands = {
    'english': {
      'Hello': "Hello, I'm Jason AI, your Virtual Assistant.",
      'how are you': "I'm fine, thank you for asking.",
      'help':
          "Of course I can because I'm Jason AI your Virtual Assistant. What can I help?",
      'time': "It's 7:30 right now.",
      'weather':
          "The weather is sunny now and it will rain at 5 pm.",
      'schedule': "Today you are free, enjoy your holiday.",
      'thank you': "No problem, I'm here for you.",

      'happy': "It's good if you are happy. I hope you are always happy everyday.",
      'sad': "Don't be sad. I'll give you a joke. How do trees access the internet? They log in.",
    },
    'indonesian': {
      'halo': "Halo, saya Jason AI, asisten virtual Anda.",
      'apa kabar': "Saya baik-baik saja, terima kasih telah bertanya.",
      'bantu':
          "Tentu saja, saya bisa karena saya Jason AI asisten virtual Anda. Apa yang bisa saya bantu?",
      'jam': "Sekarang pukul 7:30.",
      'cuaca': "Cuacanya cerah sekarang dan akan hujan pukul 5 sore.",
      'jadwal': "Hari ini Anda bebas, nikmati liburan Anda.",
      'terima kasih': "Tidak masalah, saya di sini untuk Anda.",

      'senang': "Saya ikut bahagia jika kamu bahagia.",
      'sedih': "Jangan bersedih lagi dan mari tertawa bersama aku."
    }
  };

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();
    _flutterTts.setPitch(4.0);
    _flutterTts.setSpeechRate(1.0);
  }

  void _handleCommand(String text) {
    print("Received text: $text");
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 1000), () {
      String response = "Sorry, I don't understand.";
      String lang = _detectLanguage(text);

      _commands[lang]?.forEach((command, resp) {
        if (text.toLowerCase().contains(command)) {
          response = resp;
        }
      });

      var sentimentResult = _analyzeSentiment(text, lang);
      var sentimentScore = sentimentResult['score'];
      print("Sentiment score: $sentimentScore");

      _speak(response, lang);
      setState(() {
        _conversation
            .add({"text": text, "isUser": true, "sentiment": sentimentScore});
        _conversation.add({"text": response, "isUser": false, "sentiment": 0});
      });
    });
  }

  String _detectLanguage(String text) {
    if (text.contains(RegExp(
        r'halo|apa kabar|bantu|jam berapa|cuaca|jadwal|terima kasih|baik|senang|bahagia|sedih|kesal|marah',
        caseSensitive: false))) {
      return 'indonesian';
    } else {
      return 'english';
    }
  }

  Map<String, dynamic> _analyzeSentiment(String text, String lang) {
    if (lang == 'indonesian') {
      final indonesianWords = text.toLowerCase().split(' ');
      int score = 0;

      for (var word in indonesianWords) {
        if (_indonesianPositiveWords.contains(word)) {
          score += 1;
        } else if (_indonesianNegativeWords.contains(word)) {
          score -= 1;
        }
      }

      return {'score': score};
    } else {
      return _sentiment.analysis(text);
    }
  }

  void _listen(bool isStart) async {
    if (isStart) {
      bool available = await _speech.initialize(
        onStatus: (val) => print('onStatus: $val'),
        onError: (val) => print('onError: $val'),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) {
            if (val.finalResult) {
              setState(() {
                _text = val.recognizedWords;
                _handleCommand(_text);
                _isListening = false;
                _speech.stop();
              });
            }
          },
          localeId: 'id-ID',
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  void _speak(String text, String lang) async {
    await _flutterTts.setLanguage(lang == 'indonesian' ? 'id-ID' : 'en-US');
    await _flutterTts.speak(text);
  }

  void _sendMessage() {
    String text = _textController.text;
    if (text.isNotEmpty) {
      _handleCommand(text);
      _textController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Jason AI',
          style: TextStyle(color: Colors.white, fontSize: 30),
        ),
        centerTitle: true,
        backgroundColor: Color.fromARGB(255, 0, 46, 52),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(
                "https://th.bing.com/th/id/OIP.H3Gr3JbIKmJzKJng9GS5kwAAAA?rs=1&pid=ImgDetMain"),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: _conversation.length,
                itemBuilder: (context, index) {
                  return ChatBubble(
                    message: _conversation[index]['text'],
                    isUser: _conversation[index]['isUser'],
                    sentiment: _conversation[index]['sentiment'],
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                      child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Color.fromARGB(255, 0, 46, 52),
                      hintText: "Type a message",
                      hintStyle: const TextStyle(color: Colors.white),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                    onSubmitted: (value) {
                      _sendMessage();
                    },
                  )),
                  const SizedBox(width: 8),
                  FloatingActionButton(
                    onPressed: _sendMessage,
                    backgroundColor: Color.fromARGB(255, 0, 255, 81),
                    child: const Icon(Icons.send),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton(
                    onPressed: () {
                      if (_isListening) {
                        _listen(false);
                      } else {
                        _listen(true);
                      }
                    },
                    backgroundColor: Color.fromARGB(255, 0, 255, 81),
                    child: Icon(
                        _isListening ? Icons.record_voice_over : Icons.mic),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isUser;
  final int sentiment;

  const ChatBubble(
      {super.key,
      required this.message,
      required this.isUser,
      required this.sentiment});

  @override
  Widget build(BuildContext context) {
    Color bubbleColor;

    if (isUser) {
      if (sentiment > 0) {
        bubbleColor = Colors.blue;
      } else if (sentiment < 0) {
        bubbleColor = Colors.red;
      } else {
        bubbleColor = Color.fromARGB(255, 0, 122, 92);
      }
    } else {
      bubbleColor = Color.fromARGB(255, 0, 46, 52);
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      margin: EdgeInsets.symmetric(vertical: 4),
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: EdgeInsets.all(10),
          child: Text(
            message,
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
