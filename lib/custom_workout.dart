import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CustomWorkoutPage extends StatefulWidget {
  @override
  _CustomWorkoutPageState createState() => _CustomWorkoutPageState();
}

class _CustomWorkoutPageState extends State<CustomWorkoutPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = true;
  List<Map<String, dynamic>> _savedWorkouts = [];
  List<Map<String, dynamic>> _customRoutines = [];

  // Controllers for custom routine creation
  final TextEditingController _routineNameController = TextEditingController();
  final TextEditingController _setsController = TextEditingController();
  final TextEditingController _repsController = TextEditingController();
  final TextEditingController _restTimeController = TextEditingController();

  // Selected day for workout assignment
  String _selectedDay = 'Monday';
  final List<String> _daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _routineNameController.dispose();
    _setsController.dispose();
    _repsController.dispose();
    _restTimeController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final user = _auth.currentUser;
      if (user != null) {
        // Load saved workouts
        final savedWorkoutsSnapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('workouts')
            .where('workoutType', isEqualTo: 'favorite_exercise')
            .get();

        final savedWorkouts = savedWorkoutsSnapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            ...data,
          };
        }).toList();

        // Load custom routines
        final customRoutinesSnapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('custom_routines')
            .orderBy('createdAt', descending: true)
            .get();

        final customRoutines = customRoutinesSnapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            ...data,
          };
        }).toList();

        setState(() {
          _savedWorkouts = savedWorkouts;
          _customRoutines = customRoutines;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: backgroundColor,
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFf8f9fa),
      appBar: AppBar(
        title: Text(
          'Customize Your Workout',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: Color(0xFF6e9277),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading ? _buildLoadingState() : _buildMainContent(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6e9277)),
          ),
          SizedBox(height: 20),
          Text(
            'Loading your workout data...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          _buildHeaderSection(),
          SizedBox(height: 24),

          // Custom Routines Section
          _buildCustomRoutinesSection(),
          SizedBox(height: 24),

          // Available Exercises Section
          _buildAvailableExercisesSection(),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6e9277).withOpacity(0.1),
            Color(0xFF6e9277).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Color(0xFF6e9277).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(0xFF6e9277),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.fitness_center,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create Your Perfect Workout',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                        fontFamily: 'Poppins',
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Customize sets, reps, and rest time from your saved exercises',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomRoutinesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Your Custom Routines',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
                fontFamily: 'Poppins',
              ),
            ),
            Text(
              '${_customRoutines.length} routines',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        if (_customRoutines.isEmpty)
          _buildEmptyCustomRoutines()
        else
          _buildCustomRoutinesList(),
      ],
    );
  }

  Widget _buildEmptyCustomRoutines() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.fitness_center_outlined,
            size: 48,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'No Custom Routines Yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
              fontFamily: 'Poppins',
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Create your first custom routine from your saved exercises below',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomRoutinesList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: _customRoutines.length,
      itemBuilder: (context, index) {
        final routine = _customRoutines[index];
        return _buildCustomRoutineCard(routine);
      },
    );
  }

  Widget _buildCustomRoutineCard(Map<String, dynamic> routine) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(0xFF6e9277),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.fitness_center,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      routine['name'] ?? 'Untitled Routine',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                        fontFamily: 'Poppins',
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${routine['exercises']?.length ?? 0} exercises • ${routine['assignedDay'] ?? 'Not assigned'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    _editCustomRoutine(routine);
                  } else if (value == 'delete') {
                    _deleteCustomRoutine(routine['id']);
                  } else if (value == 'assign') {
                    _assignRoutineToDay(routine);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 16, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Edit', style: TextStyle(fontFamily: 'Poppins')),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'assign',
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today,
                            size: 16, color: Colors.green),
                        SizedBox(width: 8),
                        Text('Assign Day',
                            style: TextStyle(fontFamily: 'Poppins')),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 16, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(fontFamily: 'Poppins')),
                      ],
                    ),
                  ),
                ],
                child: Icon(Icons.more_vert, color: Colors.grey[600]),
              ),
            ],
          ),
          if (routine['exercises'] != null &&
              (routine['exercises'] as List).isNotEmpty)
            Container(
              margin: EdgeInsets.only(top: 12),
              child: Column(
                children: (routine['exercises'] as List)
                    .take(3)
                    .map<Widget>((exercise) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Color(0xFF6e9277),
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${exercise['name']} - ${exercise['sets']}x${exercise['reps']}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvailableExercisesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Available Exercises',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
                fontFamily: 'Poppins',
              ),
            ),
            Text(
              '${_savedWorkouts.length} exercises',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        if (_savedWorkouts.isEmpty)
          _buildEmptySavedWorkouts()
        else
          _buildSavedWorkoutsList(),
      ],
    );
  }

  Widget _buildEmptySavedWorkouts() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.favorite_border,
            size: 48,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'No Saved Exercises',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
              fontFamily: 'Poppins',
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Save exercises from the workout library to create custom routines',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedWorkoutsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: _savedWorkouts.length,
      itemBuilder: (context, index) {
        final workout = _savedWorkouts[index];
        return _buildSavedWorkoutCard(workout);
      },
    );
  }

  Widget _buildSavedWorkoutCard(Map<String, dynamic> workout) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Color(0xFF6e9277).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.fitness_center,
            color: Color(0xFF6e9277),
            size: 20,
          ),
        ),
        title: Text(
          workout['exerciseName'] ?? 'Unknown Exercise',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
            fontFamily: 'Poppins',
          ),
        ),
        subtitle: Text(
          workout['muscleGroup'] ?? 'Unknown Muscle Group',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontFamily: 'Poppins',
          ),
        ),
        trailing: ElevatedButton(
          onPressed: () => _addExerciseToRoutine(workout),
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF6e9277),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          child: Text(
            'Add to Routine',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              fontFamily: 'Poppins',
            ),
          ),
        ),
      ),
    );
  }

  void _addExerciseToRoutine(Map<String, dynamic> exercise) {
    _showCreateRoutineDialog(exercise);
  }

  void _showCreateRoutineDialog(Map<String, dynamic> exercise) {
    _routineNameController.clear();
    _setsController.text = '3';
    _repsController.text = '12';
    _restTimeController.text = '60';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Create Custom Routine',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _routineNameController,
                decoration: InputDecoration(
                  labelText: 'Routine Name',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Exercise: ${exercise['exerciseName']}',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Poppins',
                ),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _setsController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Sets',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _repsController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Reps',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              TextField(
                controller: _restTimeController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Rest Time (seconds)',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedDay,
                decoration: InputDecoration(
                  labelText: 'Assign to Day',
                  border: OutlineInputBorder(),
                ),
                items: _daysOfWeek.map((day) {
                  return DropdownMenuItem(
                    value: day,
                    child: Text(day),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedDay = value!;
                  });
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _createCustomRoutine(exercise);
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF6e9277),
              foregroundColor: Colors.white,
            ),
            child: Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _createCustomRoutine(Map<String, dynamic> exercise) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final routineData = {
        'name': _routineNameController.text.trim(),
        'exercises': [
          {
            'id': exercise['id'],
            'name': exercise['exerciseName'],
            'muscleGroup': exercise['muscleGroup'],
            'sets': int.tryParse(_setsController.text) ?? 3,
            'reps': int.tryParse(_repsController.text) ?? 12,
            'restTime': int.tryParse(_restTimeController.text) ?? 60,
          }
        ],
        'assignedDay': _selectedDay,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('custom_routines')
          .add(routineData);

      _showSnackBar('Custom routine created successfully!', Colors.green);
      _loadData();
    } catch (e) {
      print('Error creating custom routine: $e');
      _showSnackBar('Failed to create routine. Please try again.', Colors.red);
    }
  }

  void _editCustomRoutine(Map<String, dynamic> routine) {
    // TODO: Implement edit functionality
    _showSnackBar('Edit functionality coming soon!', Colors.blue);
  }

  Future<void> _deleteCustomRoutine(String routineId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('custom_routines')
          .doc(routineId)
          .delete();

      _showSnackBar('Routine deleted successfully!', Colors.green);
      _loadData();
    } catch (e) {
      print('Error deleting routine: $e');
      _showSnackBar('Failed to delete routine. Please try again.', Colors.red);
    }
  }

  void _assignRoutineToDay(Map<String, dynamic> routine) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Assign to Day',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
        content: DropdownButtonFormField<String>(
          value: routine['assignedDay'] ?? 'Monday',
          decoration: InputDecoration(
            labelText: 'Select Day',
            border: OutlineInputBorder(),
          ),
          items: _daysOfWeek.map((day) {
            return DropdownMenuItem(
              value: day,
              child: Text(day),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedDay = value!;
            });
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _updateRoutineDay(routine['id']);
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF6e9277),
              foregroundColor: Colors.white,
            ),
            child: Text('Assign'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateRoutineDay(String routineId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('custom_routines')
          .doc(routineId)
          .update({
        'assignedDay': _selectedDay,
      });

      _showSnackBar('Routine assigned to $_selectedDay!', Colors.green);
      _loadData();
    } catch (e) {
      print('Error updating routine day: $e');
      _showSnackBar('Failed to assign routine. Please try again.', Colors.red);
    }
  }
}
