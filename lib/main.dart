import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'image_provider_helper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  }
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppController()..initialize(),
      child: const NutritionFitnessApp(),
    ),
  );
}

class NutritionFitnessApp extends StatelessWidget {
  const NutritionFitnessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AI Calorie Tracker',
      themeMode: ThemeMode.system,
      theme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        brightness: Brightness.light,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: const HomeShell(),
    );
  }
}

enum Gender { male, female }

enum FitnessGoal { loseFat, maintainWeight, gainMuscle, improveFitness }

enum ActivityLevel {
  sedentary,
  lightlyActive,
  moderatelyActive,
  veryActive,
  athlete,
}

enum MealCategory { breakfast, lunch, dinner, snacks }

enum TrainingLevel { beginner, intermediate, advanced }

extension EnumLabel on Enum {
  String get label {
    final raw = name;
    final withSpaces = raw.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (m) => ' ${m.group(1)}',
    );
    return '${withSpaces[0].toUpperCase()}${withSpaces.substring(1)}';
  }
}

class Profile {
  Profile({
    this.id,
    required this.name,
    required this.gender,
    required this.age,
    required this.weightKg,
    required this.heightCm,
    required this.goal,
    required this.activityLevel,
    required this.trainDaysPerWeek,
    required this.minutesPerWorkout,
    required this.cardioSessionsPerWeek,
    required this.dailySteps,
  });

  final int? id;
  final String name;
  final Gender gender;
  final int age;
  final double weightKg;
  final double heightCm;
  final FitnessGoal goal;
  final ActivityLevel activityLevel;
  final int trainDaysPerWeek;
  final int minutesPerWorkout;
  final int cardioSessionsPerWeek;
  final int dailySteps;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'gender': gender.name,
      'age': age,
      'weightKg': weightKg,
      'heightCm': heightCm,
      'goal': goal.name,
      'activityLevel': activityLevel.name,
      'trainDaysPerWeek': trainDaysPerWeek,
      'minutesPerWorkout': minutesPerWorkout,
      'cardioSessionsPerWeek': cardioSessionsPerWeek,
      'dailySteps': dailySteps,
    };
  }

  factory Profile.fromMap(Map<String, Object?> map) {
    return Profile(
      id: map['id'] as int?,
      name: map['name'] as String,
      gender: Gender.values.byName(map['gender'] as String),
      age: map['age'] as int,
      weightKg: (map['weightKg'] as num).toDouble(),
      heightCm: (map['heightCm'] as num).toDouble(),
      goal: FitnessGoal.values.byName(map['goal'] as String),
      activityLevel: ActivityLevel.values.byName(map['activityLevel'] as String),
      trainDaysPerWeek: map['trainDaysPerWeek'] as int,
      minutesPerWorkout: map['minutesPerWorkout'] as int,
      cardioSessionsPerWeek: map['cardioSessionsPerWeek'] as int,
      dailySteps: map['dailySteps'] as int,
    );
  }
}

class MealEntry {
  MealEntry({
    this.id,
    required this.profileId,
    required this.date,
    required this.category,
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    this.imagePath,
  });

  final int? id;
  final int profileId;
  final DateTime date;
  final MealCategory category;
  final String name;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final String? imagePath;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'profileId': profileId,
      'date': date.toIso8601String(),
      'category': category.name,
      'name': name,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
      'imagePath': imagePath,
    };
  }

  factory MealEntry.fromMap(Map<String, Object?> map) {
    return MealEntry(
      id: map['id'] as int?,
      profileId: map['profileId'] as int,
      date: DateTime.parse(map['date'] as String),
      category: MealCategory.values.byName(map['category'] as String),
      name: map['name'] as String,
      calories: (map['calories'] as num).toDouble(),
      protein: (map['protein'] as num).toDouble(),
      carbs: (map['carbs'] as num).toDouble(),
      fat: (map['fat'] as num).toDouble(),
      fiber: (map['fiber'] as num).toDouble(),
      imagePath: map['imagePath'] as String?,
    );
  }
}

class ProgressEntry {
  ProgressEntry({
    this.id,
    required this.profileId,
    required this.date,
    required this.weightKg,
    required this.calories,
    required this.protein,
    required this.waistCm,
    required this.workoutsCompleted,
    this.photoPath,
  });

