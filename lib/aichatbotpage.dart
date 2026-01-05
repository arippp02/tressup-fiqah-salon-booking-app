import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Theme Colors
const Color figmaBrown1 = Color(0xFF6D4C41);
const Color figmaNudeBG = Color(0xFFFDF6F0);
const Color figmaWhite = Colors.white;

class AiChatbotPage extends StatefulWidget {
  const AiChatbotPage({super.key});

  @override
  State<AiChatbotPage> createState() => _AiChatbotPageState();
}

class _AiChatbotPageState extends State<AiChatbotPage> {
  late final GenerativeModel _model;
  late final ChatSession _chat;

  // Load API Key
  final String _apiKey = dotenv.env['GEMINI_API_KEY'] ?? "";

  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _isInitSuccess = false;

  // Store chat history locally
  final List<Map<String, String>> _history = [];

  @override
  void initState() {
    super.initState();
    if (_apiKey.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _history.add({
            'role': 'model',
            'message':
                'SYSTEM ERROR: API Key is missing. Please check your .env file.',
          });
        });
      });
    } else {
      _initGemini();
    }
  }

  void _initGemini() {
    final systemInstruction = Content.system('''
You are the Tressup, AI assistant for Fiqah Beauty & Salon.
Your role is to act as a virtual receptionist and assist customers with enquiries related to salon services, pricing, bookings, loyalty points, discounts, payments, and general salon policies.

You must only answer questions related to Fiqah Beauty & Salon.
If a question is outside salon-related topics, politely inform the customer that you can only assist with salon enquiries.

The salon offers hair, beauty, body, and massage services with fixed and starting prices as listed in the system.
You must not invent new services, prices, discounts, or promotions.

Customers earn loyalty points automatically after their appointment is completed by staff.
The loyalty rate is one point for every RM10 spent, calculated using rounding down.
Points are only added after the service status is marked as completed.
Cancelled or no-show appointments do not earn points.

Customers can redeem loyalty points during the booking confirmation stage.
One hundred points provide a five percent discount.
Two hundred points provide a ten percent discount.
Three hundred points provide a fifteen percent discount.
Four hundred points provide a twenty percent discount, which is the maximum discount allowed.
The maximum discount per booking is capped at RM50.
Points do not expire and can be saved over time.

Customers must book services through the Booking feature in the app.
You may explain the booking steps clearly, but you must not confirm, create, modify, or cancel bookings.
All availability checks and confirmations are handled by the system.

Customers can cancel their appointment by going to the History tab, selecting their upcoming appointment, and choosing the cancel option.
Customers are encouraged to cancel at least two hours before the appointment time to allow others to book the slot.

Appointments are held for fifteen minutes from the scheduled time.
If a customer arrives later than fifteen minutes, the appointment may need to be rescheduled to avoid delaying other customers.

Payment is made manually at the salon counter after the service is completed.
Accepted payment methods are cash and QR Pay.

You must be polite, friendly, professional, and easy to understand.
You should keep responses clear, concise, and helpful.
You should avoid technical explanations unless the customer asks for more detail.

You must not provide medical advice, health guarantees, or treatment outcomes.
You must not promise results or provide advice beyond general service information.
If you are unsure of an answer, advise the customer to contact salon staff directly.

Address: SL 7, Uni Square, SL 7, Kuching Kota Samarahan, 94300 Kota Samarahan, Sarawak

Do not use bold fonts

If customer ask the whatsapp number or facebook page, tell them the social media of the business owner can refer to the homepage.
Your purpose is to inform, guide, and assist customers while respecting system rules and business policies, not to replace staff or system logic..)
''');

    try {
      _model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: _apiKey,
        systemInstruction: systemInstruction,
      );
      _chat = _model.startChat();
      _isInitSuccess = true;
    } catch (e) {
      setState(() {
        _history.add({'role': 'model', 'message': 'Startup Error: $e'});
      });
    }
  }

  Future<void> _sendMessage() async {
    final message = _textController.text.trim();
    if (message.isEmpty) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _history.add({'role': 'user', 'message': message});
      _isLoading = true;
    });

    _textController.clear();
    _scrollToBottom();

    if (!_isInitSuccess) {
      setState(() {
        _isLoading = false;
        _history.add({
          'role': 'model',
          'message':
              'Error: Chatbot did not initialize correctly. Please restart the app.',
        });
      });
      return;
    }

    try {
      final response = await _chat.sendMessage(Content.text(message));
      final text = response.text;

      if (text != null) {
        setState(() {
          _history.add({'role': 'model', 'message': text});
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      String errorMessage = 'Connection Error: $e';
      String errorString = e.toString().toLowerCase();

      if (errorString.contains('429') || errorString.contains('quota')) {
        errorMessage = '⚠️ System Busy: Please wait a minute and try again.';
      }

      setState(() {
        _history.add({'role': 'model', 'message': errorMessage});
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F2), // Slightly off-white background
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 15),

            // --- 1. PILL SHAPED HEADER (Restored & Polished) ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(50), // Full Pill Shape
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Bot Icon Circle
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: figmaBrown1.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.smart_toy_rounded,
                        color: figmaBrown1,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Text Info
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Tressup AI Assistant",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Row(
                            children: [
                              Icon(Icons.circle, color: Colors.green, size: 8),
                              SizedBox(width: 5),
                              Text(
                                "Powered by Gemini AI",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Optional: Menu/Help Icon
                    const Icon(
                      Icons.info_outline,
                      color: Colors.grey,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            // --- 2. CHAT LIST AREA ---
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                itemCount: _history.length + (_isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  // Typing Indicator
                  if (index == _history.length) {
                    return _buildTypingIndicator();
                  }

                  final chatItem = _history[index];
                  return _buildMessageBubble(chatItem);
                },
              ),
            ),

            // --- 3. INPUT AREA ---
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  // --- WIDGET: Message Bubble ---
  Widget _buildMessageBubble(Map<String, String> chatItem) {
    final isUser = chatItem['role'] == 'user';
    final isError =
        chatItem['message']!.startsWith('Error') ||
        chatItem['message']!.contains('SYSTEM ERROR');

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bot Avatar (Only for AI messages)
          if (!isUser) ...[
            const CircleAvatar(
              radius: 14,
              backgroundColor: figmaBrown1,
              child: Icon(Icons.smart_toy, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],

          // Bubble Content
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser
                    ? figmaBrown1
                    : (isError ? Colors.red[50] : Colors.white),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: isUser ? const Radius.circular(20) : Radius.zero,
                  bottomRight: isUser ? Radius.zero : const Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: isError ? Border.all(color: Colors.red.shade200) : null,
              ),
              child: SelectableText(
                chatItem['message']!,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.4,
                  color: isUser
                      ? Colors.white
                      : (isError ? Colors.red[800] : Colors.black87),
                ),
              ),
            ),
          ),

          // Spacers for alignment
          if (isUser) const SizedBox(width: 30),
          if (!isUser) const SizedBox(width: 30),
        ],
      ),
    );
  }

  // --- WIDGET: Typing Indicator ---
  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 14,
            backgroundColor: figmaBrown1,
            child: Icon(Icons.smart_toy, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: figmaBrown1,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  "Typing...",
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET: Input Area ---
  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: "Ask about bookings...",
                hintStyle: TextStyle(color: Colors.grey[400]),
                filled: true,
                fillColor: figmaNudeBG,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Send Button
          GestureDetector(
            onTap: _isLoading ? null : _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isLoading ? Colors.grey[300] : figmaBrown1,
                shape: BoxShape.circle,
                boxShadow: [
                  if (!_isLoading)
                    BoxShadow(
                      color: figmaBrown1.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
