import 'package:cloud_firestore/cloud_firestore.dart';
import 'person_model.dart';

class PersonRepository {
  final _collection = FirebaseFirestore.instance.collection('people');

  Stream<List<Person>> getPeople(String userId) {
    return _collection.where('userId', isEqualTo: userId).snapshots().map(
      (snapshot) => snapshot.docs.map((doc) => Person.fromFirestore(doc)).toList()
        ..sort((a, b) => a.name.compareTo(b.name)),
    );
  }

  Future<void> addPerson(Person person) async {
    await _collection.add(person.toFirestore());
  }

  Future<void> updatePerson(Person person) async {
    await _collection.doc(person.id).update(person.toFirestore());
  }

  Future<void> deletePerson(String personId) async {
    await _collection.doc(personId).delete();
  }

  Future<Person?> getPerson(String personId) async {
    final doc = await _collection.doc(personId).get();
    if (doc.exists) {
      return Person.fromFirestore(doc);
    }
    return null;
  }

  Future<void> updatePersonBalance(String personId, double newBalance) async {
    await _collection.doc(personId).update({
      'balance': newBalance,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }
} 