  final int? id;
  final int profileId;
  final DateTime date;
  final double weightKg;
  final double calories;
  final double protein;
  final double waistCm;
  final int workoutsCompleted;
  final String? photoPath;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'profileId': profileId,
      'date': date.toIso8601String(),
      'weightKg': weightKg,
      'calories': calories,
      'protein': protein,
      'waistCm': waistCm,
      'workoutsCompleted': workoutsCompleted,
      'photoPath': photoPath,
    };
  }

  factory ProgressEntry.fromMap(Map<String, Object?> map) {
    return ProgressEntry(
      id: map['id'] as int?,
      profileId: map['profileId'] as int,
      date: DateTime.parse(map['date'] as String),
      weightKg: (map['weightKg'] as num).toDouble(),
      calories: (map['calories'] as num).toDouble(),
      protein: (map['protein'] as num).toDouble(),
      waistCm: (map['waistCm'] as num).toDouble(),
      workoutsCompleted: map['workoutsCompleted'] as int,
      photoPath: map['photoPath'] as String?,
    );
  }
}

class FoodEstimate {
  FoodEstimate({
    required this.foodName,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
  });

  final String foodName;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
}

class Exercise {
  const Exercise({
    required this.name,
    required this.activationPercent,
    required this.difficulty,
    required this.equipment,
    required this.instructions,
    required this.commonMistakes,
  });

  final String name;
  final int activationPercent;
  final String difficulty;
  final String equipment;
  final String instructions;
  final String commonMistakes;
}

class WorkoutDay {
  const WorkoutDay({
    required this.day,
    required this.focus,
    required this.sets,
    required this.reps,
    required this.restSeconds,
  });

  final String day;
  final String focus;
  final int sets;
  final int reps;
  final int restSeconds;
}

class WorkoutPlan {
  const WorkoutPlan({required this.title, required this.days});

  final String title;
  final List<WorkoutDay> days;
}

