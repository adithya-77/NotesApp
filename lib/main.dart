import 'package:english_words/english_words.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:path/path.dart';
//import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky, overlays: [SystemUiOverlay.bottom]);

  // Conditionally initialize sqflite_common_ffi for desktop platforms
  if (!kIsWeb && (Platform.isLinux || Platform.isMacOS || Platform.isWindows)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  runApp(MyApp());
}

class DBHelper {
  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await initDB();
    return _db!;
  }

  Future<Database> initDB() async {
    var documentsDirectory = await getApplicationDocumentsDirectory();
    var path = join(documentsDirectory.path, "FavoritesDB.db");
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  void _onCreate(Database db, int version) async {
    await db.execute(
        "CREATE TABLE favorites(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, content TEXT)");
  }

  Future<int> insertFavorite(Map<String, String> favorite) async {
    var dbClient = await database;
    return await dbClient.insert('favorites', favorite);
  }

 Future<List<Map<String, String>>> getFavorites() async {
    var dbClient = await database;
    List<Map<String, dynamic>> result = await dbClient.query('favorites');
    
    // Convert List<Map<String, dynamic>> to List<Map<String, String>>
    List<Map<String, String>> favorites = result.map((item) {
      return {
        'title': item['title'] as String,
        'content': item['content'] as String,
      };
    }).toList();
    
    return favorites;
  }


  Future<int> deleteFavorite(String title) async {
    var dbClient = await database;
    return await dbClient.delete('favorites', where: 'title = ?', whereArgs: [title]);
    
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Namer App',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        ),
        home: MyHomePage(),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  DBHelper dbHelper = DBHelper();
  var favorites = <Map<String, dynamic>>[];

  MyAppState() {
    fetchFavorites();
  }

  Future<void> addInput(String title, String content) async {
    await dbHelper.insertFavorite({'title': title, 'content': content});
    await fetchFavorites();
    notifyListeners();
  }
  Future<void> fetchFavorites() async {
    favorites = await dbHelper.getFavorites();
    notifyListeners();
  }

  /*void addInput(String title, String content) {
    favorites.add({'title': title, 'content': content});
    notifyListeners();
  }*/

  Future<void> removeFavorite(String title) async {
    await dbHelper.deleteFavorite(title);
    await fetchFavorites();
  }
}
  //var favorites = <WordPair>[];

  //void removeFavorite(String input) {
    //for (var w in favorites)
      //favorites.remove(input);
    //} else {
      //favorites.add(current);
    //}
    //notifyListeners();
  //}
//}

// ...

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedindex=0;
  @override
  Widget build(BuildContext context) {
    Widget page;
    switch (selectedindex) {
      case 0:
        page = InputPage();
        break;
      case 1:
        page = FavoritesPage();
        break;
      default:
        throw UnimplementedError('no widget for $selectedindex');
    }


    return Scaffold(
      body: Row(
        children: [
          SafeArea(
            child: NavigationRail(
              extended: false,
              destinations: [
                NavigationRailDestination(
                  icon: Icon(Icons.home),
                  label: Text('Home'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.note_sharp),
                  label: Text('My Notes'),
                ),
              ],
              selectedIndex: selectedindex,
              onDestinationSelected: (value) {
                setState(() {
                  selectedindex=value;
                });
              },
            ),
          ),
          Expanded(
            child: Container(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: page,
            ),
          ),
        ],
      ),
    );
  }
}


class InputPage extends StatelessWidget {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    //var pair = appState.current;

    IconData icon;
    //if (appState.favorites.contains(pair)) {
      icon = Icons.add;
    //} else {
      //icon = Icons.favorite_border;
    //}

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Enter the title',
                border: UnderlineInputBorder(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Enter your content',
                border: InputBorder.none,
              ),
            ),
          ),
          SizedBox(height: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                //icon: Icon(icon),
                onPressed: () {
                  appState.addInput(_titleController.text,_controller.text);
                  _titleController.clear();
                  _controller.clear();
                },
                child:Icon(icon),//icon: Icon(icon),
                //label: Text('Add'),
              ),
              /*SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  appState.toggleFavorite();
                },
                child: Text('Toggle Favorite'),
              ),*/
            ],
          ),
        ],
      ),
    );
  }
}
          
class FavoritesPage extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    if (appState.favorites.isEmpty) {
      return Center(
        child: Text('No Notes yet.'),
      );
    }

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Text('You have ${appState.favorites.length} Notes:'),
        ),
        for (var favorite in appState.favorites.reversed)
          ListTile(
            leading: Icon(Icons.favorite),
            title: Text(favorite['title']!),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.visibility),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(favorite['title']!),
                        content: Text(favorite['content']!),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text('Close'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () {
                    appState.removeFavorite(favorite['title']!);
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }
}
          /*padding: const EdgeInsets.all(20),
          child: Text('You have '
              '${appState.favorites.length} favorites:'),
        ),
        for (var pair in appState.favorites.reversed)
          ListTile(
            leading: Icon(Icons.favorite),
            title: Text(pair),
            trailing: IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                appState.removeFavorite(pair);
            //trailing: ElevatedButton(
              //onPressed: (){
                  //appState.favorites.remove(pair);
              },
              //child: Text('Delete'),
          ),
          ),
      ],
    );
  }

}

// ...*/
class BigCard extends StatelessWidget {
  const BigCard({
    super.key,
    required this.pair,
  });

  final WordPair pair;

  @override
  Widget build(BuildContext context) {
    var theme=Theme.of(context);
    var style = theme.textTheme.displayMedium!.copyWith(
      color: theme.colorScheme.onPrimary,
    );



    return Card(
      color: theme.colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Text(pair.asLowerCase, style: style),
      ),
    );
  }
}