import 'package:grumpy/grumpy.dart';

/// {@template list_remove_element_tx_operation}
/// A [TxOperation] for removing an element from a list.
///
///  Note [Element] must properly implement equality for this operation to work correctly.
/// {@endtemplate}
class ListRemoveElementTxOperation<Element, TResult>
    extends TxOperation<List<Element>, TResult> {
  /// {@macro list_remove_element_tx_operation}
  ListRemoveElementTxOperation({
    required super.name,
    required super.id,
    required super.baseVersion,
    required this.element,
    required this.removeElement,
    required this.apply,
    this.shouldRollbackOnError = TxOperation.alwaysRollback,
  }) : super(touchedKeys: const <String>{});

  @override
  Set<String> get touchedKeys => {element.toString()};

  /// The element to be removed.
  final Element element;

  /// Creates the element on the remote and returns the commit result.
  final Future<TResult> Function() removeElement;

  /// Applies commit result to the optimistic element and returns the confirmed element.
  final Element Function(Element optimisticElement, TResult createResult) apply;

  /// {@macro shouldRollbackOnError}
  final bool Function(Object error, StackTrace? stackTrace)
  shouldRollbackOnError;

  @override
  List<Element>? applyConfirmed(List<Element> confirmed, TResult result) {
    final appliedElement = apply(element, result);
    final copy = List<Element>.from(confirmed);
    copy.remove(appliedElement);
    return copy;
  }

  @override
  Future<TResult> commit(_) => removeElement();

  @override
  List<Element> optimisticApply(List<Element> current) {
    final copy = List<Element>.from(current);

    copy.remove(element);

    return copy;
  }

  @override
  bool shouldRollback(Object error, StackTrace? stackTrace) =>
      shouldRollbackOnError(error, stackTrace);
}
