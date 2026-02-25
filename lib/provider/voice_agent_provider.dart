import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';

enum VoiceAgentState {
  idle,
  listening,
  processing,
  speaking,
}

enum PaymentMethod {
  cashOnDelivery,
  wallet,
  card,
  upi,
}

class VoiceAgentProvider with ChangeNotifier {
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();

  VoiceAgentState _state = VoiceAgentState.idle;
  String _recognizedText = '';
  String _lastCommand = '';
  bool _isInitialized = false;
  bool _isListening = false;
  bool _isTtsActive = false;
  bool _isProcessingCommand = false;

  Function(String)? onCommandReady;

  VoiceAgentState get state => _state;
  String get recognizedText => _recognizedText;
  String get lastCommand => _lastCommand;
  bool get isListening => _isListening;
  bool get isInitialized => _isInitialized;

  // ══════════════════════════════════════════════════════════════════════════
  // INITIALIZATION - ANDROID OPTIMIZED
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('✅ Already initialized');
      return;
    }

    try {
      debugPrint('🔧 Initializing voice agent...');

      final micPermission = await Permission.microphone.request();
      if (!micPermission.isGranted) {
        debugPrint('❌ Microphone permission denied');
        return;
      }
      debugPrint('✅ Microphone permission granted');

      _isInitialized = await _speechToText.initialize(
        onError: (error) {
          debugPrint('❌ Speech error: ${error.errorMsg}');
          _handleSpeechError(error.errorMsg);
        },
        onStatus: (status) {
          debugPrint('📡 Speech status: $status');
          _handleStatusChange(status);
        },
        debugLogging: true,
      );

      if (!_isInitialized) {
        debugPrint('❌ Speech-to-Text initialization failed');
        return;
      }

      debugPrint('✅ Speech-to-Text initialized');

      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(0.8);
      await _flutterTts.setPitch(1.0);

      if (defaultTargetPlatform == TargetPlatform.android) {
        try {
          await _flutterTts.setEngine("com.google.android.tts");
          await _flutterTts.setSharedInstance(false);
        } catch (e) {
          debugPrint('⚠️ Could not set TTS engine: $e');
        }
      }

      _flutterTts.setCompletionHandler(() {
        debugPrint('🔊 TTS completed');
        _isTtsActive = false;
        if (_state == VoiceAgentState.speaking) {
          _state = VoiceAgentState.idle;
          notifyListeners();
        }
      });

      _flutterTts.setErrorHandler((msg) {
        debugPrint('⚠️ TTS error: $msg');
        _isTtsActive = false;
        if (_state == VoiceAgentState.speaking) {
          _state = VoiceAgentState.idle;
          notifyListeners();
        }
      });

      _flutterTts.setCancelHandler(() {
        debugPrint('🔊 TTS cancelled');
        _isTtsActive = false;
      });

      debugPrint('✅ Voice agent fully ready');
      notifyListeners();
    } catch (e, stack) {
      debugPrint('❌ Initialization error: $e');
      debugPrint('Stack: $stack');
      _isInitialized = false;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ERROR HANDLING
  // ══════════════════════════════════════════════════════════════════════════

  void _handleSpeechError(String errorMsg) {
    debugPrint('🔴 Speech Error Handler: $errorMsg');

    if (errorMsg.contains('error_no_match') ||
        errorMsg.contains('error_speech_timeout')) {
      debugPrint('⚠️ Transient error - keeping mic open');
      return;
    }

    if (errorMsg.contains('error_audio')) {
      debugPrint('⚠️ Audio error - stopping');
      if (_isListening) {
        _isListening = false;
        _state = VoiceAgentState.idle;
        notifyListeners();
      }
    }
  }

  void _handleStatusChange(String status) {
    debugPrint('📊 Status Change: $status');

    if (status == 'listening') {
      debugPrint('✅ Microphone is ACTIVE');
      _isListening = true;
      if (_state != VoiceAgentState.listening) {
        _state = VoiceAgentState.listening;
        notifyListeners();
      }
    }

    if (status == 'done') {
      debugPrint('✅ Speech recognition completed');
    }

    if (status == 'notListening' && !_isProcessingCommand) {
      debugPrint('⚠️ Mic stopped unexpectedly');
      _isListening = false;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // START LISTENING - ANDROID AUDIO ERROR FIX
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> startListening() async {
    if (!_isInitialized) {
      debugPrint('🔧 Not initialized, initializing now...');
      await initialize();
    }

    if (!_isInitialized) {
      debugPrint('❌ Cannot start - initialization failed');
      return;
    }

    if (_isListening || _isProcessingCommand) {
      debugPrint('⚠️ Already listening or processing, ignoring request');
      return;
    }

    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        debugPrint('═══════════════════════════════════════');
        debugPrint('🎤 STARTING MICROPHONE (Attempt ${retryCount + 1}/$maxRetries)');
        debugPrint('═══════════════════════════════════════');

        debugPrint('Step 1/7: NUCLEAR audio cleanup...');
        await _nuclearAudioCleanup();

        final waitTime = 2500 + (retryCount * 500);
        debugPrint('Step 2/7: Waiting ${waitTime}ms for audio release...');
        await Future.delayed(Duration(milliseconds: waitTime));

        debugPrint('Step 3/7: Force-stopping lingering recognition...');
        if (_speechToText.isListening) {
          debugPrint('⚠️ Still listening, forcing complete stop...');
          await _speechToText.cancel();
          await _speechToText.stop();
          await Future.delayed(const Duration(milliseconds: 800));
        }

        debugPrint('Step 4/7: Verifying speech initialization...');
        if (!_speechToText.isAvailable) {
          debugPrint('⚠️ Speech not available, re-initializing...');
          _isInitialized = false;
          await initialize();
          await Future.delayed(const Duration(milliseconds: 500));
        }

        debugPrint('Step 5/7: Clearing state...');
        _recognizedText = '';
        _isProcessingCommand = false;

        debugPrint('Step 6/7: Updating UI state...');
        _state = VoiceAgentState.listening;
        _isListening = true;
        notifyListeners();

        await Future.delayed(const Duration(milliseconds: 100));

        debugPrint('Step 7/7: Starting speech recognition...');

        final listenSuccess = await _speechToText.listen(
          onResult: (result) {
            _recognizedText = result.recognizedWords;
            debugPrint('🎤 Heard: "$_recognizedText" (final: ${result.finalResult})');
            notifyListeners();

            if (result.finalResult && !_isProcessingCommand) {
              debugPrint('✅ FINAL RESULT: "$_recognizedText"');
              _handleFinalResult();
            }
          },
          listenMode: stt.ListenMode.confirmation,
          pauseFor: const Duration(seconds: 10),
          listenFor: const Duration(seconds: 120),
          partialResults: true,
          cancelOnError: false,
          onSoundLevelChange: (level) {
            if (level > 0) {
              debugPrint('🔊 Sound detected: $level');
            }
          },
          localeId: 'en_US',
        );

        if (listenSuccess == true) {
          debugPrint('✅ Microphone is ACTIVE - Speak now!');
          debugPrint('📌 Will listen for up to 2 minutes or 10s pause');
          return;
        } else {
          debugPrint('❌ Listen returned: $listenSuccess (type: ${listenSuccess.runtimeType})');
          throw Exception('Speech recognition failed to start (returned $listenSuccess)');
        }

      } catch (e, stack) {
        debugPrint('❌ Error in startListening (attempt ${retryCount + 1}): $e');

        retryCount++;

        if (retryCount < maxRetries) {
          debugPrint('🔄 Retrying in ${1000 * retryCount}ms...');
          await Future.delayed(Duration(milliseconds: 1000 * retryCount));
        } else {
          debugPrint('❌ All retry attempts failed');
          debugPrint('Stack: $stack');
          _state = VoiceAgentState.idle;
          _isListening = false;
          _isProcessingCommand = false;
          notifyListeners();
        }
      }
    }
  }

  void _handleFinalResult() {
    _isProcessingCommand = true;
    _state = VoiceAgentState.processing;
    _isListening = false;
    notifyListeners();

    if (onCommandReady != null && _recognizedText.isNotEmpty) {
      debugPrint('📲 Calling onCommandReady with: "$_recognizedText"');
      onCommandReady!(_recognizedText);
    } else {
      debugPrint('⚠️ No callback or empty text');
      Future.delayed(const Duration(milliseconds: 500), () {
        if (_state == VoiceAgentState.processing) {
          _state = VoiceAgentState.idle;
          _isProcessingCommand = false;
          notifyListeners();
        }
      });
    }
  }

  Future<void> _nuclearAudioCleanup() async {
    try {
      debugPrint('🧹💥 Starting NUCLEAR audio cleanup...');

      if (_isTtsActive) {
        await _flutterTts.stop();
        _isTtsActive = false;
        debugPrint('  ✓ TTS stopped');
        await Future.delayed(const Duration(milliseconds: 500));
      }

      try {
        await _speechToText.cancel();
        debugPrint('  ✓ Speech cancelled (1)');
        await Future.delayed(const Duration(milliseconds: 300));

        await _speechToText.stop();
        debugPrint('  ✓ Speech stopped (2)');
        await Future.delayed(const Duration(milliseconds: 300));

        await _speechToText.cancel();
        debugPrint('  ✓ Speech force-cancelled (3)');
        await Future.delayed(const Duration(milliseconds: 300));
      } catch (e) {
        debugPrint('  ⚠️ Error during speech cleanup: $e');
      }

      _isListening = false;
      _isProcessingCommand = false;
      _isTtsActive = false;

      await Future.delayed(const Duration(milliseconds: 500));
      debugPrint('  ✓ Nuclear cleanup complete');

    } catch (e) {
      debugPrint('⚠️ Error during nuclear cleanup: $e');
    }
  }

  Future<void> _completeAudioCleanup() async {
    try {
      debugPrint('🧹 Starting complete audio cleanup...');

      if (_isTtsActive) {
        await _flutterTts.stop();
        _isTtsActive = false;
        debugPrint('  ✓ TTS stopped');
        await Future.delayed(const Duration(milliseconds: 300));
      }

      if (_speechToText.isListening) {
        await _speechToText.cancel();
        debugPrint('  ✓ Speech cancelled');
        await Future.delayed(const Duration(milliseconds: 200));
      }

      await _speechToText.stop();
      debugPrint('  ✓ Speech stopped');
      await Future.delayed(const Duration(milliseconds: 200));

      _isListening = false;
      _isProcessingCommand = false;

      debugPrint('  ✓ Audio cleanup complete');

    } catch (e) {
      debugPrint('⚠️ Error during audio cleanup: $e');
    }
  }

  Future<void> stopListening() async {
    if (!_isListening) {
      debugPrint('⚠️ Not listening, nothing to stop');
      return;
    }

    debugPrint('🛑 Stopping microphone...');
    try {
      await _speechToText.stop();
      await _speechToText.cancel();
      await Future.delayed(const Duration(milliseconds: 300));
    } catch (e) {
      debugPrint('⚠️ Error stopping: $e');
    }

    _isListening = false;
    _isProcessingCommand = false;

    if (_state == VoiceAgentState.listening) {
      _state = VoiceAgentState.idle;
    }

    notifyListeners();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TEXT-TO-SPEECH - IMPROVED
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> speak(String text) async {
    if (!_isInitialized) await initialize();

    try {
      debugPrint('🔊 Preparing to speak: "$text"');

      if (_speechToText.isListening || _isListening) {
        debugPrint('  🛑 Stopping microphone for TTS...');
        await _speechToText.cancel();
        await _speechToText.stop();
        _isListening = false;
        await Future.delayed(const Duration(milliseconds: 800));
      }

      await _flutterTts.stop();
      await Future.delayed(const Duration(milliseconds: 300));

      _state = VoiceAgentState.speaking;
      _isTtsActive = true;
      notifyListeners();

      debugPrint('🔊 Speaking now: "$text"');
      final result = await _flutterTts.speak(text);

      if (result == 1) {
        debugPrint('✅ TTS started successfully');
      } else {
        debugPrint('⚠️ TTS result: $result');
      }

      Future.delayed(const Duration(seconds: 10), () {
        if (_isTtsActive) {
          debugPrint('⚠️ TTS timeout - force cleanup');
          _isTtsActive = false;
          if (_state == VoiceAgentState.speaking) {
            _state = VoiceAgentState.idle;
            notifyListeners();
          }
        }
      });

    } catch (e) {
      debugPrint('❌ TTS error: $e');
      _state = VoiceAgentState.idle;
      _isTtsActive = false;
      notifyListeners();
    }
  }

  Future<void> stop() async {
    try {
      debugPrint('🛑 Complete stop requested');
      await _nuclearAudioCleanup();
      await Future.delayed(const Duration(milliseconds: 800));
    } catch (e) {
      debugPrint('⚠️ Stop error: $e');
    }

    _state = VoiceAgentState.idle;
    _isListening = false;
    _isProcessingCommand = false;
    notifyListeners();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // IMPROVED COMMAND PARSING - MORE FLEXIBLE
  // ══════════════════════════════════════════════════════════════════════════

  bool isAddToCartCommand(String command) {
    command = command.toLowerCase();

    // ✅ Handle variations: "add red dress", "add dress", "add to cart"
    final addPatterns = ['add', 'at'];
    final cartPatterns = ['cart', 'card', 'cut'];

    // Direct patterns
    if (command.contains('add to cart') ||
        command.contains('add to card') ||
        command.contains('add to cut')) {
      return true;
    }

    // "add X" or "at X" (where X is product name)
    for (var addWord in addPatterns) {
      if (command.startsWith(addWord) || command.contains(' $addWord ')) {
        // Check if it's NOT just "add" alone
        final withoutAdd = command.replaceAll(addWord, '').trim();
        if (withoutAdd.isNotEmpty && !withoutAdd.startsWith('dress')) {
          // If it has more words after "add", it's likely "add X to cart"
          return true;
        }
        // Or if it explicitly mentions cart
        for (var cartWord in cartPatterns) {
          if (command.contains(cartWord)) {
            return true;
          }
        }
      }
    }

    return false;
  }

  bool isViewCartCommand(String command) {
    command = command.toLowerCase();

    return command.contains('view cart') ||
        command.contains('show cart') ||
        command.contains('open cart') ||
        command.contains('my cart') ||
        command.contains('see cart') ||
        command.contains('go to cart') ||
        command == 'cart';
  }

  bool isRemoveFromCartCommand(String command) {
    command = command.toLowerCase();

    return (command.contains('remove') ||
        command.contains('delete') ||
        command.contains('take out')) &&
        (command.contains('cart') ||
            command.contains('from') ||
            command.contains('item'));
  }

  bool isCheckoutCommand(String command) {
    command = command.toLowerCase();

    return command.contains('checkout') ||
        command.contains('check out') ||
        command.contains('proceed') ||
        command.contains('place order') ||
        command.contains('buy') ||
        command.contains('purchase') ||
        command.contains('pay') ||
        command.contains('payment');
  }

  String parseProductName(String command) {
    command = command.toLowerCase().trim();

    // ✅ IMPROVED: Handle multiple patterns

    // Remove common command words
    final wordsToRemove = [
      'add', 'at', 'to', 'the', 'a', 'an', 'my',
      'in', 'please', 'cart', 'card', 'cut'
    ];

    for (var word in wordsToRemove) {
      command = command.replaceAll(RegExp('\\b$word\\b'), '');
    }

    // Clean up extra spaces
    command = command.replaceAll(RegExp(r'\s+'), ' ').trim();

    debugPrint('📦 Parsed product name: "$command"');
    return command;
  }

  String parseRemoveProductName(String command) {
    command = command.toLowerCase().trim();

    final wordsToRemove = [
      'remove', 'delete', 'take', 'out', 'from',
      'cart', 'the', 'my', 'please'
    ];

    for (var word in wordsToRemove) {
      command = command.replaceAll(RegExp('\\b$word\\b'), '');
    }

    command = command.replaceAll(RegExp(r'\s+'), ' ').trim();
    return command;
  }

  PaymentMethod? parsePaymentMethod(String command) {
    command = command.toLowerCase();

    debugPrint('💳 Parsing payment method from: "$command"');

    // Cash on Delivery patterns
    if (command.contains('cash on delivery') ||
        command.contains('cash delivery') ||
        command.contains('cod') ||
        command.contains('c o d') ||
        (command.contains('cash') && !command.contains('cashback'))) {
      debugPrint('✅ Detected: Cash on Delivery');
      return PaymentMethod.cashOnDelivery;
    }

    // Wallet patterns
    if (command.contains('wallet') ||
        command.contains('my balance') ||
        command.contains('balance')) {
      debugPrint('✅ Detected: Wallet');
      return PaymentMethod.wallet;
    }

    // UPI patterns
    if (command.contains('upi') ||
        command.contains('u p i') ||
        command.contains('google pay') ||
        command.contains('gpay') ||
        command.contains('phonepe') ||
        command.contains('phone pe') ||
        command.contains('paytm') ||
        command.contains('pay tm')) {
      debugPrint('✅ Detected: UPI');
      return PaymentMethod.upi;
    }

    // Card patterns
    if (command.contains('card') ||
        command.contains('debit') ||
        command.contains('credit')) {
      debugPrint('✅ Detected: Card');
      return PaymentMethod.card;
    }

    debugPrint('⚠️ No payment method detected');
    return null;
  }

  String getPaymentMethodName(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cashOnDelivery:
        return 'Cash on Delivery';
      case PaymentMethod.wallet:
        return 'Wallet';
      case PaymentMethod.card:
        return 'Card';
      case PaymentMethod.upi:
        return 'UPI';
    }
  }

  Map<String, dynamic> parseCommand(String command) {
    command = command.toLowerCase().trim();
    _lastCommand = command;

    debugPrint('🔍 Parsing command: "$command"');
    notifyListeners();

    // Check for add to cart
    if (isAddToCartCommand(command)) {
      final productName = parseProductName(command);
      debugPrint('🛒 Add to cart detected: "$productName"');
      return {
        'action': 'add_to_cart',
        'product': productName,
        'success': productName.isNotEmpty,
        'message': productName.isNotEmpty
            ? 'Adding $productName to cart'
            : 'Please specify product name',
      };
    }

    // Check for view cart
    if (isViewCartCommand(command)) {
      debugPrint('👁️ View cart detected');
      return {
        'action': 'view_cart',
        'success': true,
        'message': 'Opening cart',
      };
    }

    // Check for remove from cart
    if (isRemoveFromCartCommand(command)) {
      final productName = parseRemoveProductName(command);
      debugPrint('🗑️ Remove from cart detected: "$productName"');
      return {
        'action': 'remove_from_cart',
        'product': productName,
        'success': productName.isNotEmpty,
        'message': productName.isNotEmpty
            ? 'Removing $productName from cart'
            : 'Please specify which item to remove',
      };
    }

    // Check for checkout
    if (isCheckoutCommand(command)) {
      final paymentMethod = parsePaymentMethod(command);
      debugPrint('💰 Checkout detected with payment: $paymentMethod');
      return {
        'action': 'checkout',
        'paymentMethod': paymentMethod,
        'paymentMethodName':
        paymentMethod != null ? getPaymentMethodName(paymentMethod) : null,
        'success': true,
        'message': paymentMethod != null
            ? 'Processing checkout with ${getPaymentMethodName(paymentMethod)}'
            : 'Opening checkout',
      };
    }

    debugPrint('❓ Unknown command');
    return {
      'action': 'unknown',
      'success': false,
      'message': 'Command not recognized',
    };
  }

  void markCommandHandled() {
    debugPrint('✅ Command marked as handled');
    _state = VoiceAgentState.idle;
    _isProcessingCommand = false;
    notifyListeners();
  }

  void clearText() {
    _recognizedText = '';
    notifyListeners();
  }

  void reset() {
    _state = VoiceAgentState.idle;
    _recognizedText = '';
    _lastCommand = '';
    _isListening = false;
    _isProcessingCommand = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _speechToText.cancel();
    _flutterTts.stop();
    onCommandReady = null;
    super.dispose();
  }
}