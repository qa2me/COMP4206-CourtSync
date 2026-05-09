import 'dart:io';
import 'dart:math';


enum MatchStatus { upcoming, ongoing, completed }
mixin Validator {
  
  void printLine() => print('------------------------------');
  bool isValidString(String value) => value.trim().isNotEmpty;
  bool isValidEmail(String email) => email.contains('@');
  bool isValidID(int id) => id > 0;
  String formatField(String label, dynamic value) =>
      '${label.padRight(14)}: $value';
}

class User with Validator {
  int _id;
  String _name;
  String _email;
  int _matchesPlayed;
  int _matchesWon;

  User({required int id,required String name,required String email,int matchesPlayed = 0,int matchesWon = 0,})  : _id = id,_name = name,_email = email,_matchesPlayed = matchesPlayed,_matchesWon = matchesWon;
  int get id => _id;
  String get name => _name;
  String get email => _email;
  int get matchesPlayed => _matchesPlayed;
  int get matchesWon => _matchesWon;

  set name(String v)=>_name =v;
  set email(String v)=>_email=v;

  void display() {
    printLine();
    print(formatField('User id',_id));
    print(formatField('Name',_name));
    print(formatField('Email',_email));
    print(formatField('Played',_matchesPlayed));
    print(formatField('Won',_matchesWon));
    printLine();
  }
}

class Court with Validator {
  int _id;
  String _name;
  String _location;
  double _x;
  double _y;
  Court({required int id,required String name,required String location,required double x,required double y,})  : _id = id,_name = name,_location = location,_x = x,_y = y;
  int get id => _id;
  String get name => _name;
  String get location => _location;
  double get x => _x;
  double get y => _y;

  set name(String v) => _name = v;
  set location(String v) => _location = v;

  void display(){
    printLine();
    print(formatField('Court id', _id));
    print(formatField('Name', _name));
    print(formatField('Location', _location));
    print(formatField('Coordinates', '($_x, $_y)'));
    printLine();
  }
}

class Match with Validator {
  int _id;
  int _player1ID;
  int _player2ID;
  int? _refereeID;
  String _score;
  MatchStatus _status;

  Match({required int id,required int player1ID,required int player2ID,int? refereeID,String score = 'N/A',MatchStatus status = MatchStatus.upcoming,})  : _id = id,_player1ID = player1ID,_player2ID = player2ID,_refereeID = refereeID,_score = score,_status = status;

  int get id => _id;
  int get player1ID => _player1ID;
  int get player2ID => _player2ID;
  int? get refereeID => _refereeID;
  String get score => _score;
  MatchStatus get status => _status;
  set score(String v) => _score = v;
  set status(MatchStatus v) => _status = v;
  void display() {
    printLine();
    print(formatField('Match id',_id));
    print(formatField('Player 1',_player1ID));
    print(formatField('Player 2',_player2ID));
    print(formatField('Referee',_refereeID ?? 'Not assigned'));
    print(formatField('Score',_score));
    print(formatField('Status',_status.name));
    printLine();
  }
}

List<User>users=[];
List<Court>courts=[];
List<Match>matches=[];
Map<int,User>userMap={};
Map<int,Court>courtMap={};
Map<int,Match>matchMap={};
final rng=Random();
int generateID(Set<int> existing){
  int id;
  do{
    id=100+rng.nextInt(900);
  }
  while(existing.contains(id));

  return id;
}

void seedData(){
  var u1=User(id:17,name:'Qais',email:'qais@gmail.com',matchesPlayed:32,matchesWon:16);
  var u2=User(id:901,name:'Osama',email:'testing@gmail.com',matchesPlayed:12,matchesWon:2);
  users.addAll([u1,u2]);
  userMap[17]=u1;
  userMap[901]=u2;

  var c1=Court(id:1,name:'Al-Qurm Court',location:'Muscat',x:22.3245, y:21.435);
  courts.add(c1);
  courtMap[1]=c1;

  var m1 =Match(id:1,player1ID:17,player2ID:901,refereeID:500,score:'6-2, 7-5',status:MatchStatus.completed);
  matches.add(m1);
  matchMap[1]=m1;}


String readString(String prompt){
  stdout.write(prompt);
  return stdin.readLineSync()?? '';}


int? readInt(String prompt){
  stdout.write(prompt);
  return int.tryParse(stdin.readLineSync()?? '');}


double? readDouble(String prompt){
  stdout.write(prompt);
  return double.tryParse(stdin.readLineSync()?? '');}


void displayAllUsers(){
  if (users.isEmpty){print('No users found.');return; }
  for (var u in users)u.display();}

void searchUser(){
  int? id=readInt('Enter User ID: ');
  if(id==null || !userMap.containsKey(id)){print('User not found.'); return; }
  userMap[id]!.display();
}
void addUser(){
  var temp=User(id: 1,name:'tmp', email:'tmp@tmp.com');
  try{
    String name = readString('Name  : ');
    String email = readString('Email : ');
    if (!temp.isValidString(name)) throw Exception('Name cannot be empty.');
    if (!temp.isValidEmail(email)) throw Exception('Invalid email address.');
    int id = generateID(userMap.keys.toSet());
    var user = User(id: id, name: name, email: email);
    users.add(user);
    userMap[id] = user;
    print('User added! id:$id');
  }
  catch(e){
    print('Error:$e');
  }
}
void deleteUser() {
  int? id = readInt('Enter User id to delete: ');
  if(id == null || !userMap.containsKey(id)) { print('User not found.'); return; }
  stdout.write('Are You Sure You Want To Delete "${userMap[id]!.name}"? (yes/no): ');
  String confirm = stdin.readLineSync() ?? '';
  if(confirm.toLowerCase() == 'yes') {
    users.removeWhere((u) => u.id == id);
    userMap.remove(id);
    print('User was deleted.');
  }
  else{
    print('Canceled.');
  }}
