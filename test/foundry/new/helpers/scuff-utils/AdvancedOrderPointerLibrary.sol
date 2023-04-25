pragma solidity ^0.8.17;

import "./ScuffDirectives.sol";
import "./BytesPointerLibrary.sol";
import "./OrderParametersPointerLibrary.sol";
import "../../../../../contracts/helpers/PointerLibraries.sol";

type AdvancedOrderPointer is uint256;

using Scuff for MemoryPointer;
using AdvancedOrderPointerLibrary for AdvancedOrderPointer global;

/// @dev Library for resolving pointers of encoded AdvancedOrder
/// struct AdvancedOrder {
///   OrderParameters parameters;
///   uint120 numerator;
///   uint120 denominator;
///   bytes signature;
///   bytes extraData;
/// }
library AdvancedOrderPointerLibrary {
  enum ScuffKind { parameters_HeadOverflow, parameters_offerer_DirtyBits, parameters_offerer_MaxValue, parameters_zone_DirtyBits, parameters_zone_MaxValue, parameters_offer_HeadOverflow, parameters_offer_length_DirtyBits, parameters_offer_length_MaxValue, parameters_offer_element_itemType_DirtyBits, parameters_offer_element_itemType_MaxValue, parameters_offer_element_token_DirtyBits, parameters_offer_element_token_MaxValue, parameters_consideration_HeadOverflow, parameters_consideration_length_DirtyBits, parameters_consideration_length_MaxValue, parameters_consideration_element_itemType_DirtyBits, parameters_consideration_element_itemType_MaxValue, parameters_consideration_element_token_DirtyBits, parameters_consideration_element_token_MaxValue, parameters_consideration_element_recipient_DirtyBits, parameters_consideration_element_recipient_MaxValue, parameters_orderType_DirtyBits, parameters_orderType_MaxValue, numerator_DirtyBits, numerator_MaxValue, denominator_DirtyBits, denominator_MaxValue, signature_HeadOverflow, extraData_HeadOverflow }

  enum ScuffableField { parameters, numerator, denominator, signature, extraData }

  uint256 internal constant numeratorOffset = 0x20;
  uint256 internal constant denominatorOffset = 0x40;
  uint256 internal constant signatureOffset = 0x60;
  uint256 internal constant extraDataOffset = 0x80;
  uint256 internal constant HeadSize = 0xa0;
  uint256 internal constant MinimumParametersScuffKind = uint256(ScuffKind.parameters_offerer_DirtyBits);
  uint256 internal constant MaximumParametersScuffKind = uint256(ScuffKind.parameters_orderType_MaxValue);

  /// @dev Convert a `MemoryPointer` to a `AdvancedOrderPointer`.
  /// This adds `AdvancedOrderPointerLibrary` functions as members of the pointer
  function wrap(MemoryPointer ptr) internal pure returns (AdvancedOrderPointer) {
    return AdvancedOrderPointer.wrap(MemoryPointer.unwrap(ptr));
  }

  /// @dev Convert a `AdvancedOrderPointer` back into a `MemoryPointer`.
  function unwrap(AdvancedOrderPointer ptr) internal pure returns (MemoryPointer) {
    return MemoryPointer.wrap(AdvancedOrderPointer.unwrap(ptr));
  }

  /// @dev Resolve the pointer to the head of `parameters` in memory.
  /// This points to the offset of the item's data relative to `ptr`
  function parametersHead(AdvancedOrderPointer ptr) internal pure returns (MemoryPointer) {
    return ptr.unwrap();
  }

  /// @dev Resolve the `OrderParametersPointer` pointing to the data buffer of `parameters`
  function parametersData(AdvancedOrderPointer ptr) internal pure returns (OrderParametersPointer) {
    return OrderParametersPointerLibrary.wrap(ptr.unwrap().offset(parametersHead(ptr).readUint256()));
  }

  /// @dev Resolve the pointer to the head of `numerator` in memory.
  /// This points to the beginning of the encoded `uint120`
  function numerator(AdvancedOrderPointer ptr) internal pure returns (MemoryPointer) {
    return ptr.unwrap().offset(numeratorOffset);
  }

  /// @dev Resolve the pointer to the head of `denominator` in memory.
  /// This points to the beginning of the encoded `uint120`
  function denominator(AdvancedOrderPointer ptr) internal pure returns (MemoryPointer) {
    return ptr.unwrap().offset(denominatorOffset);
  }

  /// @dev Resolve the pointer to the head of `signature` in memory.
  /// This points to the offset of the item's data relative to `ptr`
  function signatureHead(AdvancedOrderPointer ptr) internal pure returns (MemoryPointer) {
    return ptr.unwrap().offset(signatureOffset);
  }

  /// @dev Resolve the `BytesPointer` pointing to the data buffer of `signature`
  function signatureData(AdvancedOrderPointer ptr) internal pure returns (BytesPointer) {
    return BytesPointerLibrary.wrap(ptr.unwrap().offset(signatureHead(ptr).readUint256()));
  }

  /// @dev Resolve the pointer to the head of `extraData` in memory.
  /// This points to the offset of the item's data relative to `ptr`
  function extraDataHead(AdvancedOrderPointer ptr) internal pure returns (MemoryPointer) {
    return ptr.unwrap().offset(extraDataOffset);
  }

  /// @dev Resolve the `BytesPointer` pointing to the data buffer of `extraData`
  function extraDataData(AdvancedOrderPointer ptr) internal pure returns (BytesPointer) {
    return BytesPointerLibrary.wrap(ptr.unwrap().offset(extraDataHead(ptr).readUint256()));
  }

  /// @dev Resolve the pointer to the tail segment of the struct.
  /// This is the beginning of the dynamically encoded data.
  function tail(AdvancedOrderPointer ptr) internal pure returns (MemoryPointer) {
    return ptr.unwrap().offset(HeadSize);
  }

  function addScuffDirectives(AdvancedOrderPointer ptr, ScuffDirectivesArray directives, uint256 kindOffset, ScuffPositions positions) internal pure {
    /// @dev Overflow offset for `parameters`
    directives.push(Scuff.lower(uint256(ScuffKind.parameters_HeadOverflow) + kindOffset, 224, ptr.parametersHead(), positions));
    /// @dev Add all nested directives in parameters
    ptr.parametersData().addScuffDirectives(directives, kindOffset + MinimumParametersScuffKind, positions);
    /// @dev Add dirty upper bits to `numerator`
    directives.push(Scuff.upper(uint256(ScuffKind.numerator_DirtyBits) + kindOffset, 136, ptr.numerator(), positions));
    /// @dev Set every bit in `numerator` to 1
    directives.push(Scuff.lower(uint256(ScuffKind.numerator_MaxValue) + kindOffset, 136, ptr.numerator(), positions));
    /// @dev Add dirty upper bits to `denominator`
    directives.push(Scuff.upper(uint256(ScuffKind.denominator_DirtyBits) + kindOffset, 136, ptr.denominator(), positions));
    /// @dev Set every bit in `denominator` to 1
    directives.push(Scuff.lower(uint256(ScuffKind.denominator_MaxValue) + kindOffset, 136, ptr.denominator(), positions));
    /// @dev Overflow offset for `signature`
    directives.push(Scuff.lower(uint256(ScuffKind.signature_HeadOverflow) + kindOffset, 224, ptr.signatureHead(), positions));
    /// @dev Overflow offset for `extraData`
    directives.push(Scuff.lower(uint256(ScuffKind.extraData_HeadOverflow) + kindOffset, 224, ptr.extraDataHead(), positions));
  }

  function getScuffDirectives(AdvancedOrderPointer ptr) internal pure returns (ScuffDirective[] memory) {
    ScuffDirectivesArray directives = Scuff.makeUnallocatedArray();
    ScuffPositions positions = EmptyPositions;
    addScuffDirectives(ptr, directives, 0, positions);
    return directives.finalize();
  }

  function toString(ScuffKind k) internal pure returns (string memory) {
    if (k == ScuffKind.parameters_HeadOverflow) return "parameters_HeadOverflow";
    if (k == ScuffKind.parameters_offerer_DirtyBits) return "parameters_offerer_DirtyBits";
    if (k == ScuffKind.parameters_offerer_MaxValue) return "parameters_offerer_MaxValue";
    if (k == ScuffKind.parameters_zone_DirtyBits) return "parameters_zone_DirtyBits";
    if (k == ScuffKind.parameters_zone_MaxValue) return "parameters_zone_MaxValue";
    if (k == ScuffKind.parameters_offer_HeadOverflow) return "parameters_offer_HeadOverflow";
    if (k == ScuffKind.parameters_offer_length_DirtyBits) return "parameters_offer_length_DirtyBits";
    if (k == ScuffKind.parameters_offer_length_MaxValue) return "parameters_offer_length_MaxValue";
    if (k == ScuffKind.parameters_offer_element_itemType_DirtyBits) return "parameters_offer_element_itemType_DirtyBits";
    if (k == ScuffKind.parameters_offer_element_itemType_MaxValue) return "parameters_offer_element_itemType_MaxValue";
    if (k == ScuffKind.parameters_offer_element_token_DirtyBits) return "parameters_offer_element_token_DirtyBits";
    if (k == ScuffKind.parameters_offer_element_token_MaxValue) return "parameters_offer_element_token_MaxValue";
    if (k == ScuffKind.parameters_consideration_HeadOverflow) return "parameters_consideration_HeadOverflow";
    if (k == ScuffKind.parameters_consideration_length_DirtyBits) return "parameters_consideration_length_DirtyBits";
    if (k == ScuffKind.parameters_consideration_length_MaxValue) return "parameters_consideration_length_MaxValue";
    if (k == ScuffKind.parameters_consideration_element_itemType_DirtyBits) return "parameters_consideration_element_itemType_DirtyBits";
    if (k == ScuffKind.parameters_consideration_element_itemType_MaxValue) return "parameters_consideration_element_itemType_MaxValue";
    if (k == ScuffKind.parameters_consideration_element_token_DirtyBits) return "parameters_consideration_element_token_DirtyBits";
    if (k == ScuffKind.parameters_consideration_element_token_MaxValue) return "parameters_consideration_element_token_MaxValue";
    if (k == ScuffKind.parameters_consideration_element_recipient_DirtyBits) return "parameters_consideration_element_recipient_DirtyBits";
    if (k == ScuffKind.parameters_consideration_element_recipient_MaxValue) return "parameters_consideration_element_recipient_MaxValue";
    if (k == ScuffKind.parameters_orderType_DirtyBits) return "parameters_orderType_DirtyBits";
    if (k == ScuffKind.parameters_orderType_MaxValue) return "parameters_orderType_MaxValue";
    if (k == ScuffKind.numerator_DirtyBits) return "numerator_DirtyBits";
    if (k == ScuffKind.numerator_MaxValue) return "numerator_MaxValue";
    if (k == ScuffKind.denominator_DirtyBits) return "denominator_DirtyBits";
    if (k == ScuffKind.denominator_MaxValue) return "denominator_MaxValue";
    if (k == ScuffKind.signature_HeadOverflow) return "signature_HeadOverflow";
    return "extraData_HeadOverflow";
  }

  function toKind(uint256 k) internal pure returns (ScuffKind) {
    return ScuffKind(k);
  }

  function toKindString(uint256 k) internal pure returns (string memory) {
    return toString(toKind(k));
  }
}