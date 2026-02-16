import 'package:grumpy/grumpy.dart';

class TestRepo extends Repo<int> {
  void setData(int value) => data(value);
  void setLoading() => loading();
  void setError(Object error, [StackTrace? stackTrace]) =>
      super.error(error, stackTrace);
  @override
  String get logTag => 'TestRepo';
}