void displayAllCourts(){
  if(courts.isEmpty){print('Court was not Found!');return;
  }
  for(var c in courts)c.display();
}
void searchCourt(){
  int? id=readInt('Enter Court ID: ');
  if (id==null||!courtMap.containsKey(id)){print('Court not found.'); return;}
  courtMap[id]!.display();


}
void addCourt() {
  var temp = Court(id: 1, name: 'tmp', location: 'tmp', x: 0, y: 0);
  try {
    String name =readString('Court Name:');
    String loc=readString('Location:');
    double? x=readDouble('X Coord:');
    double? y=readDouble('Y Coord:');
    if (!temp.isValidString(name)) throw Exception('Court name cannot be empty.');
    if (x == null || y == null) throw Exception('Invalid coordinates.');
    int id = generateID(courtMap.keys.toSet());
    var court = Court(id: id, name: name,location:loc, x:x, y:y);
    courts.add(court);
    courtMap[id]=court;
    print('Court added! id:$id');
  }
  catch(e){
    print('Error:$e');
  }
}
void deleteCourt(){
  int? id = readInt('Enter the court id to delete:');
  if (id == null || !courtMap.containsKey(id)) { print('Court not found.'); return; }
  stdout.write('Delete "${courtMap[id]!.name}"?(yes/no):');
  String confirm = stdin.readLineSync() ?? '';
  if (confirm.toLowerCase()=='yes') {
    courts.removeWhere((c)=>c.id==id);
    courtMap.remove(id);
    print('Court deleted.');
  }
  else{
    print('Cancelled.');
  }
}
void displayAllMatches(){
  if (matches.isEmpty) { print('No matches found.'); return; }
  for (var m in matches) m.display();
}
void searchMatch(){
  int? id = readInt('Enter Match id: ');
  if (id == null || !matchMap.containsKey(id)) { print('Match not found.'); return; }
  matchMap[id]!.display();
}
void addMatch(){
  try {
    int? p1= readInt('Player 1 id:');
    int? p2 =readInt('Player 2 id:');
    if (p1 ==null || p2 == null || p1 == p2) throw Exception('Invalid player IDs.');
    if (!userMap.containsKey(p1) || !userMap.containsKey(p2)) throw Exception('One or both players not found.');
    int id =generateID(matchMap.keys.toSet());
    var match =Match(id: id, player1ID: p1, player2ID: p2);
    matches.add(match);
    matchMap[id] =match;
    print('Match added! id: $id');
  } catch (e){
    print('Error: $e');
  }
}
void deleteMatch() {
  int? id = readInt('Enter Match ID to delete:');
  if (id == null || !matchMap.containsKey(id)) { print('Match not found.'); return; }
  stdout.write('Delete match $id? (yes/no):');
  String confirm = stdin.readLineSync() ?? '';
  if (confirm.toLowerCase() == 'yes') {
    matches.removeWhere((m) => m.id == id);
    matchMap.remove(id);
    print('Match deleted.');
  } else {
    print('Cancelled.');
  }
}
void usersMenu(){
  while (true){
    print('\n\n--- Users Page ---');
    print('1.Show All Users');
    print('2.Search User');
    print('3.Add User');
    print('4.Delete User');
    print('0.Back');
    stdout.write('Choice:');
    switch (stdin.readLineSync()) {
      case '1': displayAllUsers(); break;
      case '2': searchUser(); break;
      case '3': addUser(); break;
      case '4': deleteUser(); break;
      case '0': return;
      default: print('Invalid option.');
    }
  }
}
void courtsMenu() {
  while (true) {
    print('\n\n--- Courts Page ---');
    print('1.Show All Courts');
    print('2.Search Court');
    print('3.Add Court');
    print('4.Delete Court');
    print('0.Back');
    stdout.write('Choice: ');
    switch (stdin.readLineSync()) {
      case '1': displayAllCourts(); break;
      case '2': searchCourt(); break;
      case '3': addCourt(); break;
      case '4': deleteCourt(); break;
      case '0': return;
      default: print('Invalid option.');
    }
  }
}
void matchesMenu(){
  while (true){
    print('\n--- Matches Page ---');
    print('1.Show All Matches');
    print('2.Search Match');
    print('3.Add Match');
    print('4.Delete Match');
    print('0.Back');
    stdout.write('Choice:');
    switch (stdin.readLineSync()) {
      case '1': displayAllMatches(); break;
      case '2': searchMatch(); break;
      case '3': addMatch(); break;
      case '4': deleteMatch(); break;
      case '0': return;
      default:print('Invalid option.');
    }
  }
}

void main(){
  seedData();
  print('Welcome to CourtSync!');
  while (true) {
    print('\n=== Main Menu ===');
    print('1.Users');
    print('2.Courts');
    print('3.Matches');
    print('0.Exit');
    stdout.write('Choice:');
    switch (stdin.readLineSync()) {
      case'1':usersMenu(); break;
      case'2':courtsMenu(); break;
      case'3':matchesMenu(); break;
      case'0':print('Salam!'); return;
      default:print('Invalid option.');
    }
  }
}