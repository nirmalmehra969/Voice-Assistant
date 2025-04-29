import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'pallete.dart';
import 'openai_service.dart';
import 'services/logger_service.dart';
import 'animations/animation_configs.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final speechToText = SpeechToText();
  final flutterTts = FlutterTts();
  String lastWords = '';
  final OpenAIService openAIService = OpenAIService();
  bool isLoading = false;
  String? generatedImageUrl;
  String? generatedContent;
  bool isDarkMode = false;
  String currentTheme = 'Default';
  String selectedLanguage = 'English';
  bool pushNotifications = true;
  bool soundEnabled = true;
  bool vibrationEnabled = true;
  final TextEditingController _searchController = TextEditingController();
  int selectedAnimationIndex = 0;

  @override
  void initState() {
    super.initState();
    initSpeechToText();
    initTextToSpeech();
  }

  Future<void> initTextToSpeech() async {
    await flutterTts.setSharedInstance(true);
    setState(() {});
  }

  Future<void> initSpeechToText() async {
    try {
      await speechToText.initialize(
        onError: (error) {
          LoggerService.error("Speech to text error: $error");
          setState(() {
            isLoading = false;
          });
        },
        onStatus: (status) {
          LoggerService.info("Speech to text status: $status");
          if (status == 'done' && lastWords.isNotEmpty) {
            // Process the speech input when status is 'done'
            processSpeechResult();
          }
        },
        debugLogging: true,
      );
      setState(() {});
    } catch (e) {
      LoggerService.error("Error initializing speech to text: $e");
    }
  }

  Future<void> processSpeechResult() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Check if the user is asking about the assistant's identity
      if (lastWords.toLowerCase().contains('who are you') ||
          lastWords.toLowerCase().contains('what is your name') ||
          lastWords.toLowerCase().contains('what are you')) {
        setState(() {
          generatedContent =
              "I am Nirmal Mehra AI, your intelligent virtual assistant. I'm here to help you with information, answer questions, generate images, and assist you with various tasks. How can I help you today?";
          generatedImageUrl = null;
          if (generatedContent != null) {
            systemSpeak(generatedContent!);
          }
          isLoading = false;
        });
        return;
      }

      // For all other queries, proceed with the OpenAI API call
      final response = await openAIService.isArtPromptAPI(lastWords);
      LoggerService.info("OpenAI response: $response");

      setState(() {
        if (response.startsWith('http')) {
          generatedImageUrl = response;
          generatedContent = null;
        } else {
          generatedContent = response;
          generatedImageUrl = null;
          if (response.isNotEmpty && !response.contains('error')) {
            systemSpeak(response);
          }
        }
        isLoading = false;
      });
    } catch (e) {
      LoggerService.error("Error processing response: $e");
      setState(() {
        isLoading = false;
        generatedContent = "Sorry, there was an error processing your request.";
      });
    }
  }

  Future<void> startListening() async {
    try {
      await speechToText.listen(
        onResult: onSpeechResult,
        listenFor: Duration(seconds: 30),
        localeId: 'en_US',
        cancelOnError: true,
        partialResults: true,
      );
      setState(() {});
    } catch (e) {
      LoggerService.error("Error starting listening: $e");
    }
  }

  Future<void> stopListening() async {
    await speechToText.stop();
    setState(() {});
  }

  void onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      if (result.finalResult) {
        lastWords = result.recognizedWords;
        LoggerService.info("Final speech result: $lastWords");
      }
    });
  }

  Future<void> systemSpeak(String content) async {
    try {
      LoggerService.info("Speaking: $content");
      if (content.isNotEmpty) {
        await flutterTts.setLanguage("en-US");
        await flutterTts.setPitch(1.0);
        await flutterTts.setSpeechRate(0.5);
        await flutterTts.speak(content);
      }
    } catch (e) {
      LoggerService.error("Error in TTS: $e");
    }
  }

  Future<void> processTextSearch(String searchText) async {
    if (searchText.trim().isEmpty) return;

    setState(() {
      isLoading = true;
      lastWords = searchText;
    });

    try {
      final response = await openAIService.isArtPromptAPI(searchText);
      LoggerService.info("OpenAI response: $response");

      setState(() {
        if (response.startsWith('http')) {
          generatedImageUrl = response;
          generatedContent = null;
        } else {
          generatedContent = response;
          generatedImageUrl = null;
          if (response.isNotEmpty && !response.contains('error')) {
            systemSpeak(response);
          }
        }
        isLoading = false;
      });
    } catch (e) {
      LoggerService.error("Error processing text search: $e");
      setState(() {
        isLoading = false;
        generatedContent = "Sorry, there was an error processing your request.";
      });
    }
  }

  void _showAnimationSelector(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Select Background Animation'),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: ListView.builder(
                itemCount: AIAnimations.animations.length,
                itemBuilder:
                    (context, index) => Card(
                      child: ListTile(
                        leading: Icon(
                          Icons.animation,
                          color:
                              selectedAnimationIndex == index
                                  ? Theme.of(context).primaryColor
                                  : null,
                        ),
                        title: Text(AIAnimations.animations[index].name),
                        subtitle: Text(
                          AIAnimations.animations[index].description,
                        ),
                        selected: selectedAnimationIndex == index,
                        onTap: () {
                          setState(() {
                            selectedAnimationIndex = index;
                          });
                          Navigator.pop(context);
                        },
                      ),
                    ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final safeAnimationIndex = selectedAnimationIndex.clamp(
      0,
      AIAnimations.animations.length - 1,
    );
    return MaterialApp(
      theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      home: AIAnimations.animations[safeAnimationIndex].builder(
        Scaffold(
          appBar: AppBar(
            title: const Text('Nirmal Mehra AI'),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: Builder(
              builder:
                  (context) => IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  ),
            ),
          ),
          drawer: Drawer(
            child: Column(
              children: [
                Container(
                  height: 180,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.deepPurple,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.2),
                        ),
                        child: const Icon(
                          Icons.psychology,
                          size: 35,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Nirmal Mehra AI',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      ListTile(
                        leading: const Icon(Icons.add_circle_outline),
                        title: const Text('New Chat'),
                        onTap: () {
                          Navigator.pop(context);
                          setState(() {
                            generatedContent = null;
                            generatedImageUrl = null;
                            lastWords = '';
                          });
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.dark_mode),
                        title: const Text('Theme Mode'),
                        trailing: Switch(
                          value: false,
                          onChanged: (bool value) {
                            // Implement theme switching
                          },
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.animation),
                        title: const Text('Background Animation'),
                        subtitle: const Text('Neural Network'),
                        onTap: () {
                          Navigator.pop(context);
                          _showAnimationSelector(context);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.color_lens),
                        title: const Text('Appearance'),
                        onTap: () {
                          Navigator.pop(context);
                          // Implement appearance settings
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.language),
                        title: const Text('Language'),
                        onTap: () {
                          Navigator.pop(context);
                          // Implement language selection
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.notifications),
                        title: const Text('Notifications'),
                        onTap: () {
                          Navigator.pop(context);
                          // Implement notification settings
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.security),
                        title: const Text('Privacy & Security'),
                        onTap: () {
                          Navigator.pop(context);
                          // Implement privacy settings
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.history),
                        title: const Text('Chat History'),
                        onTap: () {
                          Navigator.pop(context);
                          // Implement chat history
                        },
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Version 1.0.0',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Center(
                          child: ZoomIn(
                            child: Image.asset(
                              'assets/images/virtualassistant1.png',
                              height: 150,
                              width: 150,
                            ),
                          ),
                        ),
                        FadeInRight(
                          child: Visibility(
                            visible: generatedImageUrl == null,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              margin: const EdgeInsets.symmetric(
                                horizontal: 40,
                              ).copyWith(top: 10),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Pallete.borderColor,
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(
                                  20,
                                ).copyWith(topLeft: Radius.zero),
                              ),
                              constraints: BoxConstraints(
                                minHeight:
                                    generatedContent == null
                                        ? 100 // Smaller height when no content
                                        : MediaQuery.of(context).size.height *
                                            0.6, // Larger height with content
                                maxHeight:
                                    generatedContent == null
                                        ? 100 // Smaller height when no content
                                        : MediaQuery.of(context).size.height *
                                            0.6, // Larger height with content
                              ),
                              child: SingleChildScrollView(
                                child: Text(
                                  generatedContent == null
                                      ? 'Hello, I am Nirmal Mehra AI. How can I assist you today?'
                                      : generatedContent!,
                                  style: TextStyle(
                                    fontFamily: 'Cera Pro',
                                    fontSize:
                                        generatedContent == null ? 20 : 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (generatedImageUrl != null)
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                20,
                              ).copyWith(topLeft: Radius.zero),
                              child: Image.network(generatedImageUrl!),
                            ),
                          ),
                        Visibility(
                          visible:
                              generatedContent == null &&
                              generatedImageUrl == null,
                          child: Column(
                            children: [
                              const SizedBox(height: 10),
                              Container(
                                margin: EdgeInsets.only(right: 82),
                                child: SlideInLeft(
                                  child: const Text(
                                    'Here are a few features',
                                    style: TextStyle(
                                      fontFamily: 'Cera Pro',
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color.fromARGB(255, 42, 101, 150),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              SlideInLeft(
                                delay: const Duration(milliseconds: 200),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 10,
                                  ),
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 40,
                                  ).copyWith(top: 10),
                                  decoration: BoxDecoration(
                                    color: Pallete.firstSuggestionBoxColor,
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: const Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'ChatGPT',
                                        style: TextStyle(
                                          fontFamily: 'Cera Pro',
                                          color: Pallete.mainFontColor,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'A smarter way to stay organized and informed with ChatGPT',
                                        style: TextStyle(
                                          fontFamily: 'Cera Pro',
                                          color: Pallete.mainFontColor,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SlideInLeft(
                                delay: const Duration(milliseconds: 400),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 10,
                                  ),
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 40,
                                  ).copyWith(top: 10),
                                  decoration: BoxDecoration(
                                    color: Pallete.secondSuggestionBoxColor,
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: const Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Dall-E',
                                        style: TextStyle(
                                          fontFamily: 'Cera Pro',
                                          color: Pallete.mainFontColor,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'Get inspired and stay creative with your personal assistant powered by Dall-E',
                                        style: TextStyle(
                                          fontFamily: 'Cera Pro',
                                          color: Pallete.mainFontColor,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SlideInLeft(
                                delay: const Duration(milliseconds: 600),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 10,
                                  ),
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 40,
                                  ).copyWith(top: 10),
                                  decoration: BoxDecoration(
                                    color: Pallete.thirdSuggestionBoxColor,
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: const Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Smart Voice Assistant',
                                        style: TextStyle(
                                          fontFamily: 'Cera Pro',
                                          color: Pallete.mainFontColor,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'Get the best of both worlds with a voice assistant powered by Dall-E and ChatGPT',
                                        style: TextStyle(
                                          fontFamily: 'Cera Pro',
                                          color: Pallete.mainFontColor,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                    left: 16,
                    right: 16,
                    top: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  style: const TextStyle(color: Colors.white),
                                  maxLines: null,
                                  keyboardType: TextInputType.multiline,
                                  textInputAction: TextInputAction.newline,
                                  decoration: const InputDecoration(
                                    hintText: 'Type your message...',
                                    hintStyle: TextStyle(color: Colors.white70),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 10,
                                    ),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.send,
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  if (_searchController.text.isNotEmpty) {
                                    processTextSearch(_searchController.text);
                                    _searchController.clear();
                                    FocusScope.of(context).unfocus();
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ZoomIn(
                        child: FloatingActionButton(
                          backgroundColor: const Color.fromARGB(
                            255,
                            117,
                            197,
                            213,
                          ),
                          onPressed: () async {
                            FocusScope.of(context).unfocus();
                            await flutterTts.stop();
                            if (await speechToText.hasPermission &&
                                speechToText.isNotListening) {
                              setState(() {
                                generatedContent = null;
                                generatedImageUrl = null;
                                lastWords = '';
                              });
                              await startListening();
                            } else if (speechToText.isListening) {
                              await stopListening();
                              if (lastWords.isNotEmpty) {
                                await processSpeechResult();
                              }
                            } else {
                              initSpeechToText();
                            }
                          },
                          child: Icon(
                            speechToText.isListening ? Icons.stop : Icons.mic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          resizeToAvoidBottomInset: true,
          floatingActionButton: null,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
