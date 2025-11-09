import 'package:project_pipeline/features/projects/domain/entities/task_entity.dart';
import 'package:project_pipeline/features/projects/domain/repositories/task_repository.dart';

class StreamUserTasks {
  StreamUserTasks(this.repository);

  final TaskRepository repository;

  Stream<List<TaskEntity>> call(String userId) {
    return repository.streamUserTasks(userId: userId);
  }
}