class MacroTargets {
  const MacroTargets({
    required this.bmr,
    required this.tdee,
    required this.maintenance,
    required this.targetCalories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  final double bmr;
  final double tdee;
  final double maintenance;
  final double targetCalories;
  final double protein;
  final double carbs;
  final double fat;
}

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();
  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    final databasesPath = await getDatabasesPath();
    final dbPath = p.join(databasesPath, 'ai_calorie_tracker.db');
    _db = await openDatabase(dbPath, version: 1, onCreate: _onCreate);
    return _db!;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE profiles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        gender TEXT NOT NULL,
        age INTEGER NOT NULL,
        weightKg REAL NOT NULL,
        heightCm REAL NOT NULL,
        goal TEXT NOT NULL,
        activityLevel TEXT NOT NULL,
        trainDaysPerWeek INTEGER NOT NULL,
        minutesPerWorkout INTEGER NOT NULL,
        cardioSessionsPerWeek INTEGER NOT NULL,
        dailySteps INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE meal_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        profileId INTEGER NOT NULL,
        date TEXT NOT NULL,
        category TEXT NOT NULL,
        name TEXT NOT NULL,
        calories REAL NOT NULL,
        protein REAL NOT NULL,
        carbs REAL NOT NULL,
        fat REAL NOT NULL,
        fiber REAL NOT NULL,
        imagePath TEXT,
        FOREIGN KEY(profileId) REFERENCES profiles(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE progress_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        profileId INTEGER NOT NULL,
        date TEXT NOT NULL,
        weightKg REAL NOT NULL,
        calories REAL NOT NULL,
        protein REAL NOT NULL,
        waistCm REAL NOT NULL,
        workoutsCompleted INTEGER NOT NULL,
        photoPath TEXT,
        FOREIGN KEY(profileId) REFERENCES profiles(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<List<Profile>> getProfiles() async {
    final db = await database;
    final rows = await db.query('profiles', orderBy: 'id DESC');
    return rows.map(Profile.fromMap).toList();
  }

  Future<int> insertProfile(Profile profile) async {
    final db = await database;
    return db.insert('profiles', profile.toMap()..remove('id'));
  }

  Future<List<MealEntry>> getMealsForDay(int profileId, DateTime day) async {
    final db = await database;
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    final rows = await db.query(
      'meal_entries',
      where: 'profileId = ? AND date >= ? AND date < ?',
      whereArgs: [profileId, start.toIso8601String(), end.toIso8601String()],
      orderBy: 'date DESC',
    );
    return rows.map(MealEntry.fromMap).toList();
  }

  Future<int> insertMeal(MealEntry meal) async {
    final db = await database;
    return db.insert('meal_entries', meal.toMap()..remove('id'));
  }

  Future<List<ProgressEntry>> getProgress(int profileId) async {
    final db = await database;
    final rows = await db.query(
      'progress_entries',
      where: 'profileId = ?',
      whereArgs: [profileId],
      orderBy: 'date ASC',
    );
    return rows.map(ProgressEntry.fromMap).toList();
  }

  Future<int> insertProgress(ProgressEntry progress) async {
    final db = await database;
    return db.insert('progress_entries', progress.toMap()..remove('id'));
  }
}

class NutritionCalculator {
  static MacroTargets calculate(Profile profile) {
    final bmr = profile.gender == Gender.male
        ? 10 * profile.weightKg + 6.25 * profile.heightCm - 5 * profile.age + 5
        : 10 * profile.weightKg + 6.25 * profile.heightCm - 5 * profile.age - 161;

    final activityMultiplier = switch (profile.activityLevel) {
      ActivityLevel.sedentary => 1.2,
      ActivityLevel.lightlyActive => 1.375,
      ActivityLevel.moderatelyActive => 1.55,
      ActivityLevel.veryActive => 1.725,
      ActivityLevel.athlete => 1.9,
    };

    final tdee = bmr * activityMultiplier;
    final targetCalories = switch (profile.goal) {
      FitnessGoal.loseFat => tdee - 450,
      FitnessGoal.maintainWeight => tdee,
      FitnessGoal.gainMuscle => tdee + 300,
      FitnessGoal.improveFitness => tdee - 150,
    };

    final proteinPerKg = profile.goal == FitnessGoal.gainMuscle ? 2.0 : 1.8;
    final protein = profile.weightKg * proteinPerKg;
    final fat = profile.weightKg * 0.8;
    final proteinCalories = protein * 4;
    final fatCalories = fat * 9;
    final carbs = max(0, (targetCalories - proteinCalories - fatCalories) / 4);

    return MacroTargets(
      bmr: bmr,
      tdee: tdee,
      maintenance: tdee,
      targetCalories: targetCalories,
      protein: protein,
      carbs: carbs,
      fat: fat,
    );
  }
}

class OfflineFoodEstimator {
  static final _examples = <FoodEstimate>[
    FoodEstimate(
      foodName: 'Chicken Breast + Rice + Vegetables',
      calories: 650,
      protein: 52,
      carbs: 58,
      fat: 14,
      fiber: 8,
    ),
    FoodEstimate(
      foodName: 'Salmon + Sweet Potato + Salad',
      calories: 590,
      protein: 43,
      carbs: 47,
      fat: 22,
      fiber: 9,
    ),
    FoodEstimate(
      foodName: 'Greek Yogurt + Berries + Granola',
      calories: 430,
      protein: 28,
      carbs: 50,
      fat: 12,
      fiber: 6,
    ),
  ];

  static FoodEstimate estimate(String imagePath) {
    final seed = imagePath.hashCode.abs();
    return _examples[seed % _examples.length];
  }
}

class WorkoutPlanner {
  static WorkoutPlan generate({
    required Profile profile,
    required TrainingLevel level,
    required FitnessGoal goal,
  }) {
    final int sets = switch (level) {
      TrainingLevel.beginner => 3,
      TrainingLevel.intermediate => 4,
      TrainingLevel.advanced => 5,
    };

    final int reps = switch (goal) {
      FitnessGoal.gainMuscle => 10,
      FitnessGoal.loseFat => 12,
      FitnessGoal.maintainWeight => 10,
      FitnessGoal.improveFitness => 14,
    };

    final int rest = switch (goal) {
      FitnessGoal.gainMuscle => 90,
      FitnessGoal.loseFat => 45,
      FitnessGoal.maintainWeight => 60,
      FitnessGoal.improveFitness => 45,
    };

    final days = <WorkoutDay>[
      WorkoutDay(day: 'Monday', focus: 'Push', sets: sets, reps: reps, restSeconds: rest),
      WorkoutDay(day: 'Tuesday', focus: 'Pull', sets: sets, reps: reps, restSeconds: rest),
      WorkoutDay(day: 'Wednesday', focus: 'Legs', sets: sets, reps: reps, restSeconds: rest),
      WorkoutDay(day: 'Thursday', focus: 'Upper Body', sets: sets, reps: reps, restSeconds: rest),
      WorkoutDay(day: 'Friday', focus: 'Full Body', sets: sets, reps: reps, restSeconds: rest),
    ];

    return WorkoutPlan(title: '${level.label} ${goal.label} Plan', days: days);
  }
}

class AppController extends ChangeNotifier {
  final _db = AppDatabase.instance;
  final _picker = ImagePicker();

  List<Profile> profiles = [];
  List<MealEntry> todayMeals = [];
  List<ProgressEntry> progressEntries = [];
  int? selectedProfileId;

  final muscles = const [
    'Chest',
    'Shoulders',
    'Biceps',
    'Triceps',
    'Forearms',
    'Abs',
    'Obliques',
    'Upper Back',
    'Lats',
    'Lower Back',
    'Glutes',
    'Quads',
    'Hamstrings',
    'Calves',
  ];

  final Map<String, List<Exercise>> exerciseLibrary = {
    'Chest': const [
      Exercise(
        name: 'Bench Press',
        activationPercent: 92,
        difficulty: 'Intermediate',
        equipment: 'Barbell + Bench',
        instructions: 'Lower bar to chest with control and press up explosively.',
        commonMistakes: 'Flaring elbows too much and bouncing on chest.',
      ),
      Exercise(
        name: 'Incline Bench Press',
        activationPercent: 88,
        difficulty: 'Intermediate',
        equipment: 'Barbell + Incline Bench',
        instructions: 'Press along upper chest line with stable shoulder blades.',
        commonMistakes: 'Excessive back arch and incomplete range.',
      ),
      Exercise(
        name: 'Push-Ups',
        activationPercent: 78,
        difficulty: 'Beginner',
        equipment: 'Bodyweight',
        instructions: 'Keep core tight and lower chest fully each rep.',
        commonMistakes: 'Hips sagging and partial reps.',
      ),
    ],
  };

  Future<void> initialize() async {
    profiles = await _db.getProfiles();
    if (profiles.isNotEmpty) {
      selectedProfileId = profiles.first.id;
      await _loadProfileData();
    }
    notifyListeners();
  }

  Profile? get selectedProfile {
    if (selectedProfileId == null) return null;
    return profiles.where((p) => p.id == selectedProfileId).firstOrNull;
  }

  MacroTargets? get selectedTargets {
    final profile = selectedProfile;
    if (profile == null) return null;
    return NutritionCalculator.calculate(profile);
  }

  double get totalCalories => todayMeals.fold(0, (sum, e) => sum + e.calories);
  double get totalProtein => todayMeals.fold(0, (sum, e) => sum + e.protein);
  double get totalCarbs => todayMeals.fold(0, (sum, e) => sum + e.carbs);
  double get totalFat => todayMeals.fold(0, (sum, e) => sum + e.fat);

  Future<void> addProfile(Profile profile) async {
    await _db.insertProfile(profile);
    profiles = await _db.getProfiles();
    selectedProfileId = profiles.first.id;
    await _loadProfileData();
    notifyListeners();
  }

  Future<void> switchProfile(int id) async {
    selectedProfileId = id;
    await _loadProfileData();
    notifyListeners();
  }

  Future<void> addMeal(MealEntry meal) async {
    await _db.insertMeal(meal);
    await _loadProfileData();
    notifyListeners();
  }

  Future<void> addProgress(ProgressEntry progress) async {
    await _db.insertProgress(progress);
    await _loadProfileData();
    notifyListeners();
  }

  Future<void> _loadProfileData() async {
    if (selectedProfileId == null) return;
    todayMeals = await _db.getMealsForDay(selectedProfileId!, DateTime.now());
    progressEntries = await _db.getProgress(selectedProfileId!);
  }

  Future<XFile?> captureMealImage() async {
    try {
      return await _picker.pickImage(source: ImageSource.camera, imageQuality: 75);
    } catch (_) {
      return _picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
    }
  }

  Future<XFile?> pickProgressPhoto() {
    return _picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
  }

  FoodEstimate estimateFood(String imagePath) => OfflineFoodEstimator.estimate(imagePath);

  WorkoutPlan generateWorkout({required TrainingLevel level, required FitnessGoal goal}) {
    final profile = selectedProfile;
    if (profile == null) {
      return const WorkoutPlan(title: 'No profile selected', days: []);
    }
    return WorkoutPlanner.generate(profile: profile, level: level, goal: goal);
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _titles = [
    'Profiles',
    'Dashboard',
    'Food Scanner',
    'Food Diary',
    'Anatomy',
    'Exercises',
    'Workout Generator',
    'Progress',
  ];

  final _pages = const [
    ProfilesScreen(),
    DashboardScreen(),
    FoodScannerScreen(),
    FoodDiaryScreen(),
    AnatomyScreen(),
    ExercisesScreen(),
    WorkoutGeneratorScreen(),
    ProgressScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titles[_index])),
      body: _pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.people_alt), label: 'Profiles'),
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.camera_alt), label: 'Scanner'),
          NavigationDestination(icon: Icon(Icons.restaurant_menu), label: 'Diary'),
          NavigationDestination(icon: Icon(Icons.accessibility_new), label: 'Anatomy'),
          NavigationDestination(icon: Icon(Icons.fitness_center), label: 'Exercises'),
          NavigationDestination(icon: Icon(Icons.auto_awesome), label: 'Workout'),
          NavigationDestination(icon: Icon(Icons.query_stats), label: 'Progress'),
        ],
        onDestinationSelected: (value) => setState(() => _index = value),
      ),
    );
  }
}

