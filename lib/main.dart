import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Home(),
    ),
  );
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _toDoControler = TextEditingController();

  List _toDoList = [];
  Map<String, dynamic> _lastRemoved;
  int _lastRemovedPosition;

  @override
  void initState() {
    super.initState();

    _readData().then(
      (data) {
        setState(() {
          _toDoList = json.decode(data);
        });
      },
    );
  }

  void _addToDo() {
    setState(
      () {
        //Criando map para armazenar tarefas
        Map<String, dynamic> newToDo = Map();
        //pegando o título da tarefa e apresentando na lista
        newToDo["tittle"] = _toDoControler.text;
        //zerar texto ao enviar nova tarefa
        _toDoControler.text = "";
        //assim que a tarefa é inserida a mesma deve aparecer como pendete
        newToDo["ok"] = false;
        _toDoList.add(newToDo);
        _saveData();
      },
    );
  }

  //função para refresh da tela
  Future<Null> _refresh() async {
    await Future.delayed(Duration(seconds: 1));

    setState(() {
      _toDoList.sort((a, b) {
        if (a["ok"] && !b["ok"]) {
          return 1;
        } else if (!a["ok"] && b["ok"]) {
          return -1;
        } else
          return 0;
      });
      _saveData();
    });
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("ToDo List"),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(15.0, 1.0, 7.0, 1.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _toDoControler,
                    decoration: InputDecoration(
                      labelText: "Task",
                      labelStyle: TextStyle(color: Colors.blueAccent),
                    ),
                  ),
                ),
                ElevatedButton(
                  child: Text(
                    "ADD",
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed: _addToDo,
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.builder(
                padding: EdgeInsets.only(top: 10.0),
                itemCount: _toDoList.length,
                itemBuilder: buildItem,
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget buildItem(context, index) {
    return Dismissible(
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      background: Container(
        color: Colors.red,
        child: Align(
          alignment: Alignment(-0.9, 0.0),
          child: Icon(
            Icons.delete,
            color: Colors.white,
          ),
        ),
      ),
      direction: DismissDirection.startToEnd,
      onDismissed: (direction) {
        setState(
          () {
            _lastRemoved = Map.from(_toDoList[index]);
            _lastRemovedPosition = index;
            _toDoList.removeAt(index);

            _saveData();

            final alert = SnackBar(
              content: Text("Task ${_lastRemoved["tittle"]} Removed!!"),
              action: SnackBarAction(
                label: "Undo",
                onPressed: () {
                  setState(() {
                    _toDoList.insert(_lastRemovedPosition, _lastRemoved);
                    _saveData();
                  });
                },
              ),
              duration: Duration(seconds: 2),
            );
            Scaffold.of(context).removeCurrentSnackBar();
            Scaffold.of(context).showSnackBar(alert);
          },
        );
      },
      child: CheckboxListTile(
        title: Text(
          _toDoList[index]["tittle"],
        ),
        value: _toDoList[index]["ok"],
        secondary: CircleAvatar(
          child: Icon(
            _toDoList[index]["ok"] ? Icons.check : Icons.error,
          ),
        ),
        onChanged: (check) {
          setState(
            () {
              _toDoList[index]["ok"] = check;
              _saveData();
            },
          );
        },
      ),
    );
  }

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/data.json");
  }

  //salvando os dados permanentemente
  Future<File> _saveData() async {
    String data = json.encode(_toDoList);
    final file = await _getFile();
    return file.writeAsString(data);
  }

  //lendo dados e retornando para UI
  Future<String> _readData() async {
    try {
      final file = await _getFile();
      return file.readAsString();
    } catch (e) {
      return null;
    }
  }
}
