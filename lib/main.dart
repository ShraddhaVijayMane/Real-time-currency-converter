import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'currency_data.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(CurrencyConverterApp());
}

class CurrencyConverterApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Currency Converter',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: WelcomeScreen(),
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Image.asset(
            'assets/img6.jpg',
            fit: BoxFit.cover,
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                SizedBox(height: 20),
              ],
            ),
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CurrencyListScreen(),
                  ),
                );
              },
              child: Icon(Icons.arrow_forward),
            ),
          ),
        ],
      ),
    );
  }
}

class CurrencyListScreen extends StatefulWidget {
  @override
  _CurrencyListScreenState createState() => _CurrencyListScreenState();
}

class _CurrencyListScreenState extends State<CurrencyListScreen> {
  final String url = "https://api.exchangerate-api.com/v4/latest/USD";
  Map<String, dynamic> currencies = {};
  bool isLoading = true;
  String filter = ''; // Variable to hold the current search query

  @override
  void initState() {
    super.initState();
    fetchCurrencies();
  }

  Future<void> fetchCurrencies() async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() {
          currencies = json.decode(response.body)['rates'];
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load currency data');
      }
    } catch (e) {
      showErrorDialog('Failed to fetch data: ${e.toString()}');
    }
  }

  void showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void navigateToConverter() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CurrencyConverterScreen(currencies: currencies),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<String> filteredCurrencies = currencies.keys.where((currency) {
      // Filter currencies based on the search query and currency code or name
      return currency.toLowerCase().contains(filter.toLowerCase()) ||
          (currencyNames[currency] ?? '').toLowerCase().contains(filter.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Currency List'),
      ),
      backgroundColor: Color.fromARGB(255, 230, 226, 233), // Set the background color here
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Search',
                      hintText: 'Search by currency code or name',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) {
                      setState(() {
                        filter = value;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredCurrencies.length,
                    itemBuilder: (context, index) {
                      String currencyCode = filteredCurrencies[index];
                      String currencyName = currencyNames[currencyCode] ?? 'Unknown Currency';
                      return ListTile(
                        title: Text(
                          '$currencyCode - $currencyName',
                          style: TextStyle(
                            fontSize: 20, // Adjust the font size as needed
                            color: Color.fromARGB(255, 0, 0, 0), // Change the text color as needed
                          ),
                        ),
                        onTap: () {
                          navigateToConverter();
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: Positioned(
        bottom: 20,
        right: 20,
        child: FloatingActionButton(
          onPressed: navigateToConverter,
          child: Icon(Icons.arrow_forward),
        ),
      ),
    );
  }
}

class CurrencyConverterScreen extends StatefulWidget {
  final Map<String, dynamic> currencies;

  CurrencyConverterScreen({required this.currencies});

  @override
  _CurrencyConverterScreenState createState() => _CurrencyConverterScreenState();
}

class _CurrencyConverterScreenState extends State<CurrencyConverterScreen> {
  String? sourceCurrency;
  String? targetCurrency;
  String amount = '';
  String result = '';

  void convert() {
    if (sourceCurrency == null ||
        targetCurrency == null ||
        amount.isEmpty) {
      showErrorDialog('Please fill all fields');
      return;
    }

    if (!widget.currencies.containsKey(sourceCurrency) ||
        !widget.currencies.containsKey(targetCurrency)) {
      showErrorDialog('Invalid currency code');
      return;
    }

    try {
      double amountValue = double.parse(amount);
      double rate = widget.currencies[targetCurrency!] / widget.currencies[sourceCurrency!];
      double convertedAmount = amountValue * rate;

      setState(() {
        result = '$amount $sourceCurrency = ${convertedAmount.toStringAsFixed(2)} $targetCurrency';
      });
    } catch (e) {
      showErrorDialog('An error occurred. Please try again.');
    }
  }

  void clear() {
    setState(() {
      sourceCurrency = null;
      targetCurrency = null;
      amount = '';
      result = '';
    });
  }

  void showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void navigateToMoneyRecognition() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MoneyRecognitionScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Currency Converter'),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Image.asset(
            'assets/img5.jpg',
            fit: BoxFit.cover,
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: <Widget>[
                DropdownButton<String>(
                  value: sourceCurrency,
                  hint: Text('Enter your source currency', style: TextStyle(color: Color.fromARGB(255, 241, 239, 239))),
                  onChanged: (String? newValue) {
                    setState(() {
                      sourceCurrency = newValue!;
                    });
                  },
                  items: widget.currencies.keys.map<DropdownMenuItem<String>>(
                    (String value) => DropdownMenuItem<String>(
                      value: value,
                      child: Text('$value - ${currencyNames[value]}', style: TextStyle(color: Color.fromARGB(255, 8, 0, 0))),
                    ),
                  ).toList(),
                ),
                DropdownButton<String>(
                  value: targetCurrency,
                  hint: Text('Enter your target currency', style: TextStyle(color: Color.fromARGB(255, 250, 248, 248))),
                  onChanged: (String? newValue) {
                    setState(() {
                      targetCurrency = newValue!;
                    });
                  },
                  items: widget.currencies.keys.map<DropdownMenuItem<String>>(
                    (String value) => DropdownMenuItem<String>(
                      value: value,
                      child: Text('$value - ${currencyNames[value]}', style: TextStyle(color: Color.fromARGB(255, 20, 0, 0))),
                    ),
                  ).toList(),
                ),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    labelStyle: TextStyle(color: Color.fromARGB(255, 245, 240, 240)),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    amount = value;
                  },
                  style: TextStyle(color: Color.fromARGB(255, 8, 0, 0)),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: convert,
                  child: Text('Convert', style: TextStyle(color: Color.fromARGB(255, 0, 0, 0))),
                ),
                ElevatedButton(
                  onPressed: clear,
                  child: Text('Clear', style: TextStyle(color: Color.fromARGB(255, 0, 0, 0))),
                ),
                SizedBox(height: 24),
                Text(
                  result,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: navigateToMoneyRecognition,
              child: Icon(Icons.arrow_forward),
            ),
          ),
        ],
      ),
    );
  }
}

