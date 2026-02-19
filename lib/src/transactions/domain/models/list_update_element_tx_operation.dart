import 'package:grumpy/grumpy.dart';

/// {@template list_update_element_tx_operation}
/// A [TxOperation] for updating an element in a list.
///
/// Note [Element] must properly implement equality for this operation to work correctly.
/// {@endtemplate}
class ListUpdateElementTxOperation<Element, TResult>
    extends TxOperation<List<Element>, TResult> {
  /// {@macro list_update_element_tx_operation}
  const ListUpdateElementTxOperation({
    required super.name,
    required super.id,
    required super.baseVersion,
    required this.touchedElementKeys,
    required this.element,
    required this.apply,
    required this.optimisticUpdate,
    required this.updateElement,
    super.shouldRollbackOnError = TxOperation.alwaysRollback,
  }) : super(touchedKeys: touchedElementKeys);

  @override
  Set<String> get touchedKeys =>
      touchedElementKeys.map((key) => '$element.$key').toSet();

  /// The fields of the element that are touched by this update, used for conflict detection.
  final Set<String> touchedElementKeys;

  /// The element to be updated.
  final Element element;

  /// Returns the optimistically updated element based on the current element.
  final Element Function(Element current) optimisticUpdate;

  /// Updates the element on the remote and returns the commit result.
  final Future<TResult> Function(Element element) updateElement;

  /// Applies commit result to the optimistic element and returns the confirmed element.
  final Element Function(Element optimisticElement, TResult result) apply;

  @override
  List<Element>? applyConfirmed(List<Element> confirmed, TResult result) {
    final index = confirmed.indexOf(element);
    if (index == -1) {
      // Element not found, cannot apply update
      return null;
    }
    final optimisticElement = optimisticUpdate(confirmed[index]);
    final appliedElement = apply(optimisticElement, result);
    return [
      ...confirmed.sublist(0, index),
      appliedElement,
      ...confirmed.sublist(index + 1),
    ];
  }

  @override
  Future<TResult> commit(current) => updateElement(element);

  @override
  List<Element> optimisticApply(List<Element> current) {
    return current.map((element) {
      if (element == this.element) {
        return optimisticUpdate(element);
      }
      return element;
    }).toList();
  }

  @override
  String get logTag => 'ListUpdateElementTxOperation';
}