class ProfilesScreen extends StatelessWidget {
  const ProfilesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppController>(
      builder: (context, app, _) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                children: app.profiles
                    .map(
                      (profile) => ChoiceChip(
                        label: Text(profile.name),
                        selected: profile.id == app.selectedProfileId,
                        onSelected: (_) {
                          if (profile.id != null) app.switchProfile(profile.id!);
                        },
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => _showCreateProfileDialog(context),
                icon: const Icon(Icons.person_add),
                label: const Text('Create Local Profile'),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: app.profiles.length,
                  itemBuilder: (context, index) {
                    final p = app.profiles[index];
                    return Card(
                      child: ListTile(
                        title: Text(p.name),
                        subtitle: Text(
                          '${p.gender.label} • ${p.age}y • ${p.weightKg.toStringAsFixed(1)}kg • ${p.heightCm.toStringAsFixed(0)}cm\n'
                          '${p.goal.label} • ${p.activityLevel.label}',
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showCreateProfileDialog(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final name = TextEditingController();
    final age = TextEditingController(text: '28');
    final weight = TextEditingController(text: '75');
    final height = TextEditingController(text: '175');
    final trainDays = TextEditingController(text: '4');
    final minutes = TextEditingController(text: '60');
    final cardio = TextEditingController(text: '2');
    final steps = TextEditingController(text: '8000');

    Gender gender = Gender.male;
    FitnessGoal goal = FitnessGoal.maintainWeight;
    ActivityLevel activityLevel = ActivityLevel.moderatelyActive;

    final created = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('New Profile'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: name,
                        decoration: const InputDecoration(labelText: 'Name'),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      DropdownButtonFormField<Gender>(
                        value: gender,
                        items: Gender.values
                            .map((e) => DropdownMenuItem(value: e, child: Text(e.label)))
                            .toList(),
                        onChanged: (value) => setState(() => gender = value ?? gender),
                        decoration: const InputDecoration(labelText: 'Gender'),
                      ),
                      TextFormField(
                        controller: age,
                        decoration: const InputDecoration(labelText: 'Age'),
                        keyboardType: TextInputType.number,
                      ),
                      TextFormField(
                        controller: weight,
                        decoration: const InputDecoration(labelText: 'Weight (kg)'),
                        keyboardType: TextInputType.number,
                      ),
                      TextFormField(
                        controller: height,
                        decoration: const InputDecoration(labelText: 'Height (cm)'),
                        keyboardType: TextInputType.number,
                      ),
                      DropdownButtonFormField<FitnessGoal>(
                        value: goal,
                        items: FitnessGoal.values
                            .map((e) => DropdownMenuItem(value: e, child: Text(e.label)))
                            .toList(),
                        onChanged: (value) => setState(() => goal = value ?? goal),
                        decoration: const InputDecoration(labelText: 'Fitness Goal'),
                      ),
                      DropdownButtonFormField<ActivityLevel>(
                        value: activityLevel,
                        items: ActivityLevel.values
                            .map((e) => DropdownMenuItem(value: e, child: Text(e.label)))
                            .toList(),
                        onChanged: (value) =>
                            setState(() => activityLevel = value ?? activityLevel),
                        decoration: const InputDecoration(labelText: 'Activity Level'),
                      ),
                      TextFormField(
                        controller: trainDays,
                        decoration: const InputDecoration(labelText: 'Days trained/week'),
                        keyboardType: TextInputType.number,
                      ),
                      TextFormField(
                        controller: minutes,
                        decoration: const InputDecoration(labelText: 'Minutes/workout'),
                        keyboardType: TextInputType.number,
                      ),
                      TextFormField(
                        controller: cardio,
                        decoration: const InputDecoration(labelText: 'Cardio sessions/week'),
                        keyboardType: TextInputType.number,
                      ),
                      TextFormField(
                        controller: steps,
                        decoration: const InputDecoration(labelText: 'Average daily steps'),
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final profile = Profile(
                      name: name.text.trim(),
                      gender: gender,
                      age: int.tryParse(age.text) ?? 0,
                      weightKg: double.tryParse(weight.text) ?? 0,
                      heightCm: double.tryParse(height.text) ?? 0,
                      goal: goal,
                      activityLevel: activityLevel,
                      trainDaysPerWeek: int.tryParse(trainDays.text) ?? 0,
                      minutesPerWorkout: int.tryParse(minutes.text) ?? 0,
                      cardioSessionsPerWeek: int.tryParse(cardio.text) ?? 0,
                      dailySteps: int.tryParse(steps.text) ?? 0,
                    );
                    await context.read<AppController>().addProfile(profile);
                    if (context.mounted) {
                      Navigator.pop(dialogContext, true);
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (context.mounted && created == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile created locally.')),
      );
    }
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppController>(
      builder: (context, app, _) {
        final profile = app.selectedProfile;
        final targets = app.selectedTargets;

        if (profile == null || targets == null) {
          return const Center(
            child: Text('Create a profile to unlock your dashboard.'),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Hi ${profile.name}', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            _MetricsCard(
              title: 'AI Calorie Calculator',
              values: [
                'BMR: ${targets.bmr.toStringAsFixed(0)} kcal',
                'TDEE: ${targets.tdee.toStringAsFixed(0)} kcal',
                'Maintenance: ${targets.maintenance.toStringAsFixed(0)} kcal',
                'Daily Calories: ${targets.targetCalories.toStringAsFixed(0)} kcal',
                'Protein: ${targets.protein.toStringAsFixed(0)} g',
                'Carbs: ${targets.carbs.toStringAsFixed(0)} g',
                'Fat: ${targets.fat.toStringAsFixed(0)} g',
              ],
            ),
            const SizedBox(height: 12),
            _MetricsCard(
              title: "Today's Intake",
              values: [
                'Calories: ${app.totalCalories.toStringAsFixed(0)} / ${targets.targetCalories.toStringAsFixed(0)}',
                'Protein: ${app.totalProtein.toStringAsFixed(0)} / ${targets.protein.toStringAsFixed(0)} g',
                'Carbs: ${app.totalCarbs.toStringAsFixed(0)} / ${targets.carbs.toStringAsFixed(0)} g',
                'Fat: ${app.totalFat.toStringAsFixed(0)} / ${targets.fat.toStringAsFixed(0)} g',
              ],
            ),
          ],
        );
      },
    );
  }
}

class _MetricsCard extends StatelessWidget {
  const _MetricsCard({required this.title, required this.values});

  final String title;
  final List<String> values;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...values.map((line) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(line),
                )),
          ],
        ),
      ),
    );
  }
}

class FoodScannerScreen extends StatefulWidget {
  const FoodScannerScreen({super.key});

  @override
  State<FoodScannerScreen> createState() => _FoodScannerScreenState();
}

class _FoodScannerScreenState extends State<FoodScannerScreen> {
  XFile? _captured;
  FoodEstimate? _estimate;

  final _name = TextEditingController();
  final _calories = TextEditingController();
  final _protein = TextEditingController();
  final _carbs = TextEditingController();
  final _fat = TextEditingController();
  final _fiber = TextEditingController();
  MealCategory _category = MealCategory.lunch;

  @override
  void dispose() {
    _name.dispose();
    _calories.dispose();
    _protein.dispose();
    _carbs.dispose();
    _fat.dispose();
    _fiber.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppController>(
      builder: (context, app, _) {
        final hasProfile = app.selectedProfileId != null;
        if (!hasProfile) {
          return const Center(child: Text('Create/select a profile first.'));
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            FilledButton.icon(
              onPressed: _captureAndEstimate,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Scan Meal with Camera'),
            ),
            const SizedBox(height: 12),
            if (_captured != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image(
                  image: imageProviderFromPath(_captured!.path),
                  height: 180,
                  fit: BoxFit.cover,
                ),
              ),
            if (_estimate != null) ...[
              const SizedBox(height: 12),
              Text(
                'AI estimate complete. You can correct any value before saving.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              TextField(controller: _name, decoration: const InputDecoration(labelText: 'Food')), 
              DropdownButtonFormField<MealCategory>(
                value: _category,
                items: MealCategory.values
                    .map((e) => DropdownMenuItem(value: e, child: Text(e.label)))
                    .toList(),
                onChanged: (value) => setState(() => _category = value ?? _category),
                decoration: const InputDecoration(labelText: 'Meal Category'),
              ),
              TextField(
                controller: _calories,
                decoration: const InputDecoration(labelText: 'Calories'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _protein,
                decoration: const InputDecoration(labelText: 'Protein (g)'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _carbs,
                decoration: const InputDecoration(labelText: 'Carbs (g)'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _fat,
                decoration: const InputDecoration(labelText: 'Fat (g)'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _fiber,
                decoration: const InputDecoration(labelText: 'Fiber (g)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () async {
                  final meal = MealEntry(
                    profileId: app.selectedProfileId!,
                    date: DateTime.now(),
                    category: _category,
                    name: _name.text,
                    calories: double.tryParse(_calories.text) ?? 0,
                    protein: double.tryParse(_protein.text) ?? 0,
                    carbs: double.tryParse(_carbs.text) ?? 0,
                    fat: double.tryParse(_fat.text) ?? 0,
                    fiber: double.tryParse(_fiber.text) ?? 0,
                    imagePath: _captured?.path,
                  );
                  await app.addMeal(meal);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Meal added to diary.')),
                    );
                  }
                },
                child: const Text('Save to Food Diary'),
              ),
            ],
          ],
        );
      },
    );
  }

  Future<void> _captureAndEstimate() async {
    final app = context.read<AppController>();
    final image = await app.captureMealImage();
    if (image == null) return;

    final estimate = app.estimateFood(image.path);
    setState(() {
      _captured = image;
      _estimate = estimate;
      _name.text = estimate.foodName;
      _calories.text = estimate.calories.toStringAsFixed(0);
      _protein.text = estimate.protein.toStringAsFixed(0);
      _carbs.text = estimate.carbs.toStringAsFixed(0);
      _fat.text = estimate.fat.toStringAsFixed(0);
      _fiber.text = estimate.fiber.toStringAsFixed(0);
    });
  }
}

class FoodDiaryScreen extends StatelessWidget {
  const FoodDiaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppController>(
      builder: (context, app, _) {
        final targets = app.selectedTargets;
        if (app.selectedProfile == null || targets == null) {
          return const Center(child: Text('Create/select a profile first.'));
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Today's Intake"),
                    const SizedBox(height: 8),
                    Text(
                      'Calories: ${app.totalCalories.toStringAsFixed(0)} / ${targets.targetCalories.toStringAsFixed(0)}',
                    ),
                    Text(
                      'Protein: ${app.totalProtein.toStringAsFixed(0)} / ${targets.protein.toStringAsFixed(0)} g',
                    ),
                    Text(
                      'Carbs: ${app.totalCarbs.toStringAsFixed(0)} / ${targets.carbs.toStringAsFixed(0)} g',
                    ),
                    Text('Fat: ${app.totalFat.toStringAsFixed(0)} / ${targets.fat.toStringAsFixed(0)} g'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (app.todayMeals.isEmpty)
              const Card(child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No meals logged today yet.'),
              )),
            ...app.todayMeals.map(
              (meal) => Card(
                child: ListTile(
                  title: Text(meal.name),
                  subtitle: Text(
                    '${meal.category.label} • ${meal.calories.toStringAsFixed(0)} kcal\n'
                    'P ${meal.protein.toStringAsFixed(0)}g • C ${meal.carbs.toStringAsFixed(0)}g • F ${meal.fat.toStringAsFixed(0)}g',
                  ),
                  isThreeLine: true,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class AnatomyScreen extends StatefulWidget {
  const AnatomyScreen({super.key});

  @override
  State<AnatomyScreen> createState() => _AnatomyScreenState();
}

class _AnatomyScreenState extends State<AnatomyScreen> {
  String _view = 'Front';
  String? _selectedMuscle;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppController>(
      builder: (context, app, _) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'Front', label: Text('Front')),
                ButtonSegment(value: 'Back', label: Text('Back')),
                ButtonSegment(value: 'Side', label: Text('Side')),
              ],
              selected: {_view},
              onSelectionChanged: (value) => setState(() => _view = value.first),
            ),
            const SizedBox(height: 12),
            Card(
              child: SizedBox(
                height: 220,
                child: InteractiveViewer(
                  child: Center(
                    child: Text(
                      '$_view View\nRotatable body canvas (offline placeholder)',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: app.muscles
                  .map(
                    (muscle) => ChoiceChip(
                      label: Text(muscle),
                      selected: muscle == _selectedMuscle,
                      onSelected: (_) => setState(() => _selectedMuscle = muscle),
                    ),
                  )
                  .toList(),
            ),
            if (_selectedMuscle != null) ...[
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  title: Text('Selected Muscle: $_selectedMuscle'),
                  subtitle: const Text('Muscle highlighted for training guidance.'),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class ExercisesScreen extends StatefulWidget {
  const ExercisesScreen({super.key});

  @override
  State<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends State<ExercisesScreen> {
  String _muscle = 'Chest';

  @override
  Widget build(BuildContext context) {
    return Consumer<AppController>(
      builder: (context, app, _) {
        final exercises = app.exerciseLibrary[_muscle] ?? const <Exercise>[];

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<String>(
              value: _muscle,
              items: app.muscles
                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
              onChanged: (value) => setState(() => _muscle = value ?? _muscle),
              decoration: const InputDecoration(labelText: 'Select Muscle Group'),
            ),
            const SizedBox(height: 12),
            if (exercises.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Exercise library for this muscle is coming soon.'),
                ),
              ),
            ...exercises.map(
              (e) => Card(
                child: ExpansionTile(
                  title: Text(e.name),
                  subtitle: Text('${e.difficulty} • ${e.activationPercent}% activation'),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Video animation: integrated local/offline asset slot'),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Equipment: ${e.equipment}'),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Instructions: ${e.instructions}'),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Common mistakes: ${e.commonMistakes}'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class WorkoutGeneratorScreen extends StatefulWidget {
  const WorkoutGeneratorScreen({super.key});

  @override
  State<WorkoutGeneratorScreen> createState() => _WorkoutGeneratorScreenState();
}

class _WorkoutGeneratorScreenState extends State<WorkoutGeneratorScreen> {
  TrainingLevel _level = TrainingLevel.beginner;
  FitnessGoal _goal = FitnessGoal.gainMuscle;
  WorkoutPlan? _plan;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppController>(
      builder: (context, app, _) {
        if (app.selectedProfile == null) {
          return const Center(child: Text('Create/select a profile first.'));
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<TrainingLevel>(
              value: _level,
              items: TrainingLevel.values
                  .map((e) => DropdownMenuItem(value: e, child: Text(e.label)))
                  .toList(),
              onChanged: (value) => setState(() => _level = value ?? _level),
              decoration: const InputDecoration(labelText: 'Experience Level'),
            ),
            DropdownButtonFormField<FitnessGoal>(
              value: _goal,
              items: FitnessGoal.values
                  .map((e) => DropdownMenuItem(value: e, child: Text(e.label)))
                  .toList(),
              onChanged: (value) => setState(() => _goal = value ?? _goal),
              decoration: const InputDecoration(labelText: 'Goal'),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () {
                setState(() {
                  _plan = app.generateWorkout(level: _level, goal: _goal);
                });
              },
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Generate AI Workout'),
            ),
            if (_plan != null) ...[
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_plan!.title, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      ..._plan!.days.map(
                        (day) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text('${day.day}: ${day.focus}'),
                          subtitle: Text(
                            'Sets: ${day.sets} • Reps: ${day.reps} • Rest: ${day.restSeconds}s',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppController>(
      builder: (context, app, _) {
        if (app.selectedProfile == null) {
          return const Center(child: Text('Create/select a profile first.'));
        }

        final entries = app.progressEntries;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            FilledButton.icon(
              onPressed: () => _showAddProgressDialog(context),
              icon: const Icon(Icons.add_chart),
              label: const Text('Add Progress Entry'),
            ),
            const SizedBox(height: 12),
            Card(
              child: SizedBox(
                height: 220,
                child: entries.length < 2
                    ? const Center(child: Text('Add at least 2 entries for trend graphs.'))
                    : Padding(
                        padding: const EdgeInsets.all(16),
                        child: LineChart(
                          LineChartData(
                            lineBarsData: [
                              LineChartBarData(
                                isCurved: true,
                                spots: [
                                  for (var i = 0; i < entries.length; i++)
                                    FlSpot(i.toDouble(), entries[i].weightKg),
                                ],
                              ),
                            ],
                            titlesData: const FlTitlesData(
                              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            ...entries.reversed.map(
              (e) => Card(
                child: ListTile(
                  title: Text(
                    '${e.date.year}-${e.date.month.toString().padLeft(2, '0')}-${e.date.day.toString().padLeft(2, '0')}',
                  ),
                  subtitle: Text(
                    'Weight: ${e.weightKg.toStringAsFixed(1)}kg • Calories: ${e.calories.toStringAsFixed(0)}\n'
                    'Protein: ${e.protein.toStringAsFixed(0)}g • Waist: ${e.waistCm.toStringAsFixed(1)}cm • Workouts: ${e.workoutsCompleted}',
                  ),
                  isThreeLine: true,
                  trailing: e.photoPath == null
                      ? null
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image(
                            image: imageProviderFromPath(e.photoPath!),
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                          ),
                        ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAddProgressDialog(BuildContext context) async {
    final app = context.read<AppController>();
    final weight = TextEditingController();
    final calories = TextEditingController();
    final protein = TextEditingController();
    final waist = TextEditingController();
    final workouts = TextEditingController(text: '0');
    String? photoPath;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Progress Entry'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: weight,
                      decoration: const InputDecoration(labelText: 'Weight (kg)'),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      controller: calories,
                      decoration: const InputDecoration(labelText: 'Calories'),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      controller: protein,
                      decoration: const InputDecoration(labelText: 'Protein (g)'),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      controller: waist,
                      decoration: const InputDecoration(labelText: 'Waist (cm)'),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      controller: workouts,
                      decoration: const InputDecoration(labelText: 'Workouts completed'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final image = await app.pickProgressPhoto();
                        if (image != null) {
                          setState(() => photoPath = image.path);
                        }
                      },
                      icon: const Icon(Icons.photo),
                      label: Text(photoPath == null ? 'Select Progress Photo' : 'Photo Added'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    if (app.selectedProfileId == null) return;
                    final entry = ProgressEntry(
                      profileId: app.selectedProfileId!,
                      date: DateTime.now(),
                      weightKg: double.tryParse(weight.text) ?? 0,
                      calories: double.tryParse(calories.text) ?? 0,
                      protein: double.tryParse(protein.text) ?? 0,
                      waistCm: double.tryParse(waist.text) ?? 0,
                      workoutsCompleted: int.tryParse(workouts.text) ?? 0,
                      photoPath: photoPath,
                    );
                    await app.addProgress(entry);
                    if (context.mounted) Navigator.pop(dialogContext);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

extension FirstOrNullExtension<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
