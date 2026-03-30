import '../models/teacher_model.dart';
import '../models/course_model.dart';

class DataService {
  // Mock teachers data
  static List<Teacher> getTeachers() {
    return [
      Teacher(
        id: '1',
        name: 'Dr. Sarah Johnson',
        subject: 'Mathematics',
        bio: 'PhD in Applied Mathematics with 15 years of teaching experience. Specializes in calculus and linear algebra.',
        imageUrl: 'https://i.pravatar.cc/300?img=1',
        rating: 4.8,
        studentsCount: 1250,
        isOnline: true,
        isPremium: true,
      ),
      Teacher(
        id: '2',
        name: 'Prof. Michael Chen',
        subject: 'Computer Science',
        bio: 'Former Google engineer turned educator. Expert in algorithms, data structures, and machine learning.',
        imageUrl: 'https://i.pravatar.cc/300?img=12',
        rating: 4.9,
        studentsCount: 2100,
        isOnline: true,
      ),
      Teacher(
        id: '3',
        name: 'Dr. Emily Rodriguez',
        subject: 'Physics',
        bio: 'Quantum physics researcher and passionate educator. Makes complex concepts simple and engaging.',
        imageUrl: 'https://i.pravatar.cc/300?img=5',
        rating: 4.7,
        studentsCount: 890,
        isPremium: true,
      ),
      Teacher(
        id: '4',
        name: 'Prof. David Williams',
        subject: 'Chemistry',
        bio: 'Award-winning chemistry professor with expertise in organic and inorganic chemistry.',
        imageUrl: 'https://i.pravatar.cc/300?img=13',
        rating: 4.6,
        studentsCount: 750,
      ),
      Teacher(
        id: '5',
        name: 'Dr. Lisa Anderson',
        subject: 'Biology',
        bio: 'Marine biologist and environmental scientist. Brings real-world research into the classroom.',
        imageUrl: 'https://i.pravatar.cc/300?img=9',
        rating: 4.9,
        studentsCount: 1450,
        isOnline: true,
      ),
      Teacher(
        id: '6',
        name: 'Prof. James Taylor',
        subject: 'English Literature',
        bio: 'Published author and literary critic. Passionate about classic and contemporary literature.',
        imageUrl: 'https://i.pravatar.cc/300?img=14',
        rating: 4.5,
        studentsCount: 680,
        isPremium: true,
      ),
    ];
  }

  // Mock courses data
  static List<Course> getCoursesByTeacher(String teacherId) {
    final Map<String, List<Course>> teacherCourses = {
      '1': [
        Course(
          id: 'c1',
          courseName: 'Calculus I: Limits and Derivatives',
          description: 'Master the fundamentals of calculus including limits, continuity, and derivatives.',
          imagePath: 'https://picsum.photos/seed/calc1/400/250',
          modificationDate: DateTime.now(),
        ),
        Course(
          id: 'c2',
          courseName: 'Linear Algebra Fundamentals',
          description: 'Explore vectors, matrices, and linear transformations with practical applications.',
          imagePath: 'https://picsum.photos/seed/linalg/400/250',
          modificationDate: DateTime.now(),
        ),
        Course(
          id: 'c3',
          courseName: 'Advanced Calculus',
          description: 'Deep dive into multivariable calculus, series, and advanced integration techniques.',
          imagePath: 'https://picsum.photos/seed/advcalc/400/250',
          modificationDate: DateTime.now(),
        ),
      ],
      '2': [
        Course(
          id: 'c4',
          courseName: 'Data Structures & Algorithms',
          description: 'Comprehensive guide to essential data structures and algorithmic problem-solving.',
          imagePath: 'https://picsum.photos/seed/dsa/400/250',
          modificationDate: DateTime.now(),
        ),
        Course(
          id: 'c5',
          courseName: 'Machine Learning Basics',
          description: 'Introduction to machine learning algorithms and practical applications.',
          imagePath: 'https://picsum.photos/seed/ml/400/250',
          modificationDate: DateTime.now(),
        ),
        Course(
          id: 'c6',
          courseName: 'Python Programming Masterclass',
          description: 'Complete Python programming from basics to advanced concepts.',
          imagePath: 'https://picsum.photos/seed/python/400/250',
          modificationDate: DateTime.now(),
        ),
      ],
      '3': [
        Course(
          id: 'c7',
          courseName: 'Quantum Mechanics Introduction',
          description: 'Explore the quantum world with wave functions, operators, and quantum states.',
          imagePath: 'https://picsum.photos/seed/quantum/400/250',
          modificationDate: DateTime.now(),
        ),
        Course(
          id: 'c8',
          courseName: 'Classical Mechanics',
          description: 'Study motion, forces, energy, and momentum in classical physics.',
          imagePath: 'https://picsum.photos/seed/mechanics/400/250',
          modificationDate: DateTime.now(),
        ),
      ],
      '4': [
        Course(
          id: 'c9',
          courseName: 'Organic Chemistry I',
          description: 'Master organic compounds, reactions, and mechanisms.',
          imagePath: 'https://picsum.photos/seed/orgchem/400/250',
          modificationDate: DateTime.now(),
        ),
        Course(
          id: 'c10',
          courseName: 'General Chemistry',
          description: 'Foundation course covering atoms, molecules, and chemical reactions.',
          imagePath: 'https://picsum.photos/seed/genchem/400/250',
          modificationDate: DateTime.now(),
        ),
      ],
      '5': [
        Course(
          id: 'c11',
          courseName: 'Marine Biology',
          description: 'Discover ocean life, ecosystems, and marine conservation.',
          imagePath: 'https://picsum.photos/seed/marine/400/250',
          modificationDate: DateTime.now(),
        ),
        Course(
          id: 'c12',
          courseName: 'Cell Biology & Genetics',
          description: 'Study cellular structures, functions, and genetic principles.',
          imagePath: 'https://picsum.photos/seed/cell/400/250',
          modificationDate: DateTime.now(),
        ),
        Course(
          id: 'c13',
          courseName: 'Environmental Science',
          description: 'Examine ecosystems, climate change, and sustainability.',
          imagePath: 'https://picsum.photos/seed/env/400/250',
          modificationDate: DateTime.now(),
        ),
      ],
      '6': [
        Course(
          id: 'c14',
          courseName: 'Shakespeare Studies',
          description: 'Analyze the works and literary techniques of William Shakespeare.',
          imagePath: 'https://picsum.photos/seed/shakespeare/400/250',
          modificationDate: DateTime.now(),
        ),
        Course(
          id: 'c15',
          courseName: 'Modern American Literature',
          description: 'Explore contemporary American authors and literary movements.',
          imagePath: 'https://picsum.photos/seed/amlit/400/250',
          modificationDate: DateTime.now(),
        ),
      ],
    };

    return teacherCourses[teacherId] ?? [];
  }
}