class MoneyRecognitionScreen extends StatefulWidget {
  @override
  _MoneyRecognitionScreenState createState() => _MoneyRecognitionScreenState();
}

class _MoneyRecognitionScreenState extends State<MoneyRecognitionScreen> {
  CameraController? _cameraController;
  bool isCameraInitialized = false;
  bool isCameraPreviewVisible = false;
  String recognizedText = '';
  String detectedCountry = 'Unknown Country';

  @override
  void initState() {
    super.initState();
  }

  Future<void> initializeCamera() async {
    final cameras = await availableCameras();
    final camera = cameras.first;

    _cameraController = CameraController(camera, ResolutionPreset.high);
    await _cameraController!.initialize();

    setState(() {
      isCameraInitialized = true;
    });
  }

  Future<void> recognizeTextFromImage() async {
    if (!_cameraController!.value.isInitialized) {
      return;
    }

    try {
      final image = await _cameraController!.takePicture();
      final inputImage = InputImage.fromFilePath(image.path);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final RecognizedText recognizedTextResult = await textRecognizer.processImage(inputImage);

      String detectedText = recognizedTextResult.text;
      String detectedCurrencySymbol = detectCurrencySymbol(detectedText);
      detectedCountry = getCountryFromCurrency(detectedCurrencySymbol);

      setState(() {
        recognizedText = detectedText;
      });

      textRecognizer.close();
    } catch (e) {
      showErrorDialog('Failed to recognize text: ${e.toString()}');
    }
  }

  String detectCurrencySymbol(String text) {
    RegExp regex = RegExp(r'([₹\$€£¥元])');
    Match? match = regex.firstMatch(text);

    if (match != null) {
      String currencySymbol = match.group(0)!;
      return currencySymbol;
    }

    return ''; // Return empty string if no currency symbol is detected
  }

  String getCountryFromCurrency(String currencySymbol) {
    Map<String, String> currencyToCountry = {
      '₹': 'India',
      '\$': 'United States',
      '€': 'Euro',
      '£': 'United Kingdom',
      '¥': 'Japan',
      '元': 'China',
      // Add more mappings as needed
    };
    return currencyToCountry[currencySymbol] ?? 'Unknown Country';
  }

  void showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void navigateToThankYouPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ThankYouScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Money Recognition'),
      ),
      body: isCameraPreviewVisible
          ? Stack(
              children: [
                CameraPreview(_cameraController!),
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: FloatingActionButton(
                    onPressed: recognizeTextFromImage,
                    child: Icon(Icons.camera_alt),
                  ),
                ),
                Positioned(
                  top: 20,
                  left: 20,
                  child: Container(
                    color: Colors.white,
                    padding: EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recognized Text:',
                          style: TextStyle(fontSize: 18, color: Colors.black),
                        ),
                        SizedBox(height: 8),
                        Text(
                          recognizedText,
                          style: TextStyle(fontSize: 16, color: Colors.black),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Detected Country:',
                          style: TextStyle(fontSize: 18, color: Colors.black),
                        ),
                        SizedBox(height: 8),
                        Text(
                          detectedCountry,
                          style: TextStyle(fontSize: 16, color: Colors.black),
                        ),
                        SizedBox(height: 16),
                        FloatingActionButton(
                          onPressed: navigateToThankYouPage,
                          child: Icon(Icons.arrow_forward),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : Center(
              child: FloatingActionButton(
                onPressed: () async {
                  await initializeCamera();
                  setState(() {
                    isCameraPreviewVisible = true;
                  });
                },
                child: Icon(Icons.camera),
              ),
            ),
    );
  }
}

class ThankYouScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Thank You'),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/img8.jpeg'),  // Replace with your own image asset path
            fit: BoxFit.cover,
          ),
        ),
        /*child: Center(
          child: Text(
            'Thank You for Using Our App!',
            style: TextStyle(fontSize: 24, color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),*/
      ),
    );
  }
}