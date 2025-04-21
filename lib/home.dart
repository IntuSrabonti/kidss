import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'word.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Box<Word> _wordBox;
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
    _openHiveBox();
  }

  Future<void> _openHiveBox() async {
    _wordBox = await Hive.openBox<Word>('words');
    setState(() {});
  }

  Future<void> _addWord(BuildContext context) async {
    TextEditingController wordController = TextEditingController();
    TextEditingController definitionController = TextEditingController();

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Word'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: wordController,
                  decoration: const InputDecoration(labelText: 'Word'),
                ),
                TextField(
                  controller: definitionController,
                  decoration: const InputDecoration(labelText: 'Definition'),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Add'),
              onPressed: () {
                if (wordController.text.isNotEmpty &&
                    definitionController.text.isNotEmpty) {
                  final newWord = Word(
                    word: wordController.text,
                    definition: definitionController.text,
                  );
                  _wordBox.add(newWord);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _editWord(BuildContext context, int index) async {
    if (_wordBox.isEmpty) return;
    final wordToEdit = _wordBox.getAt(index);
    if (wordToEdit == null) return;

    TextEditingController wordController =
    TextEditingController(text: wordToEdit.word);
    TextEditingController definitionController =
    TextEditingController(text: wordToEdit.definition);

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Word'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: wordController,
                  decoration: const InputDecoration(labelText: 'Word'),
                ),
                TextField(
                  controller: definitionController,
                  decoration: const InputDecoration(labelText: 'Definition'),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Save'),
              onPressed: () {
                if (wordController.text.isNotEmpty &&
                    definitionController.text.isNotEmpty) {
                  final updatedWord = Word(
                    word: wordController.text,
                    definition: definitionController.text,
                  );
                  _wordBox.putAt(index, updatedWord);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _deleteWord(int index) {
    _wordBox.deleteAt(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vocabulary Practice'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by first letter',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          Expanded(
            child: ValueListenableBuilder<Box<Word>>(
              valueListenable: Hive.box<Word>('words').listenable(),
              builder: (context, box, _) {
                final allWords = box.values.toList();
                final filteredWords = _searchQuery.isEmpty
                    ? allWords
                    : allWords
                    .where((word) =>
                    word.word.toLowerCase().startsWith(_searchQuery))
                    .toList();

                if (filteredWords.isEmpty) {
                  return const Center(
                    child: Text(
                      'No matching words found. Try a different letter!',
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filteredWords.length,
                  itemBuilder: (context, index) {
                    final word = filteredWords[index];
                    final originalIndex = allWords.indexOf(word);
                    return Dismissible(
                      key: UniqueKey(),
                      onDismissed: (direction) {
                        _deleteWord(originalIndex);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${word.word} deleted')),
                        );
                      },
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20.0),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      child: ListTile(
                        title: Text(
                          word.word,
                          style:
                          const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(word.definition),
                        onTap: () {
                          _editWord(context, originalIndex);
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addWord(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    Hive.close();
    super.dispose();
  }
}