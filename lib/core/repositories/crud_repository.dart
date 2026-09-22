/// Standard CRUD contract shared by every entity repository.
///
/// [T] is the model type, [ID] is the type of its primary key.
abstract class CrudRepository<T, ID> {
  Future<List<T>> getAll();

  Future<T?> getById(ID id);

  Future<T> create(T item);

  Future<T> update(T item);

  Future<void> delete(ID id);
}
