import 'package:grumpy/grumpy.dart';

/// {@template list_add_element_tx_operation}
/// A [TxOperation] for adding an element to a list.
/// {@endtemplate}
class ListAddElementTxOperation<Element, TResult>
    extends TxOperation<List<Element>, TResult> {
  /// {@macro list_add_element_tx_operation}
  ListAddElementTxOperation({
    required super.name,
    required super.id,
    required super.baseVersion,
    required this.element,
    required this.createElement,
    required this.apply,
    super.shouldRollbackOnError = TxOperation.alwaysRollback,
  }) : super(touchedKeys: const <String>{});

  @override
  Set<String> get touchedKeys => {createElement.toString()};

  /// The optimistic element to be added.
  final Element element;

  /// Creates the element on the remote and returns the commit result.
  final Future<TResult> Function() createElement;

  /// Applies commit result to the optimistic element and returns the confirmed element.
  final Element Function(Element optimisticElement, TResult createResult) apply;

  @override
  List<Element>? applyConfirmed(List<Element> confirmed, TResult result) {
    final appliedElement = apply(element, result);
    return [...confirmed, appliedElement];
  }

  @override
  Future<TResult> commit(_) => createElement();

  @override
  List<Element> optimisticApply(List<Element> current) {
    return [...current, element];
  }

  @override
  String get logTag => 'ListAddElementTxOperation';
}
