import 'package:task_app/features/projects/domain/entities/task_entity.dart';
import 'package:task_app/features/projects/domain/repositories/task_repository.dart';

class StreamTasks {
  StreamTasks(this.repository);

  final TaskRepository repository;

  Stream<List<TaskEntity>> call(String projectId) {
    return repository.streamTasks(projectId: projectId);
  }
}


