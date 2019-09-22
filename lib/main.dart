import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:geolocator/geolocator.dart';

void main() =>
    runApp(MaterialApp(home: Home(), debugShowCheckedModeBanner: false));

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _toDoController = TextEditingController();
  List _toDoList=[];
  int _lastRemovedPosition;
  Map<String,dynamic> _lastRemoved;
  String latitude;
  String longitude;


  @override
  void initState(){
    super.initState();
    _readData().then((data){
      setState(() {
        _toDoList=json.decode(data);
      });
    });
  }

  void _addToDo(){
    setState(() {
      _gpsLocation();
      Map<String, dynamic> newToDo=Map();
      _toDoController.text=latitude+longitude;
      newToDo['title']=_toDoController.text;
      _toDoController.text='';
      newToDo['ok']=false;
      _toDoList.add(newToDo);
      _saveData();
    });
  }
  void _gpsLocation ()async{
    Position position = await Geolocator().getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    print(position);
    this.latitude=position.latitude.toString();
    this.longitude=position.longitude.toString();
  }

  Future<Null> _refresh()async{
    await Future.delayed(Duration(seconds: 1));
    setState(() {
      _toDoList.sort((a,b){
        if (a['ok']&& !b['ok']) return 1;
        else if(!a['ok']&& b['ok']) return -1;
        else return 0;
      });
    });
    return null;
  }
  /*_gpsLocation()async{
    Position position = await Geolocator().getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    return position;
  }*/
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Histório de Localização GPS"),
        backgroundColor: Colors.lightBlue,
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.fromLTRB(17, 1, 1, 17),
            child: Row(
              children: <Widget>[
                Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                          labelText: "Localização Atual",
                          labelStyle: TextStyle(color: Colors.lightBlue)),
                      controller: _toDoController,
                    )
                ),
                RaisedButton(
                  color: Colors.lightBlue,
                  child: Text("Salvar"),
                  textColor: Colors.white,
                  onPressed: () {
                    _addToDo();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.builder(
                  padding: EdgeInsets.only(top: 10),
                  itemCount: _toDoList.length,
                  itemBuilder: buildItem),
            ),
          ),
        ],
      ),
    );
  }
  Widget buildItem(context, index) {
    return Dismissible(
        key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
        background: Container(
          color: Colors.redAccent,
          child: Align(
            alignment: Alignment(-0.9, 0),
            child: Icon(
              Icons.delete,
              color: Colors.white,
            ),
          ),
        ),
        direction: DismissDirection.startToEnd,
        child: CheckboxListTile(
          title: Text(_toDoList[index]['title']),
          value: _toDoList[index]['ok'],
          onChanged: (c) {
            setState(() {
              _toDoList[index]['ok'] = c;
              _saveData();
            });
          },
          secondary: CircleAvatar(
              child: Icon(_toDoList[index]['ok']==true ?Icons.check:Icons.warning)
          ),
        ),
        onDismissed: (direction) {
          setState(() {
            _lastRemoved = Map.from(_toDoList[index]);
            _lastRemovedPosition = index;
            _toDoList.removeAt(index);
            _saveData();
            final Snack = SnackBar(
              content: Text("Localização${_lastRemoved['title']} removida"),
              action: SnackBarAction(
                  label: "Desfazer",
                  onPressed: () {
                    _toDoList.insert(_lastRemovedPosition, _lastRemoved);
                    _saveData();
                  }
              ),
              duration: Duration(seconds: 3),
            );
            Scaffold.of(context).showSnackBar(Snack);
          });
        }
    );
  }
  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/gps.json");
  }

  /*Future<File> _saveData() async {
    String data = json.encode(_toDoList);
    final file = await _getFile();
    return file.writeAsString(data);
  }*/

  Future<File> _saveData() async {
    String data = json.encode(_toDoList);
    final file = await _getFile();
    return file.writeAsString(data);
  }

  Future<String> _readData() async {
    try {
      final file = await _getFile();
      return file.readAsString();
    } catch (e) {
      return null;
    }
  }

}
