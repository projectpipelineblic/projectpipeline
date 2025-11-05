import 'package:project_pipeline/features/projects/domain/entities/task_entity.dart';
import 'package:project_pipeline/features/projects/domain/repositories/task_repository.dart';

class StreamTasks {
  StreamTasks(this.repository);

  final TaskRepository repository;

  Stream<List<TaskEntity>> call(String projectId) {
    return repository.streamTasks(projectId: projectId);
  }
}


