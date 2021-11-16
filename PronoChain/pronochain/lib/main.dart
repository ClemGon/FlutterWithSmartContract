import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:pronochain/metamask.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:web3dart/web3dart.dart';
import 'package:syncfusion_flutter_sliders/sliders.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MetaMaskProvider()..init(),
      builder: (context, child) {
        return MaterialApp(
          title: 'Flutter Demo',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primarySwatch: Colors.blue,
            visualDensity: VisualDensity.adaptivePlatformDensity,
          ),
          home: const MyHomePage(title: 'PronoChain'),
        );
    });
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Client httpClient;
  late Web3Client ethClient;
  bool data = false;
  double _value = 10;
  int myAmount = 0;
  final myAdress = "0x5132E5BED48a8bfE744e594E73E45fcF869ce508";
  String txHash = "";
  var myData;

  @override
  void initState() {
    super.initState();
    httpClient = Client();
    ethClient = Web3Client(
        "https://rinkeby.infura.io/v3/44942613c9f245c4955bd504def74962",
        httpClient);
    getBalance(myAdress);
  }

  Future<DeployedContract> loadContract() async {
    String abi = await rootBundle.loadString("assets/abi.json");
    String contractAddress = "0x517a043629e5B0416E6F0F9DD8aBc92035fD9eC4";

    final contract = DeployedContract(ContractAbi.fromJson(abi, "PronoChain"),
        EthereumAddress.fromHex(contractAddress));
    return contract;
  }

  Future<List<dynamic>> query(String functionName, List<dynamic> args) async {
    final contract = await loadContract();
    final ethFunction = contract.function(functionName);
    final result = await ethClient.call(
        contract: contract, function: ethFunction, params: args);

    return result;
  }

  Future<void> getBalance(String targetAdress) async {
    //EthereumAddress address = EthereumAddress.fromHex(targetAdress);
    List<dynamic> result = await query("getBalance", []);

    myData = result[0];
    data = true;
    print("Get Balance");
    setState(() {});
  }

  Future<String> submit(String functionName, List<dynamic> args) async {
    EthPrivateKey credentials = EthPrivateKey.fromHex(
        "4863dc55f175bb35a998f91a344581e1019dbe51cf78936951fb6f6dea3501c5");

    DeployedContract contract = await loadContract();
    final ethFunction = contract.function(functionName);
    final result = await ethClient.sendTransaction(
      credentials,
      Transaction.callContract(
          contract: contract, function: ethFunction, parameters: args),
      fetchChainIdFromNetworkId: true,
      chainId: null,
    );

    return result;
  }

  Future<String> sendCoin() async {
    var bigAmount = BigInt.from(myAmount);

    var response = await submit("depositBalance", [bigAmount]);

    print("Deposited");
    txHash = response;
    setState(() {});
    return response;
  }

  Future<String> withdrawCoin() async {
    var bigAmount = BigInt.from(myAmount);

    var response = await submit("withDrawBalance", [bigAmount]);

    print("withdraw");
    txHash = response;
    setState(() {});
    return response;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Vx.gray300,
      body: ZStack([
        VxBox()
            .blue600
            .size(context.screenWidth, context.percentHeight * 30)
            .make(),
        VStack([
          (context.percentHeight * 10).heightBox,
          "PRONOCHAIN".text.xl4.white.bold.center.makeCentered().py16(),
          (context.percentHeight * 5).heightBox,
          VxBox(
                  child: VStack([
            "Balance".text.gray700.xl2.semiBold.makeCentered(),
            10.heightBox,
            data
                ? "\$${myData}".text.bold.xl6.makeCentered().shimmer()
                : CircularProgressIndicator().centered()
          ]))
              .p16
              .white
              .size(context.screenWidth, context.percentHeight * 18)
              .rounded
              .shadowXl
              .make()
              .p16(),
          30.heightBox,
          SfSlider(
            value: _value,
            min: 0,
            max: 100,
            interval: 10,
            showLabels: true,
            showTicks: true,
            enableTooltip: true,
            onChanged: (newValue) {
              setState(() {
                _value = newValue;
                myAmount = newValue.toInt();
                print(myAmount);
              });
            },
          ),
          HStack(
            [
              TextButton(
                  onPressed: () => getBalance(myAdress),
                  child: const Text('Refresh')),
              TextButton(
                  onPressed: () => sendCoin(), child: const Text('Deposit')),
              TextButton(
                  onPressed: () => withdrawCoin(),
                  child: const Text('Withdraw')),
            ],
            alignment: MainAxisAlignment.spaceAround,
            axisSize: MainAxisSize.max,
          ).p16(),
          if (txHash != "") txHash.text.black.makeCentered().p16()
        ]),
      ]),
    );
  }
}